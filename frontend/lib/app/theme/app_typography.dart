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
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 1.2,
    color: AppColors.onSurfaceVariant,
  );
}
