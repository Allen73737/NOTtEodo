import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Brand colour set used by the monogram and every Sanctuary loader.
/// Drawn from the app palette so all loading states read as one family.
class NotteodoBrandInk {
  final Color accent;
  final Color support;
  final Color ink;
  final Color track;

  const NotteodoBrandInk._(this.accent, this.support, this.ink, this.track);

  // The app's own palette: terracotta accent into midnight teal on cream,
  // and into sage on pitch black.
  static const NotteodoBrandInk light = NotteodoBrandInk._(
    Color(0xFFD9725B),
    Color(0xFF16282C),
    Color(0xFF16282C),
    Color(0xFFE5DDD0),
  );

  static const NotteodoBrandInk dark = NotteodoBrandInk._(
    Color(0xFFE8927C),
    Color(0xFF86CBB0),
    Color(0xFFF6F3ED),
    Color(0xFF1A1A1A),
  );

  static NotteodoBrandInk of(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? dark : light;

  static NotteodoBrandInk forMode(bool isDark) => isDark ? dark : light;
}

/// Vector "N" monogram traced from `assets/images/notteodo_logo.png`.
///
/// The mark lives in a 100×100 design box and is 180° rotationally symmetric:
/// one continuous loop (split into a west and east half so two pens can draw it
/// in parallel) plus two short diagonal tails.
class NotteodoMonogramGeometry {
  NotteodoMonogramGeometry._();

  static const double designSize = 100.0;
  static const double strokeWidth = 4.1;

  static final Path loopWest = _buildPath(_loopWest);
  static final Path loopEast = _buildPath(_loopEast);
  static final Path tailNorth = _buildPath(_tailNorth);
  static final Path tailSouth = _buildPath(_tailSouth);

  static final List<ui.PathMetric> _loopMetrics = [
    ...loopWest.computeMetrics(),
    ...loopEast.computeMetrics(),
  ];
  static final List<ui.PathMetric> _tailMetrics = [
    ...tailNorth.computeMetrics(),
    ...tailSouth.computeMetrics(),
  ];

  static Path _buildPath(List<List<double>> segments) {
    final path = Path()..moveTo(segments.first[0], segments.first[1]);
    for (final s in segments) {
      path.cubicTo(s[2], s[3], s[4], s[5], s[6], s[7]);
    }
    return path;
  }

  /// The visible portion of the mark for a draw window [start, end] in 0..1.
  ///
  /// The loop pens finish at 82% of the window; the tails start at 60% so the
  /// diagonal strokes land as a final flourish.
  static Path windowed(double start, double end) {
    final out = Path();
    _extractInto(out, _loopMetrics, _remap(start, 0.0, 0.82), _remap(end, 0.0, 0.82));
    _extractInto(out, _tailMetrics, _remap(start, 0.6, 1.0), _remap(end, 0.6, 1.0));
    return out;
  }

  /// Leading points of every pen that is currently mid-stroke, used for nib sparks.
  static List<Offset> penHeads(double end) {
    final heads = <Offset>[];
    void collect(List<ui.PathMetric> metrics, double t) {
      if (t <= 0.0 || t >= 1.0) return;
      for (final m in metrics) {
        final tangent = m.getTangentForOffset(m.length * t);
        if (tangent != null) heads.add(tangent.position);
      }
    }

    collect(_loopMetrics, _remap(end, 0.0, 0.82));
    collect(_tailMetrics, _remap(end, 0.6, 1.0));
    return heads;
  }

  static double _remap(double t, double from, double to) => ((t - from) / (to - from)).clamp(0.0, 1.0);

  static void _extractInto(Path out, List<ui.PathMetric> metrics, double start, double end) {
    if (end <= start) return;
    for (final m in metrics) {
      out.addPath(m.extractPath(m.length * start, m.length * end), Offset.zero);
    }
  }
}

/// Paints the monogram with solid luxury ink, optional bloom, travelling sheen and nib sparks.
class NotteodoMonogramPainter extends CustomPainter {
  /// Visible window of the stroke, 0..1 (draw-in grows [end], erase-out grows [start]).
  final double start;
  final double end;
  final List<Color> colors;

  /// 0..1 strength of the soft bloom underneath the stroke.
  final double glow;

  /// Position of the specular sheen band across the mark (0..1), or null for none.
  final double? sheen;

  /// Multiplier on the traced stroke weight; small marks read better a little heavier.
  final double weight;
  final bool showNibs;

  NotteodoMonogramPainter({
    this.start = 0.0,
    this.end = 1.0,
    required this.colors,
    this.glow = 0.0,
    this.sheen,
    this.weight = 1.0,
    this.showNibs = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (end <= start || size.isEmpty) return;

    final side = math.min(size.width, size.height);
    canvas.save();
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    canvas.scale(side / NotteodoMonogramGeometry.designSize);

    final path = NotteodoMonogramGeometry.windowed(start, end);
    final strokeW = NotteodoMonogramGeometry.strokeWidth * weight;

    if (glow > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = strokeW * 2.4
          ..color = colors.first.withValues(alpha: 0.38 * glow.clamp(0.0, 1.0))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5),
      );
    }

    final inkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeW;
    inkPaint.color = colors.first;
    canvas.drawPath(path, inkPaint);

    final s = sheen;
    if (s != null && s > 0 && s < 1) {
      // A narrow diagonal band of light that glides across the ink.
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeW * 0.9
          ..color = colors.first,
      );
    }

    if (showNibs) {
      final nib = Paint()..color = Colors.white.withValues(alpha: 0.95);
      final halo = Paint()
        ..color = colors.first.withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2);
      for (final head in NotteodoMonogramGeometry.penHeads(end)) {
        canvas.drawCircle(head, strokeW * 1.5, halo);
        canvas.drawCircle(head, strokeW * 0.42, nib);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant NotteodoMonogramPainter old) =>
      old.start != start ||
      old.end != end ||
      old.glow != glow ||
      old.sheen != sheen ||
      old.weight != weight ||
      old.showNibs != showNibs ||
      !_sameColors(old.colors, colors);

  static bool _sameColors(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Crisp, resolution-independent brand mark. Renders correctly in both themes without
/// the colour-filter tricks the PNG emblem needed.
class NotteodoMonogram extends StatelessWidget {
  final double size;

  /// Solid colour for the mark; defaults to the theme ink. Ignored when [branded] is true.
  final Color? color;

  /// Paint with the accent brand color.
  final bool branded;
  final double weight;

  const NotteodoMonogram({
    super.key,
    this.size = 36,
    this.color,
    this.branded = false,
    this.weight = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final brand = NotteodoBrandInk.of(context);
    // Hairlines vanish below ~28px, so small marks get a gently heavier stroke.
    final autoWeight = size < 28 ? 1.0 + (28 - size) / 28 * 0.6 : 1.0;

    return Semantics(
      label: 'NOTtEodo',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: NotteodoMonogramPainter(
            colors: branded ? [brand.accent, brand.support] : [color ?? brand.ink],
            weight: weight * autoWeight,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Traced geometry (cubic segments: x0, y0, c1x, c1y, c2x, c2y, x1, y1).
// ---------------------------------------------------------------------------

const List<List<double>> _loopWest = [
  [25, 10.29, 24.56, 8.73, 22.79, 7.57, 21.47, 6.76],
  [21.47, 6.76, 20.15, 5.96, 18.53, 5.64, 17.06, 5.44],
  [17.06, 5.44, 15.59, 5.25, 13.97, 5.32, 12.65, 5.59],
  [12.65, 5.59, 11.32, 5.86, 10.07, 6.27, 9.12, 7.06],
  [9.12, 7.06, 8.16, 7.84, 7.38, 9.02, 6.91, 10.29],
  [6.91, 10.29, 6.45, 11.57, 6.42, 12.99, 6.32, 14.71],
  [6.32, 14.71, 6.23, 16.42, 6.25, 18.75, 6.32, 20.59],
  [6.32, 20.59, 6.4, 22.43, 6.52, 24.12, 6.76, 25.74],
  [6.76, 25.74, 7.01, 27.35, 7.33, 28.8, 7.79, 30.29],
  [7.79, 30.29, 8.26, 31.79, 8.7, 33.19, 9.56, 34.71],
  [9.56, 34.71, 10.42, 36.23, 11.74, 37.55, 12.94, 39.41],
  [12.94, 39.41, 14.14, 41.27, 15.42, 44.09, 16.76, 45.88],
  [16.76, 45.88, 18.11, 47.67, 19.66, 48.68, 21.03, 50.15],
  [21.03, 50.15, 22.4, 51.62, 23.85, 53.09, 25, 54.71],
  [25, 54.71, 26.15, 56.32, 27.08, 57.94, 27.94, 59.85],
  [27.94, 59.85, 28.8, 61.76, 29.71, 63.9, 30.15, 66.18],
  [30.15, 66.18, 30.59, 68.46, 30.76, 71.23, 30.59, 73.53],
  [30.59, 73.53, 30.42, 75.83, 29.85, 77.99, 29.12, 80],
  [29.12, 80, 28.38, 82.01, 27.28, 84.07, 26.18, 85.59],
  [26.18, 85.59, 25.07, 87.11, 23.92, 88.04, 22.5, 89.12],
  [22.5, 89.12, 21.08, 90.2, 19.41, 91.27, 17.65, 92.06],
  [17.65, 92.06, 15.88, 92.84, 13.58, 93.5, 11.91, 93.82],
  [11.91, 93.82, 10.25, 94.14, 8.58, 94.53, 7.65, 93.97],
  [7.65, 93.97, 6.72, 93.41, 6.54, 92.38, 6.32, 90.44],
  [6.32, 90.44, 6.1, 88.5, 6.32, 85.66, 6.32, 82.35],
  [6.32, 82.35, 6.32, 79.04, 6.32, 74.26, 6.32, 70.59],
  [6.32, 70.59, 6.32, 66.91, 6.25, 63.01, 6.32, 60.29],
  [6.32, 60.29, 6.4, 57.57, 6.47, 56.13, 6.76, 54.26],
  [6.76, 54.26, 7.06, 52.4, 7.52, 50.74, 8.09, 49.12],
  [8.09, 49.12, 8.65, 47.5, 9.19, 46.08, 10.15, 44.56],
  [10.15, 44.56, 11.1, 43.04, 12.5, 41.62, 13.82, 40],
  [13.82, 40, 15.15, 38.38, 16.35, 36.3, 18.09, 34.85],
  [18.09, 34.85, 19.83, 33.41, 21.96, 32.28, 24.26, 31.32],
  [24.26, 31.32, 26.57, 30.37, 28.97, 29.39, 31.91, 29.12],
  [31.91, 29.12, 34.85, 28.85, 39.34, 29.36, 41.91, 29.71],
  [41.91, 29.71, 44.49, 30.05, 45.39, 30.02, 47.35, 31.18],
  [47.35, 31.18, 49.31, 32.33, 51.81, 34.9, 53.68, 36.62],
  [53.68, 36.62, 55.54, 38.33, 56.99, 39.9, 58.53, 41.47],
  [58.53, 41.47, 60.07, 43.04, 61.54, 44.58, 62.94, 46.03],
  [62.94, 46.03, 64.34, 47.48, 65.69, 48.7, 66.91, 50.15],
  [66.91, 50.15, 68.14, 51.59, 69.26, 53.11, 70.29, 54.71],
  [70.29, 54.71, 71.32, 56.3, 72.3, 58.01, 73.09, 59.71],
  [73.09, 59.71, 73.87, 61.4, 74.46, 63.04, 75, 64.85],
  [75, 64.85, 75.54, 66.67, 76.08, 68.41, 76.32, 70.59],
  [76.32, 70.59, 76.57, 72.77, 76.57, 75.74, 76.47, 77.94],
  [76.47, 77.94, 76.37, 80.15, 76.03, 82.23, 75.74, 83.82],
  [75.74, 83.82, 75.44, 85.42, 74.17, 86.03, 74.71, 87.5],
];

const List<List<double>> _loopEast = [
  [74.71, 87.5, 75.25, 88.97, 77.57, 91.57, 78.97, 92.65],
  [78.97, 92.65, 80.37, 93.73, 81.72, 93.75, 83.09, 93.97],
  [83.09, 93.97, 84.46, 94.19, 85.96, 94.19, 87.21, 93.97],
  [87.21, 93.97, 88.46, 93.75, 89.66, 93.36, 90.59, 92.65],
  [90.59, 92.65, 91.52, 91.94, 92.3, 90.93, 92.79, 89.71],
  [92.79, 89.71, 93.28, 88.48, 93.41, 87.01, 93.53, 85.29],
  [93.53, 85.29, 93.65, 83.58, 93.58, 81.25, 93.53, 79.41],
  [93.53, 79.41, 93.48, 77.57, 93.43, 75.88, 93.24, 74.26],
  [93.24, 74.26, 93.04, 72.65, 92.75, 71.25, 92.35, 69.71],
  [92.35, 69.71, 91.96, 68.16, 91.76, 66.52, 90.88, 65],
  [90.88, 65, 90, 63.48, 88.21, 62.5, 87.06, 60.59],
  [87.06, 60.59, 85.91, 58.68, 85.2, 55.42, 83.97, 53.53],
  [83.97, 53.53, 82.75, 51.64, 81.1, 50.69, 79.71, 49.26],
  [79.71, 49.26, 78.31, 47.84, 76.81, 46.54, 75.59, 45],
  [75.59, 45, 74.36, 43.46, 73.28, 41.86, 72.35, 40],
  [72.35, 40, 71.42, 38.14, 70.51, 36.08, 70, 33.82],
  [70, 33.82, 69.49, 31.57, 69.19, 28.8, 69.26, 26.47],
  [69.26, 26.47, 69.34, 24.14, 69.75, 21.91, 70.44, 19.85],
  [70.44, 19.85, 71.13, 17.79, 72.28, 15.71, 73.38, 14.12],
  [73.38, 14.12, 74.49, 12.52, 75.61, 11.45, 77.06, 10.29],
  [77.06, 10.29, 78.5, 9.14, 80.25, 7.99, 82.06, 7.21],
  [82.06, 7.21, 83.87, 6.42, 86.18, 5.86, 87.94, 5.59],
  [87.94, 5.59, 89.71, 5.32, 91.72, 4.93, 92.65, 5.59],
  [92.65, 5.59, 93.58, 6.25, 93.38, 7.55, 93.53, 9.56],
  [93.53, 9.56, 93.68, 11.57, 93.53, 14.34, 93.53, 17.65],
  [93.53, 17.65, 93.53, 20.96, 93.53, 25.74, 93.53, 29.41],
  [93.53, 29.41, 93.53, 33.09, 93.65, 37.01, 93.53, 39.71],
  [93.53, 39.71, 93.41, 42.4, 93.16, 43.75, 92.79, 45.59],
  [92.79, 45.59, 92.43, 47.43, 91.91, 49.14, 91.32, 50.74],
  [91.32, 50.74, 90.74, 52.33, 90.12, 53.6, 89.26, 55.15],
  [89.26, 55.15, 88.41, 56.69, 87.55, 58.48, 86.18, 60],
  [86.18, 60, 84.8, 61.52, 82.84, 62.94, 81.03, 64.26],
  [81.03, 64.26, 79.22, 65.59, 77.48, 67.06, 75.29, 67.94],
  [75.29, 67.94, 73.11, 68.82, 70.78, 69.41, 67.94, 69.56],
  [67.94, 69.56, 65.1, 69.71, 60.71, 69.09, 58.24, 68.82],
  [58.24, 68.82, 55.76, 68.55, 54.98, 68.95, 53.09, 67.94],
  [53.09, 67.94, 51.2, 66.94, 48.75, 64.46, 46.91, 62.79],
  [46.91, 62.79, 45.07, 61.13, 43.63, 59.51, 42.06, 57.94],
  [42.06, 57.94, 40.49, 56.37, 38.87, 54.83, 37.5, 53.38],
  [37.5, 53.38, 36.13, 51.94, 35.02, 50.66, 33.82, 49.26],
  [33.82, 49.26, 32.62, 47.87, 31.37, 46.54, 30.29, 45],
  [30.29, 45, 29.22, 43.46, 28.19, 41.64, 27.35, 40],
  [27.35, 40, 26.52, 38.36, 25.86, 36.91, 25.29, 35.15],
  [25.29, 35.15, 24.73, 33.38, 24.29, 31.59, 23.97, 29.41],
  [23.97, 29.41, 23.65, 27.23, 23.36, 24.26, 23.38, 22.06],
  [23.38, 22.06, 23.41, 19.85, 23.85, 18.14, 24.12, 16.18],
  [24.12, 16.18, 24.39, 14.22, 25.44, 11.86, 25, 10.29],
];

const List<List<double>> _tailNorth = [
  [25.29, 10, 26.74, 11.1, 31.1, 14.09, 33.97, 16.62],
  [33.97, 16.62, 36.84, 19.14, 39.88, 22.57, 42.5, 25.15],
  [42.5, 25.15, 45.12, 27.72, 48.5, 30.91, 49.71, 32.06],
];

const List<List<double>> _tailSouth = [
  [74.71, 90, 73.36, 88.8, 69.39, 85.42, 66.62, 82.79],
  [66.62, 82.79, 63.85, 80.17, 60.81, 76.74, 58.09, 74.26],
  [58.09, 74.26, 55.37, 71.79, 51.59, 69, 50.29, 67.94],
];
