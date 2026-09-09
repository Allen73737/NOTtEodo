import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class CircularSpectrumRing extends StatefulWidget {
  final bool isPlaying;
  final Widget child;
  final double size;

  const CircularSpectrumRing({
    super.key,
    required this.isPlaying,
    required this.child,
    this.size = 68,
  });

  @override
  State<CircularSpectrumRing> createState() => _CircularSpectrumRingState();
}

class _CircularSpectrumRingState extends State<CircularSpectrumRing> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          painter: _RingPainter(progress: _animController.value, isPlaying: widget.isPlaying),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(child: widget.child),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;

  _RingPainter({required this.progress, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2 - 4;

    final paint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: isPlaying ? 0.35 : 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(center, baseRadius, glowPaint);

    if (isPlaying) {
      for (int i = 0; i < 24; i++) {
        final angle = (i / 24) * 2 * pi;
        final barLen = sin(angle * 3 + progress * 2 * pi).abs() * 8 + 2;

        final p1 = Offset(center.dx + cos(angle) * baseRadius, center.dy + sin(angle) * baseRadius);
        final p2 = Offset(center.dx + cos(angle) * (baseRadius + barLen), center.dy + sin(angle) * (baseRadius + barLen));

        canvas.drawLine(p1, p2, paint);
      }
    } else {
      canvas.drawCircle(center, baseRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => true;
}
