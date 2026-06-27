import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  // AQI level colors
  static const good = Color(0xFF4ADE80);
  static const moderate = Color(0xFFFACC15);
  static const sensitiveGroups = Color(0xFFFB923C);
  static const unhealthy = Color(0xFFF87171);
  static const veryUnhealthy = Color(0xFFC084FC);
  static const hazardous = Color(0xFF9F1239);

  // UI palette (dark defaults — prefer context.palette in widgets)
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

/// Theme-aware UI colors — attached to light/dark [ThemeData].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.card,
    required this.cardLight,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  final Color card;
  final Color cardLight;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  static const dark = AppPalette(
    card: AppColors.bgCard,
    cardLight: AppColors.bgCardLight,
    border: AppColors.border,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
  );

  static const light = AppPalette(
    card: Colors.white,
    cardLight: Color(0xFFF1F5F9),
    border: Color(0xFFE5E7EB),
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF64748B),
    textMuted: Color(0xFF94A3B8),
  );

  @override
  AppPalette copyWith({
    Color? card,
    Color? cardLight,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
  }) {
    return AppPalette(
      card: card ?? this.card,
      cardLight: cardLight ?? this.cardLight,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      card: Color.lerp(card, other.card, t)!,
      cardLight: Color.lerp(cardLight, other.cardLight, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;

  SystemUiOverlayStyle get appOverlayStyle =>
      Theme.of(this).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark;
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
        extensions: const [AppPalette.dark],
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
        extensions: const [AppPalette.light],
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
      
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, isDark);
    } catch (_) {}
  }
}
