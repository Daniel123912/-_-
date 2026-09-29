import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/create_pet/create_pet_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'fx/finny_fx.dart';
import 'state/game_controller.dart';
import 'theme/app_theme.dart';

class FinnyApp extends ConsumerStatefulWidget {
  const FinnyApp({super.key});

  @override
  ConsumerState<FinnyApp> createState() => _FinnyAppState();
}

class _FinnyAppState extends ConsumerState<FinnyApp>
    with WidgetsBindingObserver {
  bool _showOnboarding = true;
  var _musicBooted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        FinnyFx.resumeMusic();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        FinnyFx.pauseMusic();
    }
  }

  void _bootMusicIfNeeded(bool hasProfile) {
    if (_musicBooted || !hasProfile) return;
    _musicBooted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FinnyFx.startBackgroundMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(gameControllerProvider);
    _bootMusicIfNeeded(profileAsync.asData?.value != null);

    return MaterialApp(
      title: 'Питомец Финни',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: profileAsync.when(
        loading: () => const Scaffold(
          body: PlayBackground(
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (e, _) => Scaffold(
          body: Center(child: Text('Ошибка: $e')),
        ),
        data: (profile) {
          if (profile == null) {
            if (_showOnboarding) {
              return OnboardingScreen(
                onDone: () => setState(() => _showOnboarding = false),
              );
            }
            return const CreatePetScreen();
          }
          return const HomeScreen();
        },
      ),
    );
  }
}
