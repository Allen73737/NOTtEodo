import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Astronomical Moonphase & Synodic Lunation Disc
/// Breguet-style complication calculating the 29.53-day astronomical synodic cycle
/// on a midnight blue enamel aperture with 24K gold foil stars.
class AstronomicalMoonphaseDisc extends StatelessWidget {
  final double size;
  final DateTime? date;

  const AstronomicalMoonphaseDisc({
    super.key,
    this.size = 110.0,
    this.date,
  });

  /// Computes approximate moon age (0.0 to 29.53 days)
  double get _moonAge {
    final target = date ?? DateTime.now();
    // Known reference new moon: January 11, 2024 at 11:57 UTC
    final refNewMoon = DateTime.utc(2024, 1, 11, 11, 57);
    final diffDays = target.toUtc().difference(refNewMoon).inSeconds / 86400.0;
    const synodicMonth = 29.53058867;
    return diffDays % synodicMonth;
  }

  String get _phaseName {
    final age = _moonAge;
    if (age < 1.84) return 'New Moon';
    if (age < 5.53) return 'Waxing Crescent';
    if (age < 9.22) return 'First Quarter';
    if (age < 12.91) return 'Waxing Gibbous';
    if (age < 16.61) return 'Full Moon';
    if (age < 20.30) return 'Waning Gibbous';
    if (age < 23.99) return 'Last Quarter';
    if (age < 27.68) return 'Waning Crescent';
    return 'New Moon';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFD4AF37),
              width: 2.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: CustomPaint(
              painter: _MoonAperturePainter(moonAge: _moonAge),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _phaseName.toUpperCase(),
          style: GoogleFonts.cormorantGaramond(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
            color: const Color(0xFFD4AF37),
          ),
        ),
        Text(
          'DAY ${_moonAge.toStringAsFixed(1)} / 29.5',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}

class _MoonAperturePainter extends CustomPainter {
  final double moonAge;

  _MoonAperturePainter({required this.moonAge});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Midnight Blue Enamel Sky
    final skyPaint = Paint()..color = const Color(0xFF0A0F14);

    canvas.drawRect(rect, skyPaint);

    // 2. 24K Gold Foil Stars
    final starPaint = Paint()
      ..color = const Color(0xFFFFDF73)
      ..style = PaintingStyle.fill;

    final starPositions = [
      Offset(size.width * 0.22, size.height * 0.25),
      Offset(size.width * 0.78, size.height * 0.28),
      Offset(size.width * 0.48, size.height * 0.16),
      Offset(size.width * 0.85, size.height * 0.65),
      Offset(size.width * 0.15, size.height * 0.68),
    ];

    for (final pos in starPositions) {
      canvas.drawCircle(pos, 1.0, starPaint);
    }

    // 3. Golden Moon Disc & Shadow Cover
    final moonRadius = size.width * 0.28;
    final moonCenter = center;

    // Full Moon base gold
    final goldMoonPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(moonCenter, moonRadius, goldMoonPaint);

    // Phase Shadow: fraction 0 (new) to 1 (full) to 2 (new)
    final phaseFraction = (moonAge / 29.53058867) * 2;
    final shadowPaint = Paint()
      ..color = const Color(0xFF070B16).withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;

    // Shift shadow offset across disc
    final shadowX = (phaseFraction - 1.0) * (moonRadius * 2.1);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: moonCenter, radius: moonRadius)));
    canvas.drawCircle(moonCenter.translate(shadowX, 0), moonRadius, shadowPaint);
    canvas.restore();

    // 4. Double-Arch Breguet Aperture Mask
    final maskPaint = Paint()
      ..color = const Color(0xFF0B0D13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(center.dx, size.height * 0.9), radius: size.width * 0.45),
      math.pi,
      math.pi,
      false,
      maskPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MoonAperturePainter oldDelegate) =>
      oldDelegate.moonAge != moonAge;
}
