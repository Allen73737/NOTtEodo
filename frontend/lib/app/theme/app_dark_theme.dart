import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_component_theme.dart';

class AppDarkColors {
  static const background = Color(0xFF000000); // Pure Pitch Black (OLED)
  static const surface = Color(0xFF000000); // Pure Pitch Black OLED Surface
  static const surfaceContainerHigh = Color(0xFF0A0A0A); // Ultra-Deep Obsidian Card
  static const surfaceDim = Color(0xFF000000);

  static const primary = Color(0xFFFFFFFF); // Crisp Pure White Text (100% Legibility)
  static const secondary = Color(0xFF8E2433); // Deep Oxblood (buttons, bars, fills)
  static const onSecondary = Color(0xFFF6F3ED); // Linen text on oxblood fills
  static const accentText = Color(0xFFD0485A); // Oxblood Blush for small accent text on black
  static const secondaryContainer = Color(0xFF2A0E12); // Oxblood-tinted chip / track fill
  static const onSurfaceVariant = Color(0xFFB3B3B3); // Crisp High Contrast Subtext
  static const outlineVariant = Color(0xFF1E1E1E); // Pitch Black Subtle Border

  static const themeNotes = Color(0xFFD0485A);
  static const themeTasks = Color(0xFFD0485A);
  static const themePlanner = Color(0xFFD0485A);
  static const themeExpenses = Color(0xFFD0485A);
}

class AppDarkTheme {
  static ThemeData get darkTheme {
    return AppComponentTheme.apply(dark: true, ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppDarkColors.background,
      fontFamilyFallback: const ['Segoe UI Emoji', 'Apple Color Emoji', 'Noto Color Emoji', 'sans-serif'],
      colorScheme: const ColorScheme.dark(
        surface: AppDarkColors.surface,
        primary: AppDarkColors.primary,
        secondary: AppDarkColors.secondary,
        onSecondary: AppDarkColors.onSecondary,
        secondaryContainer: AppDarkColors.secondaryContainer,
        onSecondaryContainer: AppDarkColors.accentText,
        onSurfaceVariant: AppDarkColors.onSurfaceVariant,
        outlineVariant: AppDarkColors.outlineVariant,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: const Color(0xFF0D0B0A),
        dialBackgroundColor: const Color(0xFF191614),
        dialHandColor: AppDarkColors.secondary,
        dialTextColor: const Color(0xFFF6F3ED),
        entryModeIconColor: AppDarkColors.accentText,
        hourMinuteColor: const Color(0xFF26211E),
        hourMinuteTextColor: const Color(0xFFF6F3ED),
        dayPeriodColor: const Color(0xFF26211E),
        dayPeriodTextColor: const Color(0xFFF6F3ED),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF262220), width: 1),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppDarkColors.surfaceContainerHigh,
        titleTextStyle: TextStyle(color: AppDarkColors.primary, fontSize: 20, fontWeight: FontWeight.bold),
        contentTextStyle: TextStyle(color: AppDarkColors.onSurfaceVariant, fontSize: 14),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppDarkColors.surfaceContainerHigh,
        labelStyle: TextStyle(color: AppDarkColors.primary),
        secondarySelectedColor: AppDarkColors.secondary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppDarkColors.surfaceContainerHigh,
        labelStyle: const TextStyle(color: AppDarkColors.onSurfaceVariant),
        hintStyle: const TextStyle(color: AppDarkColors.onSurfaceVariant),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.bodoniModa(fontSize: 38, fontWeight: FontWeight.bold, color: AppDarkColors.primary),
        headlineLarge: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: AppDarkColors.primary),
        titleLarge: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: AppDarkColors.primary),
        titleMedium: GoogleFonts.dmSans(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppDarkColors.primary),
        bodyLarge: GoogleFonts.dmSans(fontSize: 16, color: AppDarkColors.primary),
        bodyMedium: GoogleFonts.dmSans(fontSize: 14.5, color: AppDarkColors.onSurfaceVariant),
        labelSmall: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppDarkColors.accentText),
      ),
    ));
  }
}
