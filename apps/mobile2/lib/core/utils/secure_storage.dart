import 'package:shared_preferences/shared_preferences.dart';
import '../constants/constants.dart';

class SecureStorage {
  SecureStorage._();

  static Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  static Future<void> setAccessToken(String token) async {
    await (await _prefs).setString(AppConstants.accessTokenKey, token);
  }

  static Future<String?> getAccessToken() async {
    return (await _prefs).getString(AppConstants.accessTokenKey);
  }

  static Future<void> setRefreshToken(String token) async {
    await (await _prefs).setString(AppConstants.refreshTokenKey, token);
  }

  static Future<String?> getRefreshToken() async {
    return (await _prefs).getString(AppConstants.refreshTokenKey);
  }

  static Future<void> setUser(String userJson) async {
    await (await _prefs).setString(AppConstants.userKey, userJson);
  }

  static Future<String?> getUser() async {
    return (await _prefs).getString(AppConstants.userKey);
  }

  static Future<void> setThemeMode(String mode) async {
    await (await _prefs).setString(AppConstants.themeKey, mode);
  }

  static Future<String?> getThemeMode() async {
    return (await _prefs).getString(AppConstants.themeKey);
  }

  static Future<void> clearAll() async {
    await (await _prefs).clear();
  }
}
