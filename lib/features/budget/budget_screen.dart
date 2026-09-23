import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/economy.dart';
import '../../domain/models.dart';
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key, this.popOnSuccess = false});

  /// Когда экран открыт через Navigator.push (средний/старший трек).
  /// В junior-доке pop ломает весь шелл — не вызывать.
  final bool popOnSuccess;

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  double? mandatory;
  double? optional;
  double? savings;
  double? gift;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(gameControllerProvider).value;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final max = profile.balance.toDouble().clamp(0.0, 300.0).toDouble();
    final sliderMax = max < 1 ? 1.0 : max;
    final suggested = GameEconomy.recommendedPlan(profile);
    final m = mandatory ??
        (profile.period.plan.total > 0
            ? profile.period.plan.mandatory.toDouble()
            : suggested.mandatory.toDouble());
    final o = optional ??
        (profile.period.plan.total > 0
            ? profile.period.plan.optional.toDouble()
            : suggested.optional.toDouble());
    final s = savings ??
        (profile.period.plan.total > 0
            ? profile.period.plan.savings.toDouble()
            : suggested.savings.toDouble());
    final g = gift ??
        (profile.period.plan.total > 0
            ? profile.period.plan.gift.toDouble()
            : suggested.gift.toDouble());
    final total = m.round() + o.round() + s.round() + g.round();
    final left = profile.balance - total;
    final locked = profile.period.phase != PeriodPhase.planning;

    return Scaffold(
      body: PlayBackground(
        roomAsset: FinnyRooms.budget,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('План бюджета'),
              backgroundColor: FinnyColors.bg.withValues(alpha: 0.78),
              surfaceTintColor: Colors.transparent,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Доступно: ${profile.balance}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          locked
                              ? 'План уже готов.'
                              : 'Раздели монеты по корзинам.',
                        ),
                      ],
                    ),
                  ),
                  if (!locked) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        final plan = GameEconomy.recommendedPlan(profile);
                        setState(() {
                          mandatory = plan.mandatory.toDouble();
                          optional = plan.optional.toDouble();
                          savings = plan.savings.toDouble();
                          gift = plan.gift.toDouble();
                        });
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Подставить умный план'),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SoftCard(
                    child: Column(
                      children: [
                        _SliderBlock(
                          label: 'Обязательное',
                          value: m.clamp(0.0, sliderMax).toDouble(),
                          max: sliderMax,
                          color: FinnyColors.budget,
                          enabled: !locked,
                          onChanged: (v) => setState(() => mandatory = v),
                        ),
                        _SliderBlock(
                          label: 'Желаемое',
                          value: o.clamp(0.0, sliderMax).toDouble(),
                          max: sliderMax,
                          color: FinnyColors.purchases,
                          enabled: !locked,
                          onChanged: (v) => setState(() => optional = v),
                        ),
                        _SliderBlock(
                          label: 'Накопления',
                          value: s.clamp(0.0, sliderMax).toDouble(),
                          max: sliderMax,
                          color: FinnyColors.savings,
                          enabled: !locked,
                          onChanged: (v) => setState(() => savings = v),
                        ),
                        _SliderBlock(
                          label: 'Подарить',
                          value: g.clamp(0.0, sliderMax).toDouble(),
                          max: sliderMax,
                          color: FinnyColors.pink,
                          enabled: !locked,
                          onChanged: (v) => setState(() => gift = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SoftCard(
                    color: left < 0
                        ? FinnyColors.coral.withValues(alpha: 0.15)
                        : FinnyColors.sky,
                    child: Text(
                      'В плане: $total · Остаток: $left',
                      style: TextStyle(
                        fontSize: 18,
                        color: left < 0
                            ? Colors.red.shade700
                            : FinnyColors.forest,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!locked)
                    FilledButton(
                      onPressed: left < 0
                          ? null
                          : () async {
                              final plan = BudgetPlan(
                                mandatory: m.round(),
                                optional: o.round(),
                                savings: s.round(),
                                gift: g.round(),
                              );
                              final result = await ref
                                  .read(gameControllerProvider.notifier)
                                  .confirmBudget(plan);
                              if (!context.mounted) return;
                              if (result.ok && result.celebrate) {
                                await showCelebration(
                                  context,
                                  title: result.celebrateTitle ?? 'План вместе!',
                                  message: result.message,
                                );
                              } else {
                                await showFeedback(context, result.message,
                                    ok: result.ok);
                              }
                              if (result.ok &&
                                  widget.popOnSuccess &&
                                  context.mounted &&
                                  Navigator.of(context).canPop()) {
                                Navigator.pop(context);
                              }
                            },
                      child: const Text('Подтвердить план'),
                    ),
                  if (locked) ...[
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'План: обяз. ${profile.period.plan.mandatory}, жел. ${profile.period.plan.optional}, копилка ${profile.period.plan.savings}, подарок ${profile.period.plan.gift}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Факт: обяз. ${profile.period.fact.mandatorySpent}, жел. ${profile.period.fact.optionalSpent}, копилка ${profile.period.fact.saved}, подарок ${profile.period.fact.giftSpent}',
                          ),
                          if (profile.period.activeQuestIds.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Задания периода: ${profile.period.periodQuestsDone}/${profile.period.activeQuestIds.length}',
                            ),
                          ],
                        ],
                      ),
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

class _SliderBlock extends StatelessWidget {
  const _SliderBlock({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.enabled,
    required this.color,
    required this.max,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;
  final Color color;
  final double max;

  @override
  Widget build(BuildContext context) {
    final divisions = (max / 5).round().clamp(4, 60);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              '$label: ${value.round()}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        Slider(
          value: value.clamp(0, max),
          max: max,
          divisions: divisions,
          activeColor: color,
          label: '${value.round()}',
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}
