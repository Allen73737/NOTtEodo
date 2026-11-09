import 'package:flutter/material.dart';

abstract class AppColors {
  // Core Serene Curation Palette (Strictly Pitch Black OLED, Obsidian, Terracotta-infused Porcelain White, and Warm Gold)
  static const Color background = Color(0xFFFAF5F2); // Porcelain White infused with delicate warm terracotta
  static const Color primary = Color(0xFF1C1917); // Obsidian Charcoal (Zero Teal / Zero Blue)
  static const Color primaryContainer = Color(0xFF292524); // Warm Stone Obsidian
  static const Color secondary = Color(0xFFD9725B); // Deep Terracotta Accent
  static const Color secondaryContainer = Color(0xFFFE8F77); // Soft Terracotta
  static const Color tertiary = Color(0xFF262621); // Warm Dark Charcoal
  
  static const Color surfaceDim = Color(0xFFE2DDD7);
  static const Color surfaceContainer = Color(0xFFF4ECE8); // Warm porcelain fill base
  static const Color surfaceContainerHigh = Color(0xFFEEE4DF);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  
  static const Color onSurface = Color(0xFF1D1C15); // Primary Text
  static const Color onSurfaceVariant = Color(0xFF424849); // Muted Text
  static const Color outline = Color(0xFF727879);
  static const Color outlineVariant = Color(0xFFC2C7C9);
  static const Color error = Color(0xFFBA1A1A);

  // Module Tonal Accents (Zero Green / Zero Teal / Zero Blue / Zero Neon Yellow)
  static const Color themeNotes = Color(0xFFFAF5F2);
  static const Color themeTasks = Color(0xFFD9725B);
  static const Color themePlanner = Color(0xFFD9725B);
  static const Color themeWardrobe = Color(0xFFE9E4D9);
  static const Color themeExpenses = Color(0xFFC87A5B); // Warm Terracotta Clay
  static const Color themeSplitter = Color(0xFFD9725B);
  static const Color themeJournal = Color(0xFFE8927C);
  static const Color themeTravel = Color(0xFF9E7B56); // Antique Warm Bronze

  // Pitch Black OLED Dark Mode Tokens
  static const Color darkBackground = Color(0xFF000000); // Pure Pitch Black OLED
  static const Color darkSurface = Color(0xFF000000); // Pure Pitch Black OLED Surface
  static const Color darkSurfaceHigh = Color(0xFF0A0A0A); // High Contrast Pitch Surface
  static const Color darkCard = Color(0xFF000000); // Pure Pitch Black Card
  static const Color darkBorder = Color(0xFF1E1E1E); // Crisp Obsidian Hairline Border
  static const Color darkTextPrimary = Color(0xFFF6F3ED); // Crisp Linen White Primary Text
  static const Color darkTextSecondary = Color(0xFFA6A096); // Warm Muted Subtext

  // Warm Terracotta & Obsidian Luxe Tokens (Strictly Zero Gold / Zero Yellow / Zero Blue / Zero Teal / Zero Green)
  static const Color goldPrimary = Color(0xFFD9725B); // Warm Terracotta (replaces gold)
  static const Color goldLight = Color(0xFFE8927C); // Soft Terracotta Rose
  static const Color goldMuted = Color(0xFFC87A5B); // Terracotta Clay
  static const Color goldDark = Color(0xFF8C3E2D); // Deep Terracotta Noir
  static const Color goldSurfaceDark = Color(0xFF1A1311); // Deep Obsidian Terracotta Tint
  static const Color goldSurfaceLight = Color(0xFFF9F1ED); // Porcelain Warm Terracotta Tint
  static const Color goldBorderDark = Color(0xFF332320); // Warm Obsidian Hairline Border
  static const Color goldBorderLight = Color(0xFFE8DAD5); // Porcelain Hairline Border
}
