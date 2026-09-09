import 'dart:math' as math;
import 'package:flutter/material.dart';

class StarlightConstellationHabitGalaxy extends StatefulWidget {
  final double size;

  const StarlightConstellationHabitGalaxy({super.key, this.size = 180.0});

  @override
  State<StarlightConstellationHabitGalaxy> createState() =>
      _StarlightConstellationHabitGalaxyState();
}

class _StarlightConstellationHabitGalaxyState
    extends State<StarlightConstellationHabitGalaxy> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
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
            painter: _GalaxyPainter(),
          ),
        );
      },
    );
  }
}

class _GalaxyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final starPaint = Paint()..color = const Color(0xFFFFD700);

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      final x = center.dx + math.cos(angle) * (size.width * 0.35);
      final y = center.dy + math.sin(angle) * (size.height * 0.35);
      canvas.drawCircle(Offset(x, y), 3.5, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
