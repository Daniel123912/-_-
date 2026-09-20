import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Всплеск монет при покупке.
Future<void> showPurchaseBurst(BuildContext context, {required int price}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'purchase-fx',
    barrierColor: Colors.black26,
    transitionDuration: const Duration(milliseconds: 360),
    pageBuilder: (context, anim, _) {
      return _FxShell(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOutSine),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: _CoinBurstCard(price: price),
          ),
        ),
      );
    },
  );
}

/// Пульс копилки при пополнении.
Future<void> showPiggyPulse(BuildContext context, {required int amount}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'save-fx',
    barrierColor: Colors.black26,
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (context, anim, _) {
      return _FxShell(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOutSine),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: _PiggyPulseCard(amount: amount),
          ),
        ),
      );
    },
  );
}

class _FxShell extends StatelessWidget {
  const _FxShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Автозакрытие через ~0.9с, чтобы не мешать демо.
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
    return SafeArea(
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: child,
        ),
      ),
    );
  }
}

class _CoinBurstCard extends StatelessWidget {
  const _CoinBurstCard({required this.price});

  final int price;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _FloatingIcons(
            icons: ['🪙', '✨', '🪙'],
          ),
          const SizedBox(height: 8),
          const Text(
            'Куплено!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '−$price',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PiggyPulseCard extends StatelessWidget {
  const _PiggyPulseCard({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
        ),
        boxShadow: [
          BoxShadow(
            color: FinnyColors.savings.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🐷', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 4),
          const Text(
            'В копилку!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '+$amount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingIcons extends StatefulWidget {
  const _FloatingIcons({required this.icons});

  final List<String> icons;

  @override
  State<_FloatingIcons> createState() => _FloatingIconsState();
}

class _FloatingIconsState extends State<_FloatingIcons>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < widget.icons.length; i++)
                Transform.translate(
                  offset: Offset(
                    (i - 1) * 28.0,
                    -12 * sin((_ctrl.value + i * 0.2) * pi),
                  ),
                  child: Opacity(
                    opacity: (1 - _ctrl.value * 0.35).clamp(0.4, 1),
                    child: Text(
                      widget.icons[i],
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
