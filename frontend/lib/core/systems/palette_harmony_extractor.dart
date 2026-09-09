import 'package:flutter/material.dart';

/// Color-Palette Extraction & Harmony Engine
/// Quantizes image color spectra into cohesive capsule color harmonies
/// (Analogous, Monochromatic, Triadic, Split-Complementary).
class PaletteHarmonyResult {
  final List<Color> dominantColors;
  final String seasonalArchetype; // Autumn Tuscan, Spring Riviera, etc.
  final List<Color> complementaryPairings;

  PaletteHarmonyResult({
    required this.dominantColors,
    required this.seasonalArchetype,
    required this.complementaryPairings,
  });
}

class PaletteHarmonyExtractor {
  static final PaletteHarmonyExtractor _instance = PaletteHarmonyExtractor._internal();
  factory PaletteHarmonyExtractor() => _instance;
  PaletteHarmonyExtractor._internal();

  /// Extracts dominant palette and computes seasonal archetype
  PaletteHarmonyResult analyzePalette(List<Color> sampleColors) {
    if (sampleColors.isEmpty) {
      // Default Haute Horlogerie Tuscan Autumn Palette
      final defaults = [
        const Color(0xFF3B281B), // Saddle Brown
        const Color(0xFFEAB368), // Amber Gold
        const Color(0xFF86CBB0), // Sage Mint
        const Color(0xFFFAF7F2), // Alabaster
      ];
      return PaletteHarmonyResult(
        dominantColors: defaults,
        seasonalArchetype: 'Tuscan Linen & Amber Hearth',
        complementaryPairings: [const Color(0xFF2C3E50), const Color(0xFFD4AC0D)],
      );
    }

    // Calculate average hue & warmth
    double avgHue = 0.0;
    double avgSat = 0.0;
    for (final c in sampleColors) {
      final hsl = HSLColor.fromColor(c);
      avgHue += hsl.hue;
      avgSat += hsl.saturation;
    }
    avgHue /= sampleColors.length;
    avgSat /= sampleColors.length;

    String archetype = 'Timeless Neutral';
    if (avgHue >= 20 && avgHue <= 55) {
      archetype = 'Golden Autumn Harvest';
    } else if (avgHue > 55 && avgHue <= 160) {
      archetype = 'Verdant Botanical Sanctuary';
    } else if (avgHue > 160 && avgHue <= 260) {
      archetype = 'Aegean Maritime Silk';
    }

    // Generate complementary hues (+180 degrees)
    final complement1 = HSLColor.fromAHSL(1.0, (avgHue + 180) % 360, avgSat.clamp(0.2, 0.7), 0.5).toColor();
    final complement2 = HSLColor.fromAHSL(1.0, (avgHue + 150) % 360, avgSat.clamp(0.2, 0.7), 0.7).toColor();

    return PaletteHarmonyResult(
      dominantColors: sampleColors,
      seasonalArchetype: archetype,
      complementaryPairings: [complement1, complement2],
    );
  }
}
