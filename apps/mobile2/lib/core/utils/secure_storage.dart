import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/constants.dart';

class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage();

  static Future<void> setAccessToken(String token) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: token);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.accessTokenKey);
  }

  static Future<void> setRefreshToken(String token) async {
    await _storage.write(key: AppConstants.refreshTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.refreshTokenKey);
  }

  static Future<void> setUser(String userJson) async {
    await _storage.write(key: AppConstants.userKey, value: userJson);
  }

  static Future<String?> getUser() async {
    return await _storage.read(key: AppConstants.userKey);
  }

  static Future<void> setThemeMode(String mode) async {
    await _storage.write(key: AppConstants.themeKey, value: mode);
  }

  static Future<String?> getThemeMode() async {
    return await _storage.read(key: AppConstants.themeKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
