import 'package:flutter/material.dart';

import 'reveal.dart';

/// Text crossed off by hand: when [struck] turns on, an ink line draws across each line
/// of it from left to right, rising a touch as it goes, like a pen stroke. Turning it
/// off lifts the ink back out.
class InkStrike extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final bool struck;
  final Color ink;
  final int? maxLines;

  const InkStrike(this.text, {super.key, this.style, required this.struck, required this.ink, this.maxLines});

  @override
  State<InkStrike> createState() => _InkStrikeState();
}

class _InkStrikeState extends State<InkStrike> with SingleTickerProviderStateMixin {
  late final AnimationController _pen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    reverseDuration: const Duration(milliseconds: 260),
    value: widget.struck ? 1 : 0,
  );
  late final Animation<double> _drawn = CurvedAnimation(parent: _pen, curve: const Cubic(0.45, 0, 0.2, 1));

  @override
  void didUpdateWidget(InkStrike old) {
    super.didUpdateWidget(old);
    if (widget.struck == old.struck) return;
    if (Motion.reduced(context)) {
      _pen.value = widget.struck ? 1 : 0;
    } else if (widget.struck) {
      _pen.forward();
    } else {
      _pen.reverse();
    }
  }

  @override
  void dispose() {
    _pen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    return CustomPaint(
      foregroundPainter: _StrikePainter(
        progress: _drawn,
        text: widget.text,
        style: style,
        ink: widget.ink,
        maxLines: widget.maxLines,
        direction: Directionality.of(context),
        scaler: MediaQuery.textScalerOf(context),
      ),
      child: Text(widget.text, style: style, maxLines: widget.maxLines, overflow: widget.maxLines == null ? null : TextOverflow.ellipsis),
    );
  }
}

class _StrikePainter extends CustomPainter {
  final Animation<double> progress;
  final String text;
  final TextStyle style;
  final Color ink;
  final int? maxLines;
  final TextDirection direction;
  final TextScaler scaler;

  _StrikePainter({
    required this.progress,
    required this.text,
    required this.style,
    required this.ink,
    required this.maxLines,
    required this.direction,
    required this.scaler,
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.value;
    if (p <= 0) return;
    final layout = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: maxLines,
      ellipsis: maxLines == null ? null : '…',
    )..layout(maxWidth: size.width);
    final lines = layout.computeLineMetrics();
    layout.dispose();
    final total = lines.fold<double>(0, (sum, l) => sum + l.width);
    if (total <= 0) return;
    final pen = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = (style.fontSize ?? 14) * 0.1 + 0.4
      ..strokeCap = StrokeCap.round;
    // The pen crosses the lines in reading order, as one continuous stroke.
    var budget = total * p;
    for (final line in lines) {
      if (budget <= 0) break;
      final len = budget.clamp(0.0, line.width);
      budget -= line.width;
      final y = line.baseline - line.ascent * 0.3;
      final x0 = line.left - 2;
      final x1 = line.left + len + (len >= line.width ? 2 : 0);
      final rise = (line.width / 40).clamp(0.6, 2.2);
      final f = len / line.width;
      canvas.drawPath(
        Path()
          ..moveTo(x0, y + rise * 0.5)
          ..quadraticBezierTo((x0 + x1) / 2, y + rise * 0.2 - 0.6, x1, y + rise * 0.5 - rise * f),
        pen,
      );
    }
  }

  @override
  bool shouldRepaint(_StrikePainter old) =>
      old.text != text || old.style != style || old.ink != ink || old.maxLines != maxLines || old.scaler != scaler;
}
