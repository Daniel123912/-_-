import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/economy.dart';
import '../../domain/models.dart';
import '../../fx/finny_fx.dart';
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/fx_overlays.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider);
    final profile = ref.watch(gameControllerProvider).value;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final canPlay = profile.period.phase == PeriodPhase.playing;

    return Scaffold(
      body: PlayBackground(
        roomAsset: FinnyRooms.savings,
        child: content.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (data) {
            final goals = GameEconomy.goalsForProfile(profile, data.goals);
            SavingsGoal? goal;
            for (final g in goals) {
              if (g.id == profile.selectedGoalId) {
                goal = g;
                break;
              }
            }
            final left = GameEconomy.remainingToGoal(profile, goal);
            final canClaim =
                goal != null && profile.savingsBalance >= goal.cost;
            final planLeft = (profile.period.plan.savings -
                    profile.period.fact.saved)
                .clamp(0, profile.balance);

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: const Text('Накопления'),
                  backgroundColor: FinnyColors.bg.withValues(alpha: 0.78),
                  surfaceTintColor: Colors.transparent,
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      SoftCard(
                        color: const Color(0xFFEC4899).withValues(alpha: 0.22),
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'в копилке',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${profile.savingsBalance}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.2,
                                height: 1,
                              ),
                            ),
                            Text(
                              'монет',
                              style: TextStyle(
                                color: FinnyColors.glow,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (goal != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Цель: ${goal.name} (${goal.cost})',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                canClaim
                                    ? 'Можно забрать!'
                                    : 'Осталось: $left',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: (profile.savingsBalance / goal.cost)
                                      .clamp(0, 1),
                                  minHeight: 8,
                                  color: FinnyColors.glow,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                            ] else
                              const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Text(
                                  'Можно копить без цели — или выбери цель ниже.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            if (canPlay &&
                                profile.period.plan.savings > 0) ...[
                              const SizedBox(height: 12),
                              Text(
                                'План: ${profile.period.fact.saved} / ${profile.period.plan.savings}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (canClaim && goal != null) ...[
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () async {
                            final result = await ref
                                .read(gameControllerProvider.notifier)
                                .claimGoal(goal!);
                            if (!context.mounted) return;
                            if (result.celebrate) {
                              await showCelebration(
                                context,
                                title: result.celebrateTitle ?? 'Цель взята!',
                                message: result.message,
                                stars: result.earnedStars,
                              );
                            } else {
                              await showFeedback(
                                context,
                                result.message,
                                ok: result.ok,
                                stars: result.earnedStars,
                              );
                            }
                          },
                          icon: const Icon(Icons.celebration_rounded),
                          label: Text('Забрать «${goal.name}»'),
                        ),
                      ],
                      const SizedBox(height: 22),
                      const SectionLabel('Цели'),
                      const SizedBox(height: 10),
                      ...goals.map(
                        (g) {
                          final selected = profile.selectedGoalId == g.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SoftCard(
                              onTap: () => ref
                                  .read(gameControllerProvider.notifier)
                                  .selectGoal(g.id),
                              color: selected
                                  ? FinnyColors.purpleLight.withValues(alpha: 0.3)
                                  : null,
                              child: Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: FinnyColors.savings,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          g.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          '${g.description} · ${g.cost} монет',
                                          style: TextStyle(
                                            color: FinnyColors.mist,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      Text(
                        canPlay
                            ? 'Пополнить'
                            : 'Сначала план бюджета',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final amount in [
                            10,
                            15,
                            20,
                            if (planLeft > 0 &&
                                planLeft != 10 &&
                                planLeft != 15 &&
                                planLeft != 20)
                              planLeft,
                          ])
                            FilledButton(
                              onPressed: !canPlay
                                  ? null
                                  : () async {
                                      final result = await ref
                                          .read(
                                              gameControllerProvider.notifier)
                                          .saveToGoal(amount);
                                      if (!context.mounted) return;
                                      if (result.ok) {
                                        await FinnyFx.save();
                                        if (!context.mounted) return;
                                        await showPiggyPulse(
                                          context,
                                          amount: amount,
                                        );
                                      }
                                      if (!context.mounted) return;
                                      if (result.celebrate) {
                                        await showCelebration(
                                          context,
                                          title: result.celebrateTitle ??
                                              'Миссия!',
                                          message: result.message,
                                          stars: result.earnedStars,
                                        );
                                      } else {
                                        await showFeedback(
                                          context,
                                          result.message,
                                          ok: result.ok,
                                        );
                                      }
                                    },
                              child: Text('+$amount'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () async {
                          final warn = await ref
                              .read(gameControllerProvider.notifier)
                              .withdraw(15, confirmed: false);
                          if (!context.mounted) return;
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Снять из копилки?'),
                              content: Text(warn.message),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Нет'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('Да, снять'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            final result = await ref
                                .read(gameControllerProvider.notifier)
                                .withdraw(15, confirmed: true);
                            if (context.mounted) {
                              await showFeedback(
                                context,
                                result.message,
                                ok: result.ok,
                              );
                            }
                          }
                        },
                        child: const Text('Снять 15 из копилки'),
                      ),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
