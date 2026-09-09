import 'dart:math';
import 'package:flutter/material.dart';

class KaleidoscopeViewer extends StatefulWidget {
  final Widget child;

  const KaleidoscopeViewer({super.key, required this.child});

  @override
  State<KaleidoscopeViewer> createState() => _KaleidoscopeViewerState();
}

class _KaleidoscopeViewerState extends State<KaleidoscopeViewer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        children: [
          widget.child,
          if (_isHovered)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _KaleidoscopePainter(progress: _controller.value),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KaleidoscopePainter extends CustomPainter {
  final double progress;

  _KaleidoscopePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * pi + progress * 2 * pi;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + cos(angle) * size.width, center.dy + sin(angle) * size.height)
        ..lineTo(center.dx + cos(angle + pi / 3) * size.width, center.dy + sin(angle + pi / 3) * size.height)
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _KaleidoscopePainter oldDelegate) => true;
}
