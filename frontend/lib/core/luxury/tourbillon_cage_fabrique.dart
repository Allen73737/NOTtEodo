import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Tourbillon Cage Kinetic Inertia Floating Fabrique
/// Multi-axis wireframe tourbillon cage rotating continuously to symbolize
/// kinetic resistance to digital gravity and chronometric precision.
class TourbillonCageFabrique extends StatefulWidget {
  final double size;

  const TourbillonCageFabrique({
    super.key,
    this.size = 72.0,
  });

  @override
  State<TourbillonCageFabrique> createState() => _TourbillonCageFabriqueState();
}

class _TourbillonCageFabriqueState extends State<TourbillonCageFabrique>
    with SingleTickerProviderStateMixin {
  late AnimationController _tourbillonController;

  @override
  void initState() {
    super.initState();
    // 60-second rotation cycle standard for 1-minute tourbillon cages
    _tourbillonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12), // Accelerated for fluid UI appreciation
    )..repeat();
  }

  @override
  void dispose() {
    _tourbillonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _tourbillonController,
        builder: (context, child) {
          return CustomPaint(
            painter: _TourbillonPainter(progress: _tourbillonController.value),
          );
        },
      ),
    );
  }
}

class _TourbillonPainter extends CustomPainter {
  final double progress;

  _TourbillonPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;
    final angle = progress * 2 * math.pi;

    // 1. Titanium Carriage Bridge (outer rotating bridge)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final titaniumPaint = Paint()
      ..color = const Color(0xFFC0C5CF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Outer cage ring
    canvas.drawCircle(Offset.zero, radius, titaniumPaint);

    // 3 curved lyre arms (Breguet-style tourbillon cage bridge)
    final lyrePaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    for (int i = 0; i < 3; i++) {
      final armAngle = (i * 2 * math.pi) / 3;
      final x = math.cos(armAngle) * radius;
      final y = math.sin(armAngle) * radius;

      final path = Path();
      path.moveTo(0, 0);
      path.quadraticBezierTo(x * 0.5, y * 0.8, x, y);
      canvas.drawPath(path, lyrePaint);
    }

    // Secondary inner counter-rotating balance
    canvas.rotate(-angle * 2.5);
    final innerWheelPaint = Paint()
      ..color = const Color(0xFFE5C158)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(Offset.zero, radius * 0.55, innerWheelPaint);

    // Central Ruby Pivot
    final jewelPaint = Paint()
      ..color = const Color(0xFFD81B60)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 3.5, jewelPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TourbillonPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
