import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'zoom_through.dart';
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
/// [dimensional] (the card view) moves each card instead of the page: the old module's
/// cards slip away one by one, then the new module's cards arrive in turn.
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
      duration: reduced ? Duration.zero : Duration(milliseconds: dimensional ? 760 : 460),
      reverseDuration: reduced ? Duration.zero : Duration(milliseconds: dimensional ? 760 : 260),
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
            if (dimensional) return _stage(child!, animation, incoming);
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

  /// Card view: the page holds still and its elements do the moving (see
  /// [PageChoreography]). The old page's cards slip away one by one; once they have
  /// cleared, the new page appears and its cards arrive in turn from the side of the
  /// chosen tab.
  Widget _stage(Widget child, Animation<double> animation, bool incoming) {
    final v = animation.value;
    final opacity = incoming
        ? Curves.easeOut.transform(const Interval(0.36, 0.46).transform(v))
        : 1 - const Interval(0.42, 0.56).transform(1 - v);
    return IgnorePointer(
      ignoring: !incoming || v < 0.5,
      child: Opacity(
        opacity: opacity,
        child: PageChoreography(animation: animation, incoming: incoming, direction: _direction, child: child),
      ),
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
    if (!EditorialMode.active) return _unfold(route, animation, secondaryAnimation, child);

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

/// The card view's page transition: the screen zooms through the card it was opened
/// from (see [ZoomThrough]). The page beneath grows toward that card and dims as the new
/// screen comes up out of it; a screen not opened from a card zooms from just above the
/// middle. It can be pulled down to close: it follows the finger while the page beneath
/// settles back and brightens.
Widget _unfold(PageRoute<dynamic> route, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
  if (_seen[route] == null) {
    _seen[route] = true;
    final origin = animation.status == AnimationStatus.forward ? CardOrigin.take() : null;
    _focus[route] = _lastFocus = _Focus(origin?.$1);
  }
  bool tracking() => route.navigator?.userGestureInProgress ?? false;
  final under = CurvedAnimation(parent: secondaryAnimation, curve: Motion.silk, reverseCurve: Motion.silk.flipped);
  return AnimatedBuilder(
    animation: under,
    child: ZoomThrough(
      animation: animation,
      origin: _focus[route]?.rect,
      tracking: tracking,
      child: _PullToClose(route: route, child: child),
    ),
    builder: (context, child) {
      final u = tracking() ? secondaryAnimation.value : under.value;
      if (u <= 0.001) {
        _beneath[route] = null;
        return child!;
      }
      // Grows toward the card the screen above was opened from.
      final focus = _beneath[route] ??= _lastFocus;
      return ZoomThrough.beneath(context, u, focus.rect, child!);
    },
  );
}

class _Focus {
  final Rect? rect;
  const _Focus(this.rect);
}

final Expando<bool> _seen = Expando();
final Expando<_Focus> _focus = Expando();
final Expando<_Focus> _beneath = Expando();
_Focus _lastFocus = const _Focus(null);

/// Lets a pushed card-view screen be pulled down to close. The pull starts only from a
/// downward drag while the screen's content is scrolled to the top, so it never fights
/// scrolling; released past a third of the way or with a flick, the screen closes,
/// otherwise it springs back.
class _PullToClose extends StatefulWidget {
  final PageRoute<dynamic> route;
  final Widget child;

  const _PullToClose({required this.route, required this.child});

  @override
  State<_PullToClose> createState() => _PullToCloseState();
}

class _PullToCloseState extends State<_PullToClose> {
  final Map<Object, bool> _atTop = {};
  bool _pulling = false;

  // The same controller the framework's own back-swipe drives.
  // ignore: invalid_use_of_protected_member
  AnimationController? get _controller => widget.route.controller;

  bool get _allowed =>
      widget.route.isCurrent &&
      !widget.route.isFirst &&
      widget.route.popDisposition == RoutePopDisposition.pop &&
      !(widget.route.navigator?.userGestureInProgress ?? true) &&
      _atTop.values.every((top) => top);

  double get _travel => context.size!.height * 0.9;

  void _start() {
    _pulling = true;
    widget.route.navigator!.didStartUserGesture();
  }

  void _update(double dy) {
    final c = _controller;
    if (!_pulling || c == null) return;
    c.value = (c.value - dy / _travel).clamp(0.0, 1.0);
  }

  void _end(double velocity) {
    final c = _controller;
    if (!_pulling || c == null) return;
    _pulling = false;
    final navigator = widget.route.navigator!;
    final flick = velocity / _travel;
    final close = flick > 1.1 || (flick > -1.1 && c.value < 0.68);
    if (close) {
      HapticFeedback.lightImpact();
      navigator.pop();
    } else {
      c.animateTo(1, duration: const Duration(milliseconds: 340), curve: Curves.easeOutCubic);
    }
    if (c.isAnimating) {
      late AnimationStatusListener done;
      done = (_) {
        navigator.didStopUserGesture();
        c.removeStatusListener(done);
      };
      c.addStatusListener(done);
    } else {
      navigator.didStopUserGesture();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.axis == Axis.vertical) _atTop[n.context ?? n] = n.metrics.pixels <= n.metrics.minScrollExtent + 0.5;
        return false;
      },
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          // Sits above the page but lets every touch through to it as well; it only
          // claims a drag that starts downward from the top of the content.
          Positioned.fill(
            child: RawGestureDetector(
              behavior: HitTestBehavior.translucent,
              gestures: {
                _DownwardDrag: GestureRecognizerFactoryWithHandlers<_DownwardDrag>(
                  () => _DownwardDrag(),
                  (r) => r
                    ..allowed = (() => _allowed)
                    ..onStart = ((_) => _start())
                    ..onUpdate = ((d) => _update(d.delta.dy))
                    ..onEnd = ((d) => _end(d.velocity.pixelsPerSecond.dy))
                    ..onCancel = (() => _end(0)),
                ),
              },
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

/// A vertical drag that only wins the gesture when it begins downward and is allowed.
class _DownwardDrag extends VerticalDragGestureRecognizer {
  bool Function() allowed = () => false;
  Offset _origin = Offset.zero;
  Offset _last = Offset.zero;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _origin = _last = event.position;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) _last = event.position;
    super.handleEvent(event);
  }

  @override
  bool hasSufficientGlobalDistanceToAccept(PointerDeviceKind pointerDeviceKind, double? deviceTouchSlop) =>
      super.hasSufficientGlobalDistanceToAccept(pointerDeviceKind, deviceTouchSlop) &&
      (_last - _origin).dy > (_last - _origin).dx.abs() &&
      allowed();
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
