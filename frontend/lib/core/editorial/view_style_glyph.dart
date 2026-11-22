import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion/motion.dart';

/// The icon for the Cards / Editorial switch. Cards is two stacked cards; Editorial is
/// a headline over a column of type. Switching morphs one into the other: the back card
/// flattens into the headline and the front card unfolds into lines of text.
class ViewStyleGlyph extends StatelessWidget {
  /// Draw the editorial page when true, the stacked cards when false.
  final bool editorial;
  final double size;
  final Color color;

  const ViewStyleGlyph({super.key, required this.editorial, required this.color, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: editorial ? 1 : 0),
      duration: Motion.reduced(context) ? Duration.zero : const Duration(milliseconds: 620),
      curve: Motion.silk,
      builder: (context, t, _) => CustomPaint(
        size: Size.square(size),
        painter: _ViewStylePainter(t: t.clamp(0.0, 1.0), color: color),
      ),
    );
  }
}

class _ViewStylePainter extends CustomPainter {
  final double t;
  final Color color;

  _ViewStylePainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 20;
    Rect r(double l, double tp, double rt, double b) => Rect.fromLTRB(l * u, tp * u, rt * u, b * u);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final fill = Paint()..color = color;
    // Its own layer, so the front card's knockout clears only the back card.
    canvas.saveLayer(Offset.zero & size, Paint());

    // The back card lifts and flattens into the headline bar.
    final back = Rect.lerp(r(6.5, 2, 18, 12.5), r(2.5, 3, 13.5, 5.6), t)!;
    final backRadius = Radius.circular(lerpDouble(2.6, 1.3, t) * u);
    if (t < 0.98) {
      canvas.drawRRect(RRect.fromRectAndRadius(back, backRadius), stroke..color = color.withValues(alpha: 1 - t));
    }
    canvas.drawRRect(RRect.fromRectAndRadius(back, backRadius), fill..color = color.withValues(alpha: t));

    // The front card opens out to the width of the column and lets go of its edges.
    final front = Rect.lerp(r(2, 7, 13.5, 18), r(2.5, 8, 17.5, 18), t)!;
    final frontRadius = Radius.circular(lerpDouble(2.6, 0, t) * u);
    final cardAlpha = (1 - t * 1.6).clamp(0.0, 1.0);
    if (cardAlpha > 0) {
      // Knock out what is behind it so the stack reads as two cards.
      canvas.drawRRect(
        RRect.fromRectAndRadius(front.inflate(1.4 * u), frontRadius),
        Paint()
          ..blendMode = BlendMode.clear
          ..color = Colors.black.withValues(alpha: cardAlpha),
      );
      canvas.drawRRect(RRect.fromRectAndRadius(front, frontRadius), Paint()..color = color.withValues(alpha: 0.16 * cardAlpha));
      canvas.drawRRect(RRect.fromRectAndRadius(front, frontRadius), stroke..color = color.withValues(alpha: cardAlpha));
    }

    // Lines of type arrive one after another, each drawn left to right.
    const lines = [(9.5, 17.5), (13.0, 17.5), (16.5, 12.0)];
    for (var i = 0; i < lines.length; i++) {
      final start = 0.25 + i * 0.15;
      final p = ((t - start) / (1 - start)).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final (y, end) = lines[i];
      final x0 = 2.5 * u;
      final x1 = x0 + (end * u - x0) * Curves.easeOut.transform(p);
      canvas.drawLine(
        Offset(x0, y * u),
        Offset(math.max(x0 + 0.01, x1), y * u),
        Paint()
          ..strokeWidth = 1.5 * u
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: p),
      );
    }
    canvas.restore();
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(_ViewStylePainter old) => old.t != t || old.color != color;
}
