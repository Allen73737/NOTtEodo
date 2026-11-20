import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'reveal.dart';
import '../editorial/editorial_mode.dart';

enum PresenceStyle {
  /// Settles in from a slight zoom; for centred dialogs that bring their own scrim.
  dialog,

  /// Rises from below; for full-screen studios and sheets.
  sheet,

  /// Descends from above; for command palettes and search.
  palette,

  /// Plain cross-fade.
  fade,
}

/// Mounts [child] with an entrance animation when [visible] becomes true and plays an
/// exit animation before unmounting it when [visible] becomes false — the missing
/// half of `if (open) Overlay()` patterns.
class MotionPresence extends StatefulWidget {
  final bool visible;
  final Widget child;
  final PresenceStyle style;

  const MotionPresence({
    super.key,
    required this.visible,
    required this.child,
    this.style = PresenceStyle.dialog,
  });

  @override
  State<MotionPresence> createState() => _MotionPresenceState();
}

class _MotionPresenceState extends State<MotionPresence> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    reverseDuration: Motion.exit,
    value: widget.visible ? 0 : 0,
  );
  Widget? _lastChild;

  @override
  void initState() {
    super.initState();
    if (widget.visible) {
      _lastChild = widget.child;
      _controller.forward();
    }
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted) setState(() => _lastChild = null);
    });
  }

  @override
  void didUpdateWidget(MotionPresence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible) {
      _lastChild = widget.child;
      if (!oldWidget.visible) _controller.forward();
    } else if (oldWidget.visible) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = _lastChild;
    if (child == null) return const SizedBox.shrink();
    if (Motion.reduced(context)) return widget.visible ? child : const SizedBox.shrink();

    return IgnorePointer(
      // Let taps fall through the moment an exit starts.
      ignoring: !widget.visible,
      child: AnimatedBuilder(
        animation: _controller,
        child: child,
        builder: (context, child) {
          final entering = _controller.status != AnimationStatus.reverse;
          final raw = _controller.value;
          final t = entering ? Motion.silk.transform(raw) : Motion.exitCurve.flipped.transform(raw);
          final inv = 1 - t;

          var dy = 0.0, scale = 1.0;
          switch (widget.style) {
            case PresenceStyle.dialog:
              scale = entering ? 1.06 - 0.06 * t : 0.97 + 0.03 * t;
            case PresenceStyle.sheet:
              dy = inv * (entering ? 48 : 28);
            case PresenceStyle.palette:
              dy = -inv * 24;
              scale = 1.02 - 0.02 * t;
            case PresenceStyle.fade:
              break;
          }

          return Opacity(
            opacity: Curves.easeOut.transform(raw),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.translationValues(0, dy, 0)..scaleByDouble(scale, scale, 1, 1),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// Switches between app modules with a direction-aware shared-axis transition:
/// the new module glides in from the side it lives on while the old one recedes.
///
/// [dimensional] (the card view) opens the new module as a widening circle from the
/// dock instead, while the old one sinks back beneath it.
class ModuleSwitcher extends StatefulWidget {
  final int index;
  final Widget child;
  final bool dimensional;

  const ModuleSwitcher({super.key, required this.index, required this.child, this.dimensional = false});

  @override
  State<ModuleSwitcher> createState() => _ModuleSwitcherState();
}

class _ModuleSwitcherState extends State<ModuleSwitcher> {
  int _direction = 1;

  @override
  void didUpdateWidget(ModuleSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _direction = widget.index > oldWidget.index ? 1 : -1;
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    final width = MediaQuery.sizeOf(context).width;
    final travel = (width * 0.06).clamp(18.0, 64.0);
    final currentKey = ValueKey(widget.index);

    final dimensional = widget.dimensional;
    return AnimatedSwitcher(
      duration: reduced ? Duration.zero : Duration(milliseconds: dimensional ? 680 : 460),
      reverseDuration: reduced ? Duration.zero : Duration(milliseconds: dimensional ? 680 : 260),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) {
        final incoming = child.key == currentKey;
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final v = animation.value;
            if (dimensional) return _iris(child!, v, incoming, travel);
            final double dx, scale, opacity;
            if (incoming) {
              final t = Motion.silk.transform(v);
              dx = (1 - t) * travel * _direction;
              scale = 0.985 + 0.015 * t;
              opacity = Curves.easeOut.transform(((v - 0.15) / 0.85).clamp(0.0, 1.0));
            } else {
              // Outgoing runs 1 → 0.
              final t = 1 - v;
              dx = -t * travel * 0.6 * _direction;
              scale = 1 - 0.02 * t;
              opacity = v;
            }
            return IgnorePointer(
              ignoring: !incoming,
              child: Opacity(
                opacity: opacity,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.translationValues(dx, 0, 0)..scaleByDouble(scale, scale, 1, 1),
                  child: child,
                ),
              ),
            );
          },
        );
      },
      child: KeyedSubtree(key: currentKey, child: widget.child),
    );
  }

  /// Card view: the new module opens as a widening circle from the dock, on the side of
  /// the tab it lives on, its edge traced by a hairline of light; it settles from a hair
  /// larger as it opens. The old module sinks back and darkens beneath it.
  Widget _iris(Widget child, double v, bool incoming, double travel) {
    final dir = _direction.toDouble();
    if (incoming) {
      final open = _irisCurve.transform(v);
      final settle = Motion.silk.transform(v);
      final scale = 1.03 - 0.03 * settle;
      final dark = Theme.of(context).brightness == Brightness.dark;
      final edge = (dark ? const Color(0xFFD0485A) : const Color(0xFF8E2433)).withValues(alpha: 0.5 * (1 - open));
      return IgnorePointer(
        ignoring: v < 0.6,
        child: ClipPath(
          clipper: _IrisClipper(open, Alignment(0.42 * dir, 1.08)),
          child: CustomPaint(
            foregroundPainter: open < 0.999 ? _IrisEdgePainter(open, Alignment(0.42 * dir, 1.08), edge) : null,
            child: Transform(
              alignment: Alignment(0.42 * dir, 1),
              transform: Matrix4.translationValues(0, (1 - settle) * 10, 0)..scaleByDouble(scale, scale, 1, 1),
              child: child,
            ),
          ),
        ),
      );
    }
    // Outgoing runs 1 → 0.
    final t = Curves.easeOutCubic.transform(1 - v);
    return IgnorePointer(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.translationValues(0, -t * 8, 0)..scaleByDouble(1 - 0.045 * t, 1 - 0.045 * t, 1, 1),
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.38 * t), BlendMode.srcATop),
          child: child,
        ),
      ),
    );
  }

  static const Curve _irisCurve = Cubic(0.6, 0, 0.18, 1);
}

/// A circle that grows from [origin] until it covers the whole box.
class _IrisClipper extends CustomClipper<Path> {
  final double open;
  final Alignment origin;

  _IrisClipper(this.open, this.origin);

  static double reach(Size size, Offset c) {
    double far = 0;
    for (final corner in [Offset.zero, Offset(size.width, 0), Offset(0, size.height), Offset(size.width, size.height)]) {
      far = far > (corner - c).distance ? far : (corner - c).distance;
    }
    return far;
  }

  @override
  Path getClip(Size size) {
    final c = origin.alongSize(size);
    return Path()..addOval(Rect.fromCircle(center: c, radius: reach(size, c) * open + 1));
  }

  @override
  bool shouldReclip(_IrisClipper old) => old.open != open || old.origin != origin;
}

class _IrisEdgePainter extends CustomPainter {
  final double open;
  final Alignment origin;
  final Color color;

  _IrisEdgePainter(this.open, this.origin, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a < 0.01) return;
    final c = origin.alongSize(size);
    final r = _IrisClipper.reach(size, c) * open;
    canvas.drawCircle(c, r - 1, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color);
    canvas.drawCircle(c, r - 6, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..color = color.withValues(alpha: color.a * 0.35));
  }

  @override
  bool shouldRepaint(_IrisEdgePainter old) => old.open != open || old.color != color;
}

/// Route transition for pushed screens: the new page rises and settles while the
/// page beneath recedes and dims, giving navigation a sense of depth.
class SanctuaryPageTransitionsBuilder extends PageTransitionsBuilder {
  const SanctuaryPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 520);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Motion.reduced(context)) return FadeTransition(opacity: animation, child: child);
    if (!EditorialMode.active) return _unfold(animation, secondaryAnimation, child);

    final enter = CurvedAnimation(parent: animation, curve: Motion.silk, reverseCurve: Motion.exitCurve.flipped);
    final under = CurvedAnimation(parent: secondaryAnimation, curve: Motion.silk);

    return AnimatedBuilder(
      animation: Listenable.merge([enter, under]),
      child: child,
      builder: (context, child) {
        final t = enter.value;
        final u = under.value;
        final scale = (0.96 + 0.04 * t) * (1 - 0.04 * u);
        return Opacity(
          opacity: Curves.easeOut.transform(animation.value.clamp(0.0, 1.0)),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.translationValues(0, (1 - t) * 40, 0)..scaleByDouble(scale, scale, 1, 1),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.28 * u), BlendMode.srcATop),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// The card view's page transition: the new page rises like a sheet laid on a stack,
/// its top corners rounded until it lands flush, a soft shadow along its upper edge.
/// The page beneath sinks a little, rounds its corners and dims, so the stack reads
/// as depth rather than a slide.
Widget _unfold(Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
  final enter = CurvedAnimation(parent: animation, curve: const Cubic(0.2, 0.9, 0.25, 1), reverseCurve: const Cubic(0.5, 0, 0.9, 0.6));
  final under = CurvedAnimation(parent: secondaryAnimation, curve: Motion.silk, reverseCurve: Motion.silk.flipped);
  return AnimatedBuilder(
    animation: Listenable.merge([enter, under]),
    child: child,
    builder: (context, child) {
      final t = enter.value;
      final inv = 1 - t;
      final u = under.value;
      Widget page = child!;
      if (u > 0.001) {
        // Beneath: sink, round and dim.
        final scale = 1 - 0.06 * u;
        page = Transform(
          alignment: Alignment.topCenter,
          transform: Matrix4.translationValues(0, 14 * u, 0)..scaleByDouble(scale, scale, 1, 1),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26 * u),
            child: ColorFiltered(colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.34 * u), BlendMode.srcATop), child: page),
          ),
        );
      }
      if (inv < 0.001) return page;
      final radius = 30 * inv;
      return FractionalTranslation(
        translation: Offset(0, 0.9 * inv),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.28 * (t < 0.98 ? 1 : 0)), blurRadius: 30, offset: const Offset(0, -6))],
          ),
          child: ClipRRect(borderRadius: BorderRadius.vertical(top: Radius.circular(radius)), child: page),
        ),
      );
    },
  );
}

/// Drop-in replacement for [showDialog]: frosted, dimmed backdrop and a dialog that
/// settles in from a slight zoom, then sinks away on dismiss.
Future<T?> showSanctuaryDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final reduced = Motion.reduced(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: reduced ? Duration.zero : const Duration(milliseconds: 420),
    pageBuilder: (context, _, __) => SafeArea(child: Builder(builder: builder)),
    transitionBuilder: (context, animation, _, child) {
      final t = CurvedAnimation(parent: animation, curve: Motion.silk, reverseCurve: Motion.exitCurve.flipped);
      return AnimatedBuilder(
        animation: t,
        child: child,
        builder: (context, child) {
          final v = t.value;
          final dark = Theme.of(context).brightness == Brightness.dark;
          return Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 6 * v, sigmaY: 6 * v),
                    child: ColoredBox(color: Colors.black.withValues(alpha: (dark ? 0.62 : 0.38) * v)),
                  ),
                ),
              ),
              Opacity(
                opacity: animation.value.clamp(0.0, 1.0),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.translationValues(0, (1 - v) * 18, 0)
                    ..scaleByDouble(0.94 + 0.06 * v, 0.94 + 0.06 * v, 1, 1),
                  child: child,
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
