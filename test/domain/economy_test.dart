import 'package:finny/domain/economy.dart';
import 'package:finny/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

PlayerProfile baseProfile({
  int balance = 100,
  AgeTrack ageTrack = AgeTrack.middle,
  bool demoMode = true,
}) {
  return PlayerProfile.fresh(
    playerName: 'Саша',
    petName: 'Финни',
    appearance: const PetAppearance(
      color: 'синий',
      eyes: 'голубые',
      accessory: 'без',
    ),
    startingBalance: balance,
    ageTrack: ageTrack,
  ).copyWith(demoMode: demoMode);
}

Quest sampleQuest({
  String id = 'q1',
  QuestTheme theme = QuestTheme.budget,
  QuestDifficulty difficulty = QuestDifficulty.easy,
  bool goodFirst = true,
  Set<AgeTrack> ageTracks = const {
    AgeTrack.junior,
    AgeTrack.middle,
    AgeTrack.senior,
  },
}) {
  return Quest(
    id: id,
    title: 'Тест',
    prompt: '?',
    theme: theme,
    difficulty: difficulty,
    ageTracks: ageTracks,
    options: [
      QuestOption(
        id: 'a',
        label: 'да',
        isGood: goodFirst,
        reward: 12,
        explanation: 'хорошо',
      ),
      const QuestOption(
        id: 'b',
        label: 'нет',
        isGood: false,
        reward: 3,
        explanation: 'подумай ещё',
      ),
    ],
  );
}

void main() {
  group('GameEconomy', () {
    test('confirmPlan rejects overspend', () {
      final profile = baseProfile(balance: 50);
      final result = GameEconomy.confirmPlan(
        profile,
        const BudgetPlan(mandatory: 30, optional: 20, savings: 10),
      );
      expect(result.ok, isFalse);
    });

    test('confirmPlan locks plan, opens playing and assigns quests', () {
      final profile = baseProfile();
      final pool = [
        sampleQuest(id: 'qb', theme: QuestTheme.budget),
        sampleQuest(id: 'qs', theme: QuestTheme.savings),
        sampleQuest(id: 'qp', theme: QuestTheme.purchases),
      ];
      final result = GameEconomy.confirmPlan(
        profile,
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
        questPool: pool,
      );
      expect(result.ok, isTrue);
      expect(result.profile.period.phase, PeriodPhase.playing);
      expect(result.profile.period.plan.total, 90);
      expect(result.profile.period.activeQuestIds.length, 3);
    });

    test('purchase fails without funds', () {
      final planned = GameEconomy.confirmPlan(
        baseProfile(balance: 20),
        const BudgetPlan(mandatory: 10, optional: 5, savings: 5),
      ).profile;
      final item = const ShopItem(
        id: 'toy',
        name: 'Мячик',
        price: 25,
        kind: ExpenseKind.optional,
        effectHint: 'весело',
        hungerDelta: 0,
        moodDelta: 5,
      );
      final result = GameEconomy.purchase(planned, item);
      expect(result.ok, isFalse);
      expect(result.message, contains('Не хватает'));
    });

    test('purchase decreases balance and updates fact', () {
      final planned = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
      ).profile;
      final item = const ShopItem(
        id: 'food',
        name: 'Еда',
        price: 20,
        kind: ExpenseKind.mandatory,
        effectHint: 'сытость',
        hungerDelta: 20,
        moodDelta: 5,
      );
      final result = GameEconomy.purchase(planned, item);
      expect(result.ok, isTrue);
      expect(result.profile.balance, 80);
      expect(result.profile.period.fact.mandatorySpent, 20);
    });

    test('savings transfer and withdraw require confirmation', () {
      var profile = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 30, optional: 20, savings: 30),
      ).profile;
      profile = profile.copyWith(selectedGoalId: 'house');
      final saved = GameEconomy.transferToSavings(profile, 15);
      expect(saved.ok, isTrue);
      expect(saved.profile.savingsBalance, 15);
      expect(saved.profile.period.fact.saved, 15);

      final warn = GameEconomy.withdrawFromSavings(
        saved.profile,
        15,
        confirmed: false,
      );
      expect(warn.ok, isFalse);

      final withdrawn = GameEconomy.withdrawFromSavings(
        saved.profile,
        15,
        confirmed: true,
      );
      expect(withdrawn.ok, isTrue);
      expect(withdrawn.profile.savingsBalance, 0);
      expect(withdrawn.profile.period.fact.saved, 0);
    });

    test('claimGoal spends savings and grants stars', () {
      var profile = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 30, optional: 20, savings: 20),
      ).profile;
      profile = profile.copyWith(
        selectedGoalId: 'party',
        savingsBalance: 90,
      );
      const goal = SavingsGoal(
        id: 'party',
        name: 'Праздник',
        cost: 90,
        description: 'fun',
      );
      final result = GameEconomy.claimGoal(profile, goal);
      expect(result.ok, isTrue);
      expect(result.profile.savingsBalance, 0);
      expect(result.profile.stars, 5);
      expect(result.profile.selectedGoalId, isNull);
    });

    test('closePeriod can grow pet after good streak', () {
      var profile = baseProfile();
      for (var i = 0; i < 2; i++) {
        profile = GameEconomy.confirmPlan(
          profile,
          const BudgetPlan(mandatory: 30, optional: 20, savings: 20),
        ).profile;
        profile = GameEconomy.purchase(
          profile,
          const ShopItem(
            id: 'food',
            name: 'Еда',
            price: 25,
            kind: ExpenseKind.mandatory,
            effectHint: 'ok',
            hungerDelta: 10,
            moodDelta: 5,
          ),
        ).profile;
        profile = GameEconomy.transferToSavings(
          profile.copyWith(selectedGoalId: 'house'),
          15,
        ).profile;
        final closed = GameEconomy.closePeriod(profile);
        profile = closed.profile;
        if (profile.period.phase == PeriodPhase.summary) {
          profile = GameEconomy.startNextPeriod(profile);
        }
      }
      expect(profile.growthStage, greaterThanOrEqualTo(1));
      expect(profile.totalPeriodsCompleted, greaterThanOrEqualTo(1));
    });

    test('quest blocked before plan', () {
      final profile = baseProfile();
      final quest = sampleQuest();
      final result =
          GameEconomy.completeQuest(profile, quest, quest.options.first);
      expect(result.ok, isFalse);
      expect(result.message, contains('плана'));
    });

    test('wrong answer allows retry; good answer closes once', () {
      var profile = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
        questPool: [sampleQuest()],
      ).profile;
      final quest = sampleQuest();
      final wrong = GameEconomy.completeQuest(
        profile,
        quest,
        quest.options.last,
      );
      expect(wrong.ok, isFalse);
      expect(wrong.profile.period.completedQuestIds, isEmpty);
      expect(wrong.profile.period.goodQuestStreak, 0);

      final first = GameEconomy.completeQuest(
        wrong.profile,
        quest,
        quest.options.first,
      );
      expect(first.ok, isTrue);
      expect(first.profile.period.completedQuestIds, contains('q1'));
      expect(first.profile.stars, 1);
      expect(first.profile.skills.budgetXp, greaterThan(0));

      final second = GameEconomy.completeQuest(
        first.profile,
        quest,
        quest.options.first,
      );
      expect(second.ok, isFalse);
    });

    test('quests filtered by age track', () {
      final junior = baseProfile(ageTrack: AgeTrack.junior);
      const easy = Quest(
        id: 'easy',
        title: 'e',
        prompt: '?',
        theme: QuestTheme.budget,
        difficulty: QuestDifficulty.easy,
        ageTracks: {AgeTrack.junior, AgeTrack.middle},
        options: [],
      );
      const hard = Quest(
        id: 'hard',
        title: 'h',
        prompt: '?',
        theme: QuestTheme.budget,
        difficulty: QuestDifficulty.hard,
        ageTracks: {AgeTrack.senior},
        options: [],
      );
      final list = GameEconomy.questsForProfile(junior, [easy, hard]);
      expect(list.map((e) => e.id), ['easy']);
    });

    test('junior never sees medium or hard difficulty', () {
      final junior = baseProfile(ageTrack: AgeTrack.junior);
      final pool = [
        sampleQuest(id: 'e', difficulty: QuestDifficulty.easy),
        sampleQuest(
          id: 'm',
          difficulty: QuestDifficulty.medium,
          ageTracks: {AgeTrack.middle, AgeTrack.senior},
        ),
        sampleQuest(
          id: 'h',
          difficulty: QuestDifficulty.hard,
          ageTracks: {AgeTrack.senior},
        ),
        // easy по сложности, но размечен только для старших — junior не видит
        sampleQuest(
          id: 'e_old',
          difficulty: QuestDifficulty.easy,
          ageTracks: {AgeTrack.middle, AgeTrack.senior},
        ),
      ];
      final visible = GameEconomy.questsForProfile(junior, pool);
      expect(visible.map((q) => q.id), ['e']);
      expect(
        visible.every((q) => q.difficulty == QuestDifficulty.easy),
        isTrue,
      );

      final picked = GameEconomy.pickPeriodQuests(junior, pool);
      expect(picked, isNotEmpty);
      expect(picked.every((id) => id == 'e'), isTrue);
    });

    test('sanitizeActiveQuestIds drops wrong age or difficulty', () {
      final junior = baseProfile(ageTrack: AgeTrack.junior).copyWith(
        period: baseProfile(ageTrack: AgeTrack.junior).period.copyWith(
              phase: PeriodPhase.playing,
              activeQuestIds: const ['ok', 'hard', 'old'],
            ),
      );
      final pool = [
        sampleQuest(id: 'ok', difficulty: QuestDifficulty.easy),
        sampleQuest(
          id: 'hard',
          difficulty: QuestDifficulty.hard,
          ageTracks: {AgeTrack.senior},
        ),
        sampleQuest(
          id: 'old',
          difficulty: QuestDifficulty.easy,
          ageTracks: {AgeTrack.middle, AgeTrack.senior},
        ),
      ];
      expect(
        GameEconomy.sanitizeActiveQuestIds(junior, pool),
        ['ok'],
      );
    });

    test('pickPeriodQuests prefers junior-only quests', () {
      final junior = baseProfile(ageTrack: AgeTrack.junior);
      final pool = [
        sampleQuest(
          id: 'shared',
          theme: QuestTheme.budget,
          ageTracks: {
            AgeTrack.junior,
            AgeTrack.middle,
            AgeTrack.senior,
          },
        ),
        sampleQuest(
          id: 'q_j_only',
          theme: QuestTheme.budget,
          ageTracks: {AgeTrack.junior},
        ),
        sampleQuest(
          id: 'qs',
          theme: QuestTheme.savings,
          ageTracks: {AgeTrack.junior},
        ),
        sampleQuest(
          id: 'qp',
          theme: QuestTheme.purchases,
          ageTracks: {AgeTrack.junior},
        ),
      ];
      final picked = GameEconomy.pickPeriodQuests(junior, pool);
      // По теме budget сначала берём задание только для junior.
      expect(picked.first, 'q_j_only');
      expect(picked, containsAll(['qs', 'qp']));
    });

    test('nextAction guides planning then quests', () {
      final planning = baseProfile();
      expect(
        GameEconomy.nextAction(planning).kind,
        NextActionKind.planBudget,
      );

      final playing = GameEconomy.confirmPlan(
        planning,
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
        questPool: [
          sampleQuest(id: 'qb', theme: QuestTheme.budget),
          sampleQuest(id: 'qs', theme: QuestTheme.savings),
          sampleQuest(id: 'qp', theme: QuestTheme.purchases),
        ],
      ).profile;
      expect(
        GameEconomy.nextAction(playing).kind,
        NextActionKind.doQuests,
      );
    });

    test('quest can be replayed in next period', () {
      var profile = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
        questPool: [sampleQuest()],
      ).profile;
      final quest = sampleQuest();
      profile = GameEconomy.completeQuest(
        profile,
        quest,
        quest.options.first,
      ).profile;
      profile = GameEconomy.closePeriod(profile).profile;
      profile = GameEconomy.startNextPeriod(profile);
      profile = GameEconomy.confirmPlan(
        profile,
        const BudgetPlan(mandatory: 30, optional: 20, savings: 20),
        questPool: [sampleQuest()],
      ).profile;
      final again = GameEconomy.completeQuest(
        profile,
        quest,
        quest.options.first,
      );
      expect(again.ok, isTrue);
    });

    test('starting balance depends on age track', () {
      expect(GameEconomy.startingBalanceFor(AgeTrack.junior), 100);
      expect(GameEconomy.startingBalanceFor(AgeTrack.middle), 110);
      expect(GameEconomy.startingBalanceFor(AgeTrack.senior), 120);
      final senior = PlayerProfile.fresh(
        playerName: 'Саша',
        petName: 'Финни',
        appearance: const PetAppearance(
          color: 'синий',
          eyes: 'голубые',
          accessory: 'без',
        ),
        ageTrack: AgeTrack.senior,
      );
      expect(senior.balance, 120);
    });

    test('period income is credited and never goes negative', () {
      final next = GameEconomy.startNextPeriod(baseProfile(balance: 50));
      expect(next.balance, 50 + GameEconomy.incomeForTrack(AgeTrack.middle));
      expect(next.period.phase, PeriodPhase.planning);
      expect(next.period.index, 2);
      expect(GameEconomy.clampBalance(-7), 0);
      expect(GameEconomy.canAfford(baseProfile(balance: 10), 11), isFalse);
    });

    test('recommendedPlan distributes full balance into four baskets', () {
      final plan = GameEconomy.recommendedPlan(baseProfile(balance: 100));
      expect(plan.total, 100);
      expect(plan.mandatory, greaterThan(0));
      expect(plan.optional, greaterThanOrEqualTo(0));
      expect(plan.savings, greaterThanOrEqualTo(0));
      expect(plan.gift, greaterThanOrEqualTo(0));
    });

    test('comparePlanFact marks good period when needs and savings ok', () {
      const plan = BudgetPlan(mandatory: 30, optional: 20, savings: 20);
      const fact = BudgetFact(mandatorySpent: 25, optionalSpent: 10, saved: 15);
      final report = GameEconomy.comparePlanFact(plan, fact);
      expect(report.mandatoryOk, isTrue);
      expect(report.savedOk, isTrue);
      expect(report.wasGoodPeriod, isTrue);
    });

    test('bad mandatory spending hurts pet stats on closePeriod', () {
      var profile = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
      ).profile;
      final beforeHunger = profile.hunger;
      final beforeMood = profile.mood;
      // Spend only optional — skip mandatory needs.
      profile = GameEconomy.purchase(
        profile,
        const ShopItem(
          id: 'toy',
          name: 'Игрушка',
          price: 10,
          kind: ExpenseKind.optional,
          effectHint: 'весело',
          hungerDelta: 0,
          moodDelta: 2,
        ),
      ).profile;
      final closed = GameEconomy.closePeriod(profile);
      expect(closed.wasGoodPeriod, isFalse);
      expect(closed.profile.hunger, lessThan(beforeHunger));
      expect(closed.profile.mood, lessThan(beforeMood + 2));
      expect(closed.feedback, contains('Обязательные'));
    });

    test('two good periods grow pet to stage 2', () {
      var profile = baseProfile().copyWith(selectedGoalId: 'house');
      expect(profile.growthStage, 1);

      for (var i = 0; i < 2; i++) {
        profile = GameEconomy.confirmPlan(
          profile,
          const BudgetPlan(mandatory: 30, optional: 20, savings: 20),
        ).profile;
        profile = GameEconomy.purchase(
          profile,
          const ShopItem(
            id: 'food',
            name: 'Еда',
            price: 25,
            kind: ExpenseKind.mandatory,
            effectHint: 'ok',
            hungerDelta: 10,
            moodDelta: 5,
          ),
        ).profile;
        profile = GameEconomy.transferToSavings(profile, 15).profile;
        final closed = GameEconomy.closePeriod(profile);
        expect(closed.wasGoodPeriod, isTrue);
        profile = closed.profile;
        if (profile.period.phase == PeriodPhase.summary) {
          profile = GameEconomy.startNextPeriod(profile);
        }
      }

      expect(profile.growthStage, 2);
      expect(
        GameEconomy.applyStageProgress(currentStage: 3, goodStreak: 5).grew,
        isFalse,
      );
    });

    test('guided path without goal still requires savings before finish', () {
      var profile = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
      ).profile;
      expect(profile.selectedGoalId, isNull);

      profile = GameEconomy.purchase(
        profile,
        const ShopItem(
          id: 'food',
          name: 'Еда',
          price: 30,
          kind: ExpenseKind.mandatory,
          effectHint: 'ok',
          hungerDelta: 10,
          moodDelta: 2,
        ),
      ).profile;

      // Без копилки нельзя завершить — иначе стадия никогда не растёт.
      expect(
        GameEconomy.nextAction(profile).kind,
        NextActionKind.saveMoney,
      );

      final saved = GameEconomy.transferToSavings(profile, 20);
      expect(saved.ok, isTrue);
      profile = saved.profile;
      expect(
        GameEconomy.nextAction(profile).kind,
        NextActionKind.finishPeriod,
      );

      final closed = GameEconomy.closePeriod(profile);
      expect(closed.wasGoodPeriod, isTrue);
      expect(closed.profile.goodPeriodStreak, 1);
    });

    test('two good periods without goal grow pet to stage 2', () {
      var profile = baseProfile();
      expect(profile.selectedGoalId, isNull);
      expect(profile.growthStage, 1);

      for (var i = 0; i < 2; i++) {
        profile = GameEconomy.confirmPlan(
          profile,
          const BudgetPlan(mandatory: 30, optional: 20, savings: 20),
        ).profile;
        profile = GameEconomy.purchase(
          profile,
          const ShopItem(
            id: 'food',
            name: 'Еда',
            price: 25,
            kind: ExpenseKind.mandatory,
            effectHint: 'ok',
            hungerDelta: 10,
            moodDelta: 5,
          ),
        ).profile;
        profile = GameEconomy.transferToSavings(profile, 15).profile;
        final closed = GameEconomy.closePeriod(profile);
        expect(closed.wasGoodPeriod, isTrue);
        profile = closed.profile;
        if (profile.period.phase == PeriodPhase.summary) {
          profile = GameEconomy.startNextPeriod(profile);
        }
      }

      expect(profile.growthStage, 2);
    });

    test('quest reward links finance to pet mood and balance', () {
      var profile = GameEconomy.confirmPlan(
        baseProfile(balance: 100),
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
        questPool: [sampleQuest()],
      ).profile;
      final before = profile.balance;
      final beforeMood = profile.mood;
      final result = GameEconomy.completeQuest(
        profile,
        sampleQuest(),
        sampleQuest().options.first,
      );
      expect(result.ok, isTrue);
      expect(result.profile.balance, greaterThan(before));
      expect(result.profile.mood, greaterThan(beforeMood));
      expect(result.earnedStars, 1);
    });

    test('confirmPlan rejects zero mandatory and negative baskets', () {
      final zeroMandatory = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 0, optional: 50, savings: 20),
      );
      expect(zeroMandatory.ok, isFalse);

      final negative = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 40, optional: -1, savings: 20),
      );
      expect(negative.ok, isFalse);
    });

    test('withdraw reduces fact.saved and rejects outside playing', () {
      var profile = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 30, optional: 20, savings: 40),
      ).profile;
      profile = profile.copyWith(selectedGoalId: 'house');
      profile = GameEconomy.transferToSavings(profile, 30).profile;
      expect(profile.period.fact.saved, 30);

      profile = GameEconomy.withdrawFromSavings(
        profile,
        20,
        confirmed: true,
      ).profile;
      expect(profile.savingsBalance, 10);
      expect(profile.period.fact.saved, 10);

      final closed = GameEconomy.closePeriod(profile).profile;
      final blocked = GameEconomy.withdrawFromSavings(
        closed,
        5,
        confirmed: true,
      );
      expect(blocked.ok, isFalse);
    });

    test('quest combo and period bonus follow reward formula', () {
      final quest = sampleQuest(id: 'q_combo');
      var profile = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
        questPool: [
          quest,
          sampleQuest(id: 'qs', theme: QuestTheme.savings),
          sampleQuest(id: 'qp', theme: QuestTheme.purchases),
        ],
      ).profile;

      // First correct: streak=1 → comboBonus 0; period +4; difficulty easy ★*2=2
      // reward = 12 + 0 + 2 + 4 + 0 = 18
      final first = GameEconomy.completeQuest(
        profile,
        quest,
        quest.options.first,
      );
      expect(first.ok, isTrue);
      expect(first.combo, 1);
      expect(first.profile.balance, profile.balance + 18);

      final q2 = sampleQuest(id: 'qs', theme: QuestTheme.savings);
      final second = GameEconomy.completeQuest(
        first.profile,
        q2,
        q2.options.first,
      );
      // streak=2 → combo (2-1)*2=2; reward = 12+2+2+4=20
      expect(second.combo, 2);
      expect(second.profile.balance, first.profile.balance + 20);
    });

    test('catalog practice gives XP without coins', () {
      final periodQuest = sampleQuest(id: 'qb', theme: QuestTheme.budget);
      final practice = sampleQuest(id: 'practice', theme: QuestTheme.savings);
      var profile = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
        questPool: [
          periodQuest,
          sampleQuest(id: 'qs', theme: QuestTheme.savings),
          sampleQuest(id: 'qp', theme: QuestTheme.purchases),
        ],
      ).profile;
      final before = profile.balance;
      final result = GameEconomy.completeQuest(
        profile,
        practice,
        practice.options.first,
      );
      expect(result.ok, isTrue);
      expect(result.profile.balance, before);
      expect(result.earnedStars, 0);
      expect(result.earnedXp, greaterThan(0));
    });

    test('wrong answer grants fail XP only once per quest', () {
      final quest = sampleQuest();
      var profile = GameEconomy.confirmPlan(
        baseProfile(ageTrack: AgeTrack.junior),
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
        questPool: [quest],
      ).profile;
      final firstWrong = GameEconomy.completeQuest(
        profile,
        quest,
        quest.options.last,
      );
      expect(firstWrong.earnedXp, 3);
      expect(firstWrong.profile.skills.budgetXp, 3);

      final secondWrong = GameEconomy.completeQuest(
        firstWrong.profile,
        quest,
        quest.options.last,
      );
      expect(secondWrong.earnedXp, 0);
      expect(secondWrong.profile.skills.budgetXp, 3);
    });

    test('incomeForTrack and estimatedPeriodsToGoal', () {
      expect(GameEconomy.incomeForTrack(AgeTrack.junior), 45);
      expect(GameEconomy.incomeForTrack(AgeTrack.middle), 40);
      expect(GameEconomy.incomeForTrack(AgeTrack.senior), 45);

      final profile = baseProfile().copyWith(savingsBalance: 30);
      const goal = SavingsGoal(
        id: 'party',
        name: 'Праздник',
        cost: 90,
        description: 'fun',
      );
      expect(
        GameEconomy.estimatedPeriodsToGoal(profile, goal, averageSaving: 15),
        4,
      );
      expect(
        GameEconomy.estimatedPeriodsToGoal(
          profile.copyWith(savingsBalance: 90),
          goal,
        ),
        0,
      );
    });

    test('closePeriod bonuses for all quests and partial quests', () {
      final pool = [
        sampleQuest(id: 'qb', theme: QuestTheme.budget),
        sampleQuest(id: 'qs', theme: QuestTheme.savings),
        sampleQuest(id: 'qp', theme: QuestTheme.purchases),
      ];
      var profile = GameEconomy.confirmPlan(
        baseProfile().copyWith(selectedGoalId: 'house'),
        const BudgetPlan(mandatory: 30, optional: 20, savings: 20),
        questPool: pool,
      ).profile;
      for (final q in pool) {
        profile = GameEconomy.completeQuest(
          profile,
          q,
          q.options.first,
        ).profile;
      }
      profile = GameEconomy.purchase(
        profile,
        const ShopItem(
          id: 'food',
          name: 'Еда',
          price: 25,
          kind: ExpenseKind.mandatory,
          effectHint: 'ok',
          hungerDelta: 10,
          moodDelta: 5,
        ),
      ).profile;
      profile = GameEconomy.transferToSavings(profile, 15).profile;
      final beforeStars = profile.stars;
      final beforeBalance = profile.balance;
      final closed = GameEconomy.closePeriod(profile);
      expect(closed.wasGoodPeriod, isTrue);
      expect(closed.profile.balance, beforeBalance + 10);
      expect(closed.profile.stars, greaterThanOrEqualTo(beforeStars + 2));
    });

    test('purchase over plan reduces mood by 3', () {
      var profile = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 20, optional: 10, savings: 20),
      ).profile;
      final beforeMood = profile.mood;
      profile = GameEconomy.purchase(
        profile,
        const ShopItem(
          id: 'toy',
          name: 'Игрушка',
          price: 15,
          kind: ExpenseKind.optional,
          effectHint: 'весело',
          hungerDelta: 0,
          moodDelta: 5,
        ),
      ).profile;
      // mood +5 item, -3 overPlan → net +2
      expect(profile.mood, beforeMood + 2);
    });

    test('pickPeriodQuests count by track', () {
      final pool = [
        sampleQuest(id: 'qb', theme: QuestTheme.budget),
        sampleQuest(id: 'qs', theme: QuestTheme.savings),
        sampleQuest(id: 'qp', theme: QuestTheme.purchases),
        sampleQuest(id: 'qb2', theme: QuestTheme.budget),
        sampleQuest(
          id: 'qm',
          theme: QuestTheme.budget,
          difficulty: QuestDifficulty.medium,
        ),
        sampleQuest(
          id: 'qh',
          theme: QuestTheme.budget,
          difficulty: QuestDifficulty.hard,
        ),
      ];
      expect(
        GameEconomy.pickPeriodQuests(
          baseProfile(ageTrack: AgeTrack.junior),
          pool,
        ).length,
        4,
      );
      expect(
        GameEconomy.pickPeriodQuests(
          baseProfile(ageTrack: AgeTrack.middle),
          pool,
        ).length,
        4,
      );
      expect(
        GameEconomy.pickPeriodQuests(
          baseProfile(ageTrack: AgeTrack.senior),
          pool,
        ).length,
        4,
      );
    });

    test('goalsForProfile filters by age track', () {
      const goals = [
        SavingsGoal(
          id: 'treat',
          name: 'Лакомство',
          cost: 60,
          description: 'x',
          ageTracks: {AgeTrack.junior, AgeTrack.middle},
        ),
        SavingsGoal(
          id: 'bike',
          name: 'Велосипед',
          cost: 180,
          description: 'x',
          ageTracks: {AgeTrack.senior},
        ),
      ];
      final juniorGoals = GameEconomy.goalsForProfile(
        baseProfile(ageTrack: AgeTrack.junior),
        goals,
      );
      expect(juniorGoals.map((g) => g.id), ['treat']);
    });

    test('nextAction covers claimGoal buyMandatory save and finish', () {
      final claimProfile = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 30, optional: 20, savings: 20),
      ).profile.copyWith(selectedGoalId: 'party', savingsBalance: 90);
      expect(
        GameEconomy.nextAction(
          claimProfile,
          goal: const SavingsGoal(
            id: 'party',
            name: 'Праздник',
            cost: 90,
            description: 'x',
          ),
        ).kind,
        NextActionKind.claimGoal,
      );

      var playing = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
      ).profile;
      expect(
        GameEconomy.nextAction(playing).kind,
        NextActionKind.buyMandatory,
      );

      playing = GameEconomy.purchase(
        playing,
        const ShopItem(
          id: 'food',
          name: 'Еда',
          price: 30,
          kind: ExpenseKind.mandatory,
          effectHint: 'ok',
          hungerDelta: 10,
          moodDelta: 2,
        ),
      ).profile.copyWith(selectedGoalId: 'house');
      expect(
        GameEconomy.nextAction(playing).kind,
        NextActionKind.saveMoney,
      );

      playing = GameEconomy.transferToSavings(playing, 20).profile;
      expect(
        GameEconomy.nextAction(playing).kind,
        NextActionKind.finishPeriod,
      );

      final summary = GameEconomy.closePeriod(playing).profile;
      expect(
        GameEconomy.nextAction(summary).kind,
        NextActionKind.viewSummary,
      );
    });

    test('comparePlanFact rejects empty mandatory spend', () {
      const plan = BudgetPlan(mandatory: 30, optional: 20, savings: 20);
      const fact = BudgetFact(mandatorySpent: 0, optionalSpent: 20, saved: 20);
      final report = GameEconomy.comparePlanFact(plan, fact);
      expect(report.mandatoryOk, isFalse);
      expect(report.wasGoodPeriod, isFalse);
    });

    test('skill level adds coin bonus on period quest', () {
      final quest = sampleQuest();
      var profile = GameEconomy.confirmPlan(
        baseProfile().copyWith(
          skills: const SkillProgress(budgetXp: 80), // level 3 → bonus 2
        ),
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
        questPool: [quest],
      ).profile;
      final before = profile.balance;
      final result = GameEconomy.completeQuest(
        profile,
        quest,
        quest.options.first,
      );
      // 12 + 0 + 2 + 4 + 2 skill = 20
      expect(result.profile.balance, before + 20);
    });

    test('lessons filtered by age and complete once with reward', () {
      const juniorLesson = LearningLesson(
        id: 'l_j',
        title: 'Нужное',
        hook: 'hook',
        story: 'story',
        theme: QuestTheme.budget,
        ageTracks: {AgeTrack.junior},
        steps: [
          LessonStep(title: '1', text: 't', icon: 'restaurant'),
        ],
        quiz: LessonQuiz(
          prompt: '?',
          options: [
            QuestOption(
              id: 'a',
              label: 'да',
              isGood: true,
              reward: 4,
              explanation: 'верно',
            ),
            QuestOption(
              id: 'b',
              label: 'нет',
              isGood: false,
              reward: 0,
              explanation: 'нет',
            ),
          ],
        ),
        rewardXp: 8,
        rewardCoins: 4,
      );
      const seniorOnly = LearningLesson(
        id: 'l_s',
        title: 'Сюрприз',
        hook: 'h',
        story: 's',
        theme: QuestTheme.budget,
        ageTracks: {AgeTrack.senior},
        steps: [],
        quiz: LessonQuiz(
          prompt: '?',
          options: [
            QuestOption(
              id: 'a',
              label: 'ok',
              isGood: true,
              reward: 1,
              explanation: 'ok',
            ),
          ],
        ),
      );

      final junior = baseProfile(ageTrack: AgeTrack.junior);
      final list = GameEconomy.lessonsForProfile(
        junior,
        [juniorLesson, seniorOnly],
      );
      expect(list.map((e) => e.id), ['l_j']);

      final wrong = GameEconomy.completeLesson(
        junior,
        juniorLesson,
        juniorLesson.quiz.options.last,
      );
      expect(wrong.ok, isFalse);
      expect(wrong.profile.completedLessonIds, isEmpty);

      final ok = GameEconomy.completeLesson(
        junior,
        juniorLesson,
        juniorLesson.quiz.options.first,
      );
      expect(ok.ok, isTrue);
      expect(ok.profile.completedLessonIds, contains('l_j'));
      expect(ok.profile.balance, junior.balance + 4);
      expect(ok.earnedStars, 1);

      final again = GameEconomy.completeLesson(
        ok.profile,
        juniorLesson,
        juniorLesson.quiz.options.first,
      );
      expect(again.ok, isTrue);
      expect(again.earnedStars, 0);
      expect(again.profile.balance, ok.profile.balance);
    });

    test('gift purchase updates giftSpent', () {
      var profile = GameEconomy.confirmPlan(
        baseProfile(balance: 100),
        const BudgetPlan(mandatory: 30, optional: 20, savings: 20, gift: 15),
      ).profile;
      final result = GameEconomy.purchase(
        profile,
        const ShopItem(
          id: 'gift_friend',
          name: 'Подарок другу',
          price: 15,
          kind: ExpenseKind.gift,
          effectHint: 'ok',
          hungerDelta: 0,
          moodDelta: 10,
        ),
      );
      expect(result.ok, isTrue);
      expect(result.profile.period.fact.giftSpent, 15);
      expect(result.profile.balance, 85);
    });

    test('daily login bonus once per day; skip day does not wipe', () {
      final day = DateTime(2026, 9, 18);
      final first = GameEconomy.claimDailyLogin(baseProfile(), now: day);
      expect(first.ok, isTrue);
      expect(first.profile.balance, 100 + GameEconomy.loginBonusCoins);
      final again = GameEconomy.claimDailyLogin(first.profile, now: day);
      expect(again.ok, isFalse);
      expect(again.profile.balance, first.profile.balance);
      final nextDay = GameEconomy.claimDailyLogin(
        first.profile,
        now: day.add(const Duration(days: 1)),
      );
      expect(nextDay.ok, isTrue);
      expect(nextDay.profile.completedQuestIds, isEmpty);
    });

    test('parent grant respects cap', () {
      var profile = baseProfile();
      final first = GameEconomy.grantParentCoins(profile);
      expect(first.ok, isTrue);
      expect(first.profile.parentGrantTotal, GameEconomy.parentGrantAmount);
      profile = first.profile.copyWith(parentGrantTotal: GameEconomy.parentGrantCap);
      final blocked = GameEconomy.grantParentCoins(profile);
      expect(blocked.ok, isFalse);
    });

    test('normalizeCooldowns enables demo and clears lock', () {
      final now = DateTime(2026, 9, 28, 10);
      final stuck = baseProfile(demoMode: false).copyWith(
        nextPeriodAvailableAt:
            now.add(const Duration(minutes: 50)).toIso8601String(),
      );
      final fixed = GameEconomy.normalizeCooldowns(stuck, now: now);
      expect(fixed.demoMode, isTrue);
      expect(fixed.nextPeriodAvailableAt, isNull);
      expect(GameEconomy.canAdvancePeriod(fixed, now: now), isTrue);
    });

    test('non-demo mode blocks next period until cooldown', () {
      var profile = GameEconomy.confirmPlan(
        baseProfile().copyWith(demoMode: false),
        const BudgetPlan(mandatory: 40, optional: 20, savings: 20),
      ).profile;
      profile = GameEconomy.purchase(
        profile,
        const ShopItem(
          id: 'food',
          name: 'Еда',
          price: 30,
          kind: ExpenseKind.mandatory,
          effectHint: 'ok',
          hungerDelta: 10,
          moodDelta: 5,
        ),
      ).profile;
      profile = GameEconomy.transferToSavings(profile, 15).profile;
      final closed = GameEconomy.closePeriod(profile);
      expect(closed.profile.nextPeriodAvailableAt, isNotNull);
      final blocked = GameEconomy.startNextPeriod(closed.profile);
      expect(blocked.period.index, closed.profile.period.index);
      final unlocked = GameEconomy.startNextPeriod(
        closed.profile.copyWith(demoMode: true),
      );
      expect(unlocked.period.index, closed.profile.period.index + 1);
    });

    test('stage progress hint mentions next stage', () {
      final hint = GameEconomy.stageProgressHint(baseProfile());
      expect(hint, contains('хорош'));
      expect(GameEconomy.stageTitle(1), 'Малыш');
      expect(GameEconomy.stageTitle(3), 'Чемпион');
    });

    test('claimSecretOfDay once per day', () {
      final profile = baseProfile();
      final first = GameEconomy.claimSecretOfDay(
        profile,
        now: DateTime(2026, 9, 23),
      );
      expect(first.ok, isTrue);
      expect(first.celebrate, isTrue);
      expect(first.profile.balance, greaterThan(profile.balance));
      final second = GameEconomy.claimSecretOfDay(
        first.profile,
        now: DateTime(2026, 9, 23),
      );
      expect(second.ok, isFalse);
    });

    test('parent challenge completes with celebration', () {
      var profile = baseProfile(balance: 100).copyWith(
        selectedGoalId: 'g1',
        period: GamePeriod(
          index: 1,
          startingBalance: 100,
          phase: PeriodPhase.playing,
          plan: const BudgetPlan(mandatory: 20, optional: 20, savings: 40),
        ),
      );
      profile = GameEconomy.setParentChallenge(profile, 20).profile;
      final saved = GameEconomy.transferToSavings(profile, 20);
      expect(saved.ok, isTrue);
      expect(saved.celebrate, isTrue);
      expect(saved.profile.parentChallengeTarget, isNull);
      expect(saved.earnedStars, 3);
    });

    test('purchase tracks cosmetics and can complete collection', () {
      var profile = baseProfile(balance: 200).copyWith(
        period: GamePeriod(
          index: 1,
          startingBalance: 200,
          phase: PeriodPhase.playing,
          plan: const BudgetPlan(
            mandatory: 20,
            optional: 100,
            savings: 20,
            gift: 40,
          ),
        ),
        ownedItemIds: const ['mystery_box', 'gift_friend'],
      );
      final item = const ShopItem(
        id: 'gift_charity',
        name: 'Доброе дело',
        price: 10,
        kind: ExpenseKind.gift,
        effectHint: 'ok',
        hungerDelta: 0,
        moodDelta: 5,
        emoji: '💝',
      );
      final result = GameEconomy.purchase(profile, item);
      expect(result.ok, isTrue);
      expect(result.profile.ownedItemIds, contains('gift_charity'));
      expect(result.celebrate, isTrue);
      expect(result.collectionCompleteId, 'kindness');
    });

    test('closePeriod soft fail adds fix hint', () {
      final profile = baseProfile(balance: 50).copyWith(
        period: GamePeriod(
          index: 1,
          startingBalance: 50,
          phase: PeriodPhase.playing,
          plan: const BudgetPlan(mandatory: 40, optional: 0, savings: 10),
          fact: const BudgetFact(mandatorySpent: 5, saved: 0),
        ),
      );
      final closed = GameEconomy.closePeriod(profile);
      expect(closed.softFail, isTrue);
      expect(closed.feedback, contains('Как поправить'));
      expect(closed.feedback, contains('Неделя'));
    });

    test('sort_buckets interaction validates placements', () {
      final quest = Quest.fromJson({
        'id': 'q_sort_test',
        'title': 'Тест',
        'theme': 'budget',
        'difficulty': 'easy',
        'interaction': 'sort_buckets',
        'prompt': 'Разложи',
        'sortItems': [
          {'id': 'a', 'label': 'Еда', 'correctBucket': 'mandatory'},
          {'id': 'b', 'label': 'Игрушка', 'correctBucket': 'optional'},
          {'id': 'c', 'label': 'Копилка', 'correctBucket': 'savings'},
        ],
        'options': [
          {
            'id': 'ok',
            'label': 'ok',
            'isGood': true,
            'reward': 10,
            'explanation': 'ok',
          },
          {
            'id': 'bad',
            'label': 'bad',
            'isGood': false,
            'reward': 1,
            'explanation': 'bad',
          },
        ],
      });
      expect(quest.interaction, QuestInteraction.sortBuckets);
      expect(
        GameEconomy.isSortBucketsCorrect(quest, {
          'a': 'mandatory',
          'b': 'optional',
          'c': 'savings',
        }),
        isTrue,
      );
      expect(
        GameEconomy.isSortBucketsCorrect(quest, {
          'a': 'optional',
          'b': 'mandatory',
          'c': 'savings',
        }),
        isFalse,
      );
    });

    test('quest refresh every interval rotates period set', () {
      final pool = [
        sampleQuest(id: 'qb1', theme: QuestTheme.budget),
        sampleQuest(id: 'qb2', theme: QuestTheme.budget),
        sampleQuest(id: 'qs1', theme: QuestTheme.savings),
        sampleQuest(id: 'qs2', theme: QuestTheme.savings),
        sampleQuest(id: 'qp1', theme: QuestTheme.purchases),
        sampleQuest(id: 'qp2', theme: QuestTheme.purchases),
      ];
      final now = DateTime(2026, 9, 25, 12);
      var profile = baseProfile(demoMode: false).copyWith(
        period: GamePeriod(
          index: 1,
          startingBalance: 100,
          phase: PeriodPhase.planning,
        ),
      );
      final planned = GameEconomy.confirmPlan(
        profile,
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
        questPool: pool,
      );
      expect(planned.ok, isTrue);
      profile = planned.profile.copyWith(
        questsRefreshedAt: now.toIso8601String(),
        demoMode: false,
      );
      expect(profile.period.activeQuestIds, isNotEmpty);

      final tooSoon = GameEconomy.refreshPeriodQuests(
        profile,
        pool,
        now: now.add(GameEconomy.questRefreshInterval ~/ 2),
      );
      expect(tooSoon.ok, isFalse);
      expect(tooSoon.message, contains('через'));

      final due = GameEconomy.refreshPeriodQuests(
        profile,
        pool,
        now: now.add(GameEconomy.questRefreshInterval + const Duration(minutes: 1)),
      );
      expect(due.ok, isTrue);
      expect(due.profile.questRefreshCount, profile.questRefreshCount + 1);
      expect(due.profile.period.activeQuestIds, isNotEmpty);
      expect(due.profile.period.completedQuestIds, isEmpty);
    });

    test('demo mode allows quest refresh immediately', () {
      final pool = [
        sampleQuest(id: 'qb1', theme: QuestTheme.budget),
        sampleQuest(id: 'qs1', theme: QuestTheme.savings),
        sampleQuest(id: 'qp1', theme: QuestTheme.purchases),
      ];
      var profile = baseProfile(demoMode: true);
      final planned = GameEconomy.confirmPlan(
        profile,
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
        questPool: pool,
      );
      expect(planned.ok, isTrue);
      final refreshed = GameEconomy.refreshPeriodQuests(
        planned.profile,
        pool,
      );
      expect(refreshed.ok, isTrue);
    });

    test('need_want and order_steps interactives validate correctly', () {
      final needWant = Quest(
        id: 'nw',
        title: 'nw',
        prompt: '?',
        theme: QuestTheme.purchases,
        interaction: QuestInteraction.needWant,
        sortItems: const [
          QuestSortItem(id: 'food', label: 'Еда', correctBucket: 'need'),
          QuestSortItem(id: 'toy', label: 'Игрушка', correctBucket: 'want'),
        ],
        options: [
          const QuestOption(
            id: 'a',
            label: 'ok',
            isGood: true,
            reward: 10,
            explanation: 'да',
          ),
          const QuestOption(
            id: 'b',
            label: 'no',
            isGood: false,
            reward: 2,
            explanation: 'нет',
          ),
        ],
      );
      expect(
        GameEconomy.isNeedWantCorrect(needWant, {'food': 'need', 'toy': 'want'}),
        isTrue,
      );
      expect(
        GameEconomy.isNeedWantCorrect(needWant, {'food': 'want', 'toy': 'want'}),
        isFalse,
      );

      final order = Quest(
        id: 'ord',
        title: 'ord',
        prompt: '?',
        theme: QuestTheme.budget,
        interaction: QuestInteraction.orderSteps,
        sortItems: const [
          QuestSortItem(id: 'plan', label: 'План', correctBucket: '1'),
          QuestSortItem(id: 'buy', label: 'Купить', correctBucket: '2'),
          QuestSortItem(id: 'save', label: 'Копить', correctBucket: '3'),
        ],
        options: [
          const QuestOption(
            id: 'a',
            label: 'ok',
            isGood: true,
            reward: 10,
            explanation: 'да',
          ),
          const QuestOption(
            id: 'b',
            label: 'no',
            isGood: false,
            reward: 2,
            explanation: 'нет',
          ),
        ],
      );
      expect(
        GameEconomy.isOrderStepsCorrect(order, ['plan', 'buy', 'save']),
        isTrue,
      );
      expect(
        GameEconomy.isOrderStepsCorrect(order, ['buy', 'plan', 'save']),
        isFalse,
      );
    });

    test('parent coplay: grant then confirm plan celebrates together', () {
      final profile = baseProfile(balance: 40);
      final granted = GameEconomy.grantParentCoins(profile);
      expect(granted.ok, isTrue);
      expect(granted.profile.parentCoplayPending, isTrue);
      expect(granted.profile.balance, 60);

      final planned = GameEconomy.confirmPlan(
        granted.profile,
        const BudgetPlan(mandatory: 30, optional: 10, savings: 20),
      );
      expect(planned.ok, isTrue);
      expect(planned.celebrate, isTrue);
      expect(planned.profile.parentCoplayPending, isFalse);
    });

    test('wrong quest answer exposes whyHint for pedagogy', () {
      final profile = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
        questPool: [sampleQuest()],
      ).profile;
      final quest = sampleQuest();
      final fail = quest.failOption;
      final result = GameEconomy.completeQuest(profile, quest, fail);
      expect(result.ok, isFalse);
      expect(result.whyHint, isNotNull);
      expect(result.tip, isNotNull);
    });
  });
}
