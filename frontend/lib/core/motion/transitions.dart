import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'reveal.dart';

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
/// [dimensional] (the card view) turns it into a swing through space: the new module
/// pivots in on its near edge like a card being turned while the old one swings away.
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
      duration: reduced ? Duration.zero : Duration(milliseconds: dimensional ? 620 : 460),
      reverseDuration: reduced ? Duration.zero : Duration(milliseconds: dimensional ? 340 : 260),
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
            if (dimensional) return _swing(child!, v, incoming, travel);
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

  Widget _swing(Widget child, double v, bool incoming, double travel) {
    final dir = _direction.toDouble();
    final Matrix4 m;
    final double opacity;
    final Alignment hinge;
    if (incoming) {
      final t = Motion.settle.transform(v);
      final inv = 1 - t;
      hinge = dir > 0 ? Alignment.centerLeft : Alignment.centerRight;
      m = Matrix4.identity()
        ..setEntry(3, 2, 0.0011)
        ..translateByDouble(inv * travel * 1.6 * dir, inv * 24, 0, 1)
        ..rotateY(-inv * 0.55 * dir)
        ..scaleByDouble(0.9 + 0.1 * t, 0.9 + 0.1 * t, 1, 1);
      opacity = Curves.easeOut.transform(((v - 0.08) / 0.6).clamp(0.0, 1.0));
    } else {
      // Outgoing runs 1 → 0.
      final t = Curves.easeInCubic.transform(1 - v);
      hinge = dir > 0 ? Alignment.centerRight : Alignment.centerLeft;
      m = Matrix4.identity()
        ..setEntry(3, 2, 0.0011)
        ..translateByDouble(-t * travel * dir, 0, 0, 1)
        ..rotateY(t * 0.4 * dir)
        ..scaleByDouble(1 - 0.1 * t, 1 - 0.1 * t, 1, 1);
      opacity = v;
    }
    return IgnorePointer(
      ignoring: !incoming,
      child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: Transform(alignment: hinge, transform: m, child: child)),
    );
  }
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
