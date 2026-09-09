import 'dart:math' as math;
import 'package:flutter/material.dart';

class VintageCompassRoseDial extends StatefulWidget {
  final double size;

  const VintageCompassRoseDial({super.key, this.size = 120.0});

  @override
  State<VintageCompassRoseDial> createState() => _VintageCompassRoseDialState();
}

class _VintageCompassRoseDialState extends State<VintageCompassRoseDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, _) {
        return Transform.rotate(
          angle: _rotationController.value * math.pi * 2,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _CompassPainter(),
          ),
        );
      },
    );
  }
}

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final brassPaint = Paint()
      ..color = const Color(0xFFC88552)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius - 4, brassPaint);

    final needlePaint = Paint()
      ..color = const Color(0xFFD9725B)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx, center.dy - radius + 8);
    path.lineTo(center.dx + 6, center.dy);
    path.lineTo(center.dx - 6, center.dy);
    path.close();

    canvas.drawPath(path, needlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
