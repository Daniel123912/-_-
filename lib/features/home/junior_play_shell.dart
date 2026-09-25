import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/economy.dart';
import '../../domain/engagement.dart';
import '../../domain/models.dart';
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../adult/adult_screen.dart';
import '../budget/budget_screen.dart';
import '../learn/learn_screen.dart';
import '../period/period_summary_screen.dart';
import '../quests/quests_screen.dart';
import '../savings/savings_screen.dart';
import '../shop/shop_screen.dart';
import '../widgets/common.dart';

/// Единый игровой «Talking Tom»-шелл (стиль 7–8) для всех возрастов:
/// большая комната с питомцем + яркая нижняя панель.
class JuniorPlayShell extends ConsumerStatefulWidget {
  const JuniorPlayShell({super.key});

  @override
  ConsumerState<JuniorPlayShell> createState() => _JuniorPlayShellState();
}

class _JuniorPlayShellState extends ConsumerState<JuniorPlayShell> {
  var _tab = 0;
  var _loginClaimed = false;
  /// Временная реплика (тап / бонус / реакция). null → живой контекст.
  String? _overrideSpeech;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoginBonus());
  }

  void _pinSpeech(String text) {
    setState(() => _overrideSpeech = text);
  }

  Future<void> _tryLoginBonus() async {
    if (_loginClaimed || !mounted) return;
    _loginClaimed = true;
    final result =
        await ref.read(gameControllerProvider.notifier).claimDailyLogin();
    if (!mounted || !result.ok) return;
    _pinSpeech(result.message);
  }

  void _onSpeak(String text) {
    _pinSpeech(text);
  }

  Future<void> _claimSecret() async {
    final result =
        await ref.read(gameControllerProvider.notifier).claimSecretOfDay();
    if (!mounted) return;
    _pinSpeech(result.message);
    if (result.celebrate) {
      await showCelebration(
        context,
        title: result.celebrateTitle ?? 'Секрет дня!',
        message: result.message,
        stars: result.earnedStars,
      );
    } else {
      await showFeedback(context, result.message, ok: result.ok);
    }
  }

  Future<void> _runNext(NextAction next) async {
    if (next.kind == NextActionKind.finishPeriod) {
      final closed =
          await ref.read(gameControllerProvider.notifier).finishPeriod();
      if (!mounted) return;
      if (closed.stageGrew) {
        await showCelebration(
          context,
          title: 'Новая стадия!',
          message: closed.feedback,
        );
      } else {
        // Показываем итог (хороший streak или «как поправить») сразу на питомце.
        _pinSpeech(closed.feedback);
      }
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PeriodSummaryScreen()),
      );
      return;
    }
    if (next.kind == NextActionKind.viewSummary) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PeriodSummaryScreen()),
      );
      return;
    }
    setState(() {
      _tab = switch (next.kind) {
        NextActionKind.planBudget => 4,
        NextActionKind.doQuests => 1,
        NextActionKind.buyMandatory => 2,
        NextActionKind.saveMoney || NextActionKind.claimGoal => 3,
        _ => 0,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(gameControllerProvider).value;
    if (profile == null) {
      return const Scaffold(body: Center(child: Text('Нет профиля')));
    }

    final content = ref.watch(contentProvider);
    final goal = content.maybeWhen(
      data: (data) {
        for (final g in GameEconomy.goalsForProfile(profile, data.goals)) {
          if (g.id == profile.selectedGoalId) return g;
        }
        return null;
      },
      orElse: () => null,
    );
    final next = GameEconomy.nextAction(profile, goal: goal);
    final story = Engagement.storyForPeriod(profile.period.index);
    final canSecret = GameEconomy.canClaimSecretOfDay(profile);
    final contextSpeech = Engagement.petContextSpeech(
      profile: profile,
      next: next,
      goalName: goal?.name,
    );
    final bubbleText = _overrideSpeech ?? contextSpeech;

    // После покупки / задания / копилки — питомец объясняет «что изменилось».
    ref.listen(gameControllerProvider, (prev, nextAsync) {
      final before = prev?.value;
      final after = nextAsync.value;
      if (before == null || after == null || !mounted) return;
      if (_tab != 0) return;
      final afterGoal = content.maybeWhen(
        data: (data) {
          for (final g in GameEconomy.goalsForProfile(after, data.goals)) {
            if (g.id == after.selectedGoalId) return g;
          }
          return null;
        },
        orElse: () => null,
      );
      final afterNext = GameEconomy.nextAction(after, goal: afterGoal);
      final reaction = Engagement.petStateChangeSpeech(
        before: before,
        after: after,
        next: afterNext,
        goalName: afterGoal?.name,
      );
      if (reaction == null) return;
      setState(() => _overrideSpeech = reaction);
    });

    // Ленивые вкладки: IndexedStack держал все экраны (и ~30MB PNG магазина) сразу.
    final Widget body = switch (_tab) {
      1 => const QuestsScreen(),
      2 => const ShopScreen(),
      3 => const SavingsScreen(),
      4 => const BudgetScreen(),
      _ => _JuniorPetRoom(
          profile: profile,
          next: next,
          story: story,
          bubbleText: bubbleText,
          canSecret: canSecret,
          onSpeak: _onSpeak,
          onSecret: _claimSecret,
          onNext: () => _runNext(next),
          onLearn: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LearnScreen()),
          ),
          onAdult: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdultGateScreen()),
          ),
          onCoplay: () => setState(() {
            _tab = profile.period.phase == PeriodPhase.planning ? 4 : 3;
            _overrideSpeech = profile.period.phase == PeriodPhase.planning
                ? 'Составь план с монетами от родителя!'
                : 'Отложи часть в копилку — вы вместе!';
          }),
        ),
    };

    return Scaffold(
      extendBody: false,
      body: body,
      bottomNavigationBar: _JuniorDock(
        index: _tab,
        onChanged: (i) => setState(() {
          _tab = i;
          // Возврат домой → свежий контекст «что дальше».
          if (i == 0) _overrideSpeech = null;
        }),
      ),
    );
  }
}

class _JuniorPetRoom extends StatelessWidget {
  const _JuniorPetRoom({
    required this.profile,
    required this.next,
    required this.story,
    required this.bubbleText,
    required this.canSecret,
    required this.onSpeak,
    required this.onSecret,
    required this.onNext,
    required this.onLearn,
    required this.onAdult,
    required this.onCoplay,
  });

  final PlayerProfile profile;
  final NextAction next;
  final PeriodStory story;
  final String bubbleText;
  final bool canSecret;
  final ValueChanged<String> onSpeak;
  final VoidCallback onSecret;
  final VoidCallback onNext;
  final VoidCallback onLearn;
  final VoidCallback onAdult;
  final VoidCallback onCoplay;

  @override
  Widget build(BuildContext context) {
    // Scaffold уже резервирует место под dock — не дублируем +88.
    const bottomPad = 12.0;
    final challenge = profile.parentChallengeTarget;
    final h = MediaQuery.sizeOf(context).height;
    final compact = h < 720;

    return PlayBackground(
      roomAsset: FinnyRooms.home,
      scrimTop: 0.22,
      scrimBottom: 0.12,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final petSize = (constraints.maxHeight * (compact ? 0.40 : 0.44))
                .clamp(180.0, compact ? 260.0 : 300.0);
            final gap = compact ? 8.0 : 12.0;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, bottomPad),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - bottomPad - 6,
                ),
                child: Column(
                  children: [
                    _TopHud(
                      balance: profile.balance,
                      savings: profile.savingsBalance,
                      stars: profile.stars,
                      canSecret: canSecret,
                      onSecret: onSecret,
                      onLearn: onLearn,
                      onAdult: onAdult,
                    ),
                    SizedBox(height: gap),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        story.hook,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          height: 1.15,
                        ),
                      ),
                    ),
                    if (challenge != null) ...[
                      SizedBox(height: gap),
                      _ChallengeBar(
                        saved: profile.parentChallengeSaved,
                        target: challenge,
                      ),
                    ],
                    if (profile.parentCoplayPending) ...[
                      SizedBox(height: gap),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: onCoplay,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFEC4899)
                                      .withValues(alpha: 0.85),
                                  const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.85),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              profile.period.phase == PeriodPhase.planning
                                  ? 'Вместе! Родитель дал +${profile.parentCoplayAmount} — составь план →'
                                  : 'Вместе! +${profile.parentCoplayAmount} от родителя — отложи в копилку →',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: gap),
                    Row(
                      children: [
                        Expanded(
                          child: _StatFace(
                            icon: Icons.restaurant_rounded,
                            label: 'Сытость',
                            value: profile.hunger,
                            color: const Color(0xFF2DD4BF),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatFace(
                            icon: Icons.sentiment_satisfied_alt_rounded,
                            label: 'Настрой',
                            value: profile.mood,
                            color: const Color(0xFFFBBF24),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: gap),
                    _SpeechBubble(text: bubbleText),
                    SizedBox(height: compact ? 4 : 8),
                    PetAvatar(
                      appearance: profile.appearance,
                      stage: profile.growthStage,
                      mood: profile.mood,
                      hunger: profile.hunger,
                      petName: profile.petName,
                      ownedItemIds: profile.ownedItemIds,
                      size: petSize,
                      showLabel: false,
                      animate: true,
                      onSpeak: onSpeak,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.petName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                            shadows: const [
                              Shadow(
                                color: Colors.black38,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'стадия ${profile.growthStage} «${GameEconomy.stageTitle(profile.growthStage)}» · ★ ${profile.stars}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        height: 1.15,
                      ),
                    ),
                    Text(
                      GameEconomy.stageProgressHint(profile),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: gap + 2),
                    _PlayCta(
                      title: next.title,
                      onTap: onNext,
                    ),
                    const SizedBox(height: 8),
                    _LearnInvite(onTap: onLearn),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChallengeBar extends StatelessWidget {
  const _ChallengeBar({required this.saved, required this.target});

  final int saved;
  final int target;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF34D399).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF34D399)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Миссия от родителя: $saved/$target',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: target <= 0 ? 0 : (saved / target).clamp(0.0, 1.0),
              minHeight: 8,
              color: const Color(0xFF34D399),
              backgroundColor: Colors.black26,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeInOutSine,
          switchOutCurve: Curves.easeInOutSine,
          child: Text(
            text,
            key: ValueKey(text),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF4C1D95),
              fontWeight: FontWeight.w800,
              fontSize: 14,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayCta extends StatelessWidget {
  const _PlayCta({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8A3D), Color(0xFFFF4D8D)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4D8D).withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LearnInvite extends StatelessWidget {
  const _LearnInvite({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withValues(alpha: 0.18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34D399),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Школа Финни',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      height: 1.1,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopHud extends StatelessWidget {
  const _TopHud({
    required this.balance,
    required this.savings,
    required this.stars,
    required this.canSecret,
    required this.onSecret,
    required this.onLearn,
    required this.onAdult,
  });

  final int balance;
  final int savings;
  final int stars;
  final bool canSecret;
  final VoidCallback onSecret;
  final VoidCallback onLearn;
  final VoidCallback onAdult;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _HudPill(
                  icon: Icons.payments_rounded,
                  label: '$balance',
                  color: const Color(0xFFFBBF24),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _HudPill(
                  icon: Icons.savings_rounded,
                  label: '$savings',
                  color: const Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _HudPill(
                  icon: Icons.star_rounded,
                  label: '$stars',
                  color: const Color(0xFFF472B6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canSecret) ...[
              _RoundIconButton(
                icon: Icons.auto_awesome_rounded,
                color: const Color(0xFFF59E0B),
                onTap: onSecret,
              ),
              const SizedBox(width: 6),
            ],
            _RoundIconButton(
              icon: Icons.auto_stories_rounded,
              color: const Color(0xFF34D399),
              onTap: onLearn,
            ),
            const SizedBox(width: 6),
            _RoundIconButton(
              icon: Icons.family_restroom_rounded,
              color: Colors.white24,
              onTap: onAdult,
            ),
          ],
        ),
      ],
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _StatFace extends StatelessWidget {
  const _StatFace({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    height: 1.1,
                  ),
                ),
              ),
              Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (value.clamp(0, 100)) / 100,
              minHeight: 7,
              backgroundColor: Colors.black26,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _JuniorDock extends StatelessWidget {
  const _JuniorDock({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = <({IconData icon, String label, Color color})>[
    (icon: Icons.home_rounded, label: 'Дом', color: Color(0xFFC4B5FD)),
    (icon: Icons.extension_rounded, label: 'Квесты', color: Color(0xFFF472B6)),
    (icon: Icons.storefront_rounded, label: 'Магазин', color: Color(0xFFFBBF24)),
    (icon: Icons.savings_rounded, label: 'Копилка', color: Color(0xFF38BDF8)),
    (icon: Icons.pie_chart_rounded, label: 'План', color: Color(0xFF34D399)),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final active = _items[index.clamp(0, _items.length - 1)].color;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 8 + bottom * 0.35),
        child: Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3B1A7A),
                Color(0xFF24104F),
                Color(0xFF1A0B3A),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: active.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _DockItem(
                    icon: _items[i].icon,
                    label: _items[i].label,
                    color: _items[i].color,
                    selected: index == i,
                    onTap: () => onChanged(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: color.withValues(alpha: 0.25),
        highlightColor: color.withValues(alpha: 0.12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeInOutSine,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: selected ? color.withValues(alpha: 0.16) : Colors.transparent,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeInOutSine,
                width: selected ? 42 : 38,
                height: selected ? 42 : 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: selected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(color, Colors.white, 0.28)!,
                            color,
                            Color.lerp(color, Colors.black, 0.12)!,
                          ],
                        )
                      : null,
                  color: selected ? null : color.withValues(alpha: 0.2),
                  border: Border.all(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.55)
                        : color.withValues(alpha: 0.35),
                    width: selected ? 1.8 : 1.1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.55),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : const <BoxShadow>[],
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : color,
                  size: selected ? 24 : 20,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.72),
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  fontSize: 11,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
