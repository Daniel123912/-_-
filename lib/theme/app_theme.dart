import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Локальные OFL-шрифты (без сети при старте).
class FinnyFonts {
  static const display = 'Fredoka';
  static const body = 'Nunito';

  static TextStyle fredoka({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: display,
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle nunito({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: body,
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

/// Finny — тёмный purple из Figma Make.
class FinnyColors {
  static const purpleDeep = Color(0xFF1A0533);
  static const purpleMid = Color(0xFF2D1165);
  static const purpleCard = Color(0xFF3D1A7A);
  static const purpleLight = Color(0xFF7C3AED);
  static const purpleBright = Color(0xFFA78BFA);
  static const indigo = Color(0xFF4F46E5);
  static const gold = Color(0xFFFBBF24);
  static const goldDark = Color(0xFFD97706);
  static const mint = Color(0xFF34D399);
  static const pink = Color(0xFFF472B6);
  static const sky = Color(0xFF60A5FA);
  static const bg = Color(0xFF0D0120);
  static const bgAlt = Color(0xFF0A1628);
  static const ink = Color(0xFFFFFFFF);
  static const mist = Color(0xFF9CA3AF);
  static const card = Color(0xFF2D1165);
  static const line = Color(0x26FFFFFF);
  static const sheet = Color(0xFF1A0533);

  // Aliases used across screens
  static const cream = bg;
  static const forest = purpleLight;
  static const leaf = purpleBright;
  static const sun = gold;
  static const coral = pink;
  static const glow = gold;
  static const budget = Color(0xFF0D9488);
  static const savings = sky;
  static const purchases = gold;
}

class AppTheme {
  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: FinnyColors.purpleLight,
      brightness: Brightness.dark,
      primary: FinnyColors.purpleLight,
      secondary: FinnyColors.gold,
      tertiary: FinnyColors.pink,
      surface: FinnyColors.purpleMid,
      onSurface: FinnyColors.ink,
    );

    final seed = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: FinnyFonts.body,
    );
    final body = seed.textTheme;
    final display = seed.textTheme.apply(fontFamily: FinnyFonts.display);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: base,
      fontFamily: FinnyFonts.body,
      scaffoldBackgroundColor: const Color(0xFF5B21B6),
      splashFactory: InkRipple.splashFactory,
      textTheme: body.copyWith(
        displayLarge: display.displayLarge?.copyWith(
          color: FinnyColors.ink,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        displayMedium: display.displayMedium?.copyWith(
          color: FinnyColors.ink,
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: display.headlineLarge?.copyWith(
          color: FinnyColors.ink,
          fontWeight: FontWeight.w400,
          fontSize: 34,
          height: 1.1,
        ),
        headlineMedium: display.headlineMedium?.copyWith(
          color: FinnyColors.ink,
          fontWeight: FontWeight.w400,
          fontSize: 28,
          height: 1.1,
        ),
        headlineSmall: display.headlineSmall?.copyWith(
          color: FinnyColors.ink,
          fontWeight: FontWeight.w400,
          fontSize: 22,
          height: 1.15,
        ),
        titleLarge: display.titleLarge?.copyWith(
          color: FinnyColors.ink,
          fontWeight: FontWeight.w400,
          fontSize: 20,
        ),
        titleMedium: body.titleMedium?.copyWith(
          color: FinnyColors.ink,
          fontWeight: FontWeight.w800,
          fontSize: 17,
        ),
        bodyLarge: body.bodyLarge?.copyWith(
          color: FinnyColors.ink,
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: body.bodyMedium?.copyWith(
          color: FinnyColors.ink,
          fontSize: 15,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
        labelLarge: body.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: FinnyColors.ink,
        titleTextStyle: display.titleLarge?.copyWith(
          color: FinnyColors.ink,
          fontWeight: FontWeight.w400,
          fontSize: 22,
        ),
        iconTheme: const IconThemeData(color: FinnyColors.ink),
      ),
      cardTheme: CardThemeData(
        color: FinnyColors.card.withValues(alpha: 0.55),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: FinnyColors.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FinnyColors.purpleLight,
          foregroundColor: Colors.white,
          disabledBackgroundColor: FinnyColors.purpleMid,
          disabledForegroundColor: FinnyColors.mist,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shadowColor: FinnyColors.purpleLight.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: display.labelLarge?.copyWith(
            fontWeight: FontWeight.w400,
            fontSize: 18,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FinnyColors.ink,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: FinnyColors.line, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: body.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FinnyColors.purpleBright,
          textStyle: body.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: FinnyColors.purpleLight,
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        secondarySelectedColor: FinnyColors.purpleLight,
        labelStyle: body.bodyMedium!.copyWith(
          fontWeight: FontWeight.w700,
          color: FinnyColors.ink,
        ),
        secondaryLabelStyle: body.bodyMedium!.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        side: const BorderSide(color: FinnyColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        checkmarkColor: Colors.white,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: FinnyColors.purpleBright,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
        thumbColor: FinnyColors.gold,
        overlayColor: FinnyColors.purpleLight.withValues(alpha: 0.2),
        trackHeight: 6,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: FinnyColors.purpleBright,
        linearTrackColor: Colors.white.withValues(alpha: 0.1),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: FinnyColors.purpleMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: FinnyColors.line),
        ),
        titleTextStyle: display.titleLarge?.copyWith(
          color: FinnyColors.ink,
          fontSize: 22,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: FinnyColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: FinnyColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: FinnyColors.purpleBright),
        ),
        hintStyle: TextStyle(color: FinnyColors.mist.withValues(alpha: 0.8)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: FinnyColors.purpleBright,
        unselectedLabelColor: FinnyColors.mist,
        indicatorColor: FinnyColors.purpleLight,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: body.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      dividerTheme: const DividerThemeData(
        color: FinnyColors.line,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: FinnyColors.ink),
    );
  }
}

/// Пути к комнатам вкладок нижнего дока.
abstract final class FinnyRooms {
  static const homeDay = 'assets/images/room_home_day.jpg';
  static const homeEvening = 'assets/images/room_home_evening.jpg';
  static const home = homeDay;
  static const quests = 'assets/images/room_quests_bg.png';
  static const shop = 'assets/images/room_shop_bg.png';
  static const savings = 'assets/images/room_savings_bg.png';
  static const budget = 'assets/images/room_budget_bg.png';

  /// Вечер с 18:00 до 5:59, днём — светлый фон.
  static bool isEveningNow([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    return h >= 18 || h < 6;
  }

  static String homeForNow([DateTime? now]) =>
      isEveningNow(now) ? homeEvening : homeDay;

  /// Следующая смена день↔вечер (для таймера в UI).
  static DateTime nextHomeSwitchAt([DateTime? now]) {
    final n = now ?? DateTime.now();
    if (isEveningNow(n)) {
      // до 6:00 сегодня или завтра
      final today6 = DateTime(n.year, n.month, n.day, 6);
      if (n.isBefore(today6)) return today6;
      return DateTime(n.year, n.month, n.day + 1, 6);
    }
    return DateTime(n.year, n.month, n.day, 18);
  }
}

/// Яркий градиент 7–8 лет + опциональная комната (картинка) под вкладку.
class PlayBackground extends StatelessWidget {
  const PlayBackground({
    super.key,
    required this.child,
    this.roomAsset,
    this.scrimTop = 0.28,
    this.scrimBottom = 0.22,
  });

  final Widget child;

  /// Если задан — рисуем иллюстрацию комнаты поверх градиента.
  final String? roomAsset;

  /// Затемнение сверху (читаемость AppBar / HUD).
  final double scrimTop;

  /// Затемнение снизу (читаемость кнопок / списков).
  final double scrimBottom;

  @override
  Widget build(BuildContext context) {
    final room = roomAsset;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screenW = MediaQuery.sizeOf(context).width;
    final bgCacheW = (screenW * dpr).round().clamp(720, 1600);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF5B21B6),
            Color(0xFF7C3AED),
            Color(0xFFDB2777),
            Color(0xFFFBBF24),
          ],
          stops: [0.0, 0.35, 0.72, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (room != null)
            Positioned.fill(
              child: Image.asset(
                room,
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.15),
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
                cacheWidth: bgCacheW,
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink(),
              ),
            )
          else ...[
            Positioned(
              top: -120,
              right: -60,
              child: _MeshBlob(
                size: 320,
                colors: [
                  Colors.white.withValues(alpha: 0.18),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: _MeshBlob(
                size: 280,
                colors: [
                  FinnyColors.gold.withValues(alpha: 0.28),
                  FinnyColors.gold.withValues(alpha: 0),
                ],
              ),
            ),
            const Positioned.fill(child: IgnorePointer(child: _StarsField())),
          ],
          if (room != null)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: scrimTop),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: scrimBottom),
                    ],
                    stops: const [0.0, 0.16, 0.68, 1.0],
                  ),
                ),
              ),
            ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _StarsField extends StatelessWidget {
  const _StarsField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarsPainter());
  }
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < 28; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = 0.6 + rnd.nextDouble() * 1.8;
      paint.color = Colors.white.withValues(alpha: 0.2 + rnd.nextDouble() * 0.35);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MeshBlob extends StatelessWidget {
  const _MeshBlob({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

/// Матовая карточка (единый вид на web и native, без «скачущего» blur).
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.onTap,
    this.radius = 24,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    // База всегда матовая; цветной tint поверх неё, а не вместо (иначе
    // карточки с alpha 0.12 выглядят «прозрачными», а без color — матовыми).
    const base = Color(0xE61A1030); // ~90% тёмный
    final fill = color == null ? base : Color.alphaBlend(color!, base);
    final content = Material(
      color: fill,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(
              onTap: onTap,
              child: Padding(padding: padding, child: child),
            ),
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: content,
      ),
    );
  }
}

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.bottom,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AppBar(
          title: title,
          actions: actions,
          leading: leading,
          bottom: bottom,
          backgroundColor: const Color(0xFF5B21B6).withValues(alpha: 0.78),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: FinnyFonts.fredoka(
        color: FinnyColors.ink,
        fontWeight: FontWeight.w400,
        fontSize: 20,
      ),
    );
  }
}

/// Бейдж монет как в Figma.
class CoinBadge extends StatelessWidget {
  const CoinBadge({super.key, required this.amount, this.suffix = '₽'});

  final int amount;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: FinnyColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: FinnyColors.gold.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$amount$suffix',
        style: FinnyFonts.nunito(
          color: FinnyColors.gold,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}
