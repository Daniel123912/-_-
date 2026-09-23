import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_controller.dart';
import 'junior_play_shell.dart';

/// Главный экран: единый игровой шелл (как у трека 7–8) для всех возрастов.
/// Сложность заданий по-прежнему зависит от `ageTrack`.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(gameControllerProvider).value;
    if (profile == null) {
      return const Scaffold(body: Center(child: Text('Нет профиля')));
    }
    return const JuniorPlayShell();
  }
}
