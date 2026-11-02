import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Blued Steel Breguet Pomme Hands Progress Tracker
/// Heated-blue watchmaker hands with hollow eccentric crescents gliding
/// over an ivory enamel chapter ring for reading or session time.
class BreguetHandsTracker extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final String centerCaption;

  const BreguetHandsTracker({
    super.key,
    required this.progress,
    this.size = 130.0,
    this.centerCaption = 'MINUTES',
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
            painter: _BreguetDialPainter(progress: progress.clamp(0.0, 1.0)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          centerCaption.toUpperCase(),
          style: GoogleFonts.cormorantGaramond(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: const Color(0xFFD4AF37),
          ),
        ),
      ],
    );
  }
}

class _BreguetDialPainter extends CustomPainter {
  final double progress;

  _BreguetDialPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;

    // 1. Ivory Enamel Dial Face
    final dialPaint = Paint()
      ..color = const Color(0xFFF9F7F0)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, dialPaint);

    final bezelPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(center, radius, bezelPaint);

    // 2. Minute Track & Roman Hour Indices
    final indexPaint = Paint()
      ..color = const Color(0xFF2C2825)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 2 * math.pi) / 12 - math.pi / 2;
      final outerX = center.dx + math.cos(angle) * (radius - 3);
      final outerY = center.dy + math.sin(angle) * (radius - 3);
      final innerX = center.dx + math.cos(angle) * (radius - 8);
      final innerY = center.dy + math.sin(angle) * (radius - 8);
      canvas.drawLine(Offset(outerX, outerY), Offset(innerX, innerY), indexPaint);
    }

    // 3. Thermally Blued Steel Breguet Pomme Hand
    final handAngle = (progress * 2 * math.pi) - math.pi / 2;
    final handLength = radius * 0.78;

    final handPaint = Paint()
      ..color = const Color(0xFF2C3E42) // Midnight-teal steel
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final tipX = center.dx + math.cos(handAngle) * handLength;
    final tipY = center.dy + math.sin(handAngle) * handLength;
    canvas.drawLine(center, Offset(tipX, tipY), handPaint);

    // Open-Crescent Pomme Eyelet near tip
    final eyeletDist = handLength * 0.72;
    final eyeletCenter = Offset(
      center.dx + math.cos(handAngle) * eyeletDist,
      center.dy + math.sin(handAngle) * eyeletDist,
    );

    final eyeletPaint = Paint()
      ..color = const Color(0xFF2C3E42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(eyeletCenter, 4.0, eyeletPaint);

    // Center Golden Cap
    final centerCap = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.2, centerCap);
  }

  @override
  bool shouldRepaint(covariant _BreguetDialPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
