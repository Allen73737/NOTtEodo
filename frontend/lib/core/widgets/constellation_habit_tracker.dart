import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class ConstellationHabitTracker extends StatelessWidget {
  final int streakDays;

  const ConstellationHabitTracker({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(120, 60),
      painter: _ConstellationPainter(streakDays: streakDays),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  final int streakDays;

  _ConstellationPainter({required this.streakDays});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final starPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;

    final points = [
      const Offset(10, 40),
      const Offset(35, 15),
      const Offset(65, 45),
      const Offset(95, 20),
      const Offset(115, 50),
    ];

    for (int i = 0; i < points.length - 1 && i < streakDays; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], i <= streakDays ? 4 : 2, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) => oldDelegate.streakDays != streakDays;
}
