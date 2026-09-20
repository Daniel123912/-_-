import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/models.dart';

class GameContent {
  const GameContent({
    required this.items,
    required this.goals,
    required this.quests,
    required this.lessons,
    required this.models,
    required this.colors,
    required this.eyes,
    required this.accessories,
  });

  final List<ShopItem> items;
  final List<SavingsGoal> goals;
  final List<Quest> quests;
  final List<LearningLesson> lessons;
  final List<PetModel> models;
  final List<String> colors;
  final List<String> eyes;
  final List<String> accessories;

  int get petCombinations => colors.length * eyes.length * accessories.length;
}

class ContentLoader {
  static Future<GameContent> load() async {
    final itemsRaw =
        await rootBundle.loadString('assets/content/items.json');
    final goalsRaw =
        await rootBundle.loadString('assets/content/goals.json');
    final questsRaw =
        await rootBundle.loadString('assets/content/quests.json');
    final lessonsRaw =
        await rootBundle.loadString('assets/content/lessons.json');
    final petsRaw = await rootBundle.loadString('assets/content/pets.json');

    final items = _parseList(itemsRaw, ShopItem.fromJson);
    final goals = _parseList(goalsRaw, SavingsGoal.fromJson);
    final quests = _parseList(questsRaw, Quest.fromJson);
    final lessons = _parseList(lessonsRaw, LearningLesson.fromJson);
    final pets = _parsePets(petsRaw);

    final empty = <String>[
      if (items.isEmpty) 'items',
      if (goals.isEmpty) 'goals',
      if (quests.isEmpty) 'quests',
      if (lessons.isEmpty) 'lessons',
      if (pets.models.isEmpty) 'pets.models',
      if (pets.colors.isEmpty) 'pets.colors',
      if (pets.eyes.isEmpty) 'pets.eyes',
      if (pets.accessories.isEmpty) 'pets.accessories',
    ];
    if (empty.isNotEmpty) {
      throw StateError('Контент пустой или повреждён: ${empty.join(', ')}');
    }

    return GameContent(
      items: items,
      goals: goals,
      quests: quests,
      lessons: lessons,
      models: pets.models,
      colors: pets.colors,
      eyes: pets.eyes,
      accessories: pets.accessories,
    );
  }

  /// Парсит JSON-массив; битые элементы пропускает, чтобы один кривой
  /// объект не ронял весь контент.
  static List<T> _parseList<T>(
    String raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <T>[];
      for (final e in decoded) {
        if (e is! Map) continue;
        try {
          out.add(fromJson(Map<String, dynamic>.from(e)));
        } catch (_) {
          // Пропускаем битый элемент.
        }
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  static ({
    List<PetModel> models,
    List<String> colors,
    List<String> eyes,
    List<String> accessories,
  }) _parsePets(String raw) {
    try {
      final pets = jsonDecode(raw);
      if (pets is! Map) {
        return (
          models: const [],
          colors: const [],
          eyes: const [],
          accessories: const [],
        );
      }
      final modelsRaw = pets['models'];
      final models = <PetModel>[];
      if (modelsRaw is List) {
        for (final e in modelsRaw) {
          if (e is! Map) continue;
          try {
            models.add(PetModel.fromJson(Map<String, dynamic>.from(e)));
          } catch (_) {}
        }
      }
      final eyes = _stringList(pets['eyes']);
      final bodiesFallback = _stringList(pets['bodies']);
      return (
        models: models,
        colors: _stringList(pets['colors']),
        eyes: eyes.isNotEmpty ? eyes : bodiesFallback,
        accessories: _stringList(pets['accessories']),
      );
    } catch (_) {
      return (
        models: const [],
        colors: const [],
        eyes: const [],
        accessories: const [],
      );
    }
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.whereType<String>().where((s) => s.trim().isNotEmpty).toList();
  }
}
