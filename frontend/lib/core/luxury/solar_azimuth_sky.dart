import 'package:flutter/material.dart';

/// Real-Time Sun Angle & Golden Hour Sky Gradient
/// Dynamically shifts sky illumination, solar azimuth highlights, and starlight
/// density based on local hour and minute.
class SolarAzimuthSky extends StatelessWidget {
  final Widget child;
  final DateTime? customTime;

  const SolarAzimuthSky({
    super.key,
    required this.child,
    this.customTime,
  });

  @override
  Widget build(BuildContext context) {
    final now = customTime ?? DateTime.now();
    final hourFraction = now.hour + (now.minute / 60.0);

    // Color bands according to diurnal cycle:
    // 05:00 - 08:00 Dawn (Rose Quartz & Soft Apricot)
    // 08:00 - 16:30 Solar Noon (Luminous Ivory & Alabaster)
    // 16:30 - 19:30 Golden Hour (Rich Amber & Burnished Honey)
    // 19:30 - 05:00 Starlight Sanctuary (Midnight Indigo & Obsidian)
    late List<Color> skyColors;
    late Alignment solarCenter;

    if (hourFraction >= 5.0 && hourFraction < 8.5) {
      // Dawn
      skyColors = const [Color(0xFFF7D6CD), Color(0xFFFCEFEA), Color(0xFFE8D0BA)];
      solarCenter = const Alignment(-0.8, -0.4);
    } else if (hourFraction >= 8.5 && hourFraction < 16.5) {
      // Day
      skyColors = const [Color(0xFFFAF7F2), Color(0xFFF4ECE1), Color(0xFFEFE6D8)];
      solarCenter = const Alignment(0.0, -0.9);
    } else if (hourFraction >= 16.5 && hourFraction < 19.5) {
      // Golden Hour
      skyColors = const [Color(0xFFEAB368), Color(0xFFE8927C), Color(0xFFD47355)];
      solarCenter = const Alignment(0.8, -0.3);
    } else {
      // Twilight / Night
      skyColors = const [Color(0xFF090A0F), Color(0xFF12141C), Color(0xFF1B1E2B)];
      solarCenter = const Alignment(0.5, -0.8);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: solarCenter,
          radius: 1.4,
          colors: skyColors,
        ),
      ),
      child: child,
    );
  }
}
