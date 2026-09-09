import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Circadian Color Temperature & Typography Drift Service
/// Calculates solar elevation based on local time and shifts screen color temperature
/// from 6500K daylight down to 2200K candlelight, subtly boosting serif font weights at night.
class CircadianColorDriftService {
  /// Returns Kelvin temperature estimate between 2200K (night) and 6500K (noon)
  static double getEffectiveKelvin([DateTime? time]) {
    final now = time ?? DateTime.now();
    final hourFraction = now.hour + (now.minute / 60.0);

    // Diurnal sine curve peaked at 13:00 (1:00 PM)
    final solarPhase = ((hourFraction - 13.0) / 24.0) * 2 * math.pi;
    final normalizedSun = (math.cos(solarPhase) + 1.0) / 2.0; // 0.0 (night) to 1.0 (noon)

    return 2200.0 + (normalizedSun * (6500.0 - 2200.0));
  }

  /// Tint overlay color representing warmth filter
  static Color getCircadianTint([DateTime? time]) {
    final kelvin = getEffectiveKelvin(time);
    if (kelvin >= 5500) {
      return Colors.transparent;
    }
    final warmthFactor = (1.0 - (kelvin - 2200.0) / (5500.0 - 2200.0)).clamp(0.0, 1.0);
    return const Color(0xFFFF9E3B).withValues(alpha: warmthFactor * 0.12);
  }

  /// Nighttime optical font weight adjustment
  static FontWeight getAdaptiveSerifWeight([DateTime? time]) {
    final kelvin = getEffectiveKelvin(time);
    if (kelvin < 3000) {
      return FontWeight.w600; // Slightly thicker ink lines in dim candlelight
    }
    return FontWeight.w400;
  }
}
