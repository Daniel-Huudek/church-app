import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localCacheProvider = Provider<LocalCache>((ref) => LocalCache.instance);

class LocalCache {
  LocalCache._();

  static final LocalCache instance = LocalCache._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _store {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('LocalCache.init() must be called before use');
    }
    return prefs;
  }

  Future<void> setJson(String key, Object value) async {
    await _store.setString(key, jsonEncode(value));
  }

  dynamic getJson(String key) {
    final raw = _store.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? getMap(String key) {
    final value = getJson(key);
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  List<Map<String, dynamic>>? getList(String key) {
    final value = getJson(key);
    if (value is! List) return null;
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> remove(String key) async {
    await _store.remove(key);
  }
}
