import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'card_morph.dart';
import 'reveal.dart';

/// Card view: the card catches the light where it is touched. A soft bloom opens under
/// the finger and follows it, the rim brightens to a hairline, and on release the light
/// drains away slowly. Nothing moves or tilts; the press itself is the card's scale.
///
/// Built on raw pointer events so it never competes with taps or scrolling; a drag
/// that turns into a scroll lets the light go.
class TouchSheen extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final Color light;
  final Color rim;

  const TouchSheen({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.light = Colors.white,
    this.rim = Colors.white,
  });

  @override
  State<TouchSheen> createState() => _TouchSheenState();
}

class _TouchSheenState extends State<TouchSheen> with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 720),
  );
  late final Animation<double> _amount = CurvedAnimation(parent: _glow, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInOutSine);
  final ValueNotifier<Offset> _at = ValueNotifier(Offset.zero);
  Offset? _downAt;

  @override
  void dispose() {
    _glow.dispose();
    _at.dispose();
    super.dispose();
  }

  void _press(Offset local) {
    if (Motion.reduced(context)) return;
    _at.value = local;
    _glow.forward();
  }

  void _release() {
    _downAt = null;
    _glow.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) {
        if (e.kind != PointerDeviceKind.mouse) return;
        _at.value = e.localPosition;
        if (!_glow.isForwardOrCompleted) _glow.animateTo(0.55);
      },
      onExit: (_) => _release(),
      child: Listener(
        onPointerDown: (e) {
          _downAt = e.localPosition;
          // Whatever this card opens grows out of it.
          CardOrigin.note(context, radius: widget.borderRadius.topLeft.x);
          _press(e.localPosition);
        },
        onPointerMove: (e) {
          final down = _downAt;
          if (down != null && (e.localPosition - down).distance > 18) {
            CardOrigin.clear();
            _release();
            return;
          }
          _at.value = e.localPosition;
        },
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: CustomPaint(
          foregroundPainter: _SheenPainter(
            repaint: Listenable.merge([_amount, _at]),
            amount: _amount,
            at: _at,
            light: widget.light,
            rim: widget.rim,
            radius: widget.borderRadius,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _SheenPainter extends CustomPainter {
  final Animation<double> amount;
  final ValueNotifier<Offset> at;
  final Color light;
  final Color rim;
  final BorderRadius radius;

  _SheenPainter({required Listenable repaint, required this.amount, required this.at, required this.light, required this.rim, required this.radius})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final a = amount.value.clamp(0.0, 1.0);
    if (a <= 0.01) return;
    final rect = Offset.zero & size;
    final rrect = radius.toRRect(rect);
    canvas.save();
    canvas.clipRRect(rrect);
    // The bloom opens from a point to a broad pool of light.
    final r = size.shortestSide.clamp(140.0, 380.0) * (0.45 + 0.55 * a);
    final c = at.value;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [light.withValues(alpha: 0.13 * a), light.withValues(alpha: 0.05 * a), light.withValues(alpha: 0)],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.restore();
    // A hairline rim, brightest on the side nearest the finger.
    final dx = size.width == 0 ? 0.0 : (c.dx / size.width * 2 - 1).clamp(-1.0, 1.0);
    final dy = size.height == 0 ? 0.0 : (c.dy / size.height * 2 - 1).clamp(-1.0, 1.0);
    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment(dx, dy),
          end: Alignment(-dx, -dy),
          colors: [rim.withValues(alpha: 0.42 * a), rim.withValues(alpha: 0.06 * a)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SheenPainter old) => old.light != light || old.rim != rim || old.radius != radius;
}
