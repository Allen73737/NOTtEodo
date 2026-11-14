import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'reveal.dart';

/// Card view: leans its child toward the finger (or cursor) in 3D, with a soft glint
/// that follows, and springs back flat with a small wobble on release.
///
/// Built on raw pointer events so it never competes with taps or scrolling; a drag
/// that turns into a scroll lets the surface go.
class TiltSurface extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;

  /// Largest lean, in radians, at the very edge of the surface.
  final double maxTilt;
  final Color glint;

  const TiltSurface({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.maxTilt = 0.08,
    this.glint = Colors.white,
  });

  @override
  State<TiltSurface> createState() => _TiltSurfaceState();
}

class _TiltSurfaceState extends State<TiltSurface> with SingleTickerProviderStateMixin {
  late final AnimationController _engage = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    reverseDuration: const Duration(milliseconds: 760),
  );
  late final Animation<double> _amount = CurvedAnimation(parent: _engage, curve: Curves.easeOutCubic, reverseCurve: Curves.elasticIn);

  /// Pointer position as -1…1 on each axis, and as pixels for the glint.
  final ValueNotifier<(Offset, Offset)> _pointer = ValueNotifier((Offset.zero, Offset.zero));
  Offset? _downAt;

  @override
  void dispose() {
    _engage.dispose();
    _pointer.dispose();
    super.dispose();
  }

  void _track(Offset local) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final s = box.size;
    final n = Offset((local.dx / s.width * 2 - 1).clamp(-1.0, 1.0), (local.dy / s.height * 2 - 1).clamp(-1.0, 1.0));
    _pointer.value = (n, local);
  }

  void _press(Offset local) {
    if (Motion.reduced(context)) return;
    _track(local);
    _engage.forward();
  }

  void _release() {
    _downAt = null;
    _engage.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) => e.kind == PointerDeviceKind.mouse ? _press(e.localPosition) : null,
      onExit: (_) => _release(),
      child: Listener(
        onPointerDown: (e) {
          _downAt = e.localPosition;
          _press(e.localPosition);
        },
        onPointerMove: (e) {
          final down = _downAt;
          // Moved like a scroll: let go rather than ride along with it.
          if (down != null && (e.localPosition - down).distance > 18) {
            _release();
            return;
          }
          _track(e.localPosition);
        },
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: AnimatedBuilder(
          animation: Listenable.merge([_amount, _pointer]),
          child: widget.child,
          builder: (context, child) {
            final a = _amount.value;
            final (n, px) = _pointer.value;
            final m = Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(-n.dy * widget.maxTilt * a)
              ..rotateY(n.dx * widget.maxTilt * a);
            return Transform(
              alignment: Alignment.center,
              transform: m,
              child: CustomPaint(
                foregroundPainter: _GlintPainter(at: px, amount: a.clamp(0.0, 1.0), color: widget.glint, radius: widget.borderRadius),
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GlintPainter extends CustomPainter {
  final Offset at;
  final double amount;
  final Color color;
  final BorderRadius radius;

  _GlintPainter({required this.at, required this.amount, required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    if (amount <= 0.01) return;
    final rect = Offset.zero & size;
    canvas.clipRRect(radius.toRRect(rect));
    final r = size.shortestSide.clamp(140.0, 360.0);
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(colors: [color.withValues(alpha: 0.11 * amount), color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: at, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_GlintPainter old) => old.at != at || old.amount != amount || old.color != color;
}
