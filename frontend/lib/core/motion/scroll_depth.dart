import 'package:flutter/material.dart';
import 'reveal.dart';

/// Gives a card depth as it scrolls off the top of the screen: it tips back on its
/// lower edge, shrinks a little and dims, like a card being leafed past in a stack.
/// Passes its child through untouched outside a vertical scrollable.
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

  /// 0 while the card is fully on screen, rising to 1 as it leaves past the top.
  double _leaving() {
    final box = context.findRenderObject();
    final viewport = _scrollable?.context.findRenderObject();
    if (box is! RenderBox || viewport is! RenderBox || !box.attached || !viewport.attached || !box.hasSize) return 0;
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    if (top >= 0) return 0;
    return (-top / (box.size.height * 0.9)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final scrollable = _scrollable;
    if (scrollable == null || Motion.reduced(context)) return widget.child;

    return AnimatedBuilder(
      animation: scrollable.position,
      child: widget.child,
      builder: (context, child) {
        final p = Curves.easeIn.transform(_leaving());
        if (p == 0) return child!;
        final m = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateX(p * 0.32)
          ..scaleByDouble(1 - 0.07 * p, 1 - 0.07 * p, 1, 1);
        return Opacity(
          opacity: 1 - 0.55 * p,
          child: Transform(alignment: Alignment.bottomCenter, transform: m, child: child),
        );
      },
    );
  }
}
