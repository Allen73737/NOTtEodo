import 'package:flutter/material.dart';

abstract class AppColors {
  // Core Serene Curation Palette
  static const Color background = Color(0xFFFEF9EE); // Warm Cream Canvas
  static const Color primary = Color(0xFF16282C); // Midnight Teal
  static const Color primaryContainer = Color(0xFF2C3E42); // Deep Slate Teal
  static const Color secondary = Color(0xFFD9725B); // Deep Terracotta Accent
  static const Color secondaryContainer = Color(0xFFFE8F77); // Soft Terracotta
  static const Color tertiary = Color(0xFF262621); // Warm Dark Charcoal
  
  static const Color surfaceDim = Color(0xFFDEDACF);
  static const Color surfaceContainer = Color(0xFFF3EDE2); // Glass Fill Base
  static const Color surfaceContainerHigh = Color(0xFFEDE8DD);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  
  static const Color onSurface = Color(0xFF1D1C15); // Primary Text
  static const Color onSurfaceVariant = Color(0xFF424849); // Muted Text
  static const Color outline = Color(0xFF727879);
  static const Color outlineVariant = Color(0xFFC2C7C9);
  static const Color error = Color(0xFFBA1A1A);

  // Module Tonal Accents
  static const Color themeNotes = Color(0xFFFEF9EE);
  static const Color themeTasks = Color(0xFFD9725B);
  static const Color themePlanner = Color(0xFF7E998A);
  static const Color themeWardrobe = Color(0xFFE9E4D9);
  static const Color themeExpenses = Color(0xFF6B7A63);
  static const Color themeSplitter = Color(0xFFC88552);
  static const Color themeJournal = Color(0xFFC28E8E);
  static const Color themeTravel = Color(0xFF4F7D8C);

  // Pitch Black OLED Dark Mode Tokens
  static const Color darkBackground = Color(0xFF000000); // Pure Pitch Black OLED
  static const Color darkSurface = Color(0xFF000000); // Pure Pitch Black OLED Surface
  static const Color darkSurfaceHigh = Color(0xFF0A0A0A); // High Contrast Pitch Surface
  static const Color darkCard = Color(0xFF000000); // Pure Pitch Black Card
  static const Color darkBorder = Color(0xFF1E1E1E); // Crisp Obsidian Hairline Border
  static const Color darkTextPrimary = Color(0xFFF6F3ED); // Crisp Linen White Primary Text
  static const Color darkTextSecondary = Color(0xFFA6A096); // Warm Muted Subtext

  // Haute Horlogerie Sovereign Gold Tokens
  static const Color goldPrimary = Color(0xFFD4AF37); // Imperial Champagne Gold
  static const Color goldLight = Color(0xFFE8C872); // Luminous Gilt Sheen
  static const Color goldMuted = Color(0xFFB39230); // Brushed Satin Gold
  static const Color goldDark = Color(0xFF6B581E); // Antique Champlevé Bronze
  static const Color goldSurfaceDark = Color(0xFF161410); // Deep Obsidian Gold Tint
  static const Color goldSurfaceLight = Color(0xFFF9F5EC); // Florentine Cream Gilt Tint
  static const Color goldBorderDark = Color(0xFF332D20); // Refined Horological Hairline Border (Dark)
  static const Color goldBorderLight = Color(0xFFE8DEC8); // Refined Horological Hairline Border (Light)
}
