import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class LiquidSandFocusTimer extends StatefulWidget {
  final int durationMinutes;

  const LiquidSandFocusTimer({super.key, this.durationMinutes = 25});

  @override
  State<LiquidSandFocusTimer> createState() => _LiquidSandFocusTimerState();
}

class _LiquidSandFocusTimerState extends State<LiquidSandFocusTimer> with SingleTickerProviderStateMixin {
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(minutes: widget.durationMinutes),
    )..repeat();
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _timerController,
      builder: (context, _) {
        final progress = _timerController.value;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size(16, 22),
                painter: _HourglassSandPainter(progress: progress),
              ),
              const SizedBox(width: 8),
              Text(
                '${(widget.durationMinutes * (1 - progress)).floor()}:${((1 - progress) * 60 % 60).floor().toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HourglassSandPainter extends CustomPainter {
  final double progress;

  _HourglassSandPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;

    // Top Sand Triangle
    final topPath = Path()
      ..moveTo(2, 2)
      ..lineTo(size.width - 2, 2)
      ..lineTo(size.width / 2, (size.height / 2) * (1 - progress))
      ..close();
    canvas.drawPath(topPath, paint);

    // Bottom Sand Triangle
    final bottomPath = Path()
      ..moveTo(size.width / 2, size.height / 2)
      ..lineTo(size.width - 2, size.height - 2)
      ..lineTo(2, size.height - 2)
      ..close();
    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(covariant _HourglassSandPainter oldDelegate) => oldDelegate.progress != progress;
}
