import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Короткие звуки + вибрация: покупка, копилка, успех/мягкая ошибка.
class FinnyFx {
  FinnyFx._();

  static final AudioPlayer _player = AudioPlayer();
  static var _ready = false;
  static var soundEnabled = true;

  static void setSoundEnabled(bool enabled) {
    soundEnabled = enabled;
    if (!enabled) {
      try {
        _player.stop();
      } catch (_) {}
    }
  }

  static Future<void> warmUp() async {
    if (_ready) return;
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      _ready = true;
    } catch (_) {
      // Web/автоплей может блокировать — UI всё равно живой.
    }
  }

  static Future<void> purchase() => _play(
        'sounds/purchase.wav',
        haptic: HapticFeedback.mediumImpact,
      );

  static Future<void> save() => _play(
        'sounds/save.wav',
        haptic: HapticFeedback.lightImpact,
      );

  static Future<void> success() => _play(
        'sounds/success.wav',
        haptic: HapticFeedback.mediumImpact,
      );

  static Future<void> softFail() => _play(
        'sounds/soft_fail.wav',
        haptic: HapticFeedback.selectionClick,
      );

  static Future<void> _play(
    String asset, {
    required Future<void> Function() haptic,
  }) async {
    try {
      await haptic();
    } catch (_) {}
    if (!soundEnabled) return;
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
    try {
      await warmUp();
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (_) {
      // Без звука — только анимация/хаптик.
    }
  }
}
