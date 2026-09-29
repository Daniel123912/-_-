import 'models.dart';

/// Сюжетная «эпоха» игрового периода (вместо «период 3»).
class PeriodStory {
  const PeriodStory({
    required this.title,
    required this.hook,
    required this.mission,
  });

  final String title;
  final String hook;
  final String mission;
}

enum CosmeticSlot { head, held, backpack, feet, room }

class CosmeticVisual {
  const CosmeticVisual({
    required this.emoji,
    required this.slot,
    this.image = '',
  });

  final String emoji;
  final CosmeticSlot slot;
  final String image;
}

class ItemCollection {
  const ItemCollection({
    required this.id,
    required this.name,
    required this.emoji,
    required this.itemIds,
  });

  final String id;
  final String name;
  final String emoji;
  final List<String> itemIds;

  int ownedCount(Iterable<String> owned) =>
      itemIds.where(owned.toSet().contains).length;

  bool isComplete(Iterable<String> owned) =>
      ownedCount(owned) >= itemIds.length;

  double progress(Iterable<String> owned) {
    if (itemIds.isEmpty) return 0;
    return (ownedCount(owned) / itemIds.length).clamp(0.0, 1.0);
  }
}

/// Контент вовлечения: эпохи, коллекции, косметика, реакции питомца.
class Engagement {
  static const periodStories = <PeriodStory>[
    PeriodStory(
      title: 'Неделя заботы',
      hook: 'Сначала еда, потом копилка.',
      mission: 'Купи нужное и отложи монеты.',
    ),
    PeriodStory(
      title: 'Неделя в магазине',
      hook: 'Сначала план — потом витрина.',
      mission: 'Составь бюджет.',
    ),
    PeriodStory(
      title: 'Неделя копилки',
      hook: 'Каждая монета к мечте.',
      mission: 'Пополни копилку.',
    ),
    PeriodStory(
      title: 'Неделя подарков',
      hook: 'Можно и поделиться.',
      mission: 'Оставь на подарок.',
    ),
    PeriodStory(
      title: 'Неделя чемпиона',
      hook: 'Задания и план — к новой стадии.',
      mission: 'Сделай квесты и нужное.',
    ),
    PeriodStory(
      title: 'Неделя сюрпризов',
      hook: 'Может выпасть секрет дня.',
      mission: 'Собери коллекцию.',
    ),
  ];

  static const collections = <ItemCollection>[
    ItemCollection(
      id: 'care',
      name: 'Забота',
      emoji: '💚',
      itemIds: ['food_bowl', 'water', 'grooming', 'vet_check'],
    ),
    ItemCollection(
      id: 'keychain67',
      name: 'Коллекция 67',
      emoji: '🔑',
      itemIds: ['keychain_67', 'keychain_67_neon', 'keychain_67_gold'],
    ),
    ItemCollection(
      id: 'gamer',
      name: 'Геймер',
      emoji: '🎮',
      itemIds: ['gaming_mouse', 'keyboard', 'console', 'headphones'],
    ),
    ItemCollection(
      id: 'wheels',
      name: 'Колёса',
      emoji: '🚲',
      itemIds: ['sneakers', 'scooter', 'bicycle'],
    ),
    ItemCollection(
      id: 'friends',
      name: 'Друзья',
      emoji: '🦫',
      itemIds: ['squish_paw', 'capybara_small', 'capybara_big', 'figurine'],
    ),
    ItemCollection(
      id: 'care',
      name: 'Уход',
      emoji: '🧼',
      itemIds: [
        'food_bowl',
        'water',
        'grooming',
        'vet_check',
        'bath_soap',
        'vitamins',
        'soft_bed',
        'toothbrush',
        'first_aid',
        'nail_care',
        'towel',
      ],
    ),
    ItemCollection(
      id: 'kindness',
      name: 'Доброта',
      emoji: '🎁',
      itemIds: ['gift_friend', 'gift_charity', 'mystery_box'],
    ),
  ];

  static const cosmetics = <String, CosmeticVisual>{
    'squish_paw': CosmeticVisual(
      emoji: '🐾',
      slot: CosmeticSlot.held,
      image: 'assets/images/shop/squish_paw.png',
    ),
    'capybara_small': CosmeticVisual(
      emoji: '🦫',
      slot: CosmeticSlot.held,
      image: 'assets/images/shop/capybara_small.png',
    ),
    'keychain_67': CosmeticVisual(
      emoji: '🔑',
      slot: CosmeticSlot.backpack,
      image: 'assets/images/shop/keychain_67.png',
    ),
    'keychain_67_neon': CosmeticVisual(
      emoji: '💚',
      slot: CosmeticSlot.backpack,
      image: 'assets/images/shop/keychain_67_neon.png',
    ),
    'keychain_67_gold': CosmeticVisual(
      emoji: '✨',
      slot: CosmeticSlot.backpack,
      image: 'assets/images/shop/keychain_67_gold.png',
    ),
    'microphone': CosmeticVisual(
      emoji: '🎤',
      slot: CosmeticSlot.held,
      image: 'assets/images/shop/microphone.png',
    ),
    'headphones': CosmeticVisual(
      emoji: '🎧',
      slot: CosmeticSlot.head,
      image: 'assets/images/shop/headphones.png',
    ),
    'sneakers': CosmeticVisual(
      emoji: '👟',
      slot: CosmeticSlot.feet,
      image: 'assets/images/shop/sneakers.png',
    ),
    'gaming_mouse': CosmeticVisual(
      emoji: '🖱️',
      slot: CosmeticSlot.room,
      image: 'assets/images/shop/gaming_mouse.png',
    ),
    'keyboard': CosmeticVisual(
      emoji: '⌨️',
      slot: CosmeticSlot.room,
      image: 'assets/images/shop/keyboard.png',
    ),
    'scooter': CosmeticVisual(
      emoji: '🛴',
      slot: CosmeticSlot.room,
      image: 'assets/images/shop/scooter.png',
    ),
    'console': CosmeticVisual(
      emoji: '🎮',
      slot: CosmeticSlot.held,
      image: 'assets/images/shop/console.png',
    ),
    'bicycle': CosmeticVisual(
      emoji: '🚲',
      slot: CosmeticSlot.room,
      image: 'assets/images/shop/bicycle.png',
    ),
    'capybara_big': CosmeticVisual(
      emoji: '🦫',
      slot: CosmeticSlot.room,
      image: 'assets/images/shop/capybara_big.png',
    ),
    'smartphone': CosmeticVisual(
      emoji: '📱',
      slot: CosmeticSlot.held,
      image: 'assets/images/shop/smartphone.png',
    ),
    'mystery_box': CosmeticVisual(
      emoji: '🎁',
      slot: CosmeticSlot.room,
      image: 'assets/images/shop/mystery_box.png',
    ),
    'figurine': CosmeticVisual(
      emoji: '🪆',
      slot: CosmeticSlot.held,
      image: 'assets/images/shop/figurine.png',
    ),
    'piggy_bank': CosmeticVisual(
      emoji: '🐷',
      slot: CosmeticSlot.room,
      image: 'assets/images/shop/piggy_bank.png',
    ),
    'trophy': CosmeticVisual(
      emoji: '🏆',
      slot: CosmeticSlot.room,
      image: 'assets/images/shop/trophy.png',
    ),
    'grooming': CosmeticVisual(
      emoji: '🪥',
      slot: CosmeticSlot.held,
      image: 'assets/images/shop/grooming.png',
    ),
    'bath_soap': CosmeticVisual(emoji: '🫧', slot: CosmeticSlot.held),
    'vitamins': CosmeticVisual(emoji: '💊', slot: CosmeticSlot.held),
    'soft_bed': CosmeticVisual(emoji: '🛏️', slot: CosmeticSlot.room),
    'toothbrush': CosmeticVisual(emoji: '🦷', slot: CosmeticSlot.held),
    'first_aid': CosmeticVisual(emoji: '🩹', slot: CosmeticSlot.room),
    'nail_care': CosmeticVisual(emoji: '💅', slot: CosmeticSlot.held),
    'towel': CosmeticVisual(emoji: '🧺', slot: CosmeticSlot.room),
    'food_bowl': CosmeticVisual(
      emoji: '🍽️',
      slot: CosmeticSlot.room,
      image: 'assets/images/shop/food_bowl.png',
    ),
    'water': CosmeticVisual(
      emoji: '💧',
      slot: CosmeticSlot.room,
      image: 'assets/images/shop/water.png',
    ),
    'vet_check': CosmeticVisual(
      emoji: '🩺',
      slot: CosmeticSlot.room,
      image: 'assets/images/shop/vet_check.png',
    ),
    'gift_friend': CosmeticVisual(
      emoji: '🎀',
      slot: CosmeticSlot.room,
      image: 'assets/images/shop/gift_friend.png',
    ),
    'gift_charity': CosmeticVisual(
      emoji: '💝',
      slot: CosmeticSlot.room,
      image: 'assets/images/shop/gift_charity.png',
    ),
  };

  static PeriodStory storyForPeriod(int index) {
    final i = index < 1 ? 0 : (index - 1) % periodStories.length;
    return periodStories[i];
  }

  static bool isCosmetic(String itemId) => cosmetics.containsKey(itemId);

  static List<CosmeticVisual> visualsFor(Iterable<String> ownedIds) {
    final bySlot = <CosmeticSlot, CosmeticVisual>{};
    for (final id in ownedIds) {
      final visual = cosmetics[id];
      if (visual != null) bySlot[visual.slot] = visual;
    }
    return bySlot.values.toList();
  }

  static String petTapSpeech({
    required String petName,
    required int hunger,
    required int mood,
  }) {
    if (hunger < 35) {
      const lines = [
        'Я голодный… давай купим еду?',
        'Миска пустая. Сначала нужное!',
        'Животик урчит. Покорми меня?',
      ];
      return lines[DateTime.now().second % lines.length];
    }
    if (mood < 40) {
      const lines = [
        'Мне грустновато… может, игрушку?',
        'Обнимем? Потом продолжим копить.',
        'Давай сделаем что-то весёлое!',
      ];
      return lines[DateTime.now().second % lines.length];
    }
    if (mood >= 80) {
      final who = petName.trim().isEmpty ? 'Ты' : 'Эй,';
      final lines = [
        'Ура! $who супер!',
        'Мне так весело с тобой!',
        '$who мой чемпион!',
        'Давай ещё чуть-чуть в копилку!',
      ];
      return lines[DateTime.now().second % lines.length];
    }
    const lines = [
      'Привет! Давай играть!',
      'Нажми ещё — мне нравится!',
      'Сначала нужное — потом игрушки!',
      'Мы крутая команда!',
      'Секрет дня ждёт тебя!',
    ];
    return lines[DateTime.now().millisecond % lines.length];
  }

  /// Контекстный рассказчик главного экрана (ТЗ 2.5.9 / 2.5.10):
  /// коротко «почему так» + «что сделать дальше».
  static String petContextSpeech({
    required PlayerProfile profile,
    required NextAction next,
    String? goalName,
  }) {
    final why = _stateWhyLine(profile);
    final step = _nextStepLine(next, goalName: goalName);
    if (why == null) return step;
    return '$why $step';
  }

  /// Реакция после действия: что изменилось у питомца + следующий шаг.
  /// Возвращает null, если заметных изменений нет (пузырь можно не трогать).
  static String? petStateChangeSpeech({
    required PlayerProfile before,
    required PlayerProfile after,
    required NextAction next,
    String? goalName,
  }) {
    final hungerDelta = after.hunger - before.hunger;
    final moodDelta = after.mood - before.mood;
    final moneyChanged = after.balance != before.balance ||
        after.savingsBalance != before.savingsBalance;
    final progressChanged = before.period.phase != after.period.phase ||
        before.period.index != after.period.index ||
        before.growthStage != after.growthStage ||
        before.period.completedQuestIds.length !=
            after.period.completedQuestIds.length ||
        before.lastFeedback != after.lastFeedback;

    if (hungerDelta == 0 &&
        moodDelta == 0 &&
        !moneyChanged &&
        !progressChanged) {
      return null;
    }

    final change = _stateChangeLine(
      hungerDelta: hungerDelta,
      moodDelta: moodDelta,
    );
    final step = _nextStepLine(next, goalName: goalName);
    if (change == null) return petContextSpeech(
      profile: after,
      next: next,
      goalName: goalName,
    );
    return '$change $step';
  }

  static String? _stateWhyLine(PlayerProfile profile) {
    if (profile.hunger < 35) return 'Я голоден…';
    if (profile.mood < 40) return 'Мне грустновато.';
    if (profile.mood >= 80 && profile.hunger >= 60) {
      return 'Я сытый и довольный!';
    }
    if (profile.hunger >= 70) return 'Животик полный — спасибо!';
    return null;
  }

  static String? _stateChangeLine({
    required int hungerDelta,
    required int moodDelta,
  }) {
    if (hungerDelta >= 8) return 'Мне вкуснее — сытость выросла!';
    if (hungerDelta <= -8) return 'Я проголодался…';
    if (moodDelta >= 8) return 'Мне веселее благодаря тебе!';
    if (moodDelta <= -8) return 'Немного грустнее… но всё поправим.';
    return null;
  }

  static String _nextStepLine(NextAction next, {String? goalName}) {
    switch (next.kind) {
      case NextActionKind.planBudget:
        return 'Сначала составь план — так я не останусь без еды.';
      case NextActionKind.doQuests:
        return 'Давай задания — заработаем монеты!';
      case NextActionKind.buyMandatory:
        return 'Купи еду или уход — мне это нужно.';
      case NextActionKind.saveMoney:
        final hint = next.subtitle.trim();
        if (hint.isNotEmpty && hint.length <= 36) {
          return 'В копилку! $hint.';
        }
        return 'Отложи монеты в копилку — мечта ближе!';
      case NextActionKind.claimGoal:
        final name = (goalName == null || goalName.isEmpty) ? 'цель' : goalName;
        return 'Ура! Забери «$name» — я прыгаю!';
      case NextActionKind.finishPeriod:
        return 'Период готов — посмотрим итог вместе!';
      case NextActionKind.viewSummary:
        return 'Открой итог — расскажу, что вышло.';
    }
  }

  /// Награда «секрета дня» по календарному ключу YYYY-MM-DD.
  static SecretReward secretForDay(String dayKey) {
    final hash = dayKey.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    return switch (hash % 4) {
      0 => const SecretReward(
          title: 'Монетный сюрприз',
          message: 'Финни нашёл блестящую монетку под подушкой!',
          coins: 8,
          mood: 4,
          stars: 0,
        ),
      1 => const SecretReward(
          title: 'Обнимашки',
          message: 'Секрет дня: Финни дарит тебе огромные обнимашки!',
          coins: 3,
          mood: 12,
          stars: 1,
        ),
      2 => const SecretReward(
          title: 'Звёздочка удачи',
          message: 'Сегодня тебе светит ★ удачи — лови!',
          coins: 5,
          mood: 6,
          stars: 2,
        ),
      _ => const SecretReward(
          title: 'Тихий клад',
          message: 'Ш-ш-ш… Финни шепчет: «Отложи ещё чуть-чуть!»',
          coins: 6,
          mood: 8,
          stars: 1,
        ),
    };
  }

  static String softFailHint({
    required bool mandatoryOk,
    required bool savedOk,
    required bool planClose,
  }) {
    if (!mandatoryOk) {
      return 'Как поправить: в следующем периоде сначала купи еду и уход — Финни сразу оживится.';
    }
    if (!savedOk) {
      return 'Как поправить: отложи хотя бы немного в копилку — даже 5 монет считаются!';
    }
    if (!planClose) {
      return 'Как поправить: смотри на план перед покупкой — так факт будет ближе.';
    }
    return 'Всё поправимо. Финни верит в тебя — попробуем ещё раз вместе!';
  }
}

class SecretReward {
  const SecretReward({
    required this.title,
    required this.message,
    required this.coins,
    required this.mood,
    required this.stars,
  });

  final String title;
  final String message;
  final int coins;
  final int mood;
  final int stars;
}
