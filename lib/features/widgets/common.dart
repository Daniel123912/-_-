import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/economy.dart';
import '../../domain/engagement.dart';
import '../../domain/models.dart';
import '../../theme/app_theme.dart';

class PetAvatar extends StatefulWidget {
  const PetAvatar({
    super.key,
    required this.appearance,
    required this.stage,
    this.size = 120,
    this.showLabel = true,
    this.mood = 70,
    this.hunger = 70,
    this.animate = true,
    this.scaleByStage = true,
    this.ownedItemIds = const [],
    this.petName = 'Финни',
    this.onTap,
    this.onSpeak,
  });

  final PetAppearance appearance;
  final int stage;
  final double size;
  final bool showLabel;
  final int mood;
  final int hunger;
  final bool animate;
  /// When false, [size] is used as-is (useful for create/preview).
  final bool scaleByStage;
  final List<String> ownedItemIds;
  final String petName;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSpeak;

  @override
  State<PetAvatar> createState() => _PetAvatarState();
}

class _PetAvatarState extends State<PetAvatar> with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _react;
  bool _showHeart = false;
  bool _showTear = false;

  Color get _color {
    return switch (widget.appearance.color) {
      'розовый' => const Color(0xFFBE608A),
      'фиолетовый' => const Color(0xFF8B5CF6),
      'синий' => const Color(0xFF6AA8C3),
      _ => FinnyColors.purpleBright,
    };
  }

  String get _accessoryLabel {
    return switch (widget.appearance.accessory) {
      'ромбики' => '◆',
      'на голове' => '✦',
      _ => '·',
    };
  }

  @override
  void initState() {
    super.initState();
    // Один непрерывный цикл 0→1 без reverse — синус без рывков на стыках.
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    _react = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.animate) {
      _float.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PetAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_float.isAnimating) {
      _float.repeat();
    } else if (!widget.animate && _float.isAnimating) {
      _float.stop();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _react.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    final speech = Engagement.petTapSpeech(
      petName: widget.petName,
      hunger: widget.hunger,
      mood: widget.mood,
    );
    widget.onSpeak?.call(speech);
    widget.onTap?.call();

    final sad = widget.hunger < 35 || widget.mood < 40;
    setState(() {
      _showHeart = !sad;
      _showTear = sad;
    });
    await _react.forward(from: 0);
    if (mounted) {
      setState(() {
        _showHeart = false;
        _showTear = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage.clamp(1, 3);
    // Заметная разница размеров: Малыш → Растущий → Чемпион.
    final stageScale = !widget.scaleByStage
        ? 1.0
        : switch (stage) {
            1 => 0.72,
            2 => 1.0,
            _ => 1.22,
          };
    final floatAmp = widget.mood < 40 ? 3.5 : (stage == 3 ? 7.0 : 5.5);
    final stageLabel = switch (stage) {
      1 => 'Малыш',
      2 => 'Растущий',
      _ => 'Чемпион',
    };
    final ringColor = switch (stage) {
      1 => const Color(0xFFDDD6FE),
      2 => FinnyColors.sky,
      _ => FinnyColors.gold,
    };
    // SVG / PNG модель: соотношение сторон по стадии роста.
    final aspect = switch (stage) {
      1 => 174 / 206,
      2 => 280 / 391,
      _ => 490 / 544,
    };
    final petHeight = widget.size * stageScale;
    final petWidth = petHeight * aspect;
    final cosmetics = Engagement.visualsFor(widget.ownedItemIds);
    final svgPath = widget.appearance.assetPathFor(
      hunger: widget.hunger,
      mood: widget.mood,
      stage: stage,
    );
    final rasterPath = widget.appearance.rasterPathFor(
      hunger: widget.hunger,
      mood: widget.mood,
      stage: stage,
    );
    final dpr = MediaQuery.devicePixelRatioOf(context);
    // Растерам не даём «мылить» питомца: на больших экранах берём SVG.
    final useSvg = petWidth * dpr > 360;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _handleTap,
          child: SizedBox(
            width: petWidth + 48,
            height: petHeight + 48,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([_float, _react]),
                builder: (context, child) {
                  // Idle: чистый синус — без reverse и углов.
                  final phase =
                      widget.animate ? _float.value * 2 * math.pi : 0.0;
                  final dy = math.sin(phase) * floatAmp;
                  final rot = math.sin(phase + 0.6) * 0.018;
                  final breath = 1 + math.sin(phase) * 0.012;

                  // Tap: мягкий подъём и лёгкий наклон, без прыжка.
                  final r = Curves.easeInOutSine.transform(_react.value);
                  final reactLift = -10 * math.sin(math.pi * r);
                  final reactScale = 1 + 0.035 * math.sin(math.pi * r);
                  final reactTilt =
                      0.04 * math.sin(2 * math.pi * r) * (1 - r);

                  return Transform.translate(
                    offset: Offset(0, dy + reactLift),
                    child: Transform.rotate(
                      angle: rot + reactTilt,
                      child: Transform.scale(
                        scale: breath * reactScale,
                        child: child,
                      ),
                    ),
                  );
                },
                child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  for (final c in cosmetics)
                    if (c.slot == CosmeticSlot.room)
                      Positioned(
                        left: 0,
                        top: widget.size * 0.05,
                        child: _CosmeticBadge(
                          visual: c,
                          size: widget.size * 0.28,
                        ),
                      ),
                  if (stage >= 2)
                    Container(
                      width: petWidth + (stage == 3 ? 36 : 24),
                      height: petHeight + (stage == 3 ? 28 : 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(petHeight * 0.45),
                        border: Border.all(
                          color: ringColor.withValues(alpha: 0.45),
                          width: stage == 3 ? 3 : 2,
                        ),
                        boxShadow: stage == 3
                            ? [
                                BoxShadow(
                                  color: FinnyColors.gold.withValues(alpha: 0.3),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  if (stage == 3) ...[
                    Positioned(
                      left: 4,
                      child: Icon(
                        Icons.flare_rounded,
                        size: widget.size * 0.22,
                        color: FinnyColors.gold.withValues(alpha: 0.85),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      child: Icon(
                        Icons.flare_rounded,
                        size: widget.size * 0.22,
                        color: FinnyColors.gold.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                  // Мягкая тень под питомцем
                  Positioned(
                    bottom: widget.size * 0.02,
                    child: Container(
                      width: petWidth * 0.72,
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: petWidth,
                    height: petHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 480),
                          switchInCurve: Curves.easeInOutSine,
                          switchOutCurve: Curves.easeInOutSine,
                          transitionBuilder: (child, anim) {
                            return FadeTransition(
                              opacity: anim,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.97, end: 1)
                                    .animate(anim),
                                child: child,
                              ),
                            );
                          },
                          child: useSvg
                              ? SvgPicture.asset(
                                  svgPath,
                                  key: ValueKey('$svgPath-$stage'),
                                  width: petWidth,
                                  height: petHeight,
                                  fit: BoxFit.contain,
                                  placeholderBuilder: (_) => SvgPicture.asset(
                                    widget.appearance.assetPath,
                                    width: petWidth,
                                    height: petHeight,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : Image.asset(
                                  rasterPath,
                                  key: ValueKey('$rasterPath-$stage'),
                                  width: petWidth,
                                  height: petHeight,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  cacheWidth:
                                      (petWidth * dpr).round().clamp(64, 720),
                                  gaplessPlayback: true,
                                  errorBuilder: (_, error, stackTrace) =>
                                      SvgPicture.asset(
                                    svgPath,
                                    width: petWidth,
                                    height: petHeight,
                                    fit: BoxFit.contain,
                                    placeholderBuilder: (_) =>
                                        SvgPicture.asset(
                                      widget.appearance.assetPath,
                                      width: petWidth,
                                      height: petHeight,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                        ),
                        if (stage >= 2)
                          Positioned(
                            top: petHeight * 0.02,
                            child: Container(
                              width: widget.size * 0.2,
                              height: widget.size * 0.2,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFDE68A),
                                    Color(0xFFD97706),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: FinnyColors.goldDark
                                        .withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                stage == 3 ? '★' : '₽',
                                style: TextStyle(
                                  fontSize: widget.size * 0.085,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: petHeight * 0.08,
                          right: -2,
                          child: Container(
                            width: widget.size * 0.18,
                            height: widget.size * 0.18,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white70),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _accessoryLabel,
                              style: TextStyle(
                                fontSize: widget.size * 0.08,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final c in cosmetics)
                    if (c.slot == CosmeticSlot.head)
                      Positioned(
                        top: widget.size * 0.02,
                        child: _CosmeticBadge(
                          visual: c,
                          size: widget.size * 0.32,
                        ),
                      ),
                  for (final c in cosmetics)
                    if (c.slot == CosmeticSlot.held)
                      Positioned(
                        right: 0,
                        bottom: widget.size * 0.12,
                        child: _CosmeticBadge(
                          visual: c,
                          size: widget.size * 0.3,
                        ),
                      ),
                  AnimatedOpacity(
                    opacity: _showHeart ? 1 : 0,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOutSine,
                    child: AnimatedSlide(
                      offset: _showHeart
                          ? const Offset(0, -0.35)
                          : Offset.zero,
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeInOutSine,
                      child: const Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: EdgeInsets.only(top: 4, right: 10),
                          child: Text('💜', style: TextStyle(fontSize: 26)),
                        ),
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _showTear ? 1 : 0,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOutSine,
                    child: AnimatedSlide(
                      offset: _showTear
                          ? const Offset(0, 0.25)
                          : Offset.zero,
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeInOutSine,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: widget.size * 0.22,
                            top: widget.size * 0.18,
                          ),
                          child: const Text('💧', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        ),
        if (widget.showLabel) ...[
          const SizedBox(height: 10),
          Text(
            'Стадия $stage «$stageLabel» · ${widget.appearance.label}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FinnyColors.mist,
                ),
          ),
        ],
      ],
    );
  }
}

class _CosmeticBadge extends StatelessWidget {
  const _CosmeticBadge({required this.visual, required this.size});

  final CosmeticVisual visual;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (visual.image.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          visual.image,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
              .round()
              .clamp(64, 512),
          cacheHeight: (size * MediaQuery.devicePixelRatioOf(context))
              .round()
              .clamp(64, 512),
          errorBuilder: (_, __, ___) => Icon(
            Icons.toys_rounded,
            size: size * 0.7,
            color: FinnyColors.mist,
          ),
        ),
      );
    }
    return Text(
      visual.emoji,
      style: TextStyle(fontSize: size * 0.85),
    );
  }
}

class StatBar extends StatelessWidget {
  const StatBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: FinnyFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const Spacer(),
            Text(
              '$value%',
              style: FinnyFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value / 100),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutSine,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 10,
              color: color,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ),
      ],
    );
  }
}

class SkillChip extends StatelessWidget {
  const SkillChip({
    super.key,
    required this.theme,
    required this.level,
    required this.xp,
  });

  final QuestTheme theme;
  final int level;
  final int xp;

  Color get _color => switch (theme) {
        QuestTheme.budget => FinnyColors.mint,
        QuestTheme.savings => FinnyColors.sky,
        QuestTheme.purchases => FinnyColors.gold,
      };

  String get _label => switch (theme) {
        QuestTheme.budget => 'Бюджет',
        QuestTheme.savings => 'Копилка',
        QuestTheme.purchases => 'Покупки',
      };

  @override
  Widget build(BuildContext context) {
    final progress = (xp % 40) / 40;
    return SoftCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _label,
            style: FinnyFonts.nunito(
              fontWeight: FontWeight.w800,
              color: _color,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'ур. $level',
            style: FinnyFonts.fredoka(
              fontWeight: FontWeight.w400,
              fontSize: 18,
              color: FinnyColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              color: _color,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({super.key, required this.difficulty});

  final QuestDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final color = switch (difficulty) {
      QuestDifficulty.easy => FinnyColors.mint,
      QuestDifficulty.medium => FinnyColors.gold,
      QuestDifficulty.hard => FinnyColors.pink,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        difficulty.label,
        style: FinnyFonts.nunito(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Единый блок учебного прогресса (задания, цель, итог периода).
class LearnProgressCard extends StatelessWidget {
  const LearnProgressCard({
    super.key,
    required this.profile,
    this.goal,
    this.lessonsDone = 0,
    this.lessonsTotal = 0,
    this.onTap,
  });

  final PlayerProfile profile;
  final SavingsGoal? goal;
  final int lessonsDone;
  final int lessonsTotal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final questsDone = profile.completedQuestIds.length;
    final periodDone = profile.period.periodQuestsDone;
    final periodTotal = profile.period.activeQuestIds.isEmpty
        ? 0
        : profile.period.activeQuestIds.length;
    final goalText = goal == null
        ? 'Цель ещё не выбрана'
        : '${goal!.name}: ${profile.savingsBalance}/${goal!.cost}';
    final goalProgress = goal == null || goal!.cost <= 0
        ? 0.0
        : (profile.savingsBalance / goal!.cost).clamp(0.0, 1.0);
    final lastPeriod = profile.totalPeriodsCompleted <= 0
        ? 'Периодов ещё не завершено'
        : (profile.period.feedback.isNotEmpty
            ? profile.period.feedback
            : profile.lastFeedback);
    final stageHint = GameEconomy.stageProgressHint(profile);

    return SoftCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Учебный прогресс',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Задания: всего $questsDone · период $periodDone'
            '${periodTotal > 0 ? '/$periodTotal' : ''}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (lessonsTotal > 0) ...[
            const SizedBox(height: 4),
            Text('Уроки: $lessonsDone/$lessonsTotal'),
          ],
          const SizedBox(height: 10),
          Text(goalText, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: goalProgress,
              minHeight: 8,
              color: FinnyColors.savings,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Стадия ${profile.growthStage} «${GameEconomy.stageTitle(profile.growthStage)}»',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            stageHint,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          if (profile.totalPeriodsCompleted > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Последний период: $lastPeriod',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> showFeedback(
  BuildContext context,
  String message, {
  bool ok = true,
  int stars = 0,
  int xp = 0,
  int combo = 0,
  String? whyHint,
  String? tip,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(ok ? 'Отлично!' : 'Почти!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(fontSize: 16)),
          if (!ok && (whyHint != null && whyHint.isNotEmpty)) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FinnyColors.sun.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: FinnyColors.sun.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.lightbulb_rounded,
                        color: FinnyColors.sun,
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Почему так',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    whyHint,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!ok && tip != null && tip.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Подсказка: $tip',
              style: TextStyle(
                color: FinnyColors.mist,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
          if (stars > 0 || xp > 0 || combo > 1) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (stars > 0) _RewardPill(icon: Icons.star_rounded, text: '+$stars'),
                if (xp > 0) _RewardPill(icon: Icons.bolt_rounded, text: 'XP +$xp'),
                if (combo > 1)
                  _RewardPill(
                    icon: Icons.local_fire_department_rounded,
                    text: '×$combo',
                  ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(ok ? 'Понятно' : 'Попробую ещё'),
        ),
      ],
    ),
  );
}

/// Праздник с «конфетти» при цели / стадии / секрете / коллекции.
Future<void> showCelebration(
  BuildContext context, {
  required String title,
  required String message,
  int stars = 0,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'celebration',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, anim, _) {
      return SafeArea(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7C3AED), Color(0xFFDB2777), Color(0xFFFBBF24)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned(
                    top: -8,
                    left: 12,
                    child: Text('🎊', style: TextStyle(fontSize: 28)),
                  ),
                  const Positioned(
                    top: -4,
                    right: 20,
                    child: Text('✨', style: TextStyle(fontSize: 24)),
                  ),
                  const Positioned(
                    bottom: 48,
                    left: 8,
                    child: Text('🎉', style: TextStyle(fontSize: 22)),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: FinnyFonts.fredoka(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                      if (stars > 0) ...[
                        const SizedBox(height: 12),
                        Text(
                          '★ +$stars',
                          style: const TextStyle(
                            color: Color(0xFFFDE68A),
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF5B21B6),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Ура!'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class CollectionsCard extends StatelessWidget {
  const CollectionsCard({super.key, required this.ownedItemIds});

  final List<String> ownedItemIds;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Коллекции',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          for (final c in Engagement.collections) ...[
            Row(
              children: [
                Text(c.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${c.name}: ${c.ownedCount(ownedItemIds)}/${c.itemIds.length}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (c.isComplete(ownedItemIds))
                  const Icon(Icons.check_circle_rounded,
                      color: FinnyColors.mint, size: 18),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: c.progress(ownedItemIds),
                minHeight: 8,
                color: FinnyColors.gold,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [FinnyColors.purpleLight, FinnyColors.indigo],
        ),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: FinnyColors.gold),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Справка + короткий глоссарий терминов (п. 2.5.1 / 2.5.11 ТЗ).
Future<void> showTermsHelp(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Справка'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Как играть',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '1) Составь план бюджета.\n'
                '2) Выполни задания периода (есть и задания-действия).\n'
                '3) Купи нужное и пополни копилку.\n'
                '4) Заверши период и сравни план с фактом.\n\n'
                'Учёба — короткие уроки под возраст.\n'
                'Звёзды и XP — за умные решения.\n'
                'Комбо — серия правильных ответов подряд.',
              ),
              SizedBox(height: 16),
              Text(
                'Слова, которые важно знать',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Нужное (обязательное) — еда и уход: миска, вода, купание, витамины, лежанка, аптечка и другое. Без этого питомцу плохо.\n\n'
                'Желаемое (необязательное) — игрушки и украшения: можно отложить.\n\n'
                'Копилка / накопления — монеты, отложенные на цель отдельно от кармана.\n\n'
                'Цель — то, на что копишь (цена понятна).\n\n'
                'План — как решил разложить монеты до трат.\n\n'
                'Факт — куда монеты ушли на самом деле.\n\n'
                'Период — полный круг: план → решения → итог.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Понятно'),
        ),
      ],
    ),
  );
}
