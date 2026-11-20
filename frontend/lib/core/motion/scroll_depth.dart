import 'package:flutter/material.dart';
import 'reveal.dart';

/// Gives a card depth as it moves through the screen: it rises a little as it comes up
/// from the bottom edge, and sinks, shrinks and fades as it leaves past the top, as if
/// passing under glass. Nothing tilts.
/// Every card gets the same motion. Passes its child through untouched outside a
/// vertical scrollable.
class ScrollDepth extends StatefulWidget {
  final Widget child;

  const ScrollDepth({super.key, required this.child});

  @override
  State<ScrollDepth> createState() => _ScrollDepthState();
}

class _ScrollDepthState extends State<ScrollDepth> {
  ScrollableState? _scrollable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = Scrollable.maybeOf(context);
    _scrollable = s != null && s.axisDirection == AxisDirection.down ? s : null;
  }

  /// How far the card is through the bottom edge (0 settled, 1 just peeking in), and how
  /// far it has left past the top (0 fully on screen, 1 gone).
  (double, double) _progress() {
    final box = context.findRenderObject();
    final viewport = _scrollable?.context.findRenderObject();
    if (box is! RenderBox || viewport is! RenderBox || !box.attached || !viewport.attached || !box.hasSize || !viewport.hasSize) {
      return (0, 0);
    }
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    final h = box.size.height;
    if (top < 0) return (0, (-top / (h * 0.9)).clamp(0.0, 1.0));
    // Arriving cards settle over the last stretch of the screen, at most 220px of it.
    final zone = h.clamp(80.0, 220.0);
    return (((top + zone - viewport.size.height) / zone).clamp(0.0, 1.0), 0);
  }

  @override
  Widget build(BuildContext context) {
    final scrollable = _scrollable;
    if (scrollable == null || Motion.reduced(context)) return widget.child;

    return AnimatedBuilder(
      animation: scrollable.position,
      child: widget.child,
      builder: (context, child) {
        final (arriving, leaving) = _progress();
        if (leaving > 0) {
          final p = Curves.easeIn.transform(leaving);
          final m = Matrix4.translationValues(0, p * 18, 0)..scaleByDouble(1 - 0.06 * p, 1 - 0.06 * p, 1, 1);
          return Opacity(
            opacity: 1 - 0.6 * p,
            child: Transform(alignment: Alignment.bottomCenter, transform: m, child: child),
          );
        }
        if (arriving > 0) {
          final p = Curves.easeOut.transform(arriving);
          final m = Matrix4.translationValues(0, p * 22, 0)..scaleByDouble(1 - 0.035 * p, 1 - 0.035 * p, 1, 1);
          return Opacity(
            opacity: 1 - 0.4 * p,
            child: Transform(alignment: Alignment.topCenter, transform: m, child: child),
          );
        }
        return child!;
      },
    );
  }
}
