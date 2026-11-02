import 'package:flutter/material.dart';
import 'reveal.dart';

/// Gives a screen's opening element depth as content scrolls over it: it trails the
/// scroll slightly (parallax) and softens, rather than sliding away rigidly.
/// Passes its child through untouched outside a vertical scrollable.
class ScrollFade extends StatefulWidget {
  final Widget child;

  const ScrollFade({super.key, required this.child});

  @override
  State<ScrollFade> createState() => _ScrollFadeState();
}

class _ScrollFadeState extends State<ScrollFade> {
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scrollable = Scrollable.maybeOf(context);
    _position = scrollable != null && scrollable.axisDirection == AxisDirection.down ? scrollable.position : null;
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    if (position == null || Motion.reduced(context)) return widget.child;

    return AnimatedBuilder(
      animation: position,
      child: widget.child,
      builder: (context, child) {
        final px = position.hasPixels ? position.pixels.clamp(0.0, 320.0) : 0.0;
        return Opacity(
          opacity: 1 - (px / 320) * 0.65,
          child: Transform.translate(offset: Offset(0, px * 0.28), child: child),
        );
      },
    );
  }
}
