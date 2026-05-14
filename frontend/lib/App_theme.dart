import 'package:flutter/material.dart';

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
}