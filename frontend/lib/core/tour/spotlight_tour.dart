import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../editorial/editorial_mode.dart';
import '../motion/motion.dart';
import '../performance/sanctuary_motion_engine.dart';

/// What the person does with a highlighted element, shown as a small hint on the callout.
enum TourGesture { tap, longPress, swipe, drag, read }

/// One stop of the guided tour. A stop with no [target] is a chapter card that
/// introduces the page; every other stop spotlights the element tagged with that id.
class TourStop {
  final String chapter;
  final IconData icon;

  /// Module index of the page this stop lives on (0 Home, 1 Notes, 2 Tasks, ...).
  final int module;

  /// [TourTarget.id] of the element to highlight; null for a chapter card.
  final String? target;
  final String title;
  final String body;

  /// Copy for the editorial view, where the same element reads differently.
  final String? editorialTitle;
  final String? editorialBody;
  final TourGesture gesture;

  const TourStop.chapter({
    required this.chapter,
    required this.icon,
    required this.module,
    required this.title,
    required this.body,
  })  : target = null,
        editorialTitle = null,
        editorialBody = null,
        gesture = TourGesture.read;

  const TourStop.spot({
    required this.chapter,
    required this.icon,
    required this.module,
    required String this.target,
    required this.title,
    required this.body,
    this.editorialTitle,
    this.editorialBody,
    this.gesture = TourGesture.tap,
  });

  bool get isChapter => target == null;
  String titleFor(bool editorial) => editorial ? (editorialTitle ?? title) : title;
  String bodyFor(bool editorial) => editorial ? (editorialBody ?? body) : body;
}

/// The app shell lends the tour its navigation while it is on screen.
abstract final class TourHost {
  static ValueChanged<int>? navigate;
  static int Function()? currentModule;

  /// Brings back chrome the person may have scrolled away, such as the dock.
  static VoidCallback? revealChrome;

  static bool get attached => navigate != null && currentModule != null;
}

/// Marks a widget the guided tour can point at. Several widgets may share an id (an
/// outgoing and an incoming page during a transition); the newest visible one wins.
class TourTarget extends StatefulWidget {
  final String id;
  final Widget child;

  const TourTarget({super.key, required this.id, required this.child});

  @override
  State<TourTarget> createState() => _TourTargetState();
}

class _TourTargetState extends State<TourTarget> {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _TourRegistry.add(widget.id, _key);
  }

  @override
  void didUpdateWidget(TourTarget old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      _TourRegistry.remove(old.id, _key);
      _TourRegistry.add(widget.id, _key);
    }
  }

  @override
  void dispose() {
    _TourRegistry.remove(widget.id, _key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: _key, child: widget.child);
}

abstract final class _TourRegistry {
  static final Map<String, List<GlobalKey>> _keys = {};

  static void add(String id, GlobalKey key) => (_keys[id] ??= []).add(key);

  static void remove(String id, GlobalKey key) {
    _keys[id]?.remove(key);
    if (_keys[id]?.isEmpty ?? false) _keys.remove(id);
  }

  /// The on-screen rect of the newest laid-out widget tagged [id], with its context.
  static (BuildContext, Rect)? locate(String id, Size screen) {
    final keys = _keys[id];
    if (keys == null) return null;
    for (final key in keys.reversed) {
      final ctx = key.currentContext;
      final box = ctx?.findRenderObject();
      if (ctx == null || box is! RenderBox || !box.attached || !box.hasSize || box.size.isEmpty) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      // Laid out but parked off to the side (an outgoing page). Far below is fine: the
      // tour scrolls it into view.
      if (rect.right < 0 || rect.left > screen.width) continue;
      return (ctx, rect);
    }
    return null;
  }
}

/// A guided tour that walks from page to page, cutting a lit window around each
/// important element and explaining it in a callout beside it.
abstract final class SpotlightTour {
  static bool _running = false;

  static Future<void> start(BuildContext context, List<TourStop> stops) async {
    if (_running || stops.isEmpty) return;
    _running = true;
    final nav = Navigator.of(context, rootNavigator: true);
    // Started from a settings page: come back to the app shell first.
    nav.popUntil((r) => r.isFirst);
    try {
      await nav.push(PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, __, ___) => _SpotlightTourView(stops: stops),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut, reverseCurve: Curves.easeIn),
          child: child,
        ),
      ));
    } finally {
      _running = false;
    }
  }
}

enum _Phase { travelling, chapter, spotlight }

class _SpotlightTourView extends StatefulWidget {
  final List<TourStop> stops;

  const _SpotlightTourView({required this.stops});

  @override
  State<_SpotlightTourView> createState() => _SpotlightTourViewState();
}

class _SpotlightTourViewState extends State<_SpotlightTourView> with TickerProviderStateMixin {
  List<TourStop> get _stops => widget.stops;

  int _index = 0;
  int _direction = 1;

  /// Ids of the current chapter's elements that are on screen in this layout, taken
  /// when its card opens; the card's preview and the step pips count only these.
  Set<String>? _present;
  String? _presentChapter;
  int _seq = 0;
  _Phase _phase = _Phase.travelling;

  // The lit window glides from one element to the next.
  late final AnimationController _hole = AnimationController(vsync: this, duration: const Duration(milliseconds: 640));
  Rect? _from;
  Rect? _to;

  // The callout and chapter card arrive and leave on their own clock.
  late final AnimationController _card = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
    reverseDuration: const Duration(milliseconds: 200),
  );

  // Breathing ring, sweeping light and the tap hint all share one loop.
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

  // While true the window follows the target every frame, so a moving element (the
  // roaming Nodo orb, a page still settling) keeps its window.
  bool _tracking = false;

  @override
  void initState() {
    super.initState();
    _pulse.addListener(_track);
    WidgetsBinding.instance.addPostFrameCallback((_) => _go(0, 1));
  }

  @override
  void dispose() {
    _pulse.removeListener(_track);
    _hole.dispose();
    _card.dispose();
    _pulse.dispose();
    super.dispose();
  }

  bool get _reduced => Motion.reduced(context);

  Rect get _holeRect {
    final to = _to;
    if (to == null) return Rect.zero;
    final from = _from ?? to;
    return Rect.lerp(from, to, Motion.silk.transform(_hole.value))!;
  }

  Size get _screen => MediaQuery.sizeOf(context);

  /// Space at the bottom taken by the floating dock, which page content scrolls under.
  double get _dockClearance => 120 + MediaQuery.paddingOf(context).bottom;

  void _track() {
    if (!_tracking || !mounted) return;
    final id = _stops[_index].target;
    if (id == null) return;
    final hit = _TourRegistry.locate(id, _screen);
    if (hit == null) return;
    final rect = _padded(hit.$2);
    if (_to == null || (rect.center - _to!.center).distance > 0.5 || (rect.width - _to!.width).abs() > 0.5 || (rect.height - _to!.height).abs() > 0.5) {
      if (_hole.isAnimating) {
        // Retarget mid-flight without a jump.
        _from = _holeRect;
        _to = rect;
        _hole.forward(from: 0);
      } else {
        setState(() {
          _from = rect;
          _to = rect;
        });
      }
    }
  }

  Rect _padded(Rect r) {
    final pad = r.shortestSide < 48 ? 6.0 : 8.0;
    return r.inflate(pad);
  }

  Future<void> _wait(int ms) => Future.delayed(Duration(milliseconds: _reduced ? (ms * 0.2).round() : ms));

  Future<(BuildContext, Rect)?> _find(String id, {required bool patient}) async {
    // Poll until the element is laid out and has stopped moving. Right after moving to
    // a page, give it time to build; otherwise an element that is not there is not coming.
    Rect? last;
    for (var i = 0; i < (patient ? 18 : 4); i++) {
      final hit = _TourRegistry.locate(id, _screen);
      if (hit != null) {
        if (last != null && (hit.$2.topLeft - last.topLeft).distance < 1) return hit;
        last = hit.$2;
      }
      await _wait(90);
      if (!mounted) return null;
    }
    return _TourRegistry.locate(id, _screen);
  }

  Future<void> _go(int index, int direction) async {
    if (index < 0) return;
    if (index >= _stops.length) return _finish();
    final token = ++_seq;
    _direction = direction;
    _tracking = false;
    final stop = _stops[index];

    if (_card.value > 0) await _card.reverse();
    if (!mounted || token != _seq) return;

    TourHost.revealChrome?.call();
    final moving = TourHost.currentModule?.call() != stop.module;
    if (moving) {
      setState(() => _phase = _Phase.travelling);
      TourHost.navigate?.call(stop.module);
      await _wait(stop.isChapter ? 520 : 820);
      if (!mounted || token != _seq) return;
    }

    if (stop.isChapter) {
      SanctuaryHapticEngine.dialDetent();
      _presentChapter = stop.chapter;
      _present = {
        for (final s in _stops)
          if (s.chapter == stop.chapter && !s.isChapter && _TourRegistry.locate(s.target!, _screen) != null) s.target!,
      };
      // The window closes to a point in the middle and the chapter card rises.
      final mid = _screen.center(Offset.zero);
      setState(() {
        _index = index;
        _phase = _Phase.chapter;
        _from = _to == null ? Rect.fromCenter(center: mid, width: 0, height: 0) : _holeRect;
        _to = Rect.fromCenter(center: mid, width: 0, height: 0);
      });
      _hole.forward(from: 0);
      _card.forward(from: 0);
      return;
    }

    // Known to be absent from this layout since the chapter card looked: skip at once.
    final absent = _presentChapter == stop.chapter && !_present!.contains(stop.target);
    final hit = absent ? null : await _find(stop.target!, patient: moving);
    if (!mounted || token != _seq) return;
    if (hit == null) {
      // This element is not on screen in this layout; carry on in the same direction.
      return _go(index + direction, direction);
    }

    // Bring it into the clear part of the screen if it is under the dock or the bar.
    final r = hit.$2;
    if (r.top < 70 || r.bottom > _screen.height - _dockClearance) {
      try {
        await Scrollable.ensureVisible(
          hit.$1,
          alignment: 0.3,
          duration: _reduced ? Duration.zero : const Duration(milliseconds: 480),
          curve: Motion.silk,
        );
      } catch (_) {}
      if (!mounted || token != _seq) return;
    }

    final settled = _TourRegistry.locate(stop.target!, _screen);
    if (settled == null) return _go(index + direction, direction);
    SanctuaryHapticEngine.selection();
    final rect = _padded(settled.$2);
    setState(() {
      _index = index;
      _phase = _Phase.spotlight;
      _from = _to == null || _to!.isEmpty ? Rect.fromCenter(center: rect.center, width: rect.width * 2.2, height: rect.height * 2.2) : _holeRect;
      _to = rect;
    });
    _hole.forward(from: 0);
    _card.forward(from: 0);
    _tracking = true;
  }

  void _next() => _go(_index + 1, 1);

  void _prev() {
    // Skip back over stops that were skipped on the way here.
    _go(_index - 1, -1);
  }

  void _skipChapter() {
    final chapter = _stops[_index].chapter;
    var i = _index + 1;
    while (i < _stops.length && _stops[i].chapter == chapter) {
      i++;
    }
    _go(i, 1);
  }

  Future<void> _finish() async {
    _tracking = false;
    ++_seq;
    if (_card.value > 0) await _card.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  // --- Progress ------------------------------------------------------------

  List<String> get _chapters {
    final out = <String>[];
    for (final s in _stops) {
      if (out.isEmpty || out.last != s.chapter) out.add(s.chapter);
    }
    return out;
  }

  int get _chapterNumber => _chapters.indexOf(_stops[_index].chapter) + 1;

  List<TourStop> _stopsIn(String chapter) => [
        for (final s in _stops)
          if (s.chapter == chapter && !s.isChapter && (_presentChapter != chapter || _present!.contains(s.target) || s == _stops[_index])) s,
      ];

  // --- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = _TourPalette(dark);
    final stop = _stops[_index];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowRight): _next,
          const SingleActivator(LogicalKeyboardKey.enter): _next,
          const SingleActivator(LogicalKeyboardKey.arrowLeft): _prev,
          const SingleActivator(LogicalKeyboardKey.escape): _finish,
        },
        child: Focus(
          autofocus: true,
          child: Material(
            type: MaterialType.transparency,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // Tapping the lit element, or anywhere outside the callout, moves on.
              onTap: _phase == _Phase.spotlight ? _next : null,
              onHorizontalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v < -300) _next();
                if (v > 300) _prev();
              },
              child: Stack(
                children: [
                  // The scrim with its lit window, ring and sweep.
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_hole, _pulse]),
                      builder: (context, _) => CustomPaint(
                        painter: _SpotlightPainter(
                          hole: _phase == _Phase.travelling ? null : _holeRect,
                          pulse: _pulse.value,
                          dim: _phase == _Phase.chapter ? palette.scrimDeep : palette.scrim,
                          accent: palette.accent,
                          lit: _phase == _Phase.spotlight,
                        ),
                      ),
                    ),
                  ),
                  if (_phase == _Phase.chapter)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _card,
                        builder: (context, child) {
                          final t = Curves.easeOut.transform(_card.value);
                          return BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 10 * t, sigmaY: 10 * t),
                            child: const SizedBox.expand(),
                          );
                        },
                      ),
                    ),
                  if (_phase == _Phase.spotlight && stop.gesture != TourGesture.read)
                    AnimatedBuilder(
                      animation: Listenable.merge([_hole, _pulse, _card]),
                      builder: (context, _) => _GestureHint(
                        rect: _holeRect,
                        gesture: stop.gesture,
                        pulse: _pulse.value,
                        opacity: _card.value,
                        color: palette.onAccent,
                        accent: palette.accent,
                      ),
                    ),
                  if (_phase == _Phase.spotlight)
                    AnimatedBuilder(
                      animation: _hole,
                      builder: (context, _) => _CalloutLayout(
                        target: _holeRect,
                        safe: MediaQuery.paddingOf(context),
                        child: _Callout(
                          stop: stop,
                          editorial: EditorialMode.active,
                          palette: palette,
                          reveal: _card,
                          direction: _direction,
                          chapterNumber: _chapterNumber,
                          chapterCount: _chapters.length,
                          stepInChapter: _stopsIn(stop.chapter).indexOf(stop),
                          stepsInChapter: _stopsIn(stop.chapter).length,
                          overall: (_index + 1) / _stops.length,
                          canGoBack: _index > 0,
                          isLast: _index == _stops.length - 1,
                          onNext: _next,
                          onBack: _prev,
                          onSkip: _finish,
                        ),
                      ),
                    ),
                  if (_phase == _Phase.chapter)
                    Positioned.fill(
                      child: SafeArea(
                        child: Center(
                          child: _ChapterCard(
                            stop: stop,
                            palette: palette,
                            reveal: _card,
                            chapterNumber: _chapterNumber,
                            chapterCount: _chapters.length,
                            preview: [for (final s in _stopsIn(stop.chapter)) s.titleFor(EditorialMode.active)],
                            isFirst: _index == 0,
                            isLast: _index == _stops.length - 1,
                            onStart: _next,
                            onSkipChapter: _skipChapter,
                            onBack: _index > 0 ? _prev : null,
                            onClose: _finish,
                          ),
                        ),
                      ),
                    ),
                  if (_phase == _Phase.travelling)
                    Center(child: _TravellingMark(color: palette.accent, pulse: _pulse)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TourPalette {
  final bool dark;
  _TourPalette(this.dark);

  Color get surface => dark ? const Color(0xFF141110) : const Color(0xFFFFFCF8);
  Color get ink => dark ? const Color(0xFFF6F3ED) : const Color(0xFF1A1614);
  Color get muted => dark ? const Color(0xFFA89C9C) : const Color(0xFF6B605A);
  Color get accent => dark ? const Color(0xFFE05A6C) : const Color(0xFF8E2433);
  Color get onAccent => const Color(0xFFF6F3ED);
  Color get soft => dark ? const Color(0xFF221B1A) : const Color(0xFFF3ECE6);
  Color get track => dark ? const Color(0xFF2E2524) : const Color(0xFFE8DDD5);
  Color get scrim => Colors.black.withValues(alpha: dark ? 0.78 : 0.66);
  Color get scrimDeep => Colors.black.withValues(alpha: dark ? 0.86 : 0.74);
}

/// The dimmed screen with a rounded window cut out around the target, a hairline
/// ring, a light that travels round the ring and a ripple that breathes outwards.
class _SpotlightPainter extends CustomPainter {
  final Rect? hole;
  final double pulse;
  final Color dim;
  final Color accent;
  final bool lit;

  _SpotlightPainter({required this.hole, required this.pulse, required this.dim, required this.accent, required this.lit});

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final h = hole;
    if (h == null || h.width < 1 || h.height < 1) {
      canvas.drawRect(full, Paint()..color = dim);
      return;
    }
    final radius = Radius.circular(math.min(20, h.shortestSide / 2));
    final rr = RRect.fromRectAndRadius(h, radius);

    // A soft falloff of light around the window, so the cut never looks harsh.
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(full)
      ..addRRect(rr);
    canvas.drawPath(path, Paint()..color = dim);
    canvas.drawRRect(
      rr.inflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = accent.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    if (!lit) return;

    // Hairline ring.
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = accent.withValues(alpha: 0.9),
    );

    // A comet of light sweeping round the ring.
    final sweep = SweepGradient(
      transform: GradientRotation(pulse * math.pi * 2),
      colors: [
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: 0.95),
        Colors.white.withValues(alpha: 0),
      ],
      stops: const [0, 0.72, 0.9, 1],
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..shader = sweep.createShader(h),
    );

    // Two ripples, half a beat apart.
    for (final offset in const [0.0, 0.5]) {
      final p = (pulse * 2 + offset) % 1.0;
      final e = Curves.easeOut.transform(p);
      canvas.drawRRect(
        RRect.fromRectAndRadius(h.inflate(4 + e * 16), Radius.circular(radius.x + e * 16)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = accent.withValues(alpha: (1 - e) * 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole || old.pulse != pulse || old.dim != dim || old.lit != lit || old.accent != accent;
}

/// A fingertip that shows how to use the element: taps, presses, swipes or drags.
class _GestureHint extends StatelessWidget {
  final Rect rect;
  final TourGesture gesture;
  final double pulse;
  final double opacity;
  final Color color;
  final Color accent;

  const _GestureHint({
    required this.rect,
    required this.gesture,
    required this.pulse,
    required this.opacity,
    required this.color,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (rect.isEmpty) return const SizedBox.shrink();
    // One gesture per beat: approach, press, release.
    final beat = (pulse * 2) % 1.0;
    final press = gesture == TourGesture.longPress
        ? (beat < 0.25 ? beat / 0.25 : (beat < 0.75 ? 1.0 : (1 - beat) / 0.25))
        : math.sin(beat * math.pi).clamp(0.0, 1.0);
    var dx = 0.0;
    if (gesture == TourGesture.swipe || gesture == TourGesture.drag) {
      dx = (Curves.easeInOut.transform(beat) - 0.5) * math.min(rect.width * 0.6, 90);
    }
    final anchor = Offset(
      (rect.center.dx + dx).clamp(16.0, MediaQuery.sizeOf(context).width - 16),
      rect.center.dy + math.min(rect.height * 0.25, 14),
    );
    return Positioned(
      left: anchor.dx - 18,
      top: anchor.dy - 6,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The touch ring under the fingertip.
              Positioned(
                left: 18 - 14 - press * 6,
                top: 6 - 14 - press * 6,
                child: Container(
                  width: 28 + press * 12,
                  height: 28 + press * 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.28 * press),
                    border: Border.all(color: color.withValues(alpha: 0.7 * press), width: 1.2),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, 10 - press * 6),
                child: Transform.scale(
                  scale: 1 - press * 0.08,
                  child: Icon(LucideIcons.pointer, size: 30, color: color, shadows: const [
                    Shadow(color: Color(0x99000000), blurRadius: 10, offset: Offset(0, 3)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Places the callout below the target when it fits, above otherwise, and draws the
/// little pointer that ties it to the element.
class _CalloutLayout extends StatelessWidget {
  final Rect target;
  final EdgeInsets safe;
  final Widget child;

  const _CalloutLayout({required this.target, required this.safe, required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomSingleChildLayout(
        delegate: _CalloutDelegate(target: target, safe: safe),
        child: child,
      ),
    );
  }
}

class _CalloutDelegate extends SingleChildLayoutDelegate {
  final Rect target;
  final EdgeInsets safe;

  static const double gap = 18;
  static const double margin = 16;

  _CalloutDelegate({required this.target, required this.safe});

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final width = math.min(380.0, constraints.maxWidth - margin * 2);
    return BoxConstraints(minWidth: width, maxWidth: width, maxHeight: constraints.maxHeight * 0.62);
  }

  @override
  Offset getPositionForChild(Size size, Size child) {
    final below = size.height - safe.bottom - target.bottom - gap;
    final above = target.top - safe.top - gap;
    double top;
    if (below >= child.height + margin) {
      top = target.bottom + gap;
    } else if (above >= child.height + margin) {
      top = target.top - gap - child.height;
    } else {
      // A tall target: sit over its lower part rather than off screen.
      top = size.height - safe.bottom - margin - child.height;
    }
    final left = (target.center.dx - child.width / 2).clamp(margin, size.width - margin - child.width);
    return Offset(left, top.clamp(safe.top + margin, math.max(safe.top + margin, size.height - safe.bottom - margin - child.height)));
  }

  @override
  bool shouldRelayout(_CalloutDelegate old) => old.target != target || old.safe != safe;
}

class _Callout extends StatelessWidget {
  final TourStop stop;
  final bool editorial;
  final _TourPalette palette;
  final Animation<double> reveal;
  final int direction;
  final int chapterNumber;
  final int chapterCount;
  final int stepInChapter;
  final int stepsInChapter;
  final double overall;
  final bool canGoBack;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  const _Callout({
    required this.stop,
    required this.editorial,
    required this.palette,
    required this.reveal,
    required this.direction,
    required this.chapterNumber,
    required this.chapterCount,
    required this.stepInChapter,
    required this.stepsInChapter,
    required this.overall,
    required this.canGoBack,
    required this.isLast,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  static String _gestureLabel(TourGesture g) => switch (g) {
        TourGesture.tap => 'Tap',
        TourGesture.longPress => 'Press and hold',
        TourGesture.swipe => 'Swipe',
        TourGesture.drag => 'Drag',
        TourGesture.read => 'Look',
      };

  static IconData _gestureIcon(TourGesture g) => switch (g) {
        TourGesture.tap => LucideIcons.pointer,
        TourGesture.longPress => LucideIcons.fingerprint,
        TourGesture.swipe => LucideIcons.moveHorizontal,
        TourGesture.drag => LucideIcons.move,
        TourGesture.read => LucideIcons.eye,
      };

  /// Each piece of the callout arrives a beat after the one above it.
  Widget _stagger(int slot, Widget child) {
    final start = (slot * 0.08).clamp(0.0, 0.6);
    final curve = CurvedAnimation(parent: reveal, curve: Interval(start, math.min(1, start + 0.55), curve: Motion.silk));
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) => Opacity(
        opacity: curve.value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(18.0 * direction * (1 - curve.value), 0), child: child),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return AnimatedBuilder(
      animation: reveal,
      builder: (context, child) {
        final t = Motion.settle.transform(reveal.value.clamp(0.0, 1.0));
        return Opacity(
          opacity: Curves.easeOut.transform(reveal.value.clamp(0.0, 1.0)),
          child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
        );
      },
      // The callout itself takes taps, so they do not fall through to "next".
      child: GestureDetector(
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: p.accent.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 40, offset: const Offset(0, 18)),
              BoxShadow(color: p.accent.withValues(alpha: 0.16), blurRadius: 30),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 14, 12),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _stagger(
                  0,
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: p.soft, borderRadius: BorderRadius.circular(99)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(stop.icon, size: 12, color: p.accent),
                            const SizedBox(width: 5),
                            Text(stop.chapter.toUpperCase(),
                                style: GoogleFonts.dmSans(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: p.accent)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_gestureIcon(stop.gesture), size: 12, color: p.muted),
                          const SizedBox(width: 4),
                          Text(_gestureLabel(stop.gesture), style: GoogleFonts.dmSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.muted)),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '${stepInChapter + 1} of $stepsInChapter',
                        style: GoogleFonts.dmSans(fontSize: 12, color: p.muted, fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _stagger(
                  1,
                  Text(stop.titleFor(editorial),
                      style: GoogleFonts.bodoniModa(fontSize: 21, fontWeight: FontWeight.bold, color: p.ink, height: 1.15)),
                ),
                const SizedBox(height: 6),
                _stagger(
                  2,
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(stop.bodyFor(editorial), style: GoogleFonts.dmSans(fontSize: 14.5, height: 1.5, color: p.ink.withValues(alpha: 0.86))),
                  ),
                ),
                const SizedBox(height: 12),
                // Steps in this chapter, as pips that fill as you go.
                _stagger(
                  3,
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Row(
                      children: [
                        for (var i = 0; i < stepsInChapter; i++)
                          Expanded(
                            child: AnimatedContainer(
                              duration: Motion.standard,
                              curve: Motion.silk,
                              margin: EdgeInsets.only(right: i < stepsInChapter - 1 ? 4 : 0),
                              height: i == stepInChapter ? 4 : 3,
                              decoration: BoxDecoration(
                                color: i <= stepInChapter ? p.accent.withValues(alpha: i == stepInChapter ? 1 : 0.45) : p.track,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _stagger(
                  4,
                  Row(
                    children: [
                      TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(foregroundColor: p.muted, visualDensity: VisualDensity.compact),
                        child: Text('End tour', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      if (canGoBack)
                        IconButton(
                          tooltip: 'Back',
                          onPressed: onBack,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(LucideIcons.chevronLeft, size: 18, color: p.muted),
                        ),
                      const SizedBox(width: 4),
                      _NextPill(label: isLast ? 'Finish' : 'Next', icon: isLast ? LucideIcons.check : LucideIcons.arrowRight, palette: p, onTap: onNext),
                    ],
                  ),
                ),
                // Overall progress through the whole tour.
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: overall),
                    duration: const Duration(milliseconds: 600),
                    curve: Motion.silk,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 2,
                      backgroundColor: p.track.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation(p.accent.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final _TourPalette palette;
  final VoidCallback onTap;

  const _NextPill({required this.label, required this.icon, required this.palette, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.94,
      hoverLift: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [palette.accent, Color.lerp(palette.accent, Colors.black, 0.25)!]),
          borderRadius: BorderRadius.circular(99),
          boxShadow: [BoxShadow(color: palette.accent.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: GoogleFonts.dmSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: palette.onAccent)),
            const SizedBox(width: 6),
            Icon(icon, size: 15, color: palette.onAccent),
          ],
        ),
      ),
    );
  }
}

/// The card that opens each page's chapter: its number, name, what it is for, and
/// a preview of the elements the tour is about to point out.
class _ChapterCard extends StatelessWidget {
  final TourStop stop;
  final _TourPalette palette;
  final Animation<double> reveal;
  final int chapterNumber;
  final int chapterCount;
  final List<String> preview;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onStart;
  final VoidCallback onSkipChapter;
  final VoidCallback? onBack;
  final VoidCallback onClose;

  const _ChapterCard({
    required this.stop,
    required this.palette,
    required this.reveal,
    required this.chapterNumber,
    required this.chapterCount,
    required this.preview,
    required this.isFirst,
    required this.isLast,
    required this.onStart,
    required this.onSkipChapter,
    required this.onBack,
    required this.onClose,
  });

  Widget _stagger(int slot, Widget child, {double rise = 16}) {
    final start = (slot * 0.07).clamp(0.0, 0.6);
    final curve = CurvedAnimation(parent: reveal, curve: Interval(start, math.min(1, start + 0.5), curve: Motion.silk));
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) {
        final v = curve.value.clamp(0.0, 1.0);
        final blur = (1 - v) * 6;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, rise * (1 - v)),
            child: ImageFiltered(
              enabled: blur > 0.05,
              imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final primary = isLast ? 'Start using NOTtEodo' : (isFirst ? 'Begin the tour' : 'Show me');
    return AnimatedBuilder(
      animation: reveal,
      builder: (context, child) {
        final t = Motion.settle.transform(reveal.value.clamp(0.0, 1.0));
        return Opacity(
          opacity: Curves.easeOut.transform(reveal.value.clamp(0.0, 1.0)),
          child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        constraints: BoxConstraints(maxWidth: 440, maxHeight: MediaQuery.sizeOf(context).height * 0.84),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: p.accent.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 50, offset: const Offset(0, 24)),
            BoxShadow(color: p.accent.withValues(alpha: 0.18), blurRadius: 40),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stagger(
                0,
                Row(
                  children: [
                    Text(
                      isFirst || isLast ? 'NOTtEodo tour' : 'Chapter $chapterNumber of $chapterCount',
                      style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.accent, letterSpacing: 0.4),
                    ),
                    const Spacer(),
                    if (!isLast)
                      TextButton(
                        onPressed: onClose,
                        style: TextButton.styleFrom(foregroundColor: p.muted, visualDensity: VisualDensity.compact),
                        child: Text('End tour', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _stagger(1, _OrbitingMark(icon: stop.icon, palette: p, reveal: reveal), rise: 24),
              const SizedBox(height: 18),
              _stagger(
                2,
                Text(stop.title, style: GoogleFonts.bodoniModa(fontSize: 32, fontWeight: FontWeight.bold, color: p.ink, height: 1.08)),
              ),
              const SizedBox(height: 10),
              _stagger(3, Text(stop.body, style: GoogleFonts.dmSans(fontSize: 15, height: 1.55, color: p.ink.withValues(alpha: 0.86)))),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 18),
                _stagger(4, Text("What you'll see", style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.muted))),
                const SizedBox(height: 8),
                for (var i = 0; i < preview.length; i++)
                  _stagger(
                    5 + i,
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: p.accent.withValues(alpha: 0.75)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(preview[i], style: GoogleFonts.dmSans(fontSize: 14, height: 1.4, color: p.ink))),
                        ],
                      ),
                    ),
                    rise: 10,
                  ),
              ],
              const SizedBox(height: 18),
              _stagger(
                6 + preview.length,
                Row(
                  children: [
                    if (onBack != null)
                      IconButton(
                        tooltip: 'Back',
                        onPressed: onBack,
                        icon: Icon(LucideIcons.chevronLeft, size: 18, color: p.muted),
                      ),
                    if (!isFirst && !isLast && preview.isNotEmpty)
                      TextButton(
                        onPressed: onSkipChapter,
                        style: TextButton.styleFrom(foregroundColor: p.muted),
                        child: Text('Skip chapter', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    const Spacer(),
                    _NextPill(label: primary, icon: isLast ? LucideIcons.check : LucideIcons.arrowRight, palette: p, onTap: onStart),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The chapter's icon in a disc, circled by a slowly turning arc of light.
class _OrbitingMark extends StatefulWidget {
  final IconData icon;
  final _TourPalette palette;
  final Animation<double> reveal;

  const _OrbitingMark({required this.icon, required this.palette, required this.reveal});

  @override
  State<_OrbitingMark> createState() => _OrbitingMarkState();
}

class _OrbitingMarkState extends State<_OrbitingMark> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return SizedBox(
      width: 68,
      height: 68,
      child: AnimatedBuilder(
        animation: Listenable.merge([_spin, widget.reveal]),
        builder: (context, _) {
          final pop = Motion.settle.transform(widget.reveal.value.clamp(0.0, 1.0));
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: _spin.value * math.pi * 2,
                child: CustomPaint(size: const Size(68, 68), painter: _ArcPainter(color: p.accent)),
              ),
              Transform.scale(
                scale: 0.6 + 0.4 * pop,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [p.soft, Color.lerp(p.soft, p.accent, 0.12)!]),
                  ),
                  child: Icon(widget.icon, size: 23, color: p.accent),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1.5);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: 0.18),
    );
    canvas.drawArc(
      rect,
      0,
      math.pi * 0.7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(colors: [color.withValues(alpha: 0), color], stops: const [0, 0.35]).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}

/// Shown for the moment the tour is moving to another page.
class _TravellingMark extends StatelessWidget {
  final Color color;
  final Animation<double> pulse;

  const _TravellingMark({required this.color, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.35 + 0.65 * (0.5 + 0.5 * math.sin((pulse.value * 4 - i * 0.25) * math.pi * 2))),
              ),
            ),
        ],
      ),
    );
  }
}
