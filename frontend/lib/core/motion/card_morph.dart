import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Remembers the card that was touched last, so the screen it opens can grow out of it.
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
}

/// Grows a screen out of the card it was opened from: the card's outline widens to fill
/// the screen and its corners square off, while the card's surface gives way to the
/// screen's contents, which grow from the card's width. Closing runs it backwards, so
/// the screen shrinks home into the card.
class CardMorph extends StatefulWidget {
  final Animation<double> animation;
  final Rect origin;
  final double radius;
  final Widget child;

  /// Dim the page behind while the card grows; off when the route below dims itself.
  final bool scrim;

  const CardMorph({super.key, required this.animation, required this.origin, required this.child, this.radius = 22, this.scrim = true});

  @override
  State<CardMorph> createState() => _CardMorphState();
}

class _CardMorphState extends State<CardMorph> {
  late final CurvedAnimation _t = CurvedAnimation(parent: widget.animation, curve: _grow, reverseCurve: _grow.flipped);

  static const Curve _grow = Cubic(0.2, 0, 0, 1);

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF0F0D0D) : Colors.white;
    return LayoutBuilder(
      builder: (context, box) {
        final full = Offset.zero & box.biggest;
        return AnimatedBuilder(
          animation: _t,
          child: widget.child,
          builder: (context, child) {
            final t = _t.value.clamp(0.0, 1.0);
            final raw = widget.animation.value;
            final rect = Rect.lerp(widget.origin, full, t)!;
            final radius = BorderRadius.circular(lerpDouble(widget.radius, 0, t)!);
            final content = const Interval(0.18, 0.62, curve: Curves.easeOut).transform(raw);
            final cover = 1 - const Interval(0.3, 0.75, curve: Curves.easeIn).transform(raw);
            // The shape of this tree never changes, so the screen keeps its state at rest.
            return Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(color: Colors.black.withValues(alpha: widget.scrim ? (dark ? 0.55 : 0.32) * t : 0)),
                  ),
                ),
                Positioned.fromRect(
                  rect: rect,
                  child: IgnorePointer(
                    ignoring: widget.animation.status != AnimationStatus.completed,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: (dark ? 0.6 : 0.18) * (1 - t)), blurRadius: 40, offset: const Offset(0, 18)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: radius,
                        child: ColoredBox(
                          color: surface,
                          child: FittedBox(
                            fit: BoxFit.fitWidth,
                            alignment: Alignment.topCenter,
                            clipBehavior: Clip.hardEdge,
                            child: SizedBox(
                              width: full.width,
                              height: full.height,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Opacity(opacity: content, child: child),
                                  IgnorePointer(child: Opacity(opacity: cover, child: ColoredBox(color: surface))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
