import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/secure_storage.dart';

class ThemeState {
  final ThemeMode themeMode;

  const ThemeState({this.themeMode = ThemeMode.system});

  ThemeState copyWith({ThemeMode? themeMode}) {
    return ThemeState(themeMode: themeMode ?? this.themeMode);
  }

  bool get isDark => themeMode == ThemeMode.dark;
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final stored = await SecureStorage.getThemeMode();
    if (stored != null) {
      switch (stored) {
        case 'dark':
          state = const ThemeState(themeMode: ThemeMode.dark);
          break;
        case 'light':
          state = const ThemeState(themeMode: ThemeMode.light);
          break;
        default:
          state = const ThemeState(themeMode: ThemeMode.system);
      }
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = ThemeState(themeMode: mode);
    String value;
    switch (mode) {
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.light:
        value = 'light';
        break;
      default:
        value = 'system';
    }
    await SecureStorage.setThemeMode(value);
  }

  Future<void> toggleTheme() async {
    if (state.isDark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});
