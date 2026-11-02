import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Guilloché Sunburst Sub-Dial Gauge
/// Tri-compax circular chronograph sub-register with spiral engine-turned
/// guilloché ripples and diamond-cut beveled chapter rings.
class GuillocheSubdialGauge extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final String label;
  final String readout;
  final double size;

  const GuillocheSubdialGauge({
    super.key,
    required this.value,
    required this.label,
    required this.readout,
    this.size = 110.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _SubdialPainter(value: value.clamp(0.0, 1.0)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.cormorantGaramond(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: const Color(0xFFD4AF37),
          ),
        ),
        Text(
          readout,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SubdialPainter extends CustomPainter {
  final double value;

  _SubdialPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;

    // 1. Recessed Sunburst Guilloché Dial
    final dialPaint = Paint()
      ..color = const Color(0xFF161619)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, dialPaint);

    final bezelPaint = Paint()
      ..color = const Color(0xFF8A7322)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, radius, bezelPaint);

    // Radiating spiral sunray lines
    final sunrayPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.18)
      ..strokeWidth = 0.8;

    for (int i = 0; i < 24; i++) {
      final angle = (i * 2 * math.pi) / 24;
      final x = center.dx + math.cos(angle) * (radius - 2);
      final y = center.dy + math.sin(angle) * (radius - 2);
      canvas.drawLine(center, Offset(x, y), sunrayPaint);
    }

    // 2. Active Indicator Hand (Blued Steel)
    final handAngle = (value * 2 * math.pi) - math.pi / 2;
    final handLength = radius * 0.75;

    final handPaint = Paint()
      ..color = const Color(0xFFC88552)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final tipX = center.dx + math.cos(handAngle) * handLength;
    final tipY = center.dy + math.sin(handAngle) * handLength;
    canvas.drawLine(center, Offset(tipX, tipY), handPaint);

    // Center Gold Pivot
    final pivotPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.5, pivotPaint);
  }

  @override
  bool shouldRepaint(covariant _SubdialPainter oldDelegate) =>
      oldDelegate.value != value;
}
