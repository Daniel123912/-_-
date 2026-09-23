import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/economy.dart';
import '../../domain/models.dart';
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

class AdultGateScreen extends StatefulWidget {
  const AdultGateScreen({super.key});

  @override
  State<AdultGateScreen> createState() => _AdultGateScreenState();
}

class _AdultGateScreenState extends State<AdultGateScreen> {
  late final int a;
  late final int b;
  final _ctrl = TextEditingController();
  String? error;

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    a = 7 + rnd.nextInt(8);
    b = 3 + rnd.nextInt(7);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PlayBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('Раздел для взрослого'),
              backgroundColor: FinnyColors.bg.withValues(alpha: 0.78),
              surfaceTintColor: Colors.transparent,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverToBoxAdapter(
                child: SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Реши пример, чтобы продолжить.',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$a + $b = ?',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _ctrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          labelText: 'Ответ',
                          errorText: error,
                          filled: true,
                          fillColor: Color(0x14FFFFFF),
                        ),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          if (int.tryParse(_ctrl.text.trim()) == a + b) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const AdultPanelScreen(),
                              ),
                            );
                          } else {
                            setState(() => error = 'Неверный ответ');
                          }
                        },
                        child: const Text('Войти'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdultPanelScreen extends ConsumerWidget {
  const AdultPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(gameControllerProvider).value;

    return Scaffold(
      body: PlayBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('Прогресс и настройки'),
              backgroundColor: FinnyColors.bg.withValues(alpha: 0.78),
              surfaceTintColor: Colors.transparent,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SoftCard(
                    child: const Text(
                      'Цели приложения: научить планировать бюджет, различать нужное и желаемое, копить на цель. Задания делятся по возрасту и сложности.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (profile != null) ...[
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Игрок: ${profile.playerName}'),
                          Text('Питомец: ${profile.petName}'),
                          Text(
                            'Периодов завершено: ${profile.totalPeriodsCompleted}',
                          ),
                          Text(
                            'Заданий выполнено: ${profile.completedQuestIds.length}',
                          ),
                          Text(
                            'Стадия роста: ${profile.growthStage} «${GameEconomy.stageTitle(profile.growthStage)}»',
                          ),
                          Text(
                            'Хороших периодов подряд: ${profile.goodPeriodStreak}/2',
                          ),
                          Text(GameEconomy.stageProgressHint(profile)),
                          Text('★ ${profile.stars} · XP ${profile.skills.totalXp}'),
                          Text(
                            'Навыки: бюджет ур.${profile.skills.levelFor(QuestTheme.budget)}, '
                            'копилка ур.${profile.skills.levelFor(QuestTheme.savings)}, '
                            'покупки ур.${profile.skills.levelFor(QuestTheme.purchases)}',
                          ),
                          Text('Лучшее комбо: ${profile.comboBest}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Возраст и сложность заданий',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Уровень ${profile.ageTrack.label}: только подходящие '
                            'задания и уроки. Для 7–8 лет — «Попроще».',
                            style: TextStyle(
                              color: FinnyColors.mist,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...AgeTrack.values.map(
                            (track) => RadioListTile<AgeTrack>(
                              contentPadding: EdgeInsets.zero,
                              value: track,
                              groupValue: profile.ageTrack,
                              title: Text(
                                '${track.label} · ${track.difficultyLabel}',
                              ),
                              subtitle: Text(track.description),
                              onChanged: (v) {
                                if (v != null) {
                                  ref
                                      .read(gameControllerProvider.notifier)
                                      .setAgeTrack(v);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Режим «вместе с родителем»',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '1) Дай монеты  2) Ребёнок составляет план / копит  '
                            '3) (по желанию) челлендж копилки.\n'
                            'Выдано ${profile.parentGrantTotal}/${GameEconomy.parentGrantCap}. '
                            '${profile.parentCoplayPending ? 'Сейчас ждём план ребёнка (+${profile.parentCoplayAmount}).' : 'Можно не использовать.'}',
                            style: TextStyle(
                              color: FinnyColors.mist,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed: () async {
                              final result = await ref
                                  .read(gameControllerProvider.notifier)
                                  .grantParentCoins();
                              if (!context.mounted) return;
                              if (result.ok && result.celebrate) {
                                await showCelebration(
                                  context,
                                  title:
                                      result.celebrateTitle ?? 'Режим вместе!',
                                  message: result.message,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result.message)),
                                );
                              }
                            },
                            icon: const Icon(Icons.favorite_rounded),
                            label: Text(
                              'Вместе: +${GameEconomy.parentGrantAmount} монет ребёнку',
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Челлендж недели',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            profile.parentChallengeTarget == null
                                ? 'Задай цель: сколько монет ребёнок отложит в копилку.'
                                : 'Активно: ${profile.parentChallengeSaved}/${profile.parentChallengeTarget}. '
                                    'Ребёнок видит это как миссию с питомцем.',
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final amount in [20, 40, 60])
                                FilledButton.tonal(
                                  onPressed: () async {
                                    final result = await ref
                                        .read(gameControllerProvider.notifier)
                                        .setParentChallenge(amount);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(result.message),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text('Цель $amount'),
                                ),
                              if (profile.parentChallengeTarget != null)
                                TextButton(
                                  onPressed: () async {
                                    await ref
                                        .read(gameControllerProvider.notifier)
                                        .clearParentChallenge();
                                  },
                                  child: const Text('Снять челлендж'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Звук'),
                      subtitle: const Text(
                        'Короткие звуки при покупках, копилке и заданиях. Вибрация не отключается.',
                      ),
                      value: profile.soundEnabled,
                      onChanged: (v) => ref
                          .read(gameControllerProvider.notifier)
                          .setSoundEnabled(v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Демо-режим'),
                      subtitle: Text(
                        'Периоды идут подряд без ожидания. Выключите — пауза ~${GameEconomy.formatDurationShort(GameEconomy.normalPeriodCooldown)} между периодами.',
                      ),
                      value: profile.demoMode,
                      onChanged: (v) => ref
                          .read(gameControllerProvider.notifier)
                          .setDemoMode(v),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                    ),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Сбросить профиль?'),
                          content: const Text(
                            'Тестовый профиль вернётся к исходному состоянию. Прогресс будет удалён.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Отмена'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Сбросить'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await ref
                            .read(gameControllerProvider.notifier)
                            .resetProfile();
                        if (context.mounted) {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        }
                      }
                    },
                    child: const Text('Сбросить тестовый профиль'),
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
