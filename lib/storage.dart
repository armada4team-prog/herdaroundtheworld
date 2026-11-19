/// Saving on the phone: what's yours (nickname, follows, the Companions in your care, your
/// Passport, your sign-in), so nothing resets when the app closes.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);

  Future<Map<String, dynamic>?> readJson(String key) async {
    try {
      final raw = await read(key);
      if (raw == null) return null;
      final v = jsonDecode(raw);
      return v is Map ? Map<String, dynamic>.from(v) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeJson(String key, Object value) async {
    try {
      await write(key, jsonEncode(value));
    } catch (_) {
      // Full or unavailable: everything keeps working for this visit.
    }
  }
}

/// The phone's own storage (shared_preferences).
class PrefsStore extends KeyValueStore {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  Future<String?> read(String key) => _prefs.getString(key);
  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);
  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// Kept in memory only (tests).
class MemoryStore extends KeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> remove(String key) async => values.remove(key);
}
