import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 1. Tactile Bouncy Touch / Click Feedback Effect
class BouncyTouchEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final Duration duration;
  final bool enableHaptics;

  const BouncyTouchEffect({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
    this.duration = const Duration(milliseconds: 140),
    this.enableHaptics = true,
  });

  @override
  State<BouncyTouchEffect> createState() => _BouncyTouchEffectState();
}

class _BouncyTouchEffectState extends State<BouncyTouchEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// 2. Staggered Entrance Animation Wrapper
class StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final int baseDelayMs;
  final int stepDelayMs;
  final Duration duration;
  final Offset slideOffset;

  const StaggeredEntrance({
    super.key,
    required this.child,
    required this.index,
    this.baseDelayMs = 60,
    this.stepDelayMs = 45,
    this.duration = const Duration(milliseconds: 550),
    this.slideOffset = const Offset(0, 0.08),
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    final delay = widget.baseDelayMs + (widget.index * widget.stepDelayMs);
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}

/// 3. Glow & Glassmorphic Container with Animated Sheen Sweep
class GlowGlassCard extends StatefulWidget {
  final Widget child;
  final Color accentGlowColor;
  final double blurSigma;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  const GlowGlassCard({
    super.key,
    required this.child,
    this.accentGlowColor = const Color(0xFFD9725B),
    this.blurSigma = 20.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.onTap,
  });

  @override
  State<GlowGlassCard> createState() => _GlowGlassCardState();
}

class _GlowGlassCardState extends State<GlowGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BouncyTouchEffect(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            final glowOpacity = 0.15 + (_glowController.value * 0.15);
            return Container(
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: widget.accentGlowColor.withValues(alpha: glowOpacity),
                    blurRadius: _isHovered ? 28 : 18,
                    spreadRadius: _isHovered ? 2 : 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: widget.borderRadius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: widget.blurSigma,
                    sigmaY: widget.blurSigma,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: widget.borderRadius,
                      color: isDark
                          ? const Color(0xFF16282C).withValues(alpha: 0.75)
                          : const Color(0xFFF3EDE2).withValues(alpha: 0.80),
                      border: Border.all(
                        color: _isHovered
                            ? widget.accentGlowColor.withValues(alpha: 0.5)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.6)),
                        width: _isHovered ? 1.5 : 1.0,
                      ),
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 4. Fluid Custom Page Route Transition
class FluidPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FluidPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );

            final slideIn = Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(curvedAnimation);

            final scaleIn = Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(curvedAnimation);

            final fadeIn = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(curvedAnimation);

            return FadeTransition(
              opacity: fadeIn,
              child: ScaleTransition(
                scale: scaleIn,
                child: SlideTransition(
                  position: slideIn,
                  child: child,
                ),
              ),
            );
          },
        );
}
