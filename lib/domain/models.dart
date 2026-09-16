enum ExpenseKind { mandatory, optional, gift }

enum QuestTheme { budget, savings, purchases }

enum PeriodPhase { planning, playing, summary }

/// Возрастной трек обучения (ТЗ: 7–11 лет).
enum AgeTrack {
  junior, // 7–8
  middle, // 9–10
  senior, // 11
}

enum QuestDifficulty { easy, medium, hard }

extension AgeTrackX on AgeTrack {
  String get label => switch (this) {
        AgeTrack.junior => '7–8 лет',
        AgeTrack.middle => '9–10 лет',
        AgeTrack.senior => '11 лет',
      };

  /// Формулировка «попроще / посложнее» без акцента на возраст (Q&A).
  String get difficultyLabel => switch (this) {
        AgeTrack.junior => 'Попроще',
        AgeTrack.middle => 'Средне',
        AgeTrack.senior => 'Посложнее',
      };

  String get shortLabel => switch (this) {
        AgeTrack.junior => 'Лёгкий',
        AgeTrack.middle => 'Средний',
        AgeTrack.senior => 'Сложный',
      };

  String get description => switch (this) {
        AgeTrack.junior => 'Простые выборы: нужное и желаемое.',
        AgeTrack.middle => 'План, копилка и сравнение цен.',
        AgeTrack.senior => 'Приоритеты, компромиссы и контроль плана.',
      };

  /// Какие сложности заданий доступны на треке.
  Set<QuestDifficulty> get allowedDifficulties => switch (this) {
        AgeTrack.junior => {QuestDifficulty.easy},
        AgeTrack.middle => {QuestDifficulty.easy, QuestDifficulty.medium},
        AgeTrack.senior => {
            QuestDifficulty.easy,
            QuestDifficulty.medium,
            QuestDifficulty.hard,
          },
      };

  int get startingBalance => switch (this) {
        AgeTrack.junior => 100,
        AgeTrack.middle => 110,
        AgeTrack.senior => 120,
      };
}

AgeTrack parseAgeTrack(String raw) => switch (raw) {
      'middle' => AgeTrack.middle,
      'senior' => AgeTrack.senior,
      _ => AgeTrack.junior,
    };

extension QuestDifficultyX on QuestDifficulty {
  String get label => switch (this) {
        QuestDifficulty.easy => 'Лёгкое',
        QuestDifficulty.medium => 'Среднее',
        QuestDifficulty.hard => 'Сложное',
      };

  int get starReward => switch (this) {
        QuestDifficulty.easy => 1,
        QuestDifficulty.medium => 2,
        QuestDifficulty.hard => 3,
      };

  int get xpReward => switch (this) {
        QuestDifficulty.easy => 10,
        QuestDifficulty.medium => 18,
        QuestDifficulty.hard => 28,
      };
}

class SkillProgress {
  const SkillProgress({
    this.budgetXp = 0,
    this.savingsXp = 0,
    this.purchasesXp = 0,
  });

  final int budgetXp;
  final int savingsXp;
  final int purchasesXp;

  int xpFor(QuestTheme theme) => switch (theme) {
        QuestTheme.budget => budgetXp,
        QuestTheme.savings => savingsXp,
        QuestTheme.purchases => purchasesXp,
      };

  int levelFor(QuestTheme theme) => (xpFor(theme) / 40).floor() + 1;

  int get totalXp => budgetXp + savingsXp + purchasesXp;

  SkillProgress add(QuestTheme theme, int xp) {
    return switch (theme) {
      QuestTheme.budget => copyWith(budgetXp: budgetXp + xp),
      QuestTheme.savings => copyWith(savingsXp: savingsXp + xp),
      QuestTheme.purchases => copyWith(purchasesXp: purchasesXp + xp),
    };
  }

  SkillProgress copyWith({int? budgetXp, int? savingsXp, int? purchasesXp}) {
    return SkillProgress(
      budgetXp: budgetXp ?? this.budgetXp,
      savingsXp: savingsXp ?? this.savingsXp,
      purchasesXp: purchasesXp ?? this.purchasesXp,
    );
  }

  Map<String, dynamic> toJson() => {
        'budgetXp': budgetXp,
        'savingsXp': savingsXp,
        'purchasesXp': purchasesXp,
      };

  factory SkillProgress.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SkillProgress();
    return SkillProgress(
      budgetXp: json['budgetXp'] as int? ?? 0,
      savingsXp: json['savingsXp'] as int? ?? 0,
      purchasesXp: json['purchasesXp'] as int? ?? 0,
    );
  }
}

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.price,
    required this.kind,
    required this.effectHint,
    required this.hungerDelta,
    required this.moodDelta,
    this.emoji = '',
    this.image = '',
    this.placement = '',
  });

  final String id;
  final String name;
  final int price;
  final ExpenseKind kind;
  final String effectHint;
  final int hungerDelta;
  final int moodDelta;
  /// Эмодзи для витрины и отображения на питомце.
  final String emoji;
  /// Картинка предмета (опционально).
  final String image;
  /// Куда надевается / ставится после покупки.
  final String placement;

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      kind: parseExpenseKind(json['kind'] as String?),
      effectHint: json['effectHint'] as String,
      hungerDelta: json['hungerDelta'] as int? ?? 0,
      moodDelta: json['moodDelta'] as int? ?? 0,
      emoji: json['emoji'] as String? ?? '',
      image: json['image'] as String? ?? '',
      placement: json['placement'] as String? ?? '',
    );
  }
}

ExpenseKind parseExpenseKind(String? raw) => switch (raw) {
      'mandatory' => ExpenseKind.mandatory,
      'gift' => ExpenseKind.gift,
      _ => ExpenseKind.optional,
    };

String expenseKindToJson(ExpenseKind kind) => switch (kind) {
      ExpenseKind.mandatory => 'mandatory',
      ExpenseKind.gift => 'gift',
      ExpenseKind.optional => 'optional',
    };

class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.cost,
    required this.description,
    this.ageTracks = const {
      AgeTrack.junior,
      AgeTrack.middle,
      AgeTrack.senior,
    },
  });

  final String id;
  final String name;
  final int cost;
  final String description;
  final Set<AgeTrack> ageTracks;

  bool availableFor(AgeTrack track) => ageTracks.contains(track);

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    final tracksRaw = (json['ageTracks'] as List?)?.cast<String>();
    final ageTracks = tracksRaw == null
        ? {AgeTrack.junior, AgeTrack.middle, AgeTrack.senior}
        : tracksRaw.map(parseAgeTrack).toSet();
    return SavingsGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      cost: json['cost'] as int,
      description: json['description'] as String,
      ageTracks: ageTracks,
    );
  }
}

/// Короткий шаг урока в блоке «Учёба».
class LessonStep {
  const LessonStep({
    required this.title,
    required this.text,
    this.icon = 'lightbulb',
  });

  final String title;
  final String text;
  final String icon;

  factory LessonStep.fromJson(Map<String, dynamic> json) {
    return LessonStep(
      title: json['title'] as String,
      text: json['text'] as String,
      icon: json['icon'] as String? ?? 'lightbulb',
    );
  }
}

/// Мини-проверка в конце урока.
class LessonQuiz {
  const LessonQuiz({
    required this.prompt,
    required this.options,
  });

  final String prompt;
  final List<QuestOption> options;

  factory LessonQuiz.fromJson(Map<String, dynamic> json) {
    return LessonQuiz(
      prompt: json['prompt'] as String,
      options: (json['options'] as List)
          .map((e) => QuestOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Возрастной урок: история + шаги + проверка.
class LearningLesson {
  const LearningLesson({
    required this.id,
    required this.title,
    required this.hook,
    required this.story,
    required this.theme,
    required this.steps,
    required this.quiz,
    this.funFact = '',
    this.rewardXp = 8,
    this.rewardCoins = 3,
    this.ageTracks = const {
      AgeTrack.junior,
      AgeTrack.middle,
      AgeTrack.senior,
    },
  });

  final String id;
  final String title;
  /// Короткая «зацепка» для ребёнка.
  final String hook;
  final String story;
  final QuestTheme theme;
  final List<LessonStep> steps;
  final LessonQuiz quiz;
  final String funFact;
  final int rewardXp;
  final int rewardCoins;
  final Set<AgeTrack> ageTracks;

  bool availableFor(AgeTrack track) => ageTracks.contains(track);

  factory LearningLesson.fromJson(Map<String, dynamic> json) {
    final themeRaw = json['theme'] as String? ?? 'budget';
    final theme = switch (themeRaw) {
      'savings' => QuestTheme.savings,
      'purchases' => QuestTheme.purchases,
      _ => QuestTheme.budget,
    };
    final tracksRaw = (json['ageTracks'] as List?)?.cast<String>();
    final ageTracks = tracksRaw == null
        ? {AgeTrack.junior, AgeTrack.middle, AgeTrack.senior}
        : tracksRaw.map(parseAgeTrack).toSet();
    return LearningLesson(
      id: json['id'] as String,
      title: json['title'] as String,
      hook: json['hook'] as String? ?? '',
      story: json['story'] as String? ?? '',
      theme: theme,
      steps: (json['steps'] as List? ?? [])
          .map((e) => LessonStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      quiz: LessonQuiz.fromJson(json['quiz'] as Map<String, dynamic>),
      funFact: json['funFact'] as String? ?? '',
      rewardXp: json['rewardXp'] as int? ?? 8,
      rewardCoins: json['rewardCoins'] as int? ?? 3,
      ageTracks: ageTracks,
    );
  }
}

/// Тексты «лица» блока учёбы под возраст.
class AgeLearnGuide {
  const AgeLearnGuide({
    required this.headline,
    required this.blurb,
    required this.petLine,
    required this.badge,
  });

  final String headline;
  final String blurb;
  final String petLine;
  final String badge;

  static AgeLearnGuide forTrack(AgeTrack track) => switch (track) {
        AgeTrack.junior => const AgeLearnGuide(
          headline: 'Школа Финни',
          blurb: 'Короткие истории: нужное, желаемое и копилка.',
          petLine: 'Поиграй со мной!',
          badge: 'Попроще',
        ),
        AgeTrack.middle => const AgeLearnGuide(
          headline: 'Мастерская плана',
          blurb: 'Делим деньги, копим и сравниваем цены.',
          petLine: 'Проверим план?',
          badge: 'Средне',
        ),
        AgeTrack.senior => const AgeLearnGuide(
          headline: 'Штаб решений',
          blurb: 'План против факта и приоритеты при нехватке.',
          petLine: 'Сложный выбор — твой ход.',
          badge: 'Посложнее',
        ),
      };
}

class QuestOption {
  const QuestOption({
    required this.id,
    required this.label,
    required this.isGood,
    required this.reward,
    required this.explanation,
  });

  final String id;
  final String label;
  final bool isGood;
  final int reward;
  final String explanation;

  factory QuestOption.fromJson(Map<String, dynamic> json) {
    return QuestOption(
      id: json['id'] as String,
      label: json['label'] as String,
      isGood: json['isGood'] as bool,
      reward: json['reward'] as int,
      explanation: json['explanation'] as String,
    );
  }
}

/// Тип взаимодействия в задании (не только выбор ответа).
enum QuestInteraction {
  choice,
  sortBuckets,
  /// Нужное / желаемое (2 корзины).
  needWant,
  /// Расставь шаги в правильном порядке.
  orderSteps,
}

/// Карточка для интерактива «разложи по корзинам».
class QuestSortItem {
  const QuestSortItem({
    required this.id,
    required this.label,
    required this.correctBucket,
  });

  final String id;
  final String label;
  /// `mandatory` | `optional` | `savings`
  final String correctBucket;

  factory QuestSortItem.fromJson(Map<String, dynamic> json) {
    return QuestSortItem(
      id: json['id'] as String,
      label: json['label'] as String,
      correctBucket: json['correctBucket'] as String,
    );
  }
}

class Quest {
  const Quest({
    required this.id,
    required this.title,
    required this.prompt,
    required this.theme,
    required this.options,
    this.difficulty = QuestDifficulty.easy,
    this.tip = '',
    this.interaction = QuestInteraction.choice,
    this.sortItems = const [],
    this.ageTracks = const {
      AgeTrack.junior,
      AgeTrack.middle,
      AgeTrack.senior,
    },
  });

  final String id;
  final String title;
  final String prompt;
  final QuestTheme theme;
  final List<QuestOption> options;
  final QuestDifficulty difficulty;
  final String tip;
  final QuestInteraction interaction;
  final List<QuestSortItem> sortItems;
  final Set<AgeTrack> ageTracks;

  bool availableFor(AgeTrack track) => ageTracks.contains(track);

  QuestOption get successOption =>
      options.firstWhere((o) => o.isGood, orElse: () => options.first);

  QuestOption get failOption =>
      options.firstWhere((o) => !o.isGood, orElse: () => options.last);

  factory Quest.fromJson(Map<String, dynamic> json) {
    final themeRaw = json['theme'] as String;
    final theme = switch (themeRaw) {
      'budget' => QuestTheme.budget,
      'savings' => QuestTheme.savings,
      _ => QuestTheme.purchases,
    };
    final diffRaw = json['difficulty'] as String? ?? 'easy';
    final difficulty = switch (diffRaw) {
      'medium' => QuestDifficulty.medium,
      'hard' => QuestDifficulty.hard,
      _ => QuestDifficulty.easy,
    };
    final tracksRaw = (json['ageTracks'] as List?)?.cast<String>();
    final ageTracks = tracksRaw == null
        ? {AgeTrack.junior, AgeTrack.middle, AgeTrack.senior}
        : tracksRaw.map(parseAgeTrack).toSet();
    final interactionRaw = json['interaction'] as String? ?? 'choice';
    final interaction = switch (interactionRaw) {
      'sort_buckets' => QuestInteraction.sortBuckets,
      'need_want' => QuestInteraction.needWant,
      'order_steps' => QuestInteraction.orderSteps,
      _ => QuestInteraction.choice,
    };

    return Quest(
      id: json['id'] as String,
      title: json['title'] as String,
      prompt: json['prompt'] as String,
      theme: theme,
      difficulty: difficulty,
      tip: json['tip'] as String? ?? '',
      interaction: interaction,
      sortItems: (json['sortItems'] as List? ?? [])
          .map((e) => QuestSortItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      ageTracks: ageTracks,
      options: (json['options'] as List)
          .map((e) => QuestOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PetModel {
  const PetModel({
    required this.id,
    required this.name,
    required this.asset,
    this.thumb,
    this.vibe,
    this.family,
    this.pattern = false,
  });

  final String id;
  final String name;
  final String asset;
  final String? thumb;
  final String? vibe;
  final String? family;
  final bool pattern;

  String get thumbPath => thumb ?? 'assets/images/pets/thumbs/$id.png';

  String get subtitle {
    if (vibe != null && vibe!.trim().isNotEmpty) return vibe!;
    if (family != null && family!.trim().isNotEmpty) return family!;
    return id;
  }

  factory PetModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return PetModel(
      id: id,
      name: json['name'] as String? ?? id,
      asset: json['asset'] as String? ?? 'assets/images/pets/$id.svg',
      thumb: json['thumb'] as String?,
      vibe: json['vibe'] as String?,
      family: json['family'] as String?,
      pattern: json['pattern'] == true,
    );
  }
}

/// Лицо питомца по схеме Полины (сытость/настроение).
enum PetFaceEmotion { joy, calm, bliss, confused, sad }

class PetAppearance {
  const PetAppearance({
    required this.color,
    required this.eyes,
    required this.accessory,
    this.model = 'pet_01',
  });

  /// Цвет тела: `синий` | `розовый` | `фиолетовый`.
  final String color;

  /// Цвет глаз (связан с телом): `голубые` | `карие` | `зелёные`.
  final String eyes;

  /// Дополнение: `без` | `ромбики` | `на голове`.
  final String accessory;

  /// ID собранной модели → `assets/images/pets/<model>.svg`.
  final String model;

  /// Глаза по цвету тела (наборы Полины: синий↔голуб, роз↔карие, фиол↔зел).
  static String eyesForColor(String color) => switch (color) {
        'розовый' => 'карие',
        'фиолетовый' => 'зелёные',
        _ => 'голубые',
      };

  /// 1 спокойный · 2 радость · 3 счастье(закрытые, редко) · 4 замешательство · 5 грусть
  static PetFaceEmotion faceEmotion({required int hunger, required int mood}) {
    if (hunger < 35 || mood < 35) return PetFaceEmotion.sad;
    if (hunger < 50 || mood < 50) return PetFaceEmotion.confused;
    // Закрытые глаза почти не читаются в UI — для «очень хорошо» оставляем радость.
    if (hunger >= 70 && mood >= 70) return PetFaceEmotion.joy;
    return PetFaceEmotion.calm;
  }

  /// Путь к SVG с учётом стадии роста и эмоции. `joy` = файл без суффикса.
  String assetPathFor({
    required int hunger,
    required int mood,
    int stage = 1,
  }) {
    final emotion = faceEmotion(hunger: hunger, mood: mood);
    final id = modelForStage(stage);
    if (emotion == PetFaceEmotion.joy) {
      return 'assets/images/pets/$id.svg';
    }
    return 'assets/images/pets/${id}_${emotion.name}.svg';
  }

  /// PNG-рендер того же облика (надёжнее на Web, чем тяжёлый SVG).
  String rasterPathFor({
    required int hunger,
    required int mood,
    int stage = 1,
  }) {
    final svg = assetPathFor(hunger: hunger, mood: mood, stage: stage);
    final name = svg.split('/').last.replaceAll('.svg', '.png');
    return 'assets/images/pets/renders/$name';
  }

  /// Стадия роста питомца (не возраст ребёнка):
  /// 1 малыш · 2 растущий · 3 чемпион.
  static const Map<String, String> comboModels = {
    // стадия 1 — малыш (40/42/43)
    '1|синий|без': 'pet_01',
    '1|синий|ромбики': 'pet_02',
    '1|синий|на голове': 'pet_03',
    '1|розовый|без': 'pet_04',
    '1|розовый|ромбики': 'pet_05',
    '1|розовый|на голове': 'pet_06',
    '1|фиолетовый|без': 'pet_07',
    '1|фиолетовый|ромбики': 'pet_08',
    '1|фиолетовый|на голове': 'pet_09',
    // стадия 2 — растущий (44/45/46)
    '2|синий|без': 'pet_10',
    '2|синий|ромбики': 'pet_11',
    '2|синий|на голове': 'pet_12',
    '2|розовый|без': 'pet_13',
    '2|розовый|ромбики': 'pet_14',
    '2|розовый|на голове': 'pet_15',
    '2|фиолетовый|без': 'pet_16',
    '2|фиолетовый|ромбики': 'pet_17',
    '2|фиолетовый|на голове': 'pet_18',
    // стадия 3 — чемпион / взрослый (48/49/50)
    '3|синий|без': 'pet_19',
    '3|синий|ромбики': 'pet_20',
    '3|синий|на голове': 'pet_21',
    '3|розовый|без': 'pet_22',
    '3|розовый|ромбики': 'pet_23',
    '3|розовый|на голове': 'pet_24',
    '3|фиолетовый|без': 'pet_25',
    '3|фиолетовый|ромбики': 'pet_26',
    '3|фиолетовый|на голове': 'pet_27',
  };

  factory PetAppearance.combo({
    required String color,
    required String accessory,
    String? eyes,
    int growthStage = 1,
  }) {
    final resolvedEyes = eyes ?? eyesForColor(color);
    return PetAppearance(
      color: color,
      eyes: resolvedEyes,
      accessory: accessory,
      model: resolveModel(
        growthStage: growthStage,
        color: color,
        accessory: accessory,
      ),
    );
  }

  /// Модель тела для текущей стадии роста (1→малыш, 2→растущий, 3→чемпион).
  String modelForStage(int growthStage) {
    return resolveModel(
      growthStage: growthStage,
      color: color,
      accessory: accessory,
    );
  }

  static String resolveModel({
    required int growthStage,
    required String color,
    required String accessory,
  }) {
    final stage = growthStage.clamp(1, 3);
    return comboModels['$stage|$color|$accessory'] ??
        comboModels['1|$color|$accessory'] ??
        'pet_01';
  }

  /// Слои для Stack-сборки. Сейчас — готовый SVG комбинации.
  List<String> get layerPaths => ['assets/images/pets/$model.svg'];

  String get assetPath => 'assets/images/pets/$model.svg';

  Map<String, dynamic> toJson() => {
        'color': color,
        'eyes': eyes,
        'accessory': accessory,
        'model': model,
      };

  factory PetAppearance.fromJson(Map<String, dynamic> json) {
    final color = _migrateColor(json['color'] as String?);
    final eyes = _migrateEyes(
      json['eyes'] as String? ?? json['body'] as String?,
      color: color,
    );
    final accessory = _migrateAccessory(json['accessory'] as String?);
    final storedModel = (json['model'] as String?)?.trim();
    // model в профиле — «базовый» облик стадии 1; на экране берём modelForStage.
    return PetAppearance(
      color: color,
      eyes: eyes,
      accessory: accessory,
      model: storedModel != null && storedModel.isNotEmpty
          ? storedModel
          : resolveModel(
              growthStage: 1,
              color: color,
              accessory: accessory,
            ),
    );
  }

  static String _migrateColor(String? raw) {
    return switch (raw) {
      'розовый' => 'розовый',
      'фиолетовый' || 'фиол' => 'фиолетовый',
      _ => 'синий',
    };
  }

  static String _migrateEyes(String? raw, {String color = 'синий'}) {
    return switch (raw) {
      'карие' => 'карие',
      'зелёные' || 'зеленые' => 'зелёные',
      'голубые' => 'голубые',
      _ => eyesForColor(color),
    };
  }

  static String _migrateAccessory(String? raw) {
    return switch (raw) {
      'ромбики' || 'доп 1' || 'узоры' => 'ромбики',
      'на голове' || 'доп 2' => 'на голове',
      _ => 'без',
    };
  }

  String get label => '$color · глаза $eyes · $accessory';
}

class BudgetPlan {
  const BudgetPlan({
    required this.mandatory,
    required this.optional,
    required this.savings,
    this.gift = 0,
  });

  final int mandatory;
  final int optional;
  final int savings;
  /// Четвёртая опциональная корзина «Подарить» / на радость.
  final int gift;

  int get total => mandatory + optional + savings + gift;

  BudgetPlan copyWith({
    int? mandatory,
    int? optional,
    int? savings,
    int? gift,
  }) {
    return BudgetPlan(
      mandatory: mandatory ?? this.mandatory,
      optional: optional ?? this.optional,
      savings: savings ?? this.savings,
      gift: gift ?? this.gift,
    );
  }

  Map<String, dynamic> toJson() => {
        'mandatory': mandatory,
        'optional': optional,
        'savings': savings,
        'gift': gift,
      };

  factory BudgetPlan.fromJson(Map<String, dynamic> json) {
    return BudgetPlan(
      mandatory: json['mandatory'] as int,
      optional: json['optional'] as int,
      savings: json['savings'] as int,
      gift: json['gift'] as int? ?? 0,
    );
  }

  static const empty =
      BudgetPlan(mandatory: 0, optional: 0, savings: 0, gift: 0);
}

class BudgetFact {
  const BudgetFact({
    this.mandatorySpent = 0,
    this.optionalSpent = 0,
    this.saved = 0,
    this.giftSpent = 0,
  });

  final int mandatorySpent;
  final int optionalSpent;
  final int saved;
  final int giftSpent;

  int get spentTotal => mandatorySpent + optionalSpent + saved + giftSpent;

  BudgetFact copyWith({
    int? mandatorySpent,
    int? optionalSpent,
    int? saved,
    int? giftSpent,
  }) {
    return BudgetFact(
      mandatorySpent: mandatorySpent ?? this.mandatorySpent,
      optionalSpent: optionalSpent ?? this.optionalSpent,
      saved: saved ?? this.saved,
      giftSpent: giftSpent ?? this.giftSpent,
    );
  }

  Map<String, dynamic> toJson() => {
        'mandatorySpent': mandatorySpent,
        'optionalSpent': optionalSpent,
        'saved': saved,
        'giftSpent': giftSpent,
      };

  factory BudgetFact.fromJson(Map<String, dynamic> json) {
    return BudgetFact(
      mandatorySpent: json['mandatorySpent'] as int? ?? 0,
      optionalSpent: json['optionalSpent'] as int? ?? 0,
      saved: json['saved'] as int? ?? 0,
      giftSpent: json['giftSpent'] as int? ?? 0,
    );
  }
}

class PurchaseRecord {
  const PurchaseRecord({
    required this.itemId,
    required this.name,
    required this.price,
    required this.kind,
  });

  final String itemId;
  final String name;
  final int price;
  final ExpenseKind kind;

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'name': name,
        'price': price,
        'kind': expenseKindToJson(kind),
      };

  factory PurchaseRecord.fromJson(Map<String, dynamic> json) {
    return PurchaseRecord(
      itemId: json['itemId'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      kind: parseExpenseKind(json['kind'] as String?),
    );
  }
}

class GamePeriod {
  const GamePeriod({
    required this.index,
    required this.startingBalance,
    required this.phase,
    this.plan = BudgetPlan.empty,
    this.fact = const BudgetFact(),
    this.purchases = const [],
    this.activeQuestIds = const [],
    this.completedQuestIds = const [],
    this.feedback = '',
    this.goodQuestStreak = 0,
    this.failXpQuestIds = const [],
  });

  final int index;
  final int startingBalance;
  final PeriodPhase phase;
  final BudgetPlan plan;
  final BudgetFact fact;
  final List<PurchaseRecord> purchases;
  /// Задания, выданные на этот период (по 1+ на тему).
  final List<String> activeQuestIds;
  final List<String> completedQuestIds;
  final String feedback;
  final int goodQuestStreak;
  /// Квесты, за ошибку в которых уже начислен учебный XP в этом периоде.
  final List<String> failXpQuestIds;

  int get periodQuestsDone =>
      completedQuestIds.where(activeQuestIds.contains).length;

  bool get periodQuestsComplete =>
      activeQuestIds.isNotEmpty &&
      activeQuestIds.every(completedQuestIds.contains);

  GamePeriod copyWith({
    int? index,
    int? startingBalance,
    PeriodPhase? phase,
    BudgetPlan? plan,
    BudgetFact? fact,
    List<PurchaseRecord>? purchases,
    List<String>? activeQuestIds,
    List<String>? completedQuestIds,
    String? feedback,
    int? goodQuestStreak,
    List<String>? failXpQuestIds,
  }) {
    return GamePeriod(
      index: index ?? this.index,
      startingBalance: startingBalance ?? this.startingBalance,
      phase: phase ?? this.phase,
      plan: plan ?? this.plan,
      fact: fact ?? this.fact,
      purchases: purchases ?? this.purchases,
      activeQuestIds: activeQuestIds ?? this.activeQuestIds,
      completedQuestIds: completedQuestIds ?? this.completedQuestIds,
      feedback: feedback ?? this.feedback,
      goodQuestStreak: goodQuestStreak ?? this.goodQuestStreak,
      failXpQuestIds: failXpQuestIds ?? this.failXpQuestIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'index': index,
        'startingBalance': startingBalance,
        'phase': phase.name,
        'plan': plan.toJson(),
        'fact': fact.toJson(),
        'purchases': purchases.map((e) => e.toJson()).toList(),
        'activeQuestIds': activeQuestIds,
        'completedQuestIds': completedQuestIds,
        'feedback': feedback,
        'goodQuestStreak': goodQuestStreak,
        'failXpQuestIds': failXpQuestIds,
      };

  factory GamePeriod.fromJson(Map<String, dynamic> json) {
    return GamePeriod(
      index: json['index'] as int,
      startingBalance: json['startingBalance'] as int,
      phase: PeriodPhase.values.firstWhere(
        (e) => e.name == json['phase'],
        orElse: () => PeriodPhase.planning,
      ),
      plan: BudgetPlan.fromJson(json['plan'] as Map<String, dynamic>),
      fact: BudgetFact.fromJson(json['fact'] as Map<String, dynamic>),
      purchases: (json['purchases'] as List? ?? [])
          .map((e) => PurchaseRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeQuestIds: (json['activeQuestIds'] as List? ?? []).cast<String>(),
      completedQuestIds:
          (json['completedQuestIds'] as List? ?? []).cast<String>(),
      feedback: json['feedback'] as String? ?? '',
      goodQuestStreak: json['goodQuestStreak'] as int? ?? 0,
      failXpQuestIds: (json['failXpQuestIds'] as List? ?? []).cast<String>(),
    );
  }
}

/// Подсказка «что делать дальше» на главном экране.
enum NextActionKind {
  planBudget,
  doQuests,
  buyMandatory,
  saveMoney,
  claimGoal,
  finishPeriod,
  viewSummary,
}

class NextAction {
  const NextAction({
    required this.kind,
    required this.title,
    required this.subtitle,
  });

  final NextActionKind kind;
  final String title;
  final String subtitle;
}

class PlayerProfile {
  const PlayerProfile({
    required this.playerName,
    required this.petName,
    required this.appearance,
    required this.balance,
    required this.savingsBalance,
    required this.hunger,
    required this.mood,
    required this.growthStage,
    required this.goodPeriodStreak,
    required this.selectedGoalId,
    required this.demoMode,
    required this.onboardingDone,
    required this.period,
    required this.completedQuestIds,
    required this.lastFeedback,
    this.totalPeriodsCompleted = 0,
    this.ageTrack = AgeTrack.junior,
    this.skills = const SkillProgress(),
    this.stars = 0,
    this.comboBest = 0,
    this.completedLessonIds = const [],
    this.lastLoginBonusDay,
    this.parentGrantTotal = 0,
    this.nextPeriodAvailableAt,
    this.ownedItemIds = const [],
    this.secretClaimedDay,
    this.parentChallengeTarget,
    this.parentChallengeSaved = 0,
    this.completedCollectionIds = const [],
    this.questsRefreshedAt,
    this.questRefreshCount = 0,
    this.parentCoplayPending = false,
    this.parentCoplayAmount = 0,
    this.soundEnabled = true,
  });

  final String playerName;
  final String petName;
  final PetAppearance appearance;
  final int balance;
  final int savingsBalance;
  final int hunger;
  final int mood;
  final int growthStage;
  final int goodPeriodStreak;
  final String? selectedGoalId;
  final bool demoMode;
  final bool onboardingDone;
  final GamePeriod period;
  final List<String> completedQuestIds;
  final String lastFeedback;
  final int totalPeriodsCompleted;
  final AgeTrack ageTrack;
  final SkillProgress skills;
  final int stars;
  final int comboBest;
  final List<String> completedLessonIds;
  /// YYYY-MM-DD последнего бонуса за вход (пропуск дня не штрафует).
  final String? lastLoginBonusDay;
  /// Сколько монет родитель уже выдал за жизнь профиля.
  final int parentGrantTotal;
  /// ISO-время, когда можно начать следующий период (если не демо).
  final String? nextPeriodAvailableAt;
  /// Купленные товары (для коллекций и скинов на питомце).
  final List<String> ownedItemIds;
  /// YYYY-MM-DD, когда забрали секрет дня.
  final String? secretClaimedDay;
  /// Цель челленджа от родителя (монеты в копилку). null = нет челленджа.
  final int? parentChallengeTarget;
  /// Сколько уже отложено по текущему челленджу.
  final int parentChallengeSaved;
  /// Id полностью собранных коллекций (награда уже выдана).
  final List<String> completedCollectionIds;
  /// ISO-время последней выдачи/смены набора заданий периода.
  final String? questsRefreshedAt;
  /// Счётчик обновлений набора (для ротации id).
  final int questRefreshCount;
  /// Родитель выдал монеты — ребёнок должен спланировать (режим «вместе»).
  final bool parentCoplayPending;
  /// Сколько монет родитель только что добавил в coplay-сессии.
  final int parentCoplayAmount;
  /// Звуки интерфейса (покупка, задания и т.п.).
  final bool soundEnabled;

  PlayerProfile copyWith({
    String? playerName,
    String? petName,
    PetAppearance? appearance,
    int? balance,
    int? savingsBalance,
    int? hunger,
    int? mood,
    int? growthStage,
    int? goodPeriodStreak,
    Object? selectedGoalId = _sentinel,
    bool? demoMode,
    bool? onboardingDone,
    GamePeriod? period,
    List<String>? completedQuestIds,
    String? lastFeedback,
    int? totalPeriodsCompleted,
    AgeTrack? ageTrack,
    SkillProgress? skills,
    int? stars,
    int? comboBest,
    List<String>? completedLessonIds,
    Object? lastLoginBonusDay = _sentinel,
    int? parentGrantTotal,
    Object? nextPeriodAvailableAt = _sentinel,
    List<String>? ownedItemIds,
    Object? secretClaimedDay = _sentinel,
    Object? parentChallengeTarget = _sentinel,
    int? parentChallengeSaved,
    List<String>? completedCollectionIds,
    Object? questsRefreshedAt = _sentinel,
    int? questRefreshCount,
    bool? parentCoplayPending,
    int? parentCoplayAmount,
    bool? soundEnabled,
  }) {
    return PlayerProfile(
      playerName: playerName ?? this.playerName,
      petName: petName ?? this.petName,
      appearance: appearance ?? this.appearance,
      balance: balance ?? this.balance,
      savingsBalance: savingsBalance ?? this.savingsBalance,
      hunger: hunger ?? this.hunger,
      mood: mood ?? this.mood,
      growthStage: growthStage ?? this.growthStage,
      goodPeriodStreak: goodPeriodStreak ?? this.goodPeriodStreak,
      selectedGoalId: identical(selectedGoalId, _sentinel)
          ? this.selectedGoalId
          : selectedGoalId as String?,
      demoMode: demoMode ?? this.demoMode,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      period: period ?? this.period,
      completedQuestIds: completedQuestIds ?? this.completedQuestIds,
      lastFeedback: lastFeedback ?? this.lastFeedback,
      totalPeriodsCompleted:
          totalPeriodsCompleted ?? this.totalPeriodsCompleted,
      ageTrack: ageTrack ?? this.ageTrack,
      skills: skills ?? this.skills,
      stars: stars ?? this.stars,
      comboBest: comboBest ?? this.comboBest,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      lastLoginBonusDay: identical(lastLoginBonusDay, _sentinel)
          ? this.lastLoginBonusDay
          : lastLoginBonusDay as String?,
      parentGrantTotal: parentGrantTotal ?? this.parentGrantTotal,
      nextPeriodAvailableAt: identical(nextPeriodAvailableAt, _sentinel)
          ? this.nextPeriodAvailableAt
          : nextPeriodAvailableAt as String?,
      ownedItemIds: ownedItemIds ?? this.ownedItemIds,
      secretClaimedDay: identical(secretClaimedDay, _sentinel)
          ? this.secretClaimedDay
          : secretClaimedDay as String?,
      parentChallengeTarget: identical(parentChallengeTarget, _sentinel)
          ? this.parentChallengeTarget
          : parentChallengeTarget as int?,
      parentChallengeSaved:
          parentChallengeSaved ?? this.parentChallengeSaved,
      completedCollectionIds:
          completedCollectionIds ?? this.completedCollectionIds,
      questsRefreshedAt: identical(questsRefreshedAt, _sentinel)
          ? this.questsRefreshedAt
          : questsRefreshedAt as String?,
      questRefreshCount: questRefreshCount ?? this.questRefreshCount,
      parentCoplayPending: parentCoplayPending ?? this.parentCoplayPending,
      parentCoplayAmount: parentCoplayAmount ?? this.parentCoplayAmount,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'playerName': playerName,
        'petName': petName,
        'appearance': appearance.toJson(),
        'balance': balance,
        'savingsBalance': savingsBalance,
        'hunger': hunger,
        'mood': mood,
        'growthStage': growthStage,
        'goodPeriodStreak': goodPeriodStreak,
        'selectedGoalId': selectedGoalId,
        'demoMode': demoMode,
        'onboardingDone': onboardingDone,
        'period': period.toJson(),
        'completedQuestIds': completedQuestIds,
        'lastFeedback': lastFeedback,
        'totalPeriodsCompleted': totalPeriodsCompleted,
        'ageTrack': ageTrack.name,
        'skills': skills.toJson(),
        'stars': stars,
        'comboBest': comboBest,
        'completedLessonIds': completedLessonIds,
        'lastLoginBonusDay': lastLoginBonusDay,
        'parentGrantTotal': parentGrantTotal,
        'nextPeriodAvailableAt': nextPeriodAvailableAt,
        'ownedItemIds': ownedItemIds,
        'secretClaimedDay': secretClaimedDay,
        'parentChallengeTarget': parentChallengeTarget,
        'parentChallengeSaved': parentChallengeSaved,
        'completedCollectionIds': completedCollectionIds,
        'questsRefreshedAt': questsRefreshedAt,
        'questRefreshCount': questRefreshCount,
        'parentCoplayPending': parentCoplayPending,
        'parentCoplayAmount': parentCoplayAmount,
        'soundEnabled': soundEnabled,
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final trackRaw = json['ageTrack'] as String? ?? 'middle';
    final ageTrack = switch (trackRaw) {
      'junior' => AgeTrack.junior,
      'senior' => AgeTrack.senior,
      _ => AgeTrack.middle,
    };
    return PlayerProfile(
      playerName: json['playerName'] as String,
      petName: json['petName'] as String,
      appearance:
          PetAppearance.fromJson(json['appearance'] as Map<String, dynamic>),
      balance: json['balance'] as int,
      savingsBalance: json['savingsBalance'] as int,
      hunger: json['hunger'] as int,
      mood: json['mood'] as int,
      growthStage: json['growthStage'] as int,
      goodPeriodStreak: json['goodPeriodStreak'] as int,
      selectedGoalId: json['selectedGoalId'] as String?,
      demoMode: json['demoMode'] as bool? ?? true,
      onboardingDone: json['onboardingDone'] as bool? ?? false,
      period: GamePeriod.fromJson(json['period'] as Map<String, dynamic>),
      completedQuestIds:
          (json['completedQuestIds'] as List? ?? []).cast<String>(),
      lastFeedback: json['lastFeedback'] as String? ?? '',
      totalPeriodsCompleted: json['totalPeriodsCompleted'] as int? ?? 0,
      ageTrack: ageTrack,
      skills: SkillProgress.fromJson(json['skills'] as Map<String, dynamic>?),
      stars: json['stars'] as int? ?? 0,
      comboBest: json['comboBest'] as int? ?? 0,
      completedLessonIds:
          (json['completedLessonIds'] as List? ?? []).cast<String>(),
      lastLoginBonusDay: json['lastLoginBonusDay'] as String?,
      parentGrantTotal: json['parentGrantTotal'] as int? ?? 0,
      nextPeriodAvailableAt: json['nextPeriodAvailableAt'] as String?,
      ownedItemIds: (json['ownedItemIds'] as List? ?? []).cast<String>(),
      secretClaimedDay: json['secretClaimedDay'] as String?,
      parentChallengeTarget: json['parentChallengeTarget'] as int?,
      parentChallengeSaved: json['parentChallengeSaved'] as int? ?? 0,
      completedCollectionIds:
          (json['completedCollectionIds'] as List? ?? []).cast<String>(),
      questsRefreshedAt: json['questsRefreshedAt'] as String?,
      questRefreshCount: json['questRefreshCount'] as int? ?? 0,
      parentCoplayPending: json['parentCoplayPending'] as bool? ?? false,
      parentCoplayAmount: json['parentCoplayAmount'] as int? ?? 0,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
    );
  }

  static PlayerProfile fresh({
    required String playerName,
    required String petName,
    required PetAppearance appearance,
    AgeTrack ageTrack = AgeTrack.junior,
    int? startingBalance,
  }) {
    final balance = startingBalance ?? ageTrack.startingBalance;
    return PlayerProfile(
      playerName: playerName,
      petName: petName,
      appearance: appearance,
      balance: balance,
      savingsBalance: 0,
      hunger: 70,
      mood: 70,
      growthStage: 1,
      goodPeriodStreak: 0,
      selectedGoalId: null,
      demoMode: true,
      onboardingDone: true,
      ageTrack: ageTrack,
      skills: const SkillProgress(),
      stars: 0,
      comboBest: 0,
      completedLessonIds: const [],
      lastLoginBonusDay: null,
      parentGrantTotal: 0,
      nextPeriodAvailableAt: null,
      ownedItemIds: const [],
      secretClaimedDay: null,
      parentChallengeTarget: null,
      parentChallengeSaved: 0,
      completedCollectionIds: const [],
      questsRefreshedAt: null,
      questRefreshCount: 0,
      parentCoplayPending: false,
      parentCoplayAmount: 0,
      soundEnabled: true,
      period: GamePeriod(
        index: 1,
        startingBalance: balance,
        phase: PeriodPhase.planning,
      ),
      completedQuestIds: const [],
      lastFeedback:
          'Добро пожаловать в «Неделю заботы»! Сложность: ${ageTrack.difficultyLabel}. Сначала составь план.',
    );
  }
}

const Object _sentinel = Object();

class EconomyResult {
  const EconomyResult({
    required this.profile,
    required this.message,
    this.ok = true,
    this.earnedStars = 0,
    this.earnedXp = 0,
    this.combo = 0,
    this.celebrate = false,
    this.celebrateTitle,
    this.stageGrew = false,
    this.collectionCompleteId,
    this.whyHint,
    this.tip,
  });

  final PlayerProfile profile;
  final String message;
  final bool ok;
  final int earnedStars;
  final int earnedXp;
  final int combo;
  final bool celebrate;
  final String? celebrateTitle;
  final bool stageGrew;
  /// Id коллекции, которую только что собрали.
  final String? collectionCompleteId;
  /// Короткая педагогическая подсказка «почему так» (после ошибки).
  final String? whyHint;
  /// Совет из задания / урока.
  final String? tip;
}
