import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

class ProfileRepository {
  static const _key = 'finny_profile_v1';
  static const _backupKey = 'finny_profile_v1_backup';

  Future<PlayerProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final primary = _tryParse(prefs.getString(_key));
    if (primary != null) return primary;

    // Основной ключ битый/пустой — пробуем резервную копию.
    final backup = _tryParse(prefs.getString(_backupKey));
    if (backup != null) {
      // Восстанавливаем основной слот, чтобы следующий запуск был чистым.
      await prefs.setString(_key, jsonEncode(backup.toJson()));
      return backup;
    }
    return null;
  }

  Future<void> save(PlayerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(profile.toJson());
    final previous = prefs.getString(_key);
    if (previous != null && previous.isNotEmpty) {
      await prefs.setString(_backupKey, previous);
    }
    await prefs.setString(_key, encoded);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_backupKey);
  }

  PlayerProfile? _tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return PlayerProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
