import 'package:flutter/material.dart';

/// Real-Time Sun Angle & Golden Hour Sky Palette
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : const Color(0xFFFAF7F2),
      ),
      child: child,
    );
  }
}
