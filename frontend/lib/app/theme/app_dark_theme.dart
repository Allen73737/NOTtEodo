import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppDarkColors {
  static const background = Color(0xFF000000); // Pure Pitch Black (OLED)
  static const surface = Color(0xFF000000); // Pure Pitch Black OLED Surface
  static const surfaceContainerHigh = Color(0xFF0A0A0A); // Ultra-Deep Obsidian Card
  static const surfaceDim = Color(0xFF000000);

  static const primary = Color(0xFFFFFFFF); // Crisp Pure White Text (100% Legibility)
  static const secondary = Color(0xFFE8927C); // Vibrant Terracotta Accent
  static const onSurfaceVariant = Color(0xFFB3B3B3); // Crisp High Contrast Subtext
  static const outlineVariant = Color(0xFF1E1E1E); // Pitch Black Subtle Border

  static const themeNotes = Color(0xFFEAB368);
  static const themeTasks = Color(0xFF86CBB0);
  static const themePlanner = Color(0xFFB5C9BE);
  static const themeExpenses = Color(0xFFE8927C);
}

class AppDarkTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppDarkColors.background,
      fontFamilyFallback: const ['Segoe UI Emoji', 'Apple Color Emoji', 'Noto Color Emoji', 'sans-serif'],
      colorScheme: const ColorScheme.dark(
        surface: AppDarkColors.surface,
        primary: AppDarkColors.primary,
        secondary: AppDarkColors.secondary,
        onSurfaceVariant: AppDarkColors.onSurfaceVariant,
        outlineVariant: AppDarkColors.outlineVariant,
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
        titleMedium: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppDarkColors.primary),
        bodyLarge: GoogleFonts.dmSans(fontSize: 16, color: AppDarkColors.primary),
        bodyMedium: GoogleFonts.dmSans(fontSize: 14, color: AppDarkColors.onSurfaceVariant),
        labelSmall: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppDarkColors.secondary),
      ),
    );
  }
}
