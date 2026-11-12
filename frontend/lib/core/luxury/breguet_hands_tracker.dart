import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Precision Watchmaker Focus Dial (Breguet Pomme Hands)
/// Heated steel watchmaker hands with hollow eccentric crescents gliding
/// gracefully over a chapter ring for measuring focus sessions.
/// Styled with warm obsidian, terracotta, gold, and warm parchment (zero cyan/teal/blue).
class BreguetHandsTracker extends StatelessWidget {
  final double progress; // 0.0 to 1.0 (elapsed ratio)
  final double size;
  final String centerCaption;
  final String? timeRemainingText;
  final bool isRunning;
  final VoidCallback? onTap;

  const BreguetHandsTracker({
    super.key,
    required this.progress,
    this.size = 130.0,
    this.centerCaption = 'FOCUS',
    this.timeRemainingText,
    this.isRunning = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const terracotta = Color(0xFFD9725B);
    final subtextColor = isDark ? const Color(0xFFA89F91) : const Color(0xFF6B655B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _BreguetDialPainter(
                progress: progress.clamp(0.0, 1.0),
                isDark: isDark,
                isRunning: isRunning,
              ),
            ),
          ),
          if (timeRemainingText != null) ...[
            const SizedBox(height: 6),
            Text(
              timeRemainingText!,
              style: GoogleFonts.bodoniModa(
                fontSize: (size * 0.12).clamp(11.0, 22.0),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: isDark ? const Color(0xFFFBF8F2) : const Color(0xFF1B1917),
              ),
            ),
          ],
          if (centerCaption.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              centerCaption.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: (size * 0.075).clamp(8.5, 11.0),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.8,
                color: isRunning ? terracotta : subtextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BreguetDialPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final bool isRunning;

  _BreguetDialPainter({
    required this.progress,
    required this.isDark,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;

    // 1. Dial Face (Warm Obsidian in Dark Mode, Warm Parchment in Light Mode)
    final dialFaceColor = isDark ? const Color(0xFF0D0B0A) : const Color(0xFFFAF7F0);
    final dialPaint = Paint()
      ..color = dialFaceColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, dialPaint);

    // Bezel Rim (Executive Terracotta / Obsidian Steel — strictly NO gold/yellow)
    final bezelColor = isRunning ? const Color(0xFFD9725B) : (isDark ? const Color(0xFF332D28) : const Color(0xFFD6CEC2));
    final bezelPaint = Paint()
      ..color = bezelColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width > 80 ? 2.0 : 1.5;
    canvas.drawCircle(center, radius, bezelPaint);

    // Subtle Inner Minute Ring Track (Neutral hairline)
    final innerTrackRadius = radius * 0.85;
    final trackPaint = Paint()
      ..color = (isDark ? const Color(0xFF403832) : const Color(0xFFC8BFB2))
          .withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, innerTrackRadius, trackPaint);

    // 2. 12 Major Hour/5-Min Indices & 60 Minute Ticks
    final indexColor = isDark ? const Color(0xFFE2DDD2) : const Color(0xFF2C2825);
    final majorTickPaint = Paint()
      ..color = indexColor
      ..strokeWidth = size.width > 80 ? 1.5 : 1.0
      ..strokeCap = StrokeCap.round;

    final minorTickPaint = Paint()
      ..color = indexColor.withValues(alpha: 0.35)
      ..strokeWidth = 0.6;

    for (int i = 0; i < 60; i++) {
      final angle = (i * 2 * math.pi) / 60 - math.pi / 2;
      final isMajor = i % 5 == 0;

      final tickLength = isMajor ? (size.width > 80 ? 6.0 : 4.0) : 2.5;
      final outerX = center.dx + math.cos(angle) * (radius - 2.5);
      final outerY = center.dy + math.sin(angle) * (radius - 2.5);
      final innerX = center.dx + math.cos(angle) * (radius - 2.5 - tickLength);
      final innerY = center.dy + math.sin(angle) * (radius - 2.5 - tickLength);

      if (isMajor) {
        canvas.drawLine(Offset(outerX, outerY), Offset(innerX, innerY), majorTickPaint);
      } else if (size.width >= 100) {
        canvas.drawLine(Offset(outerX, outerY), Offset(innerX, innerY), minorTickPaint);
      }
    }

    // 3. Elapsed Arc Glow (Warm Terracotta / Gold)
    if (progress > 0.005) {
      final progressSweep = progress * 2 * math.pi;
      final arcPaint = Paint()
        ..color = const Color(0xFFD9725B).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width > 80 ? 2.5 : 1.5
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1.2),
        -math.pi / 2,
        progressSweep,
        false,
        arcPaint,
      );
    }

    // 4. Precision Breguet Pomme Hand
    // Rotates clockwise from 12 o'clock (-pi/2) matching progress
    final handAngle = (progress * 2 * math.pi) - math.pi / 2;
    final handLength = radius * 0.76;

    // Heated Obsidian/Terracotta steel (strictly NO teal/cyan)
    final handColor = isRunning
        ? const Color(0xFFD9725B) // active terracotta
        : (isDark ? const Color(0xFFF0EBE1) : const Color(0xFF1B1917)); // obsidian/cream

    final handPaint = Paint()
      ..color = handColor
      ..strokeWidth = size.width > 80 ? 2.0 : 1.4
      ..strokeCap = StrokeCap.round;

    final tipX = center.dx + math.cos(handAngle) * handLength;
    final tipY = center.dy + math.sin(handAngle) * handLength;
    canvas.drawLine(center, Offset(tipX, tipY), handPaint);

    // Open-Crescent Pomme Eyelet near the tip (Breguet signature)
    if (size.width >= 40) {
      final eyeletDist = handLength * 0.72;
      final eyeletRadius = (size.width * 0.032).clamp(2.5, 5.0);
      final eyeletCenter = Offset(
        center.dx + math.cos(handAngle) * eyeletDist,
        center.dy + math.sin(handAngle) * eyeletDist,
      );

      final eyeletPaint = Paint()
        ..color = handColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width > 80 ? 1.6 : 1.0;
      canvas.drawCircle(eyeletCenter, eyeletRadius, eyeletPaint);
    }

    // Counterweight tail (classic watchmaker balance)
    final tailLength = radius * 0.22;
    final tailX = center.dx - math.cos(handAngle) * tailLength;
    final tailY = center.dy - math.sin(handAngle) * tailLength;
    canvas.drawLine(center, Offset(tailX, tailY), handPaint);

    // 5. Center Pivot Cap (Watchmaker Terracotta Pivot)
    final centerCapPaint = Paint()
      ..color = handColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width > 80 ? 3.5 : 2.2, centerCapPaint);

    final pivotDotPaint = Paint()
      ..color = const Color(0xFFD9725B) // subtle terracotta ruby pivot
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width > 80 ? 1.5 : 1.0, pivotDotPaint);
  }

  @override
  bool shouldRepaint(covariant _BreguetDialPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isDark != isDark ||
      oldDelegate.isRunning != isRunning;
}
