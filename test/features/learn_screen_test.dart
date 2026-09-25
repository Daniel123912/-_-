import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finny/content/content_loader.dart';
import 'package:finny/domain/models.dart';
import 'package:finny/features/learn/learn_screen.dart';
import 'package:finny/state/game_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LearnScreen shows lessons for middle track', (tester) async {
    final content = await ContentLoader.load();
    expect(content.lessons, isNotEmpty, reason: 'lessons.json must load');

    final profile = PlayerProfile.fresh(
      playerName: 'Тест',
      petName: 'Финни',
      appearance: const PetAppearance(
        color: 'синий',
        eyes: 'голубые',
        accessory: 'без',
      ),
      ageTrack: AgeTrack.middle,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentProvider.overrideWith((ref) async => content),
          gameControllerProvider.overrideWith(() => _FixedProfile(profile)),
        ],
        child: const MaterialApp(home: LearnScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Школа Финни'), findsOneWidget);
    expect(find.text('Для этого возраста уроки ещё готовятся.'), findsNothing);
    expect(find.textContaining('/'), findsWidgets);
    expect(find.text('Три корзины'), findsWidgets);
    expect(find.text('Играть сейчас'), findsOneWidget);
  });
}

class _FixedProfile extends GameController {
  _FixedProfile(this._profile);
  final PlayerProfile _profile;

  @override
  Future<PlayerProfile?> build() async => _profile;
}
