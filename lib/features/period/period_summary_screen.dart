import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/economy.dart';
import '../../domain/engagement.dart';
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

class PeriodSummaryScreen extends ConsumerStatefulWidget {
  const PeriodSummaryScreen({super.key});

  @override
  ConsumerState<PeriodSummaryScreen> createState() =>
      _PeriodSummaryScreenState();
}

class _PeriodSummaryScreenState extends ConsumerState<PeriodSummaryScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Пока идёт пауза — раз в секунду обновляем кнопку.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _goNext({bool forceDemo = false}) async {
    final notifier = ref.read(gameControllerProvider.notifier);
    if (forceDemo) {
      await notifier.setDemoMode(true);
    }
    final advanced = await notifier.nextPeriod();
    if (!mounted) return;
    if (advanced) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(gameControllerProvider).value!;
    final plan = profile.period.plan;
    final fact = profile.period.fact;
    final canAdvance = GameEconomy.canAdvancePeriod(profile);
    final cooldown = GameEconomy.periodCooldownLeft(profile);
    final waitLabel = cooldown == null
        ? ''
        : GameEconomy.formatDurationShort(cooldown);

    return Scaffold(
      body: PlayBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(
                Engagement.storyForPeriod(profile.period.index).title,
              ),
              backgroundColor: FinnyColors.bg.withValues(alpha: 0.78),
              surfaceTintColor: Colors.transparent,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SoftCard(
                    color: profile.period.feedback.contains('Как поправить')
                        ? FinnyColors.coral.withValues(alpha: 0.2)
                        : FinnyColors.sky,
                    child: Text(
                      profile.period.feedback.isEmpty
                          ? profile.lastFeedback
                          : profile.period.feedback,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'План и факт',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        _Row('Обязательное', plan.mandatory, fact.mandatorySpent),
                        _Row('Желаемое', plan.optional, fact.optionalSpent),
                        _Row('Накопления', plan.savings, fact.saved),
                        _Row('Подарить', plan.gift, fact.giftSpent),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            PetAvatar(
                              appearance: profile.appearance,
                              stage: profile.growthStage,
                              mood: profile.mood,
                              hunger: profile.hunger,
                              petName: profile.petName,
                              ownedItemIds: profile.ownedItemIds,
                              size: 72,
                              showLabel: false,
                              animate: false,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Стадия ${profile.growthStage} «${GameEconomy.stageTitle(profile.growthStage)}»',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(GameEconomy.stageProgressHint(profile)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('★ ${profile.stars} · навыки XP ${profile.skills.totalXp}'),
                        Text(
                          'Задания периода: ${profile.period.periodQuestsDone}/${profile.period.activeQuestIds.isEmpty ? profile.period.completedQuestIds.length : profile.period.activeQuestIds.length}',
                        ),
                        Text(
                          'Сытость: ${profile.hunger} · Настроение: ${profile.mood}',
                        ),
                        if (profile.comboBest > 0)
                          Text('Лучшее комбо: ×${profile.comboBest}'),
                        if (profile.demoMode)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Демо: следующий период без ожидания.',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        if (!canAdvance && waitLabel.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Пауза ещё $waitLabel. Для экспертов можно продолжить сразу.',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CollectionsCard(ownedItemIds: profile.ownedItemIds),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: canAdvance ? () => _goNext() : null,
                    child: Text(
                      canAdvance
                          ? 'Следующий период'
                          : 'Подождите $waitLabel',
                    ),
                  ),
                  if (!canAdvance) ...[
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () => _goNext(forceDemo: true),
                      child: const Text('Продолжить сразу (демо)'),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.plan, this.fact);

  final String label;
  final int plan;
  final int fact;

  @override
  Widget build(BuildContext context) {
    final ok = (fact - plan).abs() <= 10;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text('план $plan'),
          const SizedBox(width: 12),
          Text(
            'факт $fact',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: ok ? FinnyColors.forest : FinnyColors.coral,
            ),
          ),
        ],
      ),
    );
  }
}
