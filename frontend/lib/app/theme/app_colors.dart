import 'package:flutter/material.dart';

abstract class AppColors {
  // Core Ivory & Oxblood Palette (Ivory light mode, Pitch Black OLED dark mode, Deep Oxblood accent)
  static const Color background = Color(0xFFF7F3EE); // Ivory
  static const Color primary = Color(0xFF1A1614); // Obsidian Charcoal
  static const Color primaryContainer = Color(0xFF292524); // Warm Stone Obsidian
  static const Color secondary = Color(0xFF7A1F2B); // Oxblood Accent
  static const Color secondaryContainer = Color(0xFFB5505E); // Rosewood Oxblood
  static const Color tertiary = Color(0xFF262621); // Warm Dark Charcoal

  static const Color surfaceDim = Color(0xFFE2DDD7);
  static const Color surfaceContainer = Color(0xFFEFE8E1); // Ivory fill base
  static const Color surfaceContainerHigh = Color(0xFFE8DFD6);
  static const Color surfaceLowest = Color(0xFFFFFFFF);

  static const Color onSurface = Color(0xFF1D1C15); // Primary Text
  static const Color onSurfaceVariant = Color(0xFF424849); // Muted Text
  static const Color outline = Color(0xFF727879);
  static const Color outlineVariant = Color(0xFFC2C7C9);
  static const Color error = Color(0xFFBA1A1A);

  // Module Tonal Accents (Zero Green / Zero Teal / Zero Blue / Zero Neon Yellow)
  static const Color themeNotes = Color(0xFFF7F3EE);
  static const Color themeTasks = Color(0xFF7A1F2B);
  static const Color themePlanner = Color(0xFF7A1F2B);
  static const Color themeWardrobe = Color(0xFFE9E4D9);
  static const Color themeExpenses = Color(0xFF9B3B47); // Muted Oxblood Clay
  static const Color themeSplitter = Color(0xFF7A1F2B);
  static const Color themeJournal = Color(0xFFB5505E);
  static const Color themeTravel = Color(0xFF9E7B56); // Antique Warm Bronze

  // Pitch Black OLED Dark Mode Tokens
  static const Color darkBackground = Color(0xFF000000); // Pure Pitch Black OLED
  static const Color darkSurface = Color(0xFF000000); // Pure Pitch Black OLED Surface
  static const Color darkSurfaceHigh = Color(0xFF0A0A0A); // High Contrast Pitch Surface
  static const Color darkCard = Color(0xFF000000); // Pure Pitch Black Card
  static const Color darkBorder = Color(0xFF1E1E1E); // Crisp Obsidian Hairline Border
  static const Color darkTextPrimary = Color(0xFFF6F3ED); // Crisp Linen White Primary Text
  static const Color darkTextSecondary = Color(0xFFA89C9C); // Warm Muted Subtext

  // Oxblood & Obsidian Luxe Tokens (legacy "gold" names kept so existing call sites compile)
  static const Color goldPrimary = Color(0xFF8E2433); // Deep Oxblood (fills in both modes)
  static const Color goldLight = Color(0xFFE2B6BB); // Oxblood Blush (accent text on black)
  static const Color goldMuted = Color(0xFF9B3B47); // Muted Oxblood Clay
  static const Color goldDark = Color(0xFF5A1620); // Oxblood Noir
  static const Color goldSurfaceDark = Color(0xFF1A0E10); // Deep Obsidian Oxblood Tint
  static const Color goldSurfaceLight = Color(0xFFF3EEE8); // Ivory Oxblood Tint
  static const Color goldBorderDark = Color(0xFF2E1A1D); // Oxblood Obsidian Hairline Border
  static const Color goldBorderLight = Color(0xFFE2D8CF); // Ivory Hairline Border
}
