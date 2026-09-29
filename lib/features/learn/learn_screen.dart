import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/economy.dart';
import '../../domain/models.dart';
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

IconData lessonIcon(String name) => switch (name) {
      'restaurant' => Icons.restaurant_rounded,
      'toys' => Icons.toys_rounded,
      'favorite' => Icons.favorite_rounded,
      'flag' => Icons.flag_rounded,
      'savings' => Icons.savings_rounded,
      'lock' => Icons.lock_rounded,
      'sell' => Icons.sell_rounded,
      'school' => Icons.school_rounded,
      'compare' => Icons.compare_rounded,
      'celebration' => Icons.celebration_rounded,
      'calculate' => Icons.calculate_rounded,
      'trending_up' => Icons.trending_up_rounded,
      'timer' => Icons.timer_rounded,
      'compare_arrows' => Icons.compare_arrows_rounded,
      'pets' => Icons.pets_rounded,
      'account_balance_wallet' => Icons.account_balance_wallet_rounded,
      'healing' => Icons.healing_rounded,
      'swap_horiz' => Icons.swap_horiz_rounded,
      'psychology' => Icons.psychology_rounded,
      'edit_note' => Icons.edit_note_rounded,
      'receipt_long' => Icons.receipt_long_rounded,
      'insights' => Icons.insights_rounded,
      'hourglass_empty' => Icons.hourglass_empty_rounded,
      'check_circle' => Icons.check_circle_rounded,
      _ => Icons.lightbulb_rounded,
    };

Color _themeColor(QuestTheme theme) => switch (theme) {
      QuestTheme.budget => FinnyColors.budget,
      QuestTheme.savings => FinnyColors.savings,
      QuestTheme.purchases => FinnyColors.purchases,
    };

String _themeLabel(QuestTheme theme) => switch (theme) {
      QuestTheme.budget => 'Бюджет',
      QuestTheme.savings => 'Копилка',
      QuestTheme.purchases => 'Покупки',
    };

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(gameControllerProvider).value;
    final content = ref.watch(contentProvider);
    if (profile == null) {
      return const Scaffold(body: Center(child: Text('Нет профиля')));
    }
    final guide = AgeLearnGuide.forTrack(profile.ageTrack);
    // Единый яркий UI как у трека 7–8 (сложность уроков — по ageTrack).
    const isJunior = true;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isJunior ? 'Школа Финни' : 'Учёба'),
        backgroundColor: FinnyColors.bg.withValues(alpha: 0.78),
        surfaceTintColor: Colors.transparent,
      ),
      body: PlayBackground(
        child: content.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Не удалось загрузить уроки.\n$e',
                  textAlign: TextAlign.center),
            ),
          ),
          data: (data) {
            final lessons =
                GameEconomy.lessonsForProfile(profile, data.lessons);
            final done =
                GameEconomy.lessonsDoneCount(profile, data.lessons);
            final featured =
                GameEconomy.featuredLesson(profile, data.lessons);
            final progress = lessons.isEmpty ? 0.0 : done / lessons.length;
            final pct = lessons.isEmpty ? 0 : (progress * 100).round();
            final left = (lessons.length - done).clamp(0, lessons.length);

            return ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
                20,
                40,
              ),
              children: [
                Text(
                  guide.headline,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  guide.blurb,
                  style: TextStyle(
                    color: FinnyColors.mist,
                    height: 1.35,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => showTermsHelp(context),
                    icon: const Icon(Icons.menu_book_rounded, size: 18),
                    label: const Text('Словарь терминов'),
                  ),
                ),
                const SizedBox(height: 10),
                SoftCard(
                  padding: const EdgeInsets.all(22),
                  color: isJunior
                      ? FinnyColors.glow.withValues(alpha: 0.18)
                      : FinnyColors.purpleLight.withValues(alpha: 0.28),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 84,
                        height: 84,
                        child: CustomPaint(
                          painter: _ProgressRingPainter(progress: progress),
                          child: Center(
                            child: Text(
                              '$pct%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              guide.badge,
                              style: TextStyle(
                                color: FinnyColors.glow,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isJunior
                                  ? '$done / ${lessons.length}'
                                  : 'Изучено $done из ${lessons.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isJunior && left > 0
                                  ? 'Ещё $left'
                                  : guide.petLine,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (featured != null) ...[
                  const SizedBox(height: 22),
                  SectionLabel(isJunior ? 'Играть сейчас' : 'Сейчас'),
                  const SizedBox(height: 10),
                  SoftCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            LessonPlayerScreen(lesson: featured),
                      ),
                    ),
                    padding: const EdgeInsets.all(18),
                    color: isJunior
                        ? FinnyColors.savings.withValues(alpha: 0.14)
                        : null,
                    child: Row(
                      children: [
                        Container(
                          width: isJunior ? 64 : 58,
                          height: isJunior ? 64 : 58,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _themeColor(featured.theme),
                                _themeColor(featured.theme)
                                    .withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            profile.completedLessonIds.contains(featured.id)
                                ? Icons.refresh_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: isJunior ? 34 : 30,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.completedLessonIds
                                        .contains(featured.id)
                                    ? (isJunior
                                        ? 'Можно сыграть снова'
                                        : 'Можно повторить')
                                    : (isJunior
                                        ? 'Новое приключение'
                                        : 'Урок для тебя сейчас'),
                                style: TextStyle(
                                  color: FinnyColors.mist,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                featured.title,
                                style: TextStyle(
                                  fontSize: isJunior ? 20 : 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                featured.hook,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: FinnyColors.mist,
                                  fontSize: 13,
                                ),
                              ),
                              if (isJunior) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Нажми — и поехали!',
                                  style: TextStyle(
                                    color: _themeColor(featured.theme),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Text(
                  isJunior
                      ? 'Все приключения · ${profile.ageTrack.label}'
                      : 'Все уроки · ${profile.ageTrack.label}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (lessons.isEmpty)
                  SoftCard(
                    child: Text(
                      'Для этого возраста уроки ещё готовятся.\n'
                      'Трек: ${profile.ageTrack.label}. '
                      'В файле уроков: ${data.lessons.length}.',
                    ),
                  )
                else
                  ...lessons.map((lesson) {
                    final learned =
                        profile.completedLessonIds.contains(lesson.id);
                    final accent = _themeColor(lesson.theme);
                    final leadIcon = lesson.steps.isNotEmpty
                        ? lessonIcon(lesson.steps.first.icon)
                        : Icons.menu_book_rounded;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SoftCard(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                LessonPlayerScreen(lesson: lesson),
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          14,
                          isJunior ? 16 : 14,
                          12,
                          isJunior ? 16 : 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: isJunior ? 52 : 46,
                              height: isJunior ? 52 : 46,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  isJunior ? 16 : 14,
                                ),
                              ),
                              child: Icon(
                                learned ? Icons.check_rounded : leadIcon,
                                color: accent,
                                size: isJunior ? 26 : 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lesson.title,
                                    style: TextStyle(
                                      fontSize: isJunior ? 17 : 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  Text(
                                    isJunior
                                        ? '${_themeLabel(lesson.theme)}'
                                            '${learned ? ' · звёздочка есть' : ' · ★+1 · +${lesson.rewardCoins}'}'
                                        : '${_themeLabel(lesson.theme)}'
                                            '${learned ? ' · изучено' : ' · ★+1 · +${lesson.rewardCoins}'}',
                                    style: TextStyle(
                                      color: FinnyColors.mist,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isJunior
                                  ? Icons.play_circle_fill_rounded
                                  : Icons.chevron_right_rounded,
                              color: isJunior
                                  ? accent
                                  : FinnyColors.mist.withValues(alpha: 0.6),
                              size: isJunior ? 30 : 24,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = FinnyColors.glow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress.clamp(0.0, 1.0) * math.pi * 2,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class LessonPlayerScreen extends ConsumerStatefulWidget {
  const LessonPlayerScreen({super.key, required this.lesson});

  final LearningLesson lesson;

  @override
  ConsumerState<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends ConsumerState<LessonPlayerScreen> {
  int _step = 0;

  int get _quizIndex => widget.lesson.steps.length + 1;

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final profile = ref.watch(gameControllerProvider).value;
    if (profile == null) {
      return const Scaffold(body: Center(child: Text('Нет профиля')));
    }
    final learned = profile.completedLessonIds.contains(lesson.id);
    final accent = _themeColor(lesson.theme);
    final totalPages = lesson.steps.length + 2;
    // Единый яркий UI как у трека 7–8 (сложность уроков — по ageTrack).
    const isJunior = true;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(lesson.title),
        backgroundColor: FinnyColors.bg.withValues(alpha: 0.78),
        surfaceTintColor: Colors.transparent,
      ),
      body: PlayBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
            20,
            32,
          ),
          children: [
            Row(
              children: [
                for (var i = 0; i < totalPages; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      height: isJunior ? 7 : 5,
                      decoration: BoxDecoration(
                        color: i <= _step
                            ? (isJunior ? accent : FinnyColors.ink)
                            : FinnyColors.line,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isJunior
                  ? 'Шаг ${_step + 1} из $totalPages'
                  : '${_step + 1} / $totalPages',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FinnyColors.mist,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            if (_step == 0) _StoryPage(lesson: lesson, accent: accent),
            if (_step > 0 && _step <= lesson.steps.length)
              _StepPage(
                step: lesson.steps[_step - 1],
                index: _step,
                total: lesson.steps.length,
                accent: accent,
              ),
            if (_step == _quizIndex)
              _QuizPage(
                lesson: lesson,
                learned: learned,
                accent: accent,
                isJunior: isJunior,
                onAnswer: (option) async {
                  final result = await ref
                      .read(gameControllerProvider.notifier)
                      .completeLesson(lesson, option);
                  if (!context.mounted) return;
                  await showFeedback(
                    context,
                    result.message,
                    ok: result.ok,
                    stars: result.earnedStars,
                  );
                  if (!context.mounted) return;
                  if (result.ok) Navigator.pop(context);
                },
              ),
            const SizedBox(height: 22),
            Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step -= 1),
                      child: const Text('Назад'),
                    ),
                  ),
                if (_step > 0 && _step < _quizIndex) const SizedBox(width: 12),
                if (_step < _quizIndex)
                  Expanded(
                    child: FilledButton(
                      onPressed: () => setState(() => _step += 1),
                      child: Text(
                        _step == 0
                            ? (isJunior ? 'Поехали!' : 'Дальше')
                            : (isJunior ? 'Дальше!' : 'Следующий шаг'),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryPage extends StatelessWidget {
  const _StoryPage({required this.lesson, required this.accent});

  final LearningLesson lesson;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                _themeLabel(lesson.theme),
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            lesson.hook,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FinnyColors.sheet,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              lesson.story,
              style: const TextStyle(fontSize: 16, height: 1.45),
            ),
          ),
          if (lesson.funFact.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded, color: accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lesson.funFact,
                    style: TextStyle(
                      color: FinnyColors.mist,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  const _StepPage({
    required this.step,
    required this.index,
    required this.total,
    required this.accent,
  });

  final LessonStep step;
  final int index;
  final int total;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
      child: Column(
        children: [
          Text(
            'Шаг $index из $total',
            style: TextStyle(
              color: FinnyColors.mist,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            key: ValueKey(step.title),
            tween: Tween(begin: 0.88, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutSine,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
              ),
              child: Icon(lessonIcon(step.icon), size: 44, color: accent),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            step.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _QuizPage extends StatelessWidget {
  const _QuizPage({
    required this.lesson,
    required this.learned,
    required this.accent,
    required this.onAnswer,
    this.isJunior = false,
  });

  final LearningLesson lesson;
  final bool learned;
  final Color accent;
  final bool isJunior;
  final Future<void> Function(QuestOption option) onAnswer;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            learned
                ? (isJunior ? 'Сыграй проверку ещё раз!' : 'Повтори проверку')
                : (isJunior
                    ? 'Мини-игра — выбери ответ и получи награду!'
                    : 'Проверка — получи награду!'),
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            lesson.quiz.prompt,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  fontSize: isJunior ? 22 : null,
                ),
          ),
          const SizedBox(height: 16),
          ...(() {
            final options = List<QuestOption>.of(lesson.quiz.options)
              ..shuffle(math.Random(lesson.id.hashCode));
            return options
                .map(
                  (opt) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SoftCard(
                      onTap: () => onAnswer(opt),
                      color: FinnyColors.sheet,
                      radius: 18,
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: isJunior ? 16 : 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: isJunior ? 40 : 34,
                            height: isJunior ? 40 : 34,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              isJunior
                                  ? Icons.pets_rounded
                                  : Icons.touch_app_rounded,
                              color: accent,
                              size: isJunior ? 20 : 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              opt.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: isJunior ? 16 : 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList();
          })(),
          if (learned)
            Text(
              isJunior
                  ? 'Звёздочка уже есть — можно просто поиграть ещё раз.'
                  : 'Награда уже получена — можно просто проверить себя.',
              style: TextStyle(color: FinnyColors.mist, fontSize: 13),
            ),
        ],
      ),
    );
  }
}
