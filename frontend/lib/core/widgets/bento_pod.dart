import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../motion/motion.dart';
import '../state/app_settings.dart';
import 'wax_seal_picker.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

enum PodTextureStyle { glass, paper, receipt, passport, polaroid, decklePaper, editorial }

/// The card-view surface: a raised card with no outline (lifted near-black on OLED
/// black, white on ivory) that deals in, leans toward the finger and sinks when pressed.
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
  });

  @override
  ConsumerState<BentoPod> createState() => _BentoPodState();
}

class _BentoPodState extends ConsumerState<BentoPod> with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  // Ink drop: a ring of oxblood that spreads from where the card was touched.
  late final AnimationController _ink;
  Offset _inkAt = Offset.zero;

  @override
  void initState() {
    super.initState();
    _ink = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    _ink.dispose();
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
              child: tappable && !Motion.reduced(context) ? _withInk(context, isDark) : _buildPodContainer(context, isDark, isEditorial),
            ),
    );

    if (tappable) {
      pod = Pressable(
        pressedScale: isEditorial ? 0.99 : 0.975,
        hoverLift: isEditorial ? 1.0 : 4.0,
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap!();
        },
        child: pod,
      );
    }

    return Reveal(
      delay: Duration(milliseconds: widget.animationDelayMs.clamp(0, 300)),
      style: isEditorial ? RevealStyle.rise : RevealStyle.deal,
      // Isolate each pod's repaints and pause its ambient animations while off screen.
      child: RepaintBoundary(child: OffscreenPause(child: isEditorial ? pod : ScrollDepth(child: pod))),
    );
  }

  Widget _withInk(BuildContext context, bool isDark) {
    final accent = isDark ? const Color(0xFFD0485A) : const Color(0xFF7A1F2B);
    return Listener(
      onPointerDown: (e) {
        _inkAt = e.localPosition;
        _ink.forward(from: 0);
      },
      child: Stack(
        children: [
          _buildPodContainer(context, isDark, false),
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_radiusFor(widget.style)),
                child: AnimatedBuilder(
                  animation: _ink,
                  builder: (context, _) => _ink.value > 0 && _ink.value < 1
                      ? CustomPaint(painter: _InkDropPainter(center: _inkAt, t: Motion.silk.transform(_ink.value), color: accent))
                      : const SizedBox.shrink(),
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
      child: widget.child,
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
