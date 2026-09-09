import 'dart:math';
import 'package:flutter/material.dart';

class CardShatterFx extends StatefulWidget {
  final Widget child;
  final bool shatter;
  final VoidCallback onComplete;

  const CardShatterFx({
    super.key,
    required this.child,
    required this.shatter,
    required this.onComplete,
  });

  @override
  State<CardShatterFx> createState() => _CardShatterFxState();
}

class _CardShatterFxState extends State<CardShatterFx> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  }

  @override
  void didUpdateWidget(CardShatterFx oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shatter && !oldWidget.shatter) {
      _controller.forward().then((_) => widget.onComplete());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.shatter) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ShatterPainter(progress: _controller.value),
          child: Opacity(opacity: 1.0 - _controller.value, child: widget.child),
        );
      },
    );
  }
}

class _ShatterPainter extends CustomPainter {
  final double progress;

  _ShatterPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: (1.0 - progress) * 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rand = Random(42);
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi;
      final dist = progress * 80 + rand.nextDouble() * 20;
      final p1 = center;
      final p2 = Offset(center.dx + cos(angle) * dist, center.dy + sin(angle) * dist);
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShatterPainter oldDelegate) => true;
}
