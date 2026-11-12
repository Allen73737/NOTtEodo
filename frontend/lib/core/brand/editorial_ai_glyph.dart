import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Creatively minimalistic, haute-horlogerie AI intelligence glyph.
/// Designed for the NOTtEodo Swiss Editorial view:
/// An astral diamond star inscribed within a delicate concentric aperture ring,
/// drawn with razor-sharp hairline precision.
class EditorialAiGlyph extends StatefulWidget {
  final double size;
  final Color? color;
  final bool animated;

  const EditorialAiGlyph({
    super.key,
    this.size = 20,
    this.color,
    this.animated = true,
  });

  @override
  State<EditorialAiGlyph> createState() => _EditorialAiGlyphState();
}

class _EditorialAiGlyphState extends State<EditorialAiGlyph>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3200),
      )..repeat();
    }
  }

  @override
  void didUpdateWidget(covariant EditorialAiGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated && _controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3200),
      )..repeat();
    } else if (!widget.animated && _controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? Theme.of(context).colorScheme.primary;

    if (_controller == null) {
      return CustomPaint(
        size: Size.square(widget.size),
        painter: _EditorialAiGlyphPainter(
          color: effectiveColor,
          progress: 0.0,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _EditorialAiGlyphPainter(
            color: effectiveColor,
            progress: _controller!.value,
          ),
        );
      },
    );
  }
}

class _EditorialAiGlyphPainter extends CustomPainter {
  final Color color;
  final double progress;

  _EditorialAiGlyphPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0;
    final radius = size.width / 2.0;

    final paintStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (size.width * 0.065).clamp(1.0, 1.8)
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final paintFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 1. Slender 4-point Astrolabe Star (Astroid / Diamond Flare)
    final starPath = Path();
    final starRadius = radius * 0.78;
    final pinch = starRadius * 0.22;

    // North
    starPath.moveTo(cx, cy - starRadius);
    // North to East
    starPath.quadraticBezierTo(cx + pinch, cy - pinch, cx + starRadius, cy);
    // East to South
    starPath.quadraticBezierTo(cx + pinch, cy + pinch, cx, cy + starRadius);
    // South to West
    starPath.quadraticBezierTo(cx - pinch, cy + pinch, cx - starRadius, cy);
    // West to North
    starPath.quadraticBezierTo(cx - pinch, cy - pinch, cx, cy - starRadius);
    starPath.close();

    // Subtle breath pulse
    final pulseScale = 1.0 + 0.04 * math.sin(progress * math.pi * 2.0);
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(pulseScale);
    canvas.translate(-cx, -cy);

    canvas.drawPath(starPath, paintStroke);

    // 2. Center aperture node
    final coreDotRadius = (size.width * 0.075).clamp(1.0, 2.0);
    canvas.drawCircle(Offset(cx, cy), coreDotRadius, paintFill);

    canvas.restore();

    // 3. Delicate orbital halo arcs with gentle slow rotation
    final ringRadius = radius * 0.94;
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (size.width * 0.045).clamp(0.8, 1.3)
      ..strokeCap = StrokeCap.round;

    final rotAngle = progress * math.pi * 2.0;
    // Draw two opposite balanced crescent arcs
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: ringRadius),
      rotAngle,
      math.pi * 0.65,
      false,
      ringPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: ringRadius),
      rotAngle + math.pi,
      math.pi * 0.65,
      false,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _EditorialAiGlyphPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}
