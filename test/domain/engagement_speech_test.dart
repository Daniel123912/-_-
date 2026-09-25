import 'package:finny/domain/engagement.dart';
import 'package:finny/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

PlayerProfile _fresh() => PlayerProfile.fresh(
      playerName: 'Саша',
      petName: 'Финни',
      appearance: const PetAppearance(
        color: 'синий',
        eyes: 'голубые',
        accessory: 'без',
      ),
      startingBalance: 100,
      ageTrack: AgeTrack.middle,
    );

void main() {
  group('petContextSpeech', () {
    test('asks to plan when phase is planning', () {
      final profile = _fresh();
      const next = NextAction(
        kind: NextActionKind.planBudget,
        title: 'Составь план',
        subtitle: 'Неделя заботы',
      );
      final speech = Engagement.petContextSpeech(profile: profile, next: next);
      expect(speech, contains('план'));
      expect(speech, contains('еды'));
    });

    test('explains hunger and asks for mandatory buy', () {
      final profile = _fresh().copyWith(hunger: 20, mood: 70);
      const next = NextAction(
        kind: NextActionKind.buyMandatory,
        title: 'Купи нужное',
        subtitle: 'Покорми Финни',
      );
      final speech = Engagement.petContextSpeech(profile: profile, next: next);
      expect(speech, contains('голод'));
      expect(speech, contains('еду'));
    });

    test('celebrates claim goal with name', () {
      final profile = _fresh().copyWith(hunger: 80, mood: 85);
      const next = NextAction(
        kind: NextActionKind.claimGoal,
        title: 'Забери цель!',
        subtitle: 'Велосипед',
      );
      final speech = Engagement.petContextSpeech(
        profile: profile,
        next: next,
        goalName: 'Велосипед',
      );
      expect(speech, contains('Велосипед'));
      expect(speech, contains('прыгаю'));
    });
  });

  group('petStateChangeSpeech', () {
    test('returns null when nothing changed', () {
      final profile = _fresh();
      const next = NextAction(
        kind: NextActionKind.doQuests,
        title: 'Сделай задания',
        subtitle: 'Осталось 2',
      );
      expect(
        Engagement.petStateChangeSpeech(
          before: profile,
          after: profile,
          next: next,
        ),
        isNull,
      );
    });

    test('mentions mood rise after optional purchase feel', () {
      final before = _fresh().copyWith(mood: 40, hunger: 70);
      final after = before.copyWith(mood: 55, balance: before.balance - 10);
      const next = NextAction(
        kind: NextActionKind.saveMoney,
        title: 'В копилку',
        subtitle: 'Отложи 5',
      );
      final speech = Engagement.petStateChangeSpeech(
        before: before,
        after: after,
        next: next,
      );
      expect(speech, isNotNull);
      expect(speech!, contains('веселее'));
      expect(speech, contains('копил'));
    });

    test('mentions fullness after food', () {
      final before = _fresh().copyWith(hunger: 30, mood: 50);
      final after = before.copyWith(hunger: 55, balance: before.balance - 15);
      const next = NextAction(
        kind: NextActionKind.doQuests,
        title: 'Сделай задания',
        subtitle: 'Осталось 1',
      );
      final speech = Engagement.petStateChangeSpeech(
        before: before,
        after: after,
        next: next,
      );
      expect(speech, isNotNull);
      expect(speech!, contains('сытость'));
    });
  });
}
