import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

abstract class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        surface: AppColors.background,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surfaceContainer: AppColors.surfaceContainer,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: const Color(0xFFFAF5F2),
        dialBackgroundColor: const Color(0xFFF2ECE6),
        dialHandColor: AppColors.secondary,
        dialTextColor: AppColors.primary,
        entryModeIconColor: AppColors.secondary,
        hourMinuteColor: const Color(0xFFECE4DE),
        hourMinuteTextColor: AppColors.primary,
        dayPeriodColor: const Color(0xFFECE4DE),
        dayPeriodTextColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE5DDD0), width: 1),
        ),
      ),
      fontFamilyFallback: const ['Segoe UI Emoji', 'Apple Color Emoji', 'Noto Color Emoji', 'sans-serif'],
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLg,
        headlineLarge: AppTypography.headlineLg,
        bodyLarge: AppTypography.bodyLg,
        bodyMedium: AppTypography.bodyMd,
        labelSmall: AppTypography.labelSm,
      ),
    );
  }
}
