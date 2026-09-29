import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/economy.dart';
import '../../domain/engagement.dart';
import '../../domain/models.dart';
import '../../theme/app_theme.dart';

/// Перекраска SVG (в т.ч. embedded PNG) — в isolate, иначе UI замирает на секунды.
class _SvgRecolorJob {
  const _SvgRecolorJob(this.raw, this.eyes);
  final String raw;
  final String eyes;
}

String _svgRecolorIsolate(_SvgRecolorJob job) {
  return PetAppearance.recolorEyeIris(job.raw, job.eyes);
}

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
    // Все стадии одного размера (как малыш) — без скачка при росте.
    final stageScale = !widget.scaleByStage ? 1.0 : 0.72;
    final floatAmp = widget.mood < 40 ? 3.5 : (stage == 3 ? 7.0 : 5.5);
    final stageLabel = switch (stage) {
      1 => 'Малыш',
      2 => 'Растущий',
      _ => 'Чемпион',
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
    final stageModel = widget.appearance.modelForStage(stage);
    final fallbackPath = 'assets/images/pets/$stageModel.svg';
    final sidePad = math.max(56.0, petWidth * 0.42);
    final toySize = math.min(petWidth * 0.48, 92.0);

    // Игрушки сбоку: слева «комната», справа «в лапках» и остальное.
    final leftToys = cosmetics
        .where((c) => c.slot == CosmeticSlot.room)
        .toList();
    final rightToys = cosmetics
        .where((c) => c.slot != CosmeticSlot.room)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _handleTap,
          child: SizedBox(
            width: petWidth + sidePad * 2,
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
                  // Игрушки слева от питомца.
                  for (var i = 0; i < leftToys.length; i++)
                    Positioned(
                      left: 2,
                      bottom: petHeight * (0.12 + i * 0.28),
                      width: toySize,
                      height: toySize,
                      child: _PetAttachedCosmetic(
                        visual: leftToys[i],
                        size: toySize * (i == 0 ? 1 : 0.85),
                        tilt: 0.06,
                      ),
                    ),
                  // Сам питомец по центру.
                  SizedBox(
                    width: petWidth,
                    height: petHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeInOutSine,
                          switchOutCurve: Curves.easeInOutSine,
                          child: _RecoloredPetSvg(
                            key: ValueKey(
                              '$stageModel-$svgPath-${widget.appearance.eyes}-${widget.appearance.accessory}',
                            ),
                            assetPath: svgPath,
                            fallbackPath: fallbackPath,
                            eyes: widget.appearance.eyes,
                            width: petWidth,
                            height: petHeight,
                          ),
                        ),
                        // Дополнение внешности (ромбики / на голове) — на теле.
                        if (widget.appearance.accessory != 'без')
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _PetAccessoryPainter(
                                  accessory: widget.appearance.accessory,
                                  color: widget.appearance.color,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Игрушки справа от питомца.
                  for (var i = 0; i < rightToys.length; i++)
                    Positioned(
                      right: 2,
                      bottom: petHeight * (0.14 + i * 0.26),
                      width: toySize,
                      height: toySize,
                      child: _PetAttachedCosmetic(
                        visual: rightToys[i],
                        size: toySize * (i == 0 ? 1 : 0.82),
                        tilt: -0.08,
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

/// SVG питомца с перекраской радужки под выбранный цвет глаз.
class _RecoloredPetSvg extends StatefulWidget {
  const _RecoloredPetSvg({
    super.key,
    required this.assetPath,
    required this.fallbackPath,
    required this.eyes,
    required this.width,
    required this.height,
  });

  final String assetPath;
  final String fallbackPath;
  final String eyes;
  final double width;
  final double height;

  @override
  State<_RecoloredPetSvg> createState() => _RecoloredPetSvgState();
}

class _RecoloredPetSvgState extends State<_RecoloredPetSvg> {
  /// Кэш уже перекрашенных SVG — без вспышки малыша при смене вкладки.
  static final Map<String, String> _cache = {};

  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _RecoloredPetSvg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath ||
        oldWidget.fallbackPath != widget.fallbackPath ||
        oldWidget.eyes != widget.eyes) {
      _future = _load();
    }
  }

  Future<String> _load() async {
    final key = '${widget.assetPath}|${widget.eyes}';
    final hit = _cache[key];
    if (hit != null) return hit;

    String raw;
    try {
      raw = await rootBundle.loadString(widget.assetPath);
    } catch (_) {
      raw = await rootBundle.loadString(widget.fallbackPath);
    }
    final colored = await compute(
      _svgRecolorIsolate,
      _SvgRecolorJob(raw, widget.eyes),
    );
    _cache[key] = colored;
    return colored;
  }

  @override
  Widget build(BuildContext context) {
    // Синхронный кэш — сразу правильная стадия, без кадра с малышом.
    final cached = _cache['${widget.assetPath}|${widget.eyes}'];
    if (cached != null) {
      return SvgPicture.string(
        cached,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.contain,
      );
    }

    return FutureBuilder<String>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          // Пусто, а не fallback малыша — иначе мигание при возврате на вкладку.
          return SizedBox(width: widget.width, height: widget.height);
        }
        return SvgPicture.string(
          snap.data!,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
        );
      },
    );
  }
}

/// Узор внешности: ромбики на теле или капельки на лбу.
class _PetAccessoryPainter extends CustomPainter {
  const _PetAccessoryPainter({
    required this.accessory,
    required this.color,
  });

  final String accessory;
  final String color;

  Color get _fill => switch (color) {
        'розовый' => const Color(0xFF9A3F66),
        'фиолетовый' => const Color(0xFF6D3BCF),
        _ => const Color(0xFF3D7A96),
      };

  Color get _light => switch (color) {
        'розовый' => const Color(0xFFF2C4D6),
        'фиолетовый' => const Color(0xFFD7C5FF),
        _ => const Color(0xFFC8E7F4),
      };

  @override
  void paint(Canvas canvas, Size size) {
    if (accessory == 'ромбики') {
      _paintBodyDiamonds(canvas, size);
    } else if (accessory == 'на голове') {
      _paintForeheadMarks(canvas, size);
    }
  }

  void _paintBodyDiamonds(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _fill.withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;
    final highlight = Paint()
      ..color = _light.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    // Овальные пятна по бокам туловища — как на эталонных thumbs.
    final spots = <(double, double, double, double)>[
      (0.22, 0.52, 0.07, 0.05),
      (0.18, 0.60, 0.055, 0.04),
      (0.28, 0.66, 0.06, 0.045),
      (0.74, 0.50, 0.07, 0.05),
      (0.78, 0.58, 0.055, 0.04),
      (0.70, 0.65, 0.06, 0.045),
      (0.34, 0.48, 0.045, 0.035),
      (0.64, 0.47, 0.045, 0.035),
    ];
    for (final (nx, ny, rw, rh) in spots) {
      final rect = Rect.fromCenter(
        center: Offset(size.width * nx, size.height * ny),
        width: size.width * rw,
        height: size.height * rh,
      );
      canvas.drawOval(rect, paint);
      canvas.drawOval(rect.deflate(rect.width * 0.28), highlight);
    }
  }

  void _paintForeheadMarks(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _light.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = _fill.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.012
      ..strokeJoin = StrokeJoin.round;

    // Три капельки треугольником на лбу (между рожками).
    final marks = <(double, double, double)>[
      (0.50, 0.13, 0.055),
      (0.43, 0.19, 0.045),
      (0.57, 0.19, 0.045),
    ];
    for (final (nx, ny, scale) in marks) {
      final path = _teardrop(
        Offset(size.width * nx, size.height * ny),
        size.width * scale,
      );
      canvas.drawPath(path, paint);
      canvas.drawPath(path, outline);
    }
  }

  Path _teardrop(Offset center, double r) {
    final path = Path();
    path.moveTo(center.dx, center.dy - r);
    path.quadraticBezierTo(
      center.dx + r * 0.95,
      center.dy - r * 0.15,
      center.dx,
      center.dy + r * 0.85,
    );
    path.quadraticBezierTo(
      center.dx - r * 0.95,
      center.dy - r * 0.15,
      center.dx,
      center.dy - r,
    );
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _PetAccessoryPainter oldDelegate) {
    return oldDelegate.accessory != accessory || oldDelegate.color != color;
  }
}

class _PetAttachedCosmetic extends StatelessWidget {
  const _PetAttachedCosmetic({
    required this.visual,
    required this.size,
    this.tilt = 0,
  });

  final CosmeticVisual visual;
  final double size;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final px = (size * dpr).round().clamp(64, 512);

    Widget content;
    if (visual.image.isNotEmpty) {
      content = Image.asset(
        visual.image,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        cacheWidth: px,
        cacheHeight: px,
        errorBuilder: (_, __, ___) => Text(
          visual.emoji,
          style: TextStyle(fontSize: size * 0.72),
        ),
      );
    } else {
      content = Text(
        visual.emoji,
        style: TextStyle(fontSize: size * 0.72),
      );
    }

    return Transform.rotate(
      angle: tilt,
      alignment: Alignment.center,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: size * 0.06,
              offset: Offset(0, size * 0.03),
            ),
          ],
        ),
        child: content,
      ),
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
