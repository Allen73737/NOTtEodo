import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// Light along a card's rounded edge, filling from the top centre down both sides to the
/// bottom as [charge] goes from 0 to 1, while a finger holds the card, so the
/// hold-to-preview can be seen coming. 0 draws nothing.
class EdgeLightPainter extends CustomPainter {
  final double radius;
  final Color color;
  final double charge;

  EdgeLightPainter({required this.radius, required this.color, this.charge = 0});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || charge <= 0) return;
    final metric = _outline(size).computeMetrics().first;
    final length = metric.length;

    final reach = length / 2 * charge;
    final a = Curves.easeOut.transform(charge.clamp(0.0, 1.0));
    _stroke(canvas, metric, 0, reach, a);
    _stroke(canvas, metric, length - reach, length, a);
  }

  /// Strokes the edge from [from] to [to] (any distance; it wraps round) at [alpha].
  void _stroke(Canvas canvas, PathMetric metric, double from, double to, double alpha) {
    if (alpha <= 0.002 || to <= from) return;
    final length = metric.length;
    final start = from % length;
    final end = start + (to - from);
    final path = end <= length
        ? metric.extractPath(start, end)
        : (metric.extractPath(start, length)..addPath(metric.extractPath(0, end - length), Offset.zero));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
        ..color = color.withValues(alpha: color.a * 0.4 * alpha),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: color.a * alpha),
    );
  }

  /// The card's rounded outline, inset to sit inside its clip, starting at the top centre
  /// and running clockwise.
  Path _outline(Size size) {
    const inset = 0.75;
    final l = inset, t = inset, r = size.width - inset, b = size.height - inset;
    final c = math.max(0.0, math.min(radius, math.min(size.width, size.height) / 2) - inset);
    final corner = Radius.circular(c);
    return Path()
      ..moveTo(size.width / 2, t)
      ..lineTo(r - c, t)
      ..arcToPoint(Offset(r, t + c), radius: corner)
      ..lineTo(r, b - c)
      ..arcToPoint(Offset(r - c, b), radius: corner)
      ..lineTo(l + c, b)
      ..arcToPoint(Offset(l, b - c), radius: corner)
      ..lineTo(l, t + c)
      ..arcToPoint(Offset(l + c, t), radius: corner)
      ..close();
  }

  @override
  bool shouldRepaint(EdgeLightPainter old) =>
      old.charge != charge || old.color != color || old.radius != radius;
}
