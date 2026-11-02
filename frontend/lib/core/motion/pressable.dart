import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'reveal.dart';

/// Tactile press & hover response for any widget.
///
/// Presses sink the child slightly and release it with a soft overshoot; on pointer
/// devices hovering lifts it a couple of pixels. Built on raw pointer events, so it can
/// wrap widgets that already handle their own taps (InkWell, IconButton, GestureDetector)
/// without competing for the gesture — pass [onTap] only when the child has no handler.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Scale while held down.
  final double pressedScale;

  /// Pixels to lift while hovered (pointer devices only). 0 disables.
  final double hoverLift;
  final bool haptics;
  final bool enabled;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.hoverLift = 2,
    this.haptics = true,
    this.enabled = true,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with TickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 420),
  );
  late final AnimationController _hover = AnimationController(vsync: this, duration: Motion.standard);
  late final Animation<double> _pressCurve = CurvedAnimation(
    parent: _press,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeOutBack.flipped,
  );

  @override
  void dispose() {
    _press.dispose();
    _hover.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent _) {
    if (!widget.enabled) return;
    if (widget.haptics) HapticFeedback.selectionClick();
    _press.forward();
  }

  void _up([PointerEvent? _]) => _press.reverse();

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    Widget content = AnimatedBuilder(
      animation: Listenable.merge([_pressCurve, _hover]),
      child: widget.child,
      builder: (context, child) {
        final p = reduced ? 0.0 : _pressCurve.value;
        final h = reduced ? 0.0 : Motion.silk.transform(_hover.value);
        final scale = 1 - (1 - widget.pressedScale) * p;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.translationValues(0, -widget.hoverLift * h * (1 - p), 0)
            ..scaleByDouble(scale, scale, 1, 1),
          child: child,
        );
      },
    );

    if (widget.onTap != null || widget.onLongPress != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onTap : null,
        onLongPress: widget.enabled ? widget.onLongPress : null,
        child: content,
      );
    }

    return MouseRegion(
      cursor: widget.onTap != null && widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => widget.enabled ? _hover.forward() : null,
      onExit: (_) => _hover.reverse(),
      child: Listener(
        onPointerDown: _down,
        onPointerUp: _up,
        onPointerCancel: _up,
        child: content,
      ),
    );
  }
}
