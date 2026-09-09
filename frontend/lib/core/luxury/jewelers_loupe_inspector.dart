import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Jeweler's Loupe Inspector on Long Press
/// Spawns a heavy brass-rimmed optical magnifying loupe providing 3x magnification
/// and purple anti-reflective lens flare over wardrobe garments or moodboard assets.
class JewelersLoupeInspector extends StatefulWidget {
  final Widget child;
  final double magnification;

  const JewelersLoupeInspector({
    super.key,
    required this.child,
    this.magnification = 2.5,
  });

  @override
  State<JewelersLoupeInspector> createState() => _JewelersLoupeInspectorState();
}

class _JewelersLoupeInspectorState extends State<JewelersLoupeInspector> {
  Offset? _touchPos;
  bool _isInspecting = false;

  void _onLongPressStart(LongPressStartDetails details) {
    HapticFeedback.mediumImpact();
    setState(() {
      _touchPos = details.localPosition;
      _isInspecting = true;
    });
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    setState(() {
      _touchPos = details.localPosition;
    });
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    setState(() {
      _isInspecting = false;
      _touchPos = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressMoveUpdate: _onLongPressMoveUpdate,
      onLongPressEnd: _onLongPressEnd,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_isInspecting && _touchPos != null)
            Positioned(
              left: _touchPos!.dx - 55,
              top: _touchPos!.dy - 120, // Hovered above finger
              child: IgnorePointer(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFEAB368), width: 4.0),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10)),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      children: [
                        // Magnified mirrored area
                        Transform.scale(
                          scale: widget.magnification,
                          origin: _touchPos!,
                          child: widget.child,
                        ),
                        // Anti-reflective optical purple coating
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF8A2BE2).withValues(alpha: 0.12),
                                const Color(0xFFEAB368).withValues(alpha: 0.25),
                              ],
                              stops: const [0.6, 0.85, 1.0],
                            ),
                          ),
                        ),
                        // Brass Rim Tick Markings
                        CustomPaint(
                          size: const Size(110, 110),
                          painter: _LoupeRimPainter(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoupeRimPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final tickPaint = Paint()
      ..color = const Color(0xFFB8860B)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 24; i++) {
      final angle = i * (pi / 12);
      final p1 = Offset(center.dx + (radius - 5) * cos(angle), center.dy + (radius - 5) * sin(angle));
      final p2 = Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
