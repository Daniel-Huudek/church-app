import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage();

  static const _accessTokenKey = '@church_app_access_token';
  static const _refreshTokenKey = '@church_app_refresh_token';
  static const _userKey = '@church_app_user';
  static const _themeKey = '@church_app_theme';

  static Future<void> setAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  static Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  static Future<void> setRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  static Future<void> setUser(String userJson) async {
    await _storage.write(key: _userKey, value: userJson);
  }

  static Future<String?> getUser() async {
    return _storage.read(key: _userKey);
  }

  static Future<void> setThemeMode(String mode) async {
    await _storage.write(key: _themeKey, value: mode);
  }

  static Future<String?> getThemeMode() async {
    return _storage.read(key: _themeKey);
  }

  /// Clears auth session keys only — preserves theme and other prefs.
  static Future<void> clearAuth() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userKey),
    ]);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
