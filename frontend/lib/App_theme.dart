import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  // AQI level colors
  static const good = Color(0xFF4ADE80);
  static const moderate = Color(0xFFFACC15);
  static const sensitiveGroups = Color(0xFFFB923C);
  static const unhealthy = Color(0xFFF87171);
  static const veryUnhealthy = Color(0xFFC084FC);
  static const hazardous = Color(0xFF9F1239);

  // UI palette
  static const bgDark = Color(0xFF0F172A);
  static const bgCard = Color(0xFF1E293B);
  static const bgCardLight = Color(0xFF263347);
  static const surface = Color(0xFFF8FAFC);
  static const border = Color(0xFF334155);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF475569);

  // Pollutant colors
  static const pm25Color = Color(0xFFEF4444);
  static const pm10Color = Color(0xFFF59E0B);
  static const o3Color = Color(0xFF3B82F6);
  static const no2Color = Color(0xFF8B5CF6);
  static const so2Color = Color(0xFF06B6D4);
  static const coColor = Color(0xFF10B981);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgDark,
        fontFamily: 'SF Pro Display',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.good,
          surface: AppColors.bgCard,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      );

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.surface,
        fontFamily: 'SF Pro Display',
        colorScheme: const ColorScheme.light(
          primary: AppColors.good,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      );
}

class ThemeNotifier extends ChangeNotifier {
  static const _prefKey = 'is_dark_theme';
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get themeMode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void toggleTheme() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    _saveToPrefs();
    notifyListeners();
  }

  void setDark(bool dark) {
    _mode = dark ? ThemeMode.dark : ThemeMode.light;
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkPref = prefs.getBool(_prefKey) ?? true;
      _mode = isDarkPref ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    } catch (_) {
      // ignore errors and keep default
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, isDark);
    } catch (_) {}
  }
}
