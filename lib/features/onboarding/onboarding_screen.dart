import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  static const _pages = [
    (
      title: 'Питомец Финни',
      body: 'Учись деньгам вместе с питомцем.',
      icon: Icons.pets_rounded,
    ),
    (
      title: 'Три решения',
      body: 'Нужное, желаемое или копилка.',
      icon: Icons.account_balance_wallet_rounded,
    ),
    (
      title: 'По возрасту',
      body: 'Задания под твой уровень.',
      icon: Icons.school_rounded,
    ),
  ];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PlayBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Финни',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 42,
                        color: FinnyColors.gold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'денежная игра с питомцем',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: FinnyColors.mist,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _page,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final p = _pages[i];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SoftCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 40,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        FinnyColors.purpleLight,
                                        FinnyColors.indigo,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: FinnyColors.purpleLight
                                            .withValues(alpha: 0.45),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    p.icon,
                                    size: 44,
                                    color: FinnyColors.gold,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  p.title,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  p.body,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(color: FinnyColors.mist),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _index == i ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _index == i
                            ? FinnyColors.purpleBright
                            : FinnyColors.line,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    if (_index < _pages.length - 1) {
                      _page.nextPage(
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOutCubic,
                      );
                    } else {
                      widget.onDone();
                    }
                  },
                  child: Text(
                    _index < _pages.length - 1 ? 'Дальше' : 'Создать питомца',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
