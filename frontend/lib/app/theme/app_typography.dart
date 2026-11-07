import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract class AppTypography {
  // Display LG (Bodoni Moda Serif)
  static TextStyle displayLg = GoogleFonts.bodoniModa(
    fontSize: 44,
    fontWeight: FontWeight.bold,
    height: 1.1,
    letterSpacing: -0.8,
    color: AppColors.primary,
  );

  // Headline LG (Bodoni Moda Serif)
  static TextStyle headlineLg = GoogleFonts.bodoniModa(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.primary,
  );

  // Body Large (DM Sans)
  static TextStyle bodyLg = GoogleFonts.dmSans(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    height: 1.6,
    letterSpacing: 0.2,
    color: AppColors.onSurface,
  );

  // Body Medium (DM Sans)
  static TextStyle bodyMd = GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0.1,
    color: AppColors.onSurface,
  );

  // Label Small Architectural Tracking (DM Sans)
  static TextStyle labelSm = GoogleFonts.dmSans(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: 1.2,
    color: AppColors.onSurfaceVariant,
  );

  // Label Medium (DM Sans)
  static TextStyle labelMd = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.4,
    color: AppColors.onSurfaceVariant,
  );

  static const List<String> availableFonts = [
    'DM Sans',
    'Inter',
    'Space Grotesk',
    'Bodoni Moda',
    'Playfair Display',
    'Courier Prime',
    'Plus Jakarta Sans',
    'Outfit',
    'Lora',
  ];

  static const Map<String, String> fontDescriptions = {
    'DM Sans': 'Clean, balanced geometric sans-serif',
    'Inter': 'Ultra-crisp, precision screen typography',
    'Space Grotesk': 'Technical, contemporary monospace flavor',
    'Bodoni Moda': 'Haute couture editorial serif',
    'Playfair Display': 'Classic, expressive high-contrast serif',
    'Courier Prime': 'Authentic typewriter monospaced prose',
    'Plus Jakarta Sans': 'Modern tech-forward aesthetic',
    'Outfit': 'Smooth, rounded geometric warmth',
    'Lora': 'Refined, literary bookish serif',
  };

  /// Dynamically resolves a TextStyle using the requested Google Font family.
  /// Falls back smoothly to DM Sans or default TextStyle if unavailable.
  static TextStyle getStyle(
    String? fontFamily, {
    TextStyle? baseStyle,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    final family = (fontFamily == null || fontFamily == 'Default' || fontFamily.isEmpty)
        ? 'DM Sans'
        : fontFamily;

    try {
      return GoogleFonts.getFont(
        family,
        textStyle: baseStyle,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      );
    } catch (_) {
      return GoogleFonts.dmSans(
        textStyle: baseStyle,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      );
    }
  }
}
