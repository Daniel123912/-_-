import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Короткие звуки + фоновая музыка + вибрация.
class FinnyFx {
  FinnyFx._();

  static final AudioPlayer _player = AudioPlayer();
  static final AudioPlayer _music = AudioPlayer();
  static var _ready = false;
  static var _musicReady = false;
  static var soundEnabled = true;

  static void setSoundEnabled(bool enabled) {
    soundEnabled = enabled;
    if (!enabled) {
      try {
        _player.stop();
      } catch (_) {}
      try {
        _music.pause();
      } catch (_) {}
    } else {
      resumeMusic();
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

  /// Фоновая музыка: громкость через кнопки телефона (media stream).
  static Future<void> startBackgroundMusic() async {
    if (!soundEnabled) return;
    try {
      if (!_musicReady) {
        await _music.setReleaseMode(ReleaseMode.loop);
        await _music.setVolume(0.45);
        await _music.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              isSpeakerphoneOn: false,
              stayAwake: false,
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.media,
              audioFocus: AndroidAudioFocus.gain,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: const {
                AVAudioSessionOptions.mixWithOthers,
              },
            ),
          ),
        );
        await _music.play(AssetSource('4.mp3'));
        _musicReady = true;
      } else {
        await _music.resume();
      }
    } catch (_) {
      // Автоплей / отсутствие файла — приложение без музыки.
    }
  }

  static Future<void> pauseMusic() async {
    try {
      await _music.pause();
    } catch (_) {}
  }

  static Future<void> resumeMusic() async {
    if (!soundEnabled) return;
    try {
      if (!_musicReady) {
        await startBackgroundMusic();
      } else {
        await _music.resume();
      }
    } catch (_) {}
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
