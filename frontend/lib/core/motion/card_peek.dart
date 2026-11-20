import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Hold-to-preview for a card: a picture of the card lifts off the page, larger and
/// drawn toward the middle of the screen, while everything behind it blurs and dims.
/// Letting go settles it back into place.
class CardPeek {
  CardPeek._(this._state);

  final GlobalKey<_PeekState> _state;

  /// Lifts the card painted by [boundary]; returns null if it cannot be pictured.
  static CardPeek? show(BuildContext context, RenderRepaintBoundary boundary, {double radius = 22}) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null || !boundary.attached || !boundary.hasSize) return null;
    final ui.Image image;
    try {
      image = boundary.toImageSync(pixelRatio: MediaQuery.devicePixelRatioOf(context));
    } catch (_) {
      return null;
    }
    final rect = MatrixUtils.transformRect(boundary.getTransformTo(null), Offset.zero & boundary.size);
    final key = GlobalKey<_PeekState>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Peek(
        key: key,
        image: image,
        origin: rect,
        radius: radius,
        onGone: () {
          entry.remove();
          entry.dispose();
          image.dispose();
        },
      ),
    );
    overlay.insert(entry);
    HapticFeedback.mediumImpact();
    return CardPeek._(key);
  }

  /// Settles the card back into the page.
  void release() => _state.currentState?.close();
}

class _Peek extends StatefulWidget {
  final ui.Image image;
  final Rect origin;
  final double radius;
  final VoidCallback onGone;

  const _Peek({super.key, required this.image, required this.origin, required this.radius, required this.onGone});

  @override
  State<_Peek> createState() => _PeekState();
}

class _PeekState extends State<_Peek> with SingleTickerProviderStateMixin {
  late final AnimationController _lift = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    reverseDuration: const Duration(milliseconds: 300),
  )..forward();
  late final Animation<double> _t = CurvedAnimation(parent: _lift, curve: const Cubic(0.34, 1.3, 0.64, 1), reverseCurve: Curves.easeInCubic);
  bool _closing = false;

  void close() {
    if (_closing) return;
    _closing = true;
    HapticFeedback.lightImpact();
    _lift.reverse().whenComplete(widget.onGone);
  }

  @override
  void dispose() {
    _lift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final o = widget.origin;
    // Large enough to read, never wider than the screen's margins.
    final grow = ((screen.width - 32) / o.width).clamp(1.0, 1.14);
    final towardMiddle = Offset(screen.width / 2, screen.height * 0.45) - o.center;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: close,
            child: AnimatedBuilder(
              animation: _lift,
              builder: (context, _) {
                final v = _lift.value;
                return BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 14 * v, sigmaY: 14 * v),
                  child: ColoredBox(color: Colors.black.withValues(alpha: (dark ? 0.5 : 0.22) * v)),
                );
              },
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final t = _t.value;
            final scale = 1 + (grow - 1) * t;
            final shift = towardMiddle * 0.35 * t;
            return Positioned.fromRect(
              rect: o.shift(shift),
              child: IgnorePointer(
                child: Transform.scale(
                  scale: scale,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.radius),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: (dark ? 0.7 : 0.22) * _lift.value), blurRadius: 48, offset: Offset(0, 24 * _lift.value)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.radius),
                      child: RawImage(image: widget.image, fit: BoxFit.fill),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
