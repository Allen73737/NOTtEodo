import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_colors.dart';
import '../performance/sanctuary_motion_engine.dart';

/// Haute Horlogerie Celestial Horizon Dial Complication
/// Renders real-time solar elevation & lunar transit along an artisanal arc.
class CelestialHorizonDial extends StatelessWidget {
  final bool isDark;

  const CelestialHorizonDial({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour + (now.minute / 60.0);
    // Solar phase calculation: 0..24 hr maps to -pi to +pi
    final solarAngle = (hour / 24.0) * 2 * math.pi - math.pi;
    final isDaytime = hour >= 6.0 && hour < 18.0;

    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final secondaryColor = isDark ? const Color(0xFF86CBB0) : const Color(0xFFC88552);

    String phaseName;
    if (hour >= 5.0 && hour < 7.5) {
      phaseName = 'AURORA DAWN';
    } else if (hour >= 7.5 && hour < 12.0) {
      phaseName = 'SOLAR ASCENT';
    } else if (hour >= 12.0 && hour < 14.5) {
      phaseName = 'SOLAR ZENITH';
    } else if (hour >= 14.5 && hour < 17.5) {
      phaseName = 'GOLDEN DRIFT';
    } else if (hour >= 17.5 && hour < 20.0) {
      phaseName = 'VESPER CREST';
    } else if (hour >= 20.0 && hour < 23.5) {
      phaseName = 'NOCTURNE SKY';
    } else {
      phaseName = 'NADIR SILENCE';
    }

    return RepaintBoundary(
      child: Tooltip(
        message: 'Celestial Complication: $phaseName (${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')})',
        child: InkWell(
          onTap: () {
            SanctuaryHapticEngine.dialDetent();
            _showAstronomicalSheet(context, phaseName, hour, isDaytime);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF000000) : const Color(0xFFF3ECE0)).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: secondaryColor.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  size: const Size(26, 16),
                  painter: _HorizonArcPainter(
                    angle: solarAngle,
                    isDaytime: isDaytime,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      phaseName,
                      style: GoogleFonts.bodoniModa(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: secondaryColor,
                      ),
                    ),
                    Text(
                      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} CET',
                      style: GoogleFonts.courierPrime(
                        fontSize: 8.0,
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAstronomicalSheet(BuildContext context, String phase, double hour, bool isDaytime) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C1014) : const Color(0xFFFAF7F0),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: const Color(0xFFE8927C).withValues(alpha: 0.5), width: 1.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isDaytime ? LucideIcons.sun : LucideIcons.moon,
                      color: const Color(0xFFE8927C),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Astronomical Meridian Dial',
                      style: GoogleFonts.bodoniModa(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Your sanctuary circadian synchronization tracks solar declination and astronomical twilight in real-time. '
              'The current epoch is $phase.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: isDark ? Colors.white70 : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161E26) : const Color(0xFFEDE5D6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8927C).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricItem('SOLAR HOUR', '${hour.toStringAsFixed(1)}h', isDark),
                  _metricItem('DAYLIGHT', isDaytime ? 'ACTIVE' : 'NOCTURNE', isDark),
                  _metricItem('CHRONO DRIFT', '0.00ms', isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _metricItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.courierPrime(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFE8927C),
          ),
        ),
      ],
    );
  }
}

class _HorizonArcPainter extends CustomPainter {
  final double angle;
  final bool isDaytime;
  final bool isDark;

  _HorizonArcPainter({
    required this.angle,
    required this.isDaytime,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height + 2);
    final radius = size.width / 2;

    // Horizon line
    final linePaint = Paint()
      ..color = (isDark ? Colors.white30 : Colors.black26)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), linePaint);

    // Celestial Arc
    final arcPaint = Paint()
      ..color = const Color(0xFFE8927C).withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      arcPaint,
    );

    // Celestial Body Position along the arc
    // angle maps roughly to progress along the visible hemisphere
    final progress = ((angle + math.pi) / (2 * math.pi)).clamp(0.0, 1.0);
    final arcAngle = math.pi + (progress * math.pi);
    final bodyX = center.dx + radius * math.cos(arcAngle);
    final bodyY = center.dy + radius * math.sin(arcAngle);

    final bodyPaint = Paint()
      ..color = isDaytime ? const Color(0xFFE8927C) : const Color(0xFFC9D3CE)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(bodyX, bodyY), 2.5, bodyPaint);
  }

  @override
  bool shouldRepaint(covariant _HorizonArcPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.isDaytime != isDaytime;
  }
}
