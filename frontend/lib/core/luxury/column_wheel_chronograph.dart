import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Haute Horlogerie Column-Wheel Chronograph Dial
/// Models the physical column wheel and pivoting steel operating lever of a luxury
/// chronograph movement, clicking forward with authentic mechanical inertia on start/stop.
class ColumnWheelChronograph extends StatefulWidget {
  final bool isRunning;
  final VoidCallback onToggle;
  final Color? steelColor;
  final Color? goldColor;

  const ColumnWheelChronograph({
    super.key,
    required this.isRunning,
    required this.onToggle,
    this.steelColor,
    this.goldColor,
  });

  @override
  State<ColumnWheelChronograph> createState() => _ColumnWheelChronographState();
}

class _ColumnWheelChronographState extends State<ColumnWheelChronograph>
    with SingleTickerProviderStateMixin {
  late AnimationController _leverController;
  int _pillarStep = 0;

  @override
  void initState() {
    super.initState();
    _leverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void didUpdateWidget(covariant ColumnWheelChronograph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRunning != widget.isRunning) {
      _pillarStep = (_pillarStep + 1) % 6;
      _leverController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _leverController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.heavyImpact();
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steel = widget.steelColor ?? (isDark ? const Color(0xFFC0C5CC) : const Color(0xFF5A626A));
    final gold = widget.goldColor ?? const Color(0xFFEAB368);

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _leverController,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(90, 90),
            painter: _ColumnWheelPainter(
              isRunning: widget.isRunning,
              leverProgress: _leverController.value,
              stepIndex: _pillarStep,
              steelColor: steel,
              goldColor: gold,
              isDark: isDark,
            ),
          );
        },
      ),
    );
  }
}

class _ColumnWheelPainter extends CustomPainter {
  final bool isRunning;
  final double leverProgress;
  final int stepIndex;
  final Color steelColor;
  final Color goldColor;
  final bool isDark;

  _ColumnWheelPainter({
    required this.isRunning,
    required this.leverProgress,
    required this.stepIndex,
    required this.steelColor,
    required this.goldColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.58, size.height * 0.52);
    const wheelRadius = 24.0;
    const anglePerStep = (2 * pi) / 6;
    final currentAngle = stepIndex * anglePerStep + (leverProgress * anglePerStep * 0.35);

    // 1. Recessed Beveled Movement Well
    final wellPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDark ? const Color(0xFF101010) : const Color(0xFFECE7DF);
    canvas.drawCircle(center, wheelRadius + 14, wellPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = goldColor.withValues(alpha: 0.3);
    canvas.drawCircle(center, wheelRadius + 14, borderPaint);

    // 2. Base Ratchet Wheel
    final basePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDark ? const Color(0xFF1E2024) : const Color(0xFFD6D0C5);
    canvas.drawCircle(center, wheelRadius, basePaint);

    // 3. Six Vertical Column Pillars (Castellated Columns)
    for (int i = 0; i < 6; i++) {
      final pillarAngle = currentAngle + (i * anglePerStep);
      final px = center.dx + (wheelRadius * 0.68) * cos(pillarAngle);
      final py = center.dy + (wheelRadius * 0.68) * sin(pillarAngle);

      final pillarPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFF7EA),
            goldColor,
            const Color(0xFF8C5C26),
          ],
        ).createShader(Rect.fromCircle(center: Offset(px, py), radius: 5.5));

      canvas.drawCircle(Offset(px, py), 5.5, pillarPaint);
      canvas.drawCircle(
        Offset(px, py),
        5.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Colors.black26,
      );
    }

    // 4. Blued Steel Center Screw
    final screwPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF1A3D66); // Horological Blued Steel
    canvas.drawCircle(center, 4.5, screwPaint);
    canvas.drawLine(
      Offset(center.dx - 2.8, center.dy),
      Offset(center.dx + 2.8, center.dy),
      Paint()..color = Colors.white70..strokeWidth = 0.9,
    );

    // 5. Operating Lever (Steel Hammer that drops between pillars)
    final leverAngle = sin(leverProgress * pi) * 0.18;
    final leverStart = Offset(size.width * 0.12, size.height * 0.22);
    final leverTip = Offset(center.dx - (wheelRadius * 0.65) + (isRunning ? 2.0 : -2.0), center.dy);

    final leverPath = Path()
      ..moveTo(leverStart.dx, leverStart.dy)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.45 + (leverAngle * 10), leverTip.dx, leverTip.dy)
      ..lineTo(leverTip.dx - 4, leverTip.dy + 8)
      ..lineTo(leverStart.dx - 6, leverStart.dy + 12)
      ..close();

    final steelPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [steelColor.withValues(alpha: 0.9), Colors.white70, steelColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(leverPath, steelPaint);
    canvas.drawPath(
      leverPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = isDark ? Colors.white24 : Colors.black12,
    );
  }

  @override
  bool shouldRepaint(covariant _ColumnWheelPainter oldDelegate) {
    return oldDelegate.isRunning != isRunning ||
        oldDelegate.leverProgress != leverProgress ||
        oldDelegate.stepIndex != stepIndex;
  }
}
