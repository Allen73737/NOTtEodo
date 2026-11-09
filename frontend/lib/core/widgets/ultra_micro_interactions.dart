import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// 1. Liquid Checkmark with Ink Splash & Confetti Burst
class LiquidCheckmark extends StatefulWidget {
  final bool isChecked;
  final ValueChanged<bool>? onChanged;
  final Color activeColor;
  final Color checkColor;
  final double size;

  const LiquidCheckmark({
    super.key,
    required this.isChecked,
    this.onChanged,
    this.activeColor = const Color(0xFFD9725B),
    this.checkColor = Colors.white,
    this.size = 26.0,
  });

  @override
  State<LiquidCheckmark> createState() => _LiquidCheckmarkState();
}

class _LiquidCheckmarkState extends State<LiquidCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fillAnimation;
  late Animation<double> _confettiAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.90), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fillAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _confettiAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (widget.isChecked) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(LiquidCheckmark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isChecked != oldWidget.isChecked) {
      if (widget.isChecked) {
        HapticFeedback.mediumImpact();
        _controller.forward(from: 0.0);
      } else {
        HapticFeedback.lightImpact();
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onChanged?.call(!widget.isChecked);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _LiquidCheckmarkPainter(
              progress: _fillAnimation.value,
              confettiProgress: _confettiAnimation.value,
              scale: _scaleAnimation.value,
              isChecked: widget.isChecked,
              activeColor: widget.activeColor,
              checkColor: widget.checkColor,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
          );
        },
      ),
    );
  }
}

class _LiquidCheckmarkPainter extends CustomPainter {
  final double progress;
  final double confettiProgress;
  final double scale;
  final bool isChecked;
  final Color activeColor;
  final Color checkColor;
  final bool isDark;

  _LiquidCheckmarkPainter({
    required this.progress,
    required this.confettiProgress,
    required this.scale,
    required this.isChecked,
    required this.activeColor,
    required this.checkColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * scale;

    // Outer Circle Border
    final borderPaint = Paint()
      ..color = isChecked
          ? activeColor
          : (isDark
              ? const Color(0xFF424849)
              : const Color(0xFF727879))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius - 1, borderPaint);

    // Liquid Fill
    if (progress > 0) {
      final fillPaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, (radius - 1) * progress, fillPaint);
    }

    // Checkmark Path Animation
    if (progress > 0.3) {
      final checkProgress = (progress - 0.3) / 0.7;
      final checkPaint = Paint()
        ..color = checkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      final p1 = Offset(size.width * 0.28, size.height * 0.52);
      final p2 = Offset(size.width * 0.44, size.height * 0.68);
      final p3 = Offset(size.width * 0.72, size.height * 0.34);

      final path = Path();
      path.moveTo(p1.dx, p1.dy);

      if (checkProgress < 0.5) {
        final currentP2 = Offset.lerp(p1, p2, checkProgress * 2)!;
        path.lineTo(currentP2.dx, currentP2.dy);
      } else {
        path.lineTo(p2.dx, p2.dy);
        final currentP3 = Offset.lerp(p2, p3, (checkProgress - 0.5) * 2)!;
        path.lineTo(currentP3.dx, currentP3.dy);
      }

      canvas.drawPath(path, checkPaint);
    }

    // Micro Confetti Burst
    if (confettiProgress > 0 && confettiProgress < 0.95 && isChecked) {
      final confettiPaint = Paint()..style = PaintingStyle.fill;
      const particleCount = 6;
      final dist = radius + (confettiProgress * 14);
      final alpha = (1.0 - confettiProgress).clamp(0.0, 1.0);

      for (int i = 0; i < particleCount; i++) {
        final angle = (i * 60) * (pi / 180);
        final px = center.dx + cos(angle) * dist;
        final py = center.dy + sin(angle) * dist;

        confettiPaint.color = i % 2 == 0
            ? activeColor.withValues(alpha: alpha)
            : const Color(0xFFFE8F77).withValues(alpha: alpha);

        canvas.drawCircle(Offset(px, py), 2.0 * alpha, confettiPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidCheckmarkPainter oldDelegate) => true;
}

/// 2. Fluid Element Entrance and Exit Wrapper
class FluidElementEntranceExit extends StatefulWidget {
  final Widget child;
  final bool isVisible;
  final Duration duration;
  final Curve curve;
  final Offset entranceOffset;
  final Offset exitOffset;

  const FluidElementEntranceExit({
    super.key,
    required this.child,
    this.isVisible = true,
    this.duration = const Duration(milliseconds: 380),
    this.curve = Curves.easeInOutCubic,
    this.entranceOffset = const Offset(0.0, 0.08),
    this.exitOffset = const Offset(0.0, -0.08),
  });

  @override
  State<FluidElementEntranceExit> createState() =>
      _FluidElementEntranceExitState();
}

class _FluidElementEntranceExitState extends State<FluidElementEntranceExit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _slideAnimation = Tween<Offset>(
      begin: widget.entranceOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(FluidElementEntranceExit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
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

/// 3. Interactive 3D Cursor Tilt Pod
class TactileTiltPod extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final Color accentGlow;

  const TactileTiltPod({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.accentGlow = const Color(0xFFD9725B),
  });

  @override
  State<TactileTiltPod> createState() => _TactileTiltPodState();
}

class _TactileTiltPodState extends State<TactileTiltPod> {
  bool _isHovered = false;
  Offset _tiltOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _tiltOffset = Offset.zero;
      }),
      onHover: (event) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final size = box.size;
        final localPos = event.localPosition;

        final px = (localPos.dx / size.width) - 0.5;
        final py = (localPos.dy / size.height) - 0.5;

        setState(() {
          _tiltOffset = Offset(px * 0.12, -py * 0.12);
        });
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_tiltOffset.dy)
            ..rotateY(_tiltOffset.dx)
            ..multiply(Matrix4.diagonal3Values(_isHovered ? 1.015 : 1.0, _isHovered ? 1.015 : 1.0, 1.0)),
          transformAlignment: Alignment.center,
          decoration: edBox(
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: widget.accentGlow.withValues(alpha: _isHovered ? 0.22 : 0.08),
                blurRadius: _isHovered ? 24 : 12,
                spreadRadius: _isHovered ? 1 : 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// 4. Pulsing Micro Glow Badge
class PulsingGlowBadge extends StatefulWidget {
  final Widget child;
  final Color badgeColor;

  const PulsingGlowBadge({
    super.key,
    required this.child,
    this.badgeColor = const Color(0xFFD9725B),
  });

  @override
  State<PulsingGlowBadge> createState() => _PulsingGlowBadgeState();
}

class _PulsingGlowBadgeState extends State<PulsingGlowBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.08);
        final glowOpacity = 0.3 + (_pulseController.value * 0.4);
        return Container(
          decoration: edBox(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.badgeColor.withValues(alpha: glowOpacity),
                blurRadius: 10 * scale,
                spreadRadius: 2 * scale,
              ),
            ],
          ),
          child: Transform.scale(
            scale: scale,
            child: widget.child,
          ),
        );
      },
    );
  }
}
