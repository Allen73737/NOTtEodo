import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LiquidMercuryCheckmark extends StatefulWidget {
  final bool isChecked;
  final ValueChanged<bool> onChanged;
  final double size;

  const LiquidMercuryCheckmark({
    super.key,
    required this.isChecked,
    required this.onChanged,
    this.size = 28.0,
  });

  @override
  State<LiquidMercuryCheckmark> createState() => _LiquidMercuryCheckmarkState();
}

class _LiquidMercuryCheckmarkState extends State<LiquidMercuryCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fluidAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fluidAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    if (widget.isChecked) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(LiquidMercuryCheckmark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isChecked != widget.isChecked) {
      if (widget.isChecked) {
        _controller.forward(from: 0.0);
        HapticFeedback.mediumImpact();
      } else {
        _controller.reverse();
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.isChecked),
      child: AnimatedBuilder(
        animation: _fluidAnimation,
        builder: (context, _) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _MercuryPainter(
              progress: _fluidAnimation.value,
              isChecked: widget.isChecked,
            ),
          );
        },
      ),
    );
  }
}

class _MercuryPainter extends CustomPainter {
  final double progress;
  final bool isChecked;

  _MercuryPainter({required this.progress, required this.isChecked});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final borderPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(center, radius - 2, borderPaint);

    if (progress > 0) {
      final fillPaint = Paint()
        ..color = const Color(0xFFE0E0E0)
        ..style = PaintingStyle.fill;

      final dropletRadius = (radius - 4) * progress;
      canvas.drawCircle(center, dropletRadius, fillPaint);

      if (progress > 0.4) {
        final checkProgress = (progress - 0.4) / 0.6;
        final checkPath = Path();
        final p1 = Offset(size.width * 0.28, size.height * 0.52);
        final p2 = Offset(size.width * 0.45, size.height * 0.68);
        final p3 = Offset(size.width * 0.72, size.height * 0.35);

        checkPath.moveTo(p1.dx, p1.dy);
        checkPath.lineTo(
          p1.dx + (p2.dx - p1.dx) * checkProgress.clamp(0.0, 1.0),
          p1.dy + (p2.dy - p1.dy) * checkProgress.clamp(0.0, 1.0),
        );
        if (checkProgress > 0.5) {
          final p3Progress = (checkProgress - 0.5) * 2;
          checkPath.lineTo(
            p2.dx + (p3.dx - p2.dx) * p3Progress.clamp(0.0, 1.0),
            p2.dy + (p3.dy - p2.dy) * p3Progress.clamp(0.0, 1.0),
          );
        }

        final checkStroke = Paint()
          ..color = const Color(0xFF16282C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        canvas.drawPath(checkPath, checkStroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MercuryPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isChecked != isChecked;
  }
}
