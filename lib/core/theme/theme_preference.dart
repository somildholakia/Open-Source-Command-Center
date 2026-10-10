import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme persistence service using shared_preferences.
/// Stores ThemeMode preference (dark / light / system).
class ThemePreference {
  static const String _key = 'theme_mode';

  /// Notifier so the app theme updates immediately when the user selects a mode.
  static final ValueNotifier<ThemeMode> notifier = ValueNotifier(
    ThemeMode.dark,
  );

  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.light:
        await prefs.setString(_key, 'light');
        break;
      case ThemeMode.system:
        await prefs.setString(_key, 'system');
        break;
      case ThemeMode.dark:
        await prefs.setString(_key, 'dark');
        break;
    }
    notifier.value = mode;
  }
}
