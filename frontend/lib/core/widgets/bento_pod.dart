import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../motion/motion.dart';
import '../state/app_settings.dart';
import 'wax_seal_picker.dart';

enum PodTextureStyle { glass, paper, receipt, passport, polaroid, decklePaper, editorial }

/// Ultra-Premium Architectural Module Container
/// Pure bespoke materiality: razor-sharp hairline chamfers, subtle specular rims,
/// luxurious obsidian/ivory depth, and buttery 120Hz micro-interactions.
/// Dynamically toggles between Architectural Bento and Swiss Minimalist Editorial styles.
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

class _BentoPodState extends ConsumerState<BentoPod> {
  bool _isHovered = false;

  /// Cursor position inside the pod, driving the specular spotlight without rebuilds.
  final ValueNotifier<Offset?> _spotlight = ValueNotifier<Offset?>(null);

  @override
  void dispose() {
    _spotlight.dispose();
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
      onHover: (e) => _spotlight.value = e.localPosition,
      onExit: (_) {
        _spotlight.value = null;
        if (_isHovered) setState(() => _isHovered = false);
      },
      child: _buildPodContainer(context, isDark, isEditorial),
    );

    if (tappable) {
      pod = Pressable(
        pressedScale: 0.985,
        hoverLift: isEditorial ? 1.5 : 3,
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap!();
        },
        child: pod,
      );
    }

    return Reveal(
      delay: Duration(milliseconds: widget.animationDelayMs.clamp(0, 300)),
      // Isolate each pod's repaints and pause its ambient animations while off screen.
      child: RepaintBoundary(child: OffscreenPause(child: pod)),
    );
  }

  Widget _buildPodContainer(BuildContext context, bool isDark, bool isEditorial) {
    final effectivePadding = widget.padding ?? (isEditorial ? const EdgeInsets.all(16) : const EdgeInsets.all(20));

    // Luxury Material Palette
    // Dark: Deep Velvet Obsidian (#0D0F13) with Titanium Hairline Border
    // Light: Crisp Architectural Chalk Ivory (#FFFFFF / #FAF8F5) with Warm Satin Border
    final Color backgroundColor;
    final Color borderColor;
    final double borderRadiusValue;
    final List<BoxShadow> shadows;

    if (isEditorial) {
      // Swiss Minimalist Editorial Style
      // Completely borderless, flush surface with zero shadows and pure seamless flow
      backgroundColor = isDark
          ? (_isHovered ? const Color(0xFF0F0D0C) : const Color(0xFF0A0908))
          : (_isHovered ? const Color(0xFFFFFFFF) : const Color(0xFFFAF5F2));
      borderColor = Colors.transparent;
      borderRadiusValue = 12.0;
      shadows = const [];
    } else {
      // Architectural Bento Style (Curated framing & soft physical depth)
      switch (widget.style) {
        case PodTextureStyle.glass:
        case PodTextureStyle.paper:
        case PodTextureStyle.decklePaper:
          backgroundColor = isDark
              ? (_isHovered ? const Color(0xFF0C0C0C) : const Color(0xFF000000))
              : (_isHovered ? Colors.white : const Color(0xFFFCFBF8));
          borderColor = isDark
              ? (_isHovered ? const Color(0xFF2C2C2C) : const Color(0xFF1A1A1A))
              : (_isHovered ? const Color(0xFFDDD7CA) : const Color(0xFFE8E3D8));
          borderRadiusValue = 20;
          shadows = [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: _isHovered ? 0.7 : 0.5)
                  : const Color(0xFF2C241D).withValues(alpha: _isHovered ? 0.08 : 0.04),
              blurRadius: _isHovered ? 24 : 12,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ];
          break;

        case PodTextureStyle.receipt:
          // Clean High-Density Ledger Surface
          backgroundColor = isDark
              ? (_isHovered ? const Color(0xFF0E0E0E) : const Color(0xFF000000))
              : (_isHovered ? const Color(0xFFFFFFFF) : const Color(0xFFF9F7F2));
          borderColor = isDark
              ? (_isHovered ? const Color(0xFF2C2C2C) : const Color(0xFF1A1A1A))
              : (_isHovered ? const Color(0xFFD8D2C4) : const Color(0xFFE4DFD3));
          borderRadiusValue = 16;
          shadows = [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.5) : const Color(0xFF1E1A17).withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ];
          break;

        case PodTextureStyle.passport:
          // Pure Pitch Obsidian
          backgroundColor = isDark
              ? (_isHovered ? const Color(0xFF0E0E0E) : const Color(0xFF000000))
              : (_isHovered ? const Color(0xFF182A2E) : const Color(0xFF142428));
          borderColor =
              isDark ? (_isHovered ? const Color(0xFF333333) : const Color(0xFF1E1E1E)) : const Color(0xFF2C3E42);
          borderRadiusValue = 20;
          shadows = [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.7) : const Color(0xFF0C1719).withValues(alpha: 0.15),
              blurRadius: _isHovered ? 26 : 14,
              offset: const Offset(0, 6),
            ),
          ];
          break;

        case PodTextureStyle.polaroid:
          backgroundColor = isDark ? (_isHovered ? const Color(0xFF0E0E0E) : const Color(0xFF000000)) : Colors.white;
          borderColor = isDark
              ? (_isHovered ? const Color(0xFF2C2C2C) : const Color(0xFF1A1A1A))
              : (_isHovered ? const Color(0xFFD6CFC0) : const Color(0xFFE6E1D4));
          borderRadiusValue = 18;
          shadows = [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.6) : const Color(0xFF2C241D).withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ];
          break;

        case PodTextureStyle.editorial:
          backgroundColor = isDark ? const Color(0xFF000000) : const Color(0xFFFAF5F2);
          borderColor = isDark ? const Color(0xFF1E1A18) : const Color(0xFFE8E0D5);
          borderRadiusValue = 8;
          shadows = const [];
          break;
      }
    }

    // Neutral light: a soft white sheen on black, a faint warm shade on ivory.
    final sheen = isDark ? Colors.white : const Color(0xFF2A2420);
    return CustomPaint(
      foregroundPainter: _SpotlightPainter(_spotlight, sheen, isDark, borderRadiusValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Motion.silk,
        padding: effectivePadding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadiusValue),
          border: isEditorial
              ? null
              : Border.all(
                  color: borderColor,
                  width: 1.0,
                ),
          boxShadow: shadows,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Soft light that follows the cursor across a pod's surface.
class _SpotlightPainter extends CustomPainter {
  final ValueNotifier<Offset?> position;
  final Color color;
  final bool isDark;
  final double cornerRadius;

  _SpotlightPainter(this.position, this.color, this.isDark, this.cornerRadius) : super(repaint: position);

  @override
  void paint(Canvas canvas, Size size) {
    final p = position.value;
    if (p == null) return;
    canvas.clipRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(cornerRadius)));
    final center = p;
    final radius = size.shortestSide.clamp(120.0, 320.0);
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Colors.transparent,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.color != color || old.isDark != isDark || old.cornerRadius != cornerRadius;
}
