import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../motion/motion.dart';
import '../state/app_settings.dart';
import 'wax_seal_picker.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

enum PodTextureStyle { glass, paper, receipt, passport, polaroid, decklePaper, editorial }

/// The card-view surface: a raised card with no outline (lifted near-black on OLED
/// black, white on ivory) that catches the light where it is touched and sinks when
/// pressed. It arrives in two beats: the surface settles into place and its contents
/// rise a moment after it. Held, its edge fills with light until the preview lifts.
/// In the editorial view it disappears and the content sits straight on the page.
class BentoPod extends ConsumerStatefulWidget implements SelfRevealing {
  final Widget child;
  final PodTextureStyle style;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final bool showWaxSeal;
  final WaxSealType waxSealType;
  final bool showWashiTape;
  final int animationDelayMs;

  /// Whether holding the card lifts a preview. Off when a hold means something else,
  /// such as picking the card up to drag it.
  final bool peek;

  const BentoPod({
    super.key,
    required this.child,
    this.style = PodTextureStyle.glass,
    this.onTap,
    this.padding,
    this.showWaxSeal = false,
    this.waxSealType = WaxSealType.monogramN,
    this.showWashiTape = false,
    this.animationDelayMs = 0,
    this.peek = true,
  });

  @override
  ConsumerState<BentoPod> createState() => _BentoPodState();
}

class _BentoPodState extends ConsumerState<BentoPod> with TickerProviderStateMixin {
  bool _isHovered = false;

  // Ink drop: a ring of oxblood that spreads from where the card was touched.
  late final AnimationController _ink;
  Offset _inkAt = Offset.zero;

  // Hold to preview: a picture of the card lifts above the blurred page.
  final GlobalKey _picture = GlobalKey();
  CardPeek? _peek;

  // The edge fills with light while the card is held, until the preview lifts.
  late final AnimationController _charge = AnimationController(vsync: this, duration: kLongPressTimeout);
  Offset _heldAt = Offset.zero;

  void _startPeek() {
    final boundary = _picture.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;
    _peek = CardPeek.show(context, boundary, radius: _radiusFor(widget.style));
    _letGo();
  }

  void _letGo() {
    if (_charge.value > 0) _charge.animateBack(0, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
  }

  void _endPeek() {
    _peek?.release();
    _peek = null;
  }

  @override
  void initState() {
    super.initState();
    _ink = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    _endPeek();
    _ink.dispose();
    _charge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tappable = widget.onTap != null;

    String cardStyle = 'bento';
    try {
      cardStyle = ref.watch(appSettingsProvider.select((s) => s.cardStyle));
    } catch (_) {}
    final isEditorial = cardStyle == 'editorial' || widget.style == PodTextureStyle.editorial;

    Widget pod = MouseRegion(
      cursor: tappable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        if (!_isHovered) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (_isHovered) setState(() => _isHovered = false);
      },
      child: isEditorial
          ? _buildPodContainer(context, isDark, isEditorial)
          // Cards catch the light where they are touched; they never tilt.
          : TouchSheen(
              borderRadius: BorderRadius.circular(_radiusFor(widget.style)),
              light: isDark ? Colors.white : const Color(0xFFFFF8F0),
              rim: isDark ? const Color(0xFFD0485A) : const Color(0xFF8E2433),
              child: Motion.reduced(context) ? _buildPodContainer(context, isDark, isEditorial) : _surface(context, isDark, tappable: tappable),
            ),
    );

    if (tappable) {
      final peekable = widget.peek && !isEditorial && !Motion.reduced(context);
      pod = Pressable(
        pressedScale: isEditorial ? 0.99 : 0.975,
        hoverLift: isEditorial ? 1.0 : 4.0,
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap!();
        },
        onLongPress: peekable ? _startPeek : null,
        child: peekable ? RepaintBoundary(key: _picture, child: pod) : pod,
      );
      if (peekable) {
        pod = Listener(onPointerUp: (_) => _endPeek(), onPointerCancel: (_) => _endPeek(), child: pod);
      }
    }

    final delay = Duration(milliseconds: widget.animationDelayMs.clamp(0, 300));
    // Isolate each pod's repaints and pause its ambient animations while off screen.
    final body = RepaintBoundary(child: OffscreenPause(child: isEditorial ? pod : ScrollDepth(child: pod)));
    if (isEditorial) return Reveal(delay: delay, style: RevealStyle.rise, child: body);
    return Reveal.builder(
      delay: delay,
      duration: const Duration(milliseconds: 900),
      builder: (context, t) => _Arrival(t: t, child: _Dealt(t: t, child: body)),
    );
  }

  /// The card with its touch ink (when tappable) and the light along its edge.
  Widget _surface(BuildContext context, bool isDark, {required bool tappable}) {
    final accent = isDark ? const Color(0xFFD0485A) : const Color(0xFF7A1F2B);
    final edge = isDark ? const Color(0xFFD0485A) : const Color(0xFF8E2433);
    final radius = _radiusFor(widget.style);
    return Listener(
      onPointerDown: (e) {
        if (!tappable) return;
        _inkAt = _heldAt = e.localPosition;
        _ink.forward(from: 0);
        _charge.forward(from: 0);
      },
      onPointerMove: (e) {
        if ((e.localPosition - _heldAt).distance > 12) _letGo();
      },
      onPointerUp: (_) => _letGo(),
      onPointerCancel: (_) => _letGo(),
      child: Stack(
        children: [
          _buildPodContainer(context, isDark, false),
          if (tappable)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: AnimatedBuilder(
                    animation: _ink,
                    builder: (context, _) => _ink.value > 0 && _ink.value < 1
                        ? CustomPaint(painter: _InkDropPainter(center: _inkAt, t: Motion.silk.transform(_ink.value), color: accent))
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _charge,
                builder: (context, _) => CustomPaint(
                  painter: EdgeLightPainter(
                    radius: radius,
                    color: edge.withValues(alpha: isDark ? 0.85 : 0.6),
                    // A quick tap never shows it; only a hold does.
                    charge: ((_charge.value - 0.3) / 0.7).clamp(0.0, 1.0),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _radiusFor(PodTextureStyle style) => switch (style) {
        PodTextureStyle.receipt => 16,
        PodTextureStyle.editorial => 8,
        _ => 22,
      };

  Widget _buildPodContainer(BuildContext context, bool isDark, bool isEditorial) {
    // Editorial: content sits flush with the page margins; only vertical rhythm remains.
    final effectivePadding = isEditorial ? const EdgeInsets.symmetric(vertical: 14) : (widget.padding ?? const EdgeInsets.all(20));

    final Color backgroundColor;
    final double borderRadiusValue;
    final List<BoxShadow> shadows;
    Border? border;

    if (isEditorial) {
      // Editorial: no surface at all. No fill, border, radius, shadow or hover tint;
      // the content is set straight on the page.
      backgroundColor = Colors.transparent;
      borderRadiusValue = 0;
      shadows = const [];
    } else {
      borderRadiusValue = _radiusFor(widget.style);
      switch (widget.style) {
        case PodTextureStyle.passport:
          // The one deliberately dark card in light mode: espresso with a linen hairline.
          backgroundColor = isDark
              ? (_isHovered ? const Color(0xFF161212) : const Color(0xFF110E0E))
              : (_isHovered ? const Color(0xFF1C1917) : const Color(0xFF161311));
          border = Border.all(color: isDark ? const Color(0xFF241C1D) : const Color(0xFF2E2622));
          shadows = _shadow(isDark, lifted: _isHovered, strength: 1.6);
        default:
          // Raised surface, no outline: a lifted near-black on OLED black, white on ivory.
          backgroundColor = isDark
              ? (_isHovered ? const Color(0xFF141111) : const Color(0xFF0F0D0D))
              : Colors.white;
          shadows = [
            ..._shadow(isDark, lifted: _isHovered),
            if (_isHovered) BoxShadow(color: const Color(0xFF8E2433).withValues(alpha: isDark ? 0.22 : 0.10), blurRadius: 28, spreadRadius: -6, offset: const Offset(0, 10)),
          ];
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Motion.silk,
      padding: effectivePadding,
      decoration: edBox(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadiusValue),
        border: border,
        boxShadow: shadows,
      ),
      child: isEditorial ? widget.child : _ArrivingContent(child: widget.child),
    );
  }

  /// Two soft layers: a tight contact shadow and a wide ambient one that deepens on hover.
  static List<BoxShadow> _shadow(bool isDark, {required bool lifted, double strength = 1}) => isDark
      ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: lifted ? 30 : 18, offset: Offset(0, lifted ? 12 : 6)),
        ]
      : [
          BoxShadow(color: const Color(0xFF2A201C).withValues(alpha: 0.04 * strength), blurRadius: 2, offset: const Offset(0, 1)),
          BoxShadow(
            color: const Color(0xFF2A201C).withValues(alpha: (lifted ? 0.10 : 0.06) * strength),
            blurRadius: lifted ? 34 : 22,
            offset: Offset(0, lifted ? 14 : 8),
          ),
        ];
}

/// How far a card is through its arrival (0…1), for the parts that follow the surface in.
class _Arrival extends InheritedWidget {
  final double t;

  const _Arrival({required this.t, required super.child});

  static double of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_Arrival>()?.t ?? 1;

  @override
  bool updateShouldNotify(_Arrival old) => old.t != t;
}

/// The first beat: the surface settles up into place from a little lower and smaller.
class _Dealt extends StatelessWidget {
  final double t;
  final Widget child;

  const _Dealt({required this.t, required this.child});

  @override
  Widget build(BuildContext context) {
    final s = const Interval(0, 0.72).transform(t);
    final move = Motion.silk.transform(s);
    final scale = 0.955 + 0.045 * move;
    return Opacity(
      opacity: Curves.easeOut.transform((s * 1.6).clamp(0.0, 1.0)),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.translationValues(0, (1 - move) * 26, 0)..scaleByDouble(scale, scale, 1, 1),
        child: child,
      ),
    );
  }
}

/// The second beat: the card's contents rise a moment after its surface lands.
class _ArrivingContent extends StatelessWidget {
  final Widget child;

  const _ArrivingContent({required this.child});

  @override
  Widget build(BuildContext context) {
    final t = _Arrival.of(context);
    final rise = Motion.silk.transform(const Interval(0.22, 0.95).transform(t));
    return Opacity(
      opacity: Curves.easeOut.transform(const Interval(0.22, 0.75).transform(t)),
      child: Transform.translate(offset: Offset(0, (1 - rise) * 10), child: child),
    );
  }
}

/// A soft disc and a thin ring that grow from the touch point and fade out.
class _InkDropPainter extends CustomPainter {
  final Offset center;
  final double t;
  final Color color;

  _InkDropPainter({required this.center, required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final reach = size.longestSide * 1.1;
    final r = reach * t;
    final fade = 1 - t;
    canvas.drawCircle(center, r, Paint()..color = color.withValues(alpha: 0.07 * fade));
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: 0.35 * fade),
    );
  }

  @override
  bool shouldRepaint(_InkDropPainter old) => old.t != t || old.center != center;
}
