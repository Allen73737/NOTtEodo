import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Suminagashi Floating Ink Fluid Canvas
/// 12th-century Japanese marbled ink craft: gentle hydrodynamic fluid displacement
/// rings that ripple across the background on touch or drag.
class SuminagashiInkCanvas extends StatefulWidget {
  final Widget child;

  const SuminagashiInkCanvas({
    super.key,
    required this.child,
  });

  @override
  State<SuminagashiInkCanvas> createState() => _SuminagashiInkCanvasState();
}

class _SuminagashiInkCanvasState extends State<SuminagashiInkCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  Offset _touchPoint = const Offset(150, 150);

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _touchPoint = details.localPosition;
        });
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SuminagashiPainter(
                    origin: _touchPoint,
                    phase: _waveController.value,
                  ),
                );
              },
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _SuminagashiPainter extends CustomPainter {
  final Offset origin;
  final double phase;

  _SuminagashiPainter({required this.origin, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final ringPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int i = 1; i <= 6; i++) {
      final baseRadius = (i * 38.0) + (phase * 38.0);
      final path = Path();

      for (double theta = 0; theta < 2 * math.pi; theta += 0.1) {
        final distortion = math.sin(theta * 4 + phase * 2 * math.pi) * 6.0;
        final r = baseRadius + distortion;
        final x = origin.dx + r * math.cos(theta);
        final y = origin.dy + r * math.sin(theta);

        if (theta == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SuminagashiPainter oldDelegate) => true;
}
