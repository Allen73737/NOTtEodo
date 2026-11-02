import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'scroll_fade.dart';

/// Shared motion vocabulary for NOTtEodo.
abstract class Motion {
  static const Duration quick = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 320);
  static const Duration entrance = Duration(milliseconds: 620);
  static const Duration exit = Duration(milliseconds: 220);

  /// Gentle deceleration with a long, silky tail.
  static const Curve silk = Cubic(0.16, 1, 0.3, 1);

  /// Decelerate with a whisper of overshoot, for things that "land".
  static const Curve settle = Cubic(0.34, 1.36, 0.64, 1);
  static const Curve exitCurve = Cubic(0.4, 0, 1, 1);

  /// Gap between consecutive elements of a cascade, and its ceiling.
  static const Duration staggerStep = Duration(milliseconds: 55);
  static const Duration staggerCap = Duration(milliseconds: 520);

  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Marker for widgets that already run their own [Reveal] entrance, so
/// [RevealChildren.revealed] does not animate them twice.
abstract interface class SelfRevealing {}

enum RevealStyle {
  /// Rise up into place with a slight scale — the default for content blocks.
  rise,

  /// Fall gently into place from above — headers and toolbars.
  drop,

  /// Slide in from the trailing edge — list rows and chips.
  slideIn,

  /// Pop with a soft overshoot — badges, icons, FABs.
  pop,

  /// Defocus → focus: blur clears as it fades in — hero titles.
  focus,

  /// Plain cross-fade.
  fade,
}

/// Entrance animation that plays the first time its child becomes visible on screen.
///
/// Reveals that become visible in the same moment are automatically choreographed into
/// a cascade ordered top-to-bottom, left-to-right, so wrapping widgets is enough to get
/// a staggered entrance — no manual indices. Content below the fold animates as it is
/// scrolled (or laid out) into view. Honours the platform "reduce motion" setting.
class Reveal extends StatefulWidget {
  final Widget child;
  final RevealStyle style;

  /// Extra delay added on top of the automatic cascade slot.
  final Duration delay;
  final Duration duration;

  /// Travel distance in logical pixels for movement-based styles.
  final double distance;

  const Reveal({
    super.key,
    required this.child,
    this.style = RevealStyle.rise,
    this.delay = Duration.zero,
    this.duration = Motion.entrance,
    this.distance = 22,
  });

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration);
  Timer? _timer;
  bool _armed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_armed) return;
    _armed = true;
    if (Motion.reduced(context)) {
      _controller.value = 1;
    } else {
      _RevealScheduler.instance.watch(this);
    }
  }

  void _play(Duration cascadeDelay) {
    if (!mounted) return;
    final delay = cascadeDelay + widget.delay;
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _RevealScheduler.instance.unwatch(this);
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) =>
          _RevealFrame(t: _controller.value, style: widget.style, distance: widget.distance, child: child!),
    );
  }
}

/// Paints a child at progress [t] of a [RevealStyle]. Keeps an identical widget shape for
/// every value of [t] so the child's state is never rebuilt when the animation ends.
class _RevealFrame extends StatelessWidget {
  final double t;
  final RevealStyle style;
  final double distance;
  final Widget child;

  const _RevealFrame({required this.t, required this.style, required this.distance, required this.child});

  @override
  Widget build(BuildContext context) {
    final move = Motion.silk.transform(t);
    final inv = 1 - move;
    final opacity = Curves.easeOut.transform((t * 1.6).clamp(0.0, 1.0));

    var dx = 0.0, dy = 0.0, scale = 1.0, blur = 0.0;
    switch (style) {
      case RevealStyle.rise:
        dy = inv * distance;
        scale = 0.97 + 0.03 * move;
      case RevealStyle.drop:
        dy = -inv * distance * 0.7;
      case RevealStyle.slideIn:
        dx = inv * distance * 1.4;
      case RevealStyle.pop:
        scale = 0.6 + 0.4 * Motion.settle.transform(t);
      case RevealStyle.focus:
        blur = inv * 10;
        scale = 1.04 - 0.04 * move;
      case RevealStyle.fade:
        break;
    }

    final transform = Matrix4.translationValues(dx, dy, 0)..scaleByDouble(scale, scale, 1, 1);
    return Opacity(
      opacity: opacity,
      child: Transform(
        transform: transform,
        alignment: Alignment.center,
        child: ImageFiltered(
          enabled: blur > 0.05,
          imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: child,
        ),
      ),
    );
  }
}

/// Watches pending reveals once per rendered frame (only while some are pending) and
/// releases those that have entered the viewport as one spatially-ordered cascade.
class _RevealScheduler {
  _RevealScheduler._();
  static final _RevealScheduler instance = _RevealScheduler._();

  final Set<_RevealState> _pending = {};
  bool _frameHooked = false;
  DateTime _burstStart = DateTime.fromMillisecondsSinceEpoch(0);
  int _burstIndex = 0;

  void watch(_RevealState state) {
    _pending.add(state);
    _ensureFrame();
  }

  void unwatch(_RevealState state) => _pending.remove(state);

  void _ensureFrame() {
    if (_frameHooked) return;
    _frameHooked = true;
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  void _onFrame(Duration _) {
    _frameHooked = false;
    if (_pending.isEmpty) return;

    final visible = <(_RevealState, Offset)>[];
    for (final state in _pending) {
      final box = state.context.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final view = View.maybeOf(state.context);
      if (view == null) continue;
      final screen = Offset.zero & (view.physicalSize / view.devicePixelRatio);
      final rect = MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
      // Start a touch before the element is fully on screen so it is mid-motion when seen.
      if (rect.overlaps(screen.inflate(-8)) || (rect.isEmpty && screen.contains(rect.topLeft))) {
        visible.add((state, rect.topLeft));
      }
    }

    if (visible.isNotEmpty) {
      visible.sort((a, b) {
        final dy = (a.$2.dy - b.$2.dy);
        return dy.abs() > 12 ? dy.sign.toInt() : a.$2.dx.compareTo(b.$2.dx);
      });
      final now = DateTime.now();
      if (now.difference(_burstStart) > const Duration(milliseconds: 260)) {
        _burstStart = now;
        _burstIndex = 0;
      }
      for (final (state, _) in visible) {
        _pending.remove(state);
        final slot = Motion.staggerStep * _burstIndex++;
        state._play(slot > Motion.staggerCap ? Motion.staggerCap : slot);
      }
    }

    // Keep polling only while something is still waiting to come into view. Polling
    // piggybacks on frames the app renders anyway (scrolling, layout, ambient motion).
    if (_pending.isNotEmpty) {
      _frameHooked = true;
      SchedulerBinding.instance.addPostFrameCallback(_onFrame);
    }
  }
}

extension RevealChildren on List<Widget> {
  /// Wraps each meaningful child in a [Reveal], respecting flex/stack parent-data widgets
  /// and leaving bare spacers untouched, so a Column/Row/Wrap cascades into view.
  ///
  /// In the default rising cascade the first element (usually a screen title) pulls
  /// into focus instead, giving each screen a distinct opening beat.
  List<Widget> revealed({RevealStyle style = RevealStyle.rise, double distance = 22}) {
    var leadPending = style == RevealStyle.rise;
    Widget wrapChild(Widget w) {
      if (leadPending) {
        leadPending = false;
        return ScrollFade(child: Reveal(style: RevealStyle.focus, distance: distance, child: w));
      }
      return Reveal(style: style, distance: distance, child: w);
    }

    return [
      for (final w in this)
        switch (w) {
          Spacer() => w,
          Expanded(:final flex, :final child) => Expanded(flex: flex, child: wrapChild(child)),
          Flexible(:final flex, :final fit, :final child) => Flexible(flex: flex, fit: fit, child: wrapChild(child)),
          Positioned() || Reveal() || SelfRevealing() || Divider() || VerticalDivider() => w,
          SizedBox(child: null) => w,
          _ => wrapChild(w),
        },
    ];
  }
}
