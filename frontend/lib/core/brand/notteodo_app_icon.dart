import 'package:flutter/material.dart';
import 'notteodo_monogram.dart';

/// The official NOTtEodo Haute Horlogerie & Sovereign App Icon widget.
/// Renders the master brand icon asset with anti-aliased squircle geometry,
/// deep pitch-black OLED backing, glowing hairline border, and optional ambient pulse.
class NotteodoAppIcon extends StatefulWidget {
  final double size;
  final double? borderRadius;
  final bool withGlow;
  final bool withBorder;
  final Color? borderColor;
  final Color? backgroundColor;
  final Widget? badge;
  final VoidCallback? onTap;

  const NotteodoAppIcon({
    super.key,
    this.size = 48,
    this.borderRadius,
    this.withGlow = false,
    this.withBorder = true,
    this.borderColor,
    this.backgroundColor,
    this.badge,
    this.onTap,
  });

  const NotteodoAppIcon.small({
    super.key,
    this.withGlow = false,
    this.withBorder = true,
    this.borderColor,
    this.backgroundColor,
    this.badge,
    this.onTap,
  })  : size = 28,
        borderRadius = 7;

  const NotteodoAppIcon.medium({
    super.key,
    this.withGlow = false,
    this.withBorder = true,
    this.borderColor,
    this.backgroundColor,
    this.badge,
    this.onTap,
  })  : size = 44,
        borderRadius = 11;

  const NotteodoAppIcon.large({
    super.key,
    this.withGlow = true,
    this.withBorder = true,
    this.borderColor,
    this.backgroundColor,
    this.badge,
    this.onTap,
  })  : size = 64,
        borderRadius = 16;

  const NotteodoAppIcon.hero({
    super.key,
    this.withGlow = true,
    this.withBorder = true,
    this.borderColor,
    this.backgroundColor,
    this.badge,
    this.onTap,
  })  : size = 96,
        borderRadius = 24;

  @override
  State<NotteodoAppIcon> createState() => _NotteodoAppIconState();
}

class _NotteodoAppIconState extends State<NotteodoAppIcon> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _glowAnimation = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    if (widget.withGlow) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(NotteodoAppIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.withGlow && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.withGlow && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? (widget.size * 0.22);
    const gold = Color(0xFFD4AF37);
    final effectiveBorderColor = widget.borderColor ?? gold.withValues(alpha: 0.5);
    final effectiveBgColor = widget.backgroundColor ?? const Color(0xFF000000);

    Widget iconContent = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: widget.size,
        height: widget.size,
        color: effectiveBgColor,
        child: Image.asset(
          'assets/images/notteodo_logo.png',
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: NotteodoMonogram(
                size: widget.size * 0.6,
                color: gold,
              ),
            );
          },
        ),
      ),
    );

    Widget decorated = AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowOpacity = widget.withGlow ? _glowAnimation.value : 0.0;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: widget.withBorder
                ? Border.all(color: effectiveBorderColor, width: 1.2)
                : null,
            boxShadow: widget.withGlow
                ? [
                    BoxShadow(
                      color: gold.withValues(alpha: glowOpacity * 0.4),
                      blurRadius: widget.size * 0.35,
                      spreadRadius: widget.size * 0.05,
                    ),
                    BoxShadow(
                      color: const Color(0xFFD9725B).withValues(alpha: glowOpacity * 0.2),
                      blurRadius: widget.size * 0.2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: child,
        );
      },
      child: iconContent,
    );

    if (widget.badge != null) {
      decorated = Stack(
        clipBehavior: Clip.none,
        children: [
          decorated,
          Positioned(
            right: -2,
            bottom: -2,
            child: widget.badge!,
          ),
        ],
      );
    }

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: decorated,
      );
    }

    return decorated;
  }
}

