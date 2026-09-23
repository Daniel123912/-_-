import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../fx/finny_fx.dart';
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/fx_overlays.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider);
    final profile = ref.watch(gameControllerProvider).value;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final plan = profile.period.plan;
    final fact = profile.period.fact;
    final canPlay = profile.period.phase == PeriodPhase.playing;

    return Scaffold(
      body: PlayBackground(
        roomAsset: FinnyRooms.shop,
        child: content.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (data) {
            final mandatory = data.items
                .where((e) => e.kind == ExpenseKind.mandatory)
                .toList(growable: false);
            final optional = data.items
                .where((e) => e.kind == ExpenseKind.optional)
                .toList(growable: false);
            final gifts = data.items
                .where((e) => e.kind == ExpenseKind.gift)
                .toList(growable: false);

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: const Text('Покупки'),
                  backgroundColor: FinnyColors.bg.withValues(alpha: 0.78),
                  surfaceTintColor: Colors.transparent,
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Баланс: ${profile.balance}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            canPlay
                                ? 'Сначала купи нужное: еда и уход.'
                                : 'Сначала подтверди план.',
                          ),
                          if (plan.total > 0) ...[
                            const SizedBox(height: 12),
                            _PlanBar(
                              label: 'Обязательное',
                              plan: plan.mandatory,
                              fact: fact.mandatorySpent,
                              color: FinnyColors.budget,
                            ),
                            const SizedBox(height: 8),
                            _PlanBar(
                              label: 'Желаемое',
                              plan: plan.optional,
                              fact: fact.optionalSpent,
                              color: FinnyColors.purchases,
                            ),
                            const SizedBox(height: 8),
                            _PlanBar(
                              label: 'Подарить',
                              plan: plan.gift,
                              fact: fact.giftSpent,
                              color: FinnyColors.pink,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                _ShopSection(
                  title: 'Обязательное · еда и уход',
                  items: mandatory,
                ),
                _ShopSection(
                  title: 'Желаемое',
                  items: optional,
                ),
                _ShopSection(
                  title: 'Подарить',
                  items: gifts,
                  bottomPadding: 24,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ShopSection extends StatelessWidget {
  const _ShopSection({
    required this.title,
    required this.items,
    this.bottomPadding = 12,
  });

  final String title;
  final List<ShopItem> items;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
      sliver: SliverList.builder(
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(title, style: Theme.of(context).textTheme.titleMedium),
            );
          }
          return _ItemCard(item: items[index - 1]);
        },
      ),
    );
  }
}

class _PlanBar extends StatelessWidget {
  const _PlanBar({
    required this.label,
    required this.plan,
    required this.fact,
    required this.color,
  });

  final String label;
  final int plan;
  final int fact;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = plan <= 0 ? 0.0 : (fact / plan).clamp(0.0, 1.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $fact / $plan'),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio > 1 ? 1 : ratio,
            minHeight: 10,
            color: fact > plan ? FinnyColors.coral : color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}

class _ItemCard extends ConsumerWidget {
  const _ItemCard({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(gameControllerProvider).value!;
    final canPlay = profile.period.phase == PeriodPhase.playing;
    final shortfall = item.price - profile.balance;
    final canAfford = shortfall <= 0;
    final canBuy = canPlay && canAfford;

    final kindLabel = switch (item.kind) {
      ExpenseKind.mandatory => 'Обязательное',
      ExpenseKind.gift => 'Подарить',
      ExpenseKind.optional => 'Желаемое',
    };
    final accent = switch (item.kind) {
      ExpenseKind.mandatory => FinnyColors.budget,
      ExpenseKind.gift => FinnyColors.pink,
      ExpenseKind.optional => FinnyColors.purchases,
    };

    final owned = profile.ownedItemIds.contains(item.id);
    final buttonLabel = !canPlay
        ? 'Сначала план'
        : canAfford
            ? (owned ? 'Ещё раз' : 'Купить')
            : 'не хватает $shortfall монет';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ItemThumb(item: item),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${item.price}',
                              style: const TextStyle(
                                color: FinnyColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        kindLabel,
                        style: TextStyle(
                          color: FinnyColors.ink.withValues(alpha: 0.65),
                        ),
                      ),
                      if (item.placement.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.placement,
                          style: TextStyle(
                            fontSize: 13,
                            color: accent.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (owned) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Уже в коллекции ✨',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: FinnyColors.gold.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (item.effectHint.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.effectHint,
                style: TextStyle(
                  color: FinnyColors.ink.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(120, 44),
                  backgroundColor: accent,
                  disabledBackgroundColor: accent.withValues(alpha: 0.28),
                  disabledForegroundColor:
                      FinnyColors.ink.withValues(alpha: 0.55),
                ),
                onPressed: !canBuy
                    ? null
                    : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(item.name),
                            content: Text('Купить за ${item.price}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Отмена'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Купить'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true || !context.mounted) return;
                        final result = await ref
                            .read(gameControllerProvider.notifier)
                            .buy(item);
                        if (!context.mounted) return;
                        if (result.ok) {
                          await FinnyFx.purchase();
                          if (!context.mounted) return;
                          await showPurchaseBurst(context, price: item.price);
                        }
                        if (!context.mounted) return;
                        if (result.celebrate) {
                          await showCelebration(
                            context,
                            title: result.celebrateTitle ?? 'Коллекция!',
                            message: result.message,
                            stars: result.earnedStars,
                          );
                        } else {
                          await showFeedback(context, result.message,
                              ok: result.ok);
                        }
                      },
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemThumb extends StatelessWidget {
  const _ItemThumb({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final hasImage = item.image.isNotEmpty;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: FinnyColors.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasImage
          ? Image.asset(
              item.image,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              cacheWidth: (72 * MediaQuery.devicePixelRatioOf(context))
                  .round()
                  .clamp(144, 288),
              cacheHeight: (72 * MediaQuery.devicePixelRatioOf(context))
                  .round()
                  .clamp(144, 288),
              errorBuilder: (context, error, stackTrace) => Text(
                item.emoji.isNotEmpty ? item.emoji : '🛒',
                style: const TextStyle(fontSize: 30),
              ),
            )
          : Text(
              item.emoji.isNotEmpty ? item.emoji : '🛒',
              style: const TextStyle(fontSize: 30),
            ),
    );
  }
}
