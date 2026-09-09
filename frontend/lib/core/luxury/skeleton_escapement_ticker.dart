import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Skeletonized Escapement Heartbeat Ticker
/// High-horology openworked escapement balance wheel oscillating at 4Hz (28,800 vph)
/// visible through an exhibition sapphire aperture.
class SkeletonEscapementTicker extends StatefulWidget {
  final double size;
  final bool isTicking;

  const SkeletonEscapementTicker({
    super.key,
    this.size = 54.0,
    this.isTicking = true,
  });

  @override
  State<SkeletonEscapementTicker> createState() => _SkeletonEscapementTickerState();
}

class _SkeletonEscapementTickerState extends State<SkeletonEscapementTicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _oscillator;

  @override
  void initState() {
    super.initState();
    // 4Hz = 250ms per half-cycle = 500ms full harmonic oscillation
    _oscillator = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _oscillator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _oscillator,
        builder: (context, child) {
          final oscillationAngle = math.sin(_oscillator.value * math.pi) * 0.45;
          return CustomPaint(
            painter: _EscapementPainter(
              angle: widget.isTicking ? oscillationAngle : 0.0,
            ),
          );
        },
      ),
    );
  }
}

class _EscapementPainter extends CustomPainter {
  final double angle;

  _EscapementPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;

    // 1. Exhibition Sapphire Bevel Rim
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFD4AF37),
          Color(0xFF8A7322),
          Color(0xFFFFF3C4),
          Color(0xFFD4AF37),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, rimPaint);

    // 2. Openworked Balance Wheel with 3 Glucydur Spokes
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final wheelPaint = Paint()
      ..color = const Color(0xFFE5C158)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawCircle(Offset.zero, radius * 0.72, wheelPaint);

    // 3 arms
    for (int i = 0; i < 3; i++) {
      final spokeAngle = (i * 2 * math.pi) / 3;
      final x = math.cos(spokeAngle) * radius * 0.72;
      final y = math.sin(spokeAngle) * radius * 0.72;
      canvas.drawLine(Offset.zero, Offset(x, y), wheelPaint);
    }

    // Hairspring Spiral (Breguet overcoil)
    final springPaint = Paint()
      ..color = const Color(0xFF4A90E2) // Blued steel spring
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final springPath = Path();
    springPath.moveTo(0, 0);
    for (double theta = 0; theta < 6 * math.pi; theta += 0.2) {
      final r = (theta / (6 * math.pi)) * (radius * 0.42);
      springPath.lineTo(r * math.cos(theta), r * math.sin(theta));
    }
    canvas.drawPath(springPath, springPaint);

    // Center Synthetic Ruby Jewel
    final jewelPaint = Paint()
      ..color = const Color(0xFFC41E3A) // Synthetic Corundum Ruby
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 3.2, jewelPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EscapementPainter oldDelegate) =>
      oldDelegate.angle != angle;
}
