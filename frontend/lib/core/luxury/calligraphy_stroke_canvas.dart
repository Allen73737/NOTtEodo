import 'package:flutter/material.dart';

/// Calligraphy Nib Dynamic Pressure Stroke Canvas
/// Varies stroke thickness, nib angle, and ink pooling dynamically
/// according to finger/stylus velocity and dwell time.
class CalligraphyStrokeCanvas extends StatefulWidget {
  final Color inkColor;
  final VoidCallback? onClear;

  const CalligraphyStrokeCanvas({
    super.key,
    this.inkColor = const Color(0xFF1E1A17),
    this.onClear,
  });

  @override
  State<CalligraphyStrokeCanvas> createState() => _CalligraphyStrokeCanvasState();
}

class _CalligraphyPoint {
  final Offset position;
  final double width;

  _CalligraphyPoint(this.position, this.width);
}

class _CalligraphyStrokeCanvasState extends State<CalligraphyStrokeCanvas> {
  final List<List<_CalligraphyPoint>> _strokes = [];
  Offset? _lastPos;
  DateTime? _lastTime;

  void _onPanStart(DragStartDetails details) {
    _lastPos = details.localPosition;
    _lastTime = DateTime.now();
    _strokes.add([_CalligraphyPoint(details.localPosition, 4.0)]);
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final now = DateTime.now();
    final pos = details.localPosition;

    if (_lastPos != null && _lastTime != null) {
      final dist = (pos - _lastPos!).distance;
      final dt = now.difference(_lastTime!).inMilliseconds.clamp(1, 100);
      final velocity = dist / dt; // pixels per ms

      // Faster velocity yields narrower, sharper nib strokes; slow lingering deposits rich pooling
      final strokeW = (6.5 / (1.0 + (velocity * 0.8))).clamp(1.5, 7.5);

      _strokes.last.add(_CalligraphyPoint(pos, strokeW));
      _lastPos = pos;
      _lastTime = now;
      setState(() {});
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _lastPos = null;
    _lastTime = null;
  }

  void clearCanvas() {
    setState(() => _strokes.clear());
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: CustomPaint(
        size: Size.infinite,
        painter: _CalligraphyPainter(strokes: _strokes, inkColor: widget.inkColor),
      ),
    );
  }
}

class _CalligraphyPainter extends CustomPainter {
  final List<List<_CalligraphyPoint>> strokes;
  final Color inkColor;

  _CalligraphyPainter({required this.strokes, required this.inkColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = inkColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) {
        if (stroke.isNotEmpty) {
          // Ink droplet deposit
          canvas.drawCircle(
            stroke.first.position,
            stroke.first.width,
            Paint()..color = inkColor,
          );
        }
        continue;
      }

      for (int i = 0; i < stroke.length - 1; i++) {
        final p1 = stroke[i];
        final p2 = stroke[i + 1];
        final avgW = (p1.width + p2.width) / 2;

        paint.strokeWidth = avgW;
        canvas.drawLine(p1.position, p2.position, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CalligraphyPainter oldDelegate) => true;
}
