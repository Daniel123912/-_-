import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/economy.dart';
import '../../domain/models.dart';
import '../../fx/finny_fx.dart';
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  QuestTheme? _themeFilter;
  bool _catalogMode = false;
  var _syncedRefresh = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_syncedRefresh) return;
    _syncedRefresh = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameControllerProvider.notifier).syncQuestRefresh();
    });
  }

  String _themeLabel(QuestTheme theme) => switch (theme) {
        QuestTheme.budget => 'Бюджет',
        QuestTheme.savings => 'Накопления',
        QuestTheme.purchases => 'Покупки',
      };

  Future<void> _onRefreshTap() async {
    final result =
        await ref.read(gameControllerProvider.notifier).refreshQuests();
    if (!mounted) return;
    await showFeedback(context, result.message, ok: result.ok);
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(contentProvider);
    final profile = ref.watch(gameControllerProvider).value;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final allowed = profile.ageTrack.allowedDifficulties.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final locked = profile.period.phase != PeriodPhase.playing;
    final canRefresh = !locked && GameEconomy.canRefreshQuests(profile);
    final refreshLeft = GameEconomy.questRefreshCooldownLeft(profile);

    return Scaffold(
      body: PlayBackground(
        roomAsset: FinnyRooms.quests,
        child: content.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (data) {
            final byId = {for (final q in data.quests) q.id: q};
            final periodQuests = GameEconomy.sanitizeActiveQuestIds(
              profile,
              data.quests,
            )
                .map((id) => byId[id])
                .whereType<Quest>()
                .toList();
            final periodDone = periodQuests
                .where(
                  (q) => GameEconomy.isQuestDoneThisPeriod(profile, q.id),
                )
                .length;

            final available = GameEconomy.questsForProfile(
              profile,
              data.quests,
              onlyTheme: _themeFilter,
            );

            final header = SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locked
                        ? 'Сначала подтверди план.'
                        : 'Сделано: $periodDone / ${periodQuests.isEmpty ? '—' : periodQuests.length}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (!locked) ...[
                    const SizedBox(height: 8),
                    Text(
                      profile.demoMode
                          ? 'Демо: набор можно обновить сразу.'
                          : (refreshLeft == null
                              ? 'Можно взять новый набор заданий.'
                              : 'Новые задания через ${GameEconomy.formatDurationShort(refreshLeft)}.'),
                      style: TextStyle(
                        color: FinnyColors.mist,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: canRefresh ? _onRefreshTap : null,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        canRefresh
                            ? 'Обновить задания'
                            : 'Обновление раз в ${GameEconomy.formatDurationShort(GameEconomy.questRefreshInterval)}',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Задания периода'),
                        selected: !_catalogMode,
                        onSelected: (_) =>
                            setState(() => _catalogMode = false),
                      ),
                      FilterChip(
                        label: const Text('Все задания'),
                        selected: _catalogMode,
                        onSelected: (_) =>
                            setState(() => _catalogMode = true),
                      ),
                    ],
                  ),
                  if (_catalogMode) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Показаны задания для ${profile.ageTrack.label} '
                      '(${profile.ageTrack.difficultyLabel}).',
                      style: TextStyle(
                        color: FinnyColors.mist,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Все темы'),
                          selected: _themeFilter == null,
                          onSelected: (_) =>
                              setState(() => _themeFilter = null),
                        ),
                        for (final t in QuestTheme.values)
                          FilterChip(
                            label: Text(_themeLabel(t)),
                            selected: _themeFilter == t,
                            onSelected: (_) =>
                                setState(() => _themeFilter = t),
                          ),
                      ],
                    ),
                  ],
                  if (!locked && periodQuests.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: periodDone / periodQuests.length,
                        minHeight: 8,
                        color: FinnyColors.coral,
                        backgroundColor:
                            FinnyColors.coral.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ],
              ),
            );

            if (locked) {
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    title: const Text('Задания'),
                    backgroundColor:
                        FinnyColors.bg.withValues(alpha: 0.78),
                    surfaceTintColor: Colors.transparent,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        header,
                        const SizedBox(height: 24),
                        const Text(
                          'Открой «План бюджета».',
                          textAlign: TextAlign.center,
                        ),
                      ]),
                    ),
                  ),
                ],
              );
            }

            if (!_catalogMode) {
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    title: const Text('Задания'),
                    backgroundColor:
                        FinnyColors.bg.withValues(alpha: 0.78),
                    surfaceTintColor: Colors.transparent,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverToBoxAdapter(child: header),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final quests = periodQuests.isEmpty
                              ? available.take(3).toList()
                              : periodQuests;
                          if (index >= quests.length) return null;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _QuestTile(
                              quest: quests[index],
                              profile: profile,
                              themeLabel: _themeLabel,
                            ),
                          );
                        },
                        childCount: (periodQuests.isEmpty
                            ? available.take(3).length
                            : periodQuests.length),
                      ),
                    ),
                  ),
                ],
              );
            }

            return DefaultTabController(
              length: allowed.length,
              child: NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverAppBar(
                    pinned: true,
                    floating: true,
                    backgroundColor:
                        FinnyColors.bg.withValues(alpha: 0.78),
                    surfaceTintColor: Colors.transparent,
                    title: const Text('Задания'),
                    bottom: TabBar(
                      tabs: [
                        for (final d in allowed) Tab(text: d.label),
                      ],
                    ),
                  ),
                ],
                body: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: header,
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          for (final difficulty in allowed)
                            _QuestList(
                              quests: GameEconomy.questsForProfile(
                                profile,
                                data.quests,
                                onlyDifficulty: difficulty,
                                onlyTheme: _themeFilter,
                              ),
                              profile: profile,
                              themeLabel: _themeLabel,
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
      ),
    );
  }
}

class _QuestTile extends StatelessWidget {
  const _QuestTile({
    required this.quest,
    required this.profile,
    required this.themeLabel,
  });

  final Quest quest;
  final PlayerProfile profile;
  final String Function(QuestTheme) themeLabel;

  @override
  Widget build(BuildContext context) {
    final done = GameEconomy.isQuestDoneThisPeriod(profile, quest.id);
    final isPeriod = profile.period.activeQuestIds.contains(quest.id);
    return SoftCard(
      onTap: done
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuestDetailScreen(quest: quest),
                ),
              ),
      color: done
          ? FinnyColors.mint.withValues(alpha: 0.14)
          : null,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (done ? FinnyColors.mint : FinnyColors.coral)
                  .withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
                      child: Icon(
              done
                  ? Icons.check_rounded
                  : switch (quest.interaction) {
                      QuestInteraction.sortBuckets => Icons.touch_app_rounded,
                      QuestInteraction.needWant => Icons.compare_arrows_rounded,
                      QuestInteraction.orderSteps => Icons.format_list_numbered_rounded,
                      QuestInteraction.choice => Icons.quiz_rounded,
                    },
              color: done ? FinnyColors.forest : FinnyColors.coral,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${themeLabel(quest.theme)}'
                  '${isPeriod ? ' · период' : ' · практика'}'
                  '${done ? ' · выполнено' : (isPeriod ? ' · ★${quest.difficulty.starReward}' : ' · без монет')}',
                  style: TextStyle(color: FinnyColors.mist, fontSize: 13),
                ),
              ],
            ),
          ),
          DifficultyBadge(difficulty: quest.difficulty),
        ],
      ),
    );
  }
}

class _QuestList extends StatelessWidget {
  const _QuestList({
    required this.quests,
    required this.profile,
    required this.themeLabel,
  });

  final List<Quest> quests;
  final PlayerProfile profile;
  final String Function(QuestTheme) themeLabel;

  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'На этом уровне пока нет заданий с выбранным фильтром.',
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _QuestTile(
            quest: quests[index],
            profile: profile,
            themeLabel: themeLabel,
          ),
        );
      },
    );
  }
}

class QuestDetailScreen extends ConsumerWidget {
  const QuestDetailScreen({super.key, required this.quest});

  final Quest quest;

  String _themeLabel(QuestTheme theme) => switch (theme) {
        QuestTheme.budget => 'Бюджет',
        QuestTheme.savings => 'Накопления',
        QuestTheme.purchases => 'Покупки',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(gameControllerProvider).value!;
    final done = GameEconomy.isQuestDoneThisPeriod(profile, quest.id);
    final isInteractive = quest.interaction != QuestInteraction.choice &&
        quest.sortItems.isNotEmpty;
    final interactionLabel = switch (quest.interaction) {
      QuestInteraction.sortBuckets => 'корзины',
      QuestInteraction.needWant => 'нужное/желаемое',
      QuestInteraction.orderSteps => 'порядок',
      QuestInteraction.choice => null,
    };

    Future<void> resolve(QuestOption option, {String? localWhy}) async {
      final result = await ref
          .read(gameControllerProvider.notifier)
          .answerQuest(quest, option);
      if (!context.mounted) return;
      if (result.ok) {
        await FinnyFx.success();
      } else {
        await FinnyFx.softFail();
      }
      if (!context.mounted) return;
      await showFeedback(
        context,
        result.message,
        ok: result.ok,
        stars: result.earnedStars,
        xp: result.earnedXp,
        combo: result.combo,
        whyHint: result.whyHint ?? localWhy ?? option.explanation,
        tip: result.tip ?? (quest.tip.isNotEmpty ? quest.tip : null),
      );
      if (!context.mounted) return;
      if (result.ok) Navigator.pop(context);
    }

    return Scaffold(
      body: PlayBackground(
        roomAsset: FinnyRooms.quests,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(quest.title),
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
                        Row(
                          children: [
                            DifficultyBadge(difficulty: quest.difficulty),
                            const SizedBox(width: 8),
                            Text(
                              _themeLabel(quest.theme),
                              style: TextStyle(color: FinnyColors.mist),
                            ),
                            if (interactionLabel != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: FinnyColors.sun.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  interactionLabel,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              '★ ${quest.difficulty.starReward} · XP ${quest.difficulty.xpReward}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        if (quest.tip.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: FinnyColors.sheet,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: FinnyColors.sun,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    quest.tip,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          quest.prompt,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (done) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Задание уже выполнено в этом периоде.',
                            style: TextStyle(
                              color: FinnyColors.forest,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!done && isInteractive)
                    switch (quest.interaction) {
                      QuestInteraction.sortBuckets => _SortBucketsQuest(
                          quest: quest,
                          onResolved: resolve,
                        ),
                      QuestInteraction.needWant => _NeedWantQuest(
                          quest: quest,
                          onResolved: resolve,
                        ),
                      QuestInteraction.orderSteps => _OrderStepsQuest(
                          quest: quest,
                          onResolved: resolve,
                        ),
                      QuestInteraction.choice => const SizedBox.shrink(),
                    }
                  else if (!done)
                    ...quest.options.map(
                      (option) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SoftCard(
                          onTap: () => resolve(option),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option.label,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: FinnyColors.ink,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortBucketsQuest extends StatefulWidget {
  const _SortBucketsQuest({
    required this.quest,
    required this.onResolved,
  });

  final Quest quest;
  final Future<void> Function(QuestOption option, {String? localWhy})
      onResolved;

  @override
  State<_SortBucketsQuest> createState() => _SortBucketsQuestState();
}

class _SortBucketsQuestState extends State<_SortBucketsQuest> {
  late final Map<String, String?> _placements;
  String? _selectedId;
  String? _hint;

  static const _buckets = <(String, String, Color)>[
    ('mandatory', 'Нужное', FinnyColors.budget),
    ('optional', 'Желаемое', FinnyColors.purchases),
    ('savings', 'Копилка', FinnyColors.savings),
  ];

  @override
  void initState() {
    super.initState();
    _placements = {
      for (final item in widget.quest.sortItems) item.id: null,
    };
  }

  Future<void> _check() async {
    final filled = _placements.values.every((v) => v != null);
    if (!filled) {
      setState(() => _hint = 'Разложи все карточки по трём корзинам.');
      return;
    }
    final map = _placements.map((k, v) => MapEntry(k, v!));
    final ok = GameEconomy.isSortBucketsCorrect(widget.quest, map);
    if (ok) {
      await widget.onResolved(widget.quest.successOption);
    } else {
      final why = GameEconomy.sortMistakeHint(widget.quest, map);
      setState(() => _hint = why);
      await widget.onResolved(widget.quest.failOption, localWhy: why);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1) Нажми карточку  2) Нажми корзину',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in widget.quest.sortItems)
                    FilterChip(
                      selected: _selectedId == item.id,
                      label: Text(
                        _placements[item.id] == null
                            ? item.label
                            : '${item.label} ✓',
                      ),
                      onSelected: (_) => setState(() {
                        _selectedId = item.id;
                        _hint = null;
                      }),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final bucket in _buckets) ...[
          SoftCard(
            onTap: _selectedId == null
                ? null
                : () => setState(() {
                      _placements[_selectedId!] = bucket.$1;
                      _selectedId = null;
                      _hint = null;
                    }),
            color: bucket.$3.withValues(alpha: 0.12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bucket.$2,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: bucket.$3,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final entry in _placements.entries)
                      if (entry.value == bucket.$1)
                        Chip(
                          label: Text(
                            widget.quest.sortItems
                                .firstWhere((e) => e.id == entry.key)
                                .label,
                          ),
                          onDeleted: () => setState(() {
                            _placements[entry.key] = null;
                          }),
                        ),
                    if (!_placements.values.contains(bucket.$1))
                      Text(
                        _selectedId == null ? 'Пусто' : 'Сюда →',
                        style: TextStyle(
                          color: FinnyColors.mist,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (_hint != null) ...[
          Text(
            _hint!,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: FinnyColors.coral,
            ),
          ),
          const SizedBox(height: 10),
        ],
        FilledButton(
          onPressed: _check,
          child: const Text('Проверить расклад'),
        ),
      ],
    );
  }
}

class _NeedWantQuest extends StatefulWidget {
  const _NeedWantQuest({
    required this.quest,
    required this.onResolved,
  });

  final Quest quest;
  final Future<void> Function(QuestOption option, {String? localWhy})
      onResolved;

  @override
  State<_NeedWantQuest> createState() => _NeedWantQuestState();
}

class _NeedWantQuestState extends State<_NeedWantQuest> {
  late final Map<String, String?> _placements;
  String? _hint;

  @override
  void initState() {
    super.initState();
    _placements = {
      for (final item in widget.quest.sortItems) item.id: null,
    };
  }

  Future<void> _check() async {
    final filled = _placements.values.every((v) => v != null);
    if (!filled) {
      setState(() => _hint = 'Отметь каждую карточку: нужное или желаемое.');
      return;
    }
    final map = _placements.map((k, v) => MapEntry(k, v!));
    final ok = GameEconomy.isNeedWantCorrect(widget.quest, map);
    if (ok) {
      await widget.onResolved(widget.quest.successOption);
    } else {
      final why = GameEconomy.sortMistakeHint(widget.quest, map);
      setState(() => _hint = why);
      await widget.onResolved(widget.quest.failOption, localWhy: why);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in widget.quest.sortItems) ...[
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        selected: _placements[item.id] == 'need',
                        label: const Text('Нужное'),
                        selectedColor: FinnyColors.budget.withValues(alpha: 0.35),
                        onSelected: (_) => setState(() {
                          _placements[item.id] = 'need';
                          _hint = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        selected: _placements[item.id] == 'want',
                        label: const Text('Желаемое'),
                        selectedColor:
                            FinnyColors.purchases.withValues(alpha: 0.35),
                        onSelected: (_) => setState(() {
                          _placements[item.id] = 'want';
                          _hint = null;
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (_hint != null) ...[
          Text(
            _hint!,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: FinnyColors.coral,
            ),
          ),
          const SizedBox(height: 10),
        ],
        FilledButton(
          onPressed: _check,
          child: const Text('Проверить'),
        ),
      ],
    );
  }
}

class _OrderStepsQuest extends StatefulWidget {
  const _OrderStepsQuest({
    required this.quest,
    required this.onResolved,
  });

  final Quest quest;
  final Future<void> Function(QuestOption option, {String? localWhy})
      onResolved;

  @override
  State<_OrderStepsQuest> createState() => _OrderStepsQuestState();
}

class _OrderStepsQuestState extends State<_OrderStepsQuest> {
  late List<QuestSortItem> _order;
  String? _hint;

  @override
  void initState() {
    super.initState();
    // Перемешиваем, чтобы не светить правильный порядок.
    _order = [...widget.quest.sortItems]..shuffle();
  }

  void _move(int from, int to) {
    if (to < 0 || to >= _order.length) return;
    setState(() {
      final item = _order.removeAt(from);
      _order.insert(to, item);
      _hint = null;
    });
  }

  Future<void> _check() async {
    final ids = _order.map((e) => e.id).toList();
    final ok = GameEconomy.isOrderStepsCorrect(widget.quest, ids);
    if (ok) {
      await widget.onResolved(widget.quest.successOption);
    } else {
      final why = GameEconomy.orderMistakeHint(widget.quest, ids);
      setState(() => _hint = why);
      await widget.onResolved(widget.quest.failOption, localWhy: why);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          child: Text(
            'Расставь шаги сверху вниз: что делать раньше?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: FinnyColors.mist,
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _order.length; i++) ...[
          SoftCard(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: FinnyColors.coral.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _order[i].label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: i == 0 ? null : () => _move(i, i - 1),
                  icon: const Icon(Icons.keyboard_arrow_up_rounded),
                ),
                IconButton(
                  onPressed:
                      i == _order.length - 1 ? null : () => _move(i, i + 1),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (_hint != null) ...[
          Text(
            _hint!,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: FinnyColors.coral,
            ),
          ),
          const SizedBox(height: 10),
        ],
        FilledButton(
          onPressed: _check,
          child: const Text('Проверить порядок'),
        ),
      ],
    );
  }
}
