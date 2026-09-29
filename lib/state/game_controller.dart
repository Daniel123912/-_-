import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/content_loader.dart';
import '../data/profile_repository.dart';
import '../domain/economy.dart';
import '../domain/models.dart';
import '../fx/finny_fx.dart';

final contentProvider = FutureProvider<GameContent>((ref) async {
  return ContentLoader.load();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final gameControllerProvider =
    AsyncNotifierProvider<GameController, PlayerProfile?>(GameController.new);

class GameController extends AsyncNotifier<PlayerProfile?> {
  static const _fallbackAppearance = PetAppearance(
    color: 'синий',
    eyes: 'голубые',
    accessory: 'без',
    model: 'pet_01',
  );

  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  PlayerProfile get _placeholderProfile => PlayerProfile.fresh(
        playerName: 'Игрок',
        petName: 'Финни',
        appearance: _fallbackAppearance,
      );

  EconomyResult _noProfile([String message = 'Сначала создай питомца.']) {
    return EconomyResult(
      profile: _placeholderProfile,
      ok: false,
      message: message,
    );
  }

  @override
  Future<PlayerProfile?> build() async {
    var profile = await _repo.load();
    if (profile == null) return null;
    FinnyFx.setSoundEnabled(profile.soundEnabled);
    final normalized = GameEconomy.normalizeCooldowns(profile);
    if (normalized != profile) {
      profile = normalized;
      await _repo.save(profile);
    }
    try {
      final content = await ref.read(contentProvider.future);
      final next =
          GameEconomy.applyDueQuestRefresh(profile, content.quests);
      if (!identical(next, profile) && next != profile) {
        profile = next;
        await _repo.save(profile);
      }
    } catch (_) {
      // Контент недоступен — оставляем профиль как есть.
    }
    return profile;
  }

  Future<void> _persist(PlayerProfile? profile) async {
    state = AsyncData(profile);
    if (profile == null) {
      await _repo.clear();
    } else {
      await _repo.save(profile);
    }
  }

  Future<void> createProfile({
    required String playerName,
    required String petName,
    required PetAppearance appearance,
    AgeTrack ageTrack = AgeTrack.junior,
  }) async {
    final profile = PlayerProfile.fresh(
      playerName: playerName.trim().isEmpty ? 'Игрок' : playerName.trim(),
      petName: petName.trim().isEmpty ? 'Финни' : petName.trim(),
      appearance: appearance,
      ageTrack: ageTrack,
    );
    FinnyFx.setSoundEnabled(profile.soundEnabled);
    await _persist(profile);
  }

  Future<void> setAgeTrack(AgeTrack track) async {
    final profile = state.value;
    if (profile == null) return;
    final content = await ref.read(contentProvider.future);
    // Сбрасываем набор квестов периода: иначе останутся id другой сложности.
    var nextPeriod = profile.period.phase == PeriodPhase.planning
        ? profile.period.copyWith(activeQuestIds: const [])
        : profile.period.copyWith(
            activeQuestIds: const [],
            completedQuestIds: const [],
            goodQuestStreak: 0,
            failXpQuestIds: const [],
          );
    final bumped = profile.copyWith(
      ageTrack: track,
      selectedGoalId: null,
      period: nextPeriod,
    );
    // В активном периоде сразу подбираем набор под новый возраст.
    if (bumped.period.phase == PeriodPhase.playing) {
      nextPeriod = nextPeriod.copyWith(
        activeQuestIds: GameEconomy.pickPeriodQuests(bumped, content.quests),
      );
    }
    await _persist(bumped.copyWith(
      period: nextPeriod,
      lastFeedback:
          'Уровень: ${track.shortLabel}. '
          'Задания и учёба обновлены.',
    ));
  }

  Future<EconomyResult> confirmBudget(BudgetPlan plan) async {
    final profile = state.value;
    if (profile == null) return _noProfile();
    final content = await ref.read(contentProvider.future);
    final result = GameEconomy.confirmPlan(
      profile,
      plan,
      questPool: content.quests,
    );
    if (result.ok) await _persist(result.profile);
    return result;
  }

  Future<EconomyResult> buy(ShopItem item) async {
    final profile = state.value;
    if (profile == null) return _noProfile();
    final result = GameEconomy.purchase(profile, item);
    if (result.ok) await _persist(result.profile);
    return result;
  }

  Future<void> selectGoal(String goalId) async {
    final profile = state.value;
    if (profile == null) return;
    await _persist(profile.copyWith(
      selectedGoalId: goalId,
      lastFeedback: 'Цель выбрана. Откладывай монеты в копилку!',
    ));
  }

  Future<EconomyResult> saveToGoal(int amount) async {
    final profile = state.value;
    if (profile == null) return _noProfile();
    final result = GameEconomy.transferToSavings(profile, amount);
    if (result.ok) await _persist(result.profile);
    return result;
  }

  Future<EconomyResult> withdraw(int amount, {required bool confirmed}) async {
    final profile = state.value;
    if (profile == null) return _noProfile();
    final result = GameEconomy.withdrawFromSavings(
      profile,
      amount,
      confirmed: confirmed,
    );
    if (result.ok) await _persist(result.profile);
    return result;
  }

  Future<EconomyResult> answerQuest(Quest quest, QuestOption option) async {
    final profile = state.value;
    if (profile == null) return _noProfile();
    final result = GameEconomy.completeQuest(profile, quest, option);
    // Сохраняем и верный, и неверный ответ (XP/комбо/настроение).
    await _persist(result.profile);
    return result;
  }

  /// Обновить набор заданий периода (раз в интервал; в демо — сразу).
  Future<EconomyResult> refreshQuests({bool force = false}) async {
    final profile = state.value;
    if (profile == null) return _noProfile();
    final content = await ref.read(contentProvider.future);
    final result = GameEconomy.refreshPeriodQuests(
      profile,
      content.quests,
      force: force,
    );
    if (result.ok) await _persist(result.profile);
    return result;
  }

  /// Подтянуть авто-обновление при открытии экрана заданий.
  Future<void> syncQuestRefresh() async {
    final profile = state.value;
    if (profile == null) return;
    final content = await ref.read(contentProvider.future);
    var next = GameEconomy.applyDueQuestRefresh(profile, content.quests);
    final safeIds = GameEconomy.sanitizeActiveQuestIds(next, content.quests);
    if (safeIds.length != next.period.activeQuestIds.length ||
        !_sameIds(safeIds, next.period.activeQuestIds)) {
      // Чужой возраст/сложность выпали из набора — добираем подходящие.
      final patched = next.copyWith(
        period: next.period.copyWith(activeQuestIds: safeIds),
      );
      next = safeIds.isEmpty && next.period.phase == PeriodPhase.playing
          ? patched.copyWith(
              period: patched.period.copyWith(
                activeQuestIds:
                    GameEconomy.pickPeriodQuests(patched, content.quests),
              ),
            )
          : patched;
    }
    if (next != profile) await _persist(next);
  }

  bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<EconomyResult> claimGoal(SavingsGoal goal) async {
    final profile = state.value;
    if (profile == null) return _noProfile();
    final result = GameEconomy.claimGoal(profile, goal);
    if (result.ok) await _persist(result.profile);
    return result;
  }

  Future<EconomyResult> completeLesson(
    LearningLesson lesson,
    QuestOption option,
  ) async {
    final profile = state.value;
    if (profile == null) return _noProfile();
    final result = GameEconomy.completeLesson(profile, lesson, option);
    await _persist(result.profile);
    return result;
  }

  Future<PeriodCloseResult> finishPeriod() async {
    final profile = state.value;
    if (profile == null) {
      return PeriodCloseResult(
        profile: _placeholderProfile,
        feedback: 'Сначала создай питомца.',
        wasGoodPeriod: false,
        softFail: true,
      );
    }
    final result = GameEconomy.closePeriod(profile);
    await _persist(result.profile);
    return result;
  }

  Future<bool> nextPeriod() async {
    final profile = state.value;
    if (profile == null) return false;
    if (!GameEconomy.canAdvancePeriod(profile)) {
      await _persist(profile.copyWith(
        lastFeedback:
            'Сейчас пауза между периодами. Нажми «Продолжить сразу (демо)» или подожди.',
      ));
      return false;
    }
    await _persist(GameEconomy.startNextPeriod(profile));
    return true;
  }

  Future<EconomyResult> claimDailyLogin() async {
    final profile = state.value;
    if (profile == null) return _noProfile('Нет профиля');
    final result = GameEconomy.claimDailyLogin(profile);
    if (result.ok) await _persist(result.profile);
    return result;
  }

  Future<EconomyResult> claimSecretOfDay() async {
    final profile = state.value;
    if (profile == null) return _noProfile();
    final result = GameEconomy.claimSecretOfDay(profile);
    if (result.ok) await _persist(result.profile);
    return result;
  }

  Future<EconomyResult> setParentChallenge(int targetCoins) async {
    final profile = state.value;
    if (profile == null) return _noProfile();
    final result = GameEconomy.setParentChallenge(profile, targetCoins);
    if (result.ok) await _persist(result.profile);
    return result;
  }

  Future<EconomyResult> clearParentChallenge() async {
    final profile = state.value;
    if (profile == null) return _noProfile();
    final result = GameEconomy.clearParentChallenge(profile);
    if (result.ok) await _persist(result.profile);
    return result;
  }

  Future<EconomyResult> grantParentCoins([int? amount]) async {
    final profile = state.value;
    if (profile == null) return _noProfile();
    final result = amount == null
        ? GameEconomy.grantParentCoins(profile)
        : GameEconomy.grantParentCoins(profile, amount: amount);
    if (result.ok) await _persist(result.profile);
    return result;
  }

  Future<void> setDemoMode(bool enabled) async {
    final profile = state.value;
    if (profile == null) return;
    await _persist(profile.copyWith(
      demoMode: enabled,
      nextPeriodAvailableAt: enabled ? null : profile.nextPeriodAvailableAt,
      lastFeedback: enabled
          ? 'Демо-режим: периоды и задания без ожидания.'
          : 'Обычный режим: пауза ~${GameEconomy.formatDurationShort(GameEconomy.normalPeriodCooldown)} между периодами, '
              'задания обновляются раз в ${GameEconomy.formatDurationShort(GameEconomy.questRefreshInterval)}.',
    ));
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final profile = state.value;
    if (profile == null) return;
    FinnyFx.setSoundEnabled(enabled);
    await _persist(profile.copyWith(
      soundEnabled: enabled,
      lastFeedback: enabled
          ? 'Звук включён: музыка и эффекты. Громкость — кнопками телефона.'
          : 'Звук выключен. Вибрация при действиях остаётся.',
    ));
  }

  Future<void> resetProfile() async {
    await _persist(null);
  }
}
