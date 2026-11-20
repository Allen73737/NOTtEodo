import 'package:flutter/material.dart';

import 'reveal.dart';

/// Remembers the card that was touched last, so the screen it opens can zoom out of it.
abstract class CardOrigin {
  static Rect? _rect;
  static double _radius = 22;
  static DateTime _at = DateTime.fromMillisecondsSinceEpoch(0);

  /// Records the on-screen bounds of the card at [context].
  static void note(BuildContext context, {double radius = 22}) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    _rect = MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
    _radius = radius;
    _at = DateTime.now();
  }

  /// Forgets the card, e.g. when the touch turned into a scroll.
  static void clear() => _rect = null;

  /// The card touched a moment ago, if any; consumed so it opens only one screen.
  static (Rect, double)? take() {
    final rect = _rect;
    _rect = null;
    if (rect == null || DateTime.now().difference(_at) > const Duration(milliseconds: 900)) return null;
    return (rect, _radius);
  }

  /// Where on a screen of [size] a zoom through [origin] is centred; a little above the
  /// middle when the screen was not opened from a card.
  static Alignment pivot(Rect? origin, Size size) {
    if (origin == null || size.isEmpty) return const Alignment(0, -0.15);
    final c = origin.center;
    return Alignment((c.dx / size.width * 2 - 1).clamp(-1.0, 1.0), (c.dy / size.height * 2 - 1).clamp(-1.0, 1.0));
  }
}

/// Opens a screen by zooming through the card it came from. The page beneath grows
/// toward the card and dims (see [ZoomThrough.beneath]) while the new screen comes up out
/// of that same point, a little small, and settles.
/// One motion, one focal point; nothing is squeezed or cross-faded. Closing runs it
/// backwards into the card.
class ZoomThrough extends StatefulWidget {
  final Animation<double> animation;

  /// The card's on-screen bounds, or null to zoom from just above the middle.
  final Rect? origin;

  /// Dim the page behind; off when the page beneath dims itself.
  final bool scrim;

  /// True while a finger drives [animation]: the screen then follows it down.
  final bool Function()? tracking;
  final Widget child;

  const ZoomThrough({super.key, required this.animation, required this.child, this.origin, this.scrim = false, this.tracking});

  /// The page beneath a zooming screen at depth [u] (0 at rest, 1 fully covered).
  static Widget beneath(BuildContext context, double u, Rect? origin, Widget child) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scale = 1 + 0.05 * u;
    return Transform(
      alignment: CardOrigin.pivot(origin, MediaQuery.sizeOf(context)),
      transform: Matrix4.diagonal3Values(scale, scale, 1),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(child: ColoredBox(color: Colors.black.withValues(alpha: (dark ? 0.5 : 0.22) * u))),
          ),
        ],
      ),
    );
  }

  @override
  State<ZoomThrough> createState() => _ZoomThroughState();
}

class _ZoomThroughState extends State<ZoomThrough> {
  late final CurvedAnimation _t = CurvedAnimation(parent: widget.animation, curve: Motion.silk, reverseCurve: Motion.silk.flipped);

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final pivot = CardOrigin.pivot(widget.origin, size);
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final follow = widget.tracking?.call() ?? false;
        // A finger moves the screen one to one; otherwise it eases.
        final t = (follow ? widget.animation.value : _t.value).clamp(0.0, 1.0);
        final inv = 1 - t;
        final scale = 0.94 + 0.06 * t;
        // The shape of this tree never changes, so the screen keeps its state at rest.
        return Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: ColoredBox(color: Colors.black.withValues(alpha: widget.scrim ? (dark ? 0.6 : 0.3) * t : 0)),
            ),
            IgnorePointer(
              ignoring: !follow && widget.animation.status != AnimationStatus.completed,
              child: Opacity(
                opacity: Curves.easeOut.transform((t * 1.6).clamp(0.0, 1.0)),
                child: Transform(
                  alignment: pivot,
                  transform: Matrix4.translationValues(0, follow ? inv * size.height * 0.9 : 0, 0)..scaleByDouble(scale, scale, 1, 1),
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
