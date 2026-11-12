import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../performance/sanctuary_motion_engine.dart';
import 'app_toast_engine.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Ultra-modern, lively, Duolingo-inspired graphical notification card.
/// Styled with Tuscan warmth (terracotta, obsidian — strictly zero cyan/blue/green/gold/yellow).
/// Features animated mascot bounce, confetti particles, pulsing aura glow,
/// shimmer sweep, progress bar, and spring entrance.
class SanctuaryAnimatedNotificationCard extends StatefulWidget {
  final AppToastItem item;
  final AnimationController entranceController;
  final AnimationController lifeController;
  final VoidCallback onDismiss;
  final VoidCallback? onAction;
  final bool isDark;

  const SanctuaryAnimatedNotificationCard({
    super.key,
    required this.item,
    required this.entranceController,
    required this.lifeController,
    required this.onDismiss,
    this.onAction,
    this.isDark = true,
  });

  @override
  State<SanctuaryAnimatedNotificationCard> createState() =>
      _SanctuaryAnimatedNotificationCardState();
}

class _SanctuaryAnimatedNotificationCardState
    extends State<SanctuaryAnimatedNotificationCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;
  late final AnimationController _confettiController;
  double _dragOffsetY = 0.0;

  // Pre-computed confetti particles
  late final List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    final rand = math.Random();
    _particles = List.generate(12, (i) => _ConfettiParticle(
      dx: (rand.nextDouble() - 0.5) * 2.0,
      dy: -(rand.nextDouble() * 0.8 + 0.4),
      rotation: rand.nextDouble() * math.pi * 2,
      size: rand.nextDouble() * 3.5 + 2.0,
      color: [
        const Color(0xFFD9725B),
        const Color(0xFFE8927C),
        const Color(0xFFC87A5B),
        const Color(0xFFB85C3F),
        const Color(0xFFF5C6B6),
      ][i % 5],
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  String get _mascotGlyph {
    final title = widget.item.title.toLowerCase();
    final msg = widget.item.message.toLowerCase();

    if (title.contains('streak') ||
        title.contains('🔥') ||
        title.contains('flame') ||
        msg.contains('streak')) {
      return '🔥';
    }
    if (title.contains('nodo') ||
        title.contains('owl') ||
        title.contains('companion') ||
        msg.contains('nodo')) {
      return '🦉';
    }
    if (title.contains('focus') ||
        title.contains('timer') ||
        title.contains('pomodoro') ||
        title.contains('dial')) {
      return '⚡';
    }
    if (title.contains('shield') ||
        title.contains('vault') ||
        title.contains('private') ||
        title.contains('lock')) {
      return '🛡️';
    }
    if (title.contains('export') ||
        title.contains('backup') ||
        title.contains('archive') ||
        title.contains('saved')) {
      return '📦';
    }
    if (title.contains('task') || title.contains('complete') || title.contains('done')) {
      return '🎯';
    }
    if (title.contains('habit') || title.contains('check')) {
      return '💪';
    }
    if (widget.item.type == ToastType.alert) {
      return '🔔';
    }
    return '✨';
  }

  String get _subHeaderText {
    final title = widget.item.title.toLowerCase();
    if (title.contains('streak') || title.contains('🔥')) {
      return 'STREAK MOMENTUM';
    }
    if (title.contains('nodo') || title.contains('companion')) {
      return 'NODO COMPANION';
    }
    if (title.contains('focus') || title.contains('timer')) {
      return 'FOCUS ESCAPEMENT';
    }
    if (title.contains('shield') || title.contains('vault')) {
      return 'PRIVATE GUARANTEE';
    }
    if (title.contains('task') || title.contains('complete')) {
      return 'MISSION COMPLETE';
    }
    if (title.contains('habit')) {
      return 'RITUAL LOGGED';
    }
    switch (widget.item.type) {
      case ToastType.alert:
        return 'SANCTUARY ALERT';
      case ToastType.info:
        return 'INTELLIGENCE PULSE';
      case ToastType.success:
        return 'MOMENTUM RECORDED';
    }
  }

  Color get _accentColor {
    final title = widget.item.title.toLowerCase();
    if (title.contains('shield') || title.contains('vault')) {
      return const Color(0xFF8FA878); // Sage Olive
    }
    switch (widget.item.type) {
      case ToastType.alert:
        return const Color(0xFFD9725B); // Tuscan Terracotta
      case ToastType.info:
        return const Color(0xFFE8927C); // Soft Terracotta
      case ToastType.success:
        return const Color(0xFFD9725B); // Signature Terracotta
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primaryText =
        isDark ? const Color(0xFFFAF7F0) : const Color(0xFF1C1917);
    final secondaryText =
        isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C);
    final cardBg = isDark ? const Color(0xFF161311) : const Color(0xFFFAF8F5);
    final accent = _accentColor;
    final isEditorial = EditorialMode.active;

    if (isEditorial) {
      return MouseRegion(
        onEnter: (_) => widget.lifeController.stop(),
        onExit: (_) {
          if (widget.entranceController.status != AnimationStatus.reverse) {
            widget.lifeController.forward();
          }
        },
        child: GestureDetector(
          onTap: widget.onDismiss,
          child: AnimatedBuilder(
            animation: widget.entranceController,
            builder: (context, child) {
              final t = widget.entranceController.value;
              final slideY = (1.0 - Curves.easeOutCubic.transform(t)) * -40.0;
              return Transform.translate(
                offset: Offset(0.0, slideY),
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  constraints: const BoxConstraints(maxWidth: 420),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141414) : const Color(0xFFFAF5F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E0DB),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(_mascotGlyph, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.item.title,
                                    style: GoogleFonts.bodoniModa(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: primaryText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (widget.item.message.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.item.message,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13.5,
                                        color: secondaryText,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (widget.item.actionLabel != null) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  SanctuaryHapticEngine.dialDetent();
                                  widget.onAction?.call();
                                  widget.onDismiss();
                                },
                                child: Text(
                                  widget.item.actionLabel!,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: widget.onDismiss,
                              child: Icon(LucideIcons.x, size: 14, color: secondaryText),
                            ),
                          ],
                        ),
                      ),
                      AnimatedBuilder(
                        animation: widget.lifeController,
                        builder: (context, _) {
                          final remaining = (1.0 - widget.lifeController.value).clamp(0.0, 1.0);
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: remaining,
                              child: Container(height: 1.5, color: accent),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => widget.lifeController.stop(),
      onExit: (_) {
        if (widget.entranceController.status != AnimationStatus.reverse) {
          widget.lifeController.forward();
        }
      },
      child: GestureDetector(
        onTap: widget.onDismiss,
        onVerticalDragUpdate: (details) {
          setState(() {
            _dragOffsetY =
                (_dragOffsetY + details.delta.dy).clamp(-80.0, 20.0);
          });
        },
        onVerticalDragEnd: (details) {
          if (_dragOffsetY < -20 || details.velocity.pixelsPerSecond.dy < -250) {
            SanctuaryHapticEngine.dialDetent();
            widget.onDismiss();
          } else {
            setState(() => _dragOffsetY = 0.0);
          }
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([widget.entranceController, _pulseController, _shimmerController, _confettiController]),
          builder: (context, child) {
            final t = widget.entranceController.value;
            // Spring bounce easing curve
            final springT = Curves.easeOutBack.transform(t);
            final slideY = (1.0 - springT) * -70.0 + _dragOffsetY;
            final scale = (0.88 + 0.12 * springT).clamp(0.0, 1.05);
            // Subtle tilt on entrance for playfulness
            final tilt = (1.0 - t) * 0.04;

            return Transform.translate(
              offset: Offset(0.0, slideY),
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(tilt),
                alignment: Alignment.center,
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Confetti burst particles on entrance
                  if (widget.item.type == ToastType.success)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _confettiController,
                        builder: (context, _) {
                          final p = _confettiController.value;
                          if (p >= 1.0) return const SizedBox.shrink();
                          return CustomPaint(
                            painter: _ConfettiPainter(
                              particles: _particles,
                              progress: p,
                              opacity: (1.0 - p).clamp(0.0, 1.0),
                            ),
                          );
                        },
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    constraints: const BoxConstraints(maxWidth: 440),
                    decoration: edBox(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.16),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: accent.withValues(
                            alpha: 0.16 + 0.10 * _pulseController.value,
                          ),
                          blurRadius: 20 + 8 * _pulseController.value,
                          spreadRadius: 1 + 2 * _pulseController.value,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Stack(
                          children: [
                            // Shimmer sweep overlay
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _shimmerController,
                                builder: (context, _) {
                                  return ShaderMask(
                                    shaderCallback: (rect) {
                                      final shimmerPos = _shimmerController.value * 2.0 - 0.5;
                                      return LinearGradient(
                                        begin: Alignment(-1.0 + shimmerPos * 2, 0),
                                        end: Alignment(shimmerPos * 2, 0),
                                        colors: [
                                          Colors.transparent,
                                          accent.withValues(alpha: 0.06),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                      ).createShader(rect);
                                    },
                                    blendMode: BlendMode.srcOver,
                                    child: Container(
                                      decoration: edBox(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Container(
                              decoration: edBox(
                                color: cardBg.withValues(alpha: isDark ? 0.94 : 0.96),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: accent.withValues(
                                    alpha: isDark ? 0.40 : 0.30,
                                  ),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Animated Graphical Mascot Avatar (Duolingo style)
                                        AnimatedBuilder(
                                          animation: _pulseController,
                                          builder: (context, _) {
                                            final pulse = _pulseController.value;
                                            // Playful wobble bounce
                                            final bounceY = math.sin(pulse * math.pi) * -4.0;
                                            final wobbleAngle = math.sin(pulse * math.pi * 2) * 0.06;
                                            final mascotScale = 1.0 + 0.10 * math.sin(pulse * math.pi);

                                            return Transform.translate(
                                              offset: Offset(0.0, bounceY),
                                              child: Transform.rotate(
                                                angle: wobbleAngle,
                                                child: Container(
                                                  width: 46,
                                                  height: 46,
                                                  decoration: edBox(
                                                    shape: BoxShape.circle,
                                                    gradient: RadialGradient(
                                                      colors: [
                                                        accent.withValues(alpha: 0.40),
                                                        accent.withValues(alpha: 0.18),
                                                        const Color(0xFFC87A5B).withValues(alpha: 0.08),
                                                      ],
                                                    ),
                                                    border: Border.all(
                                                      color: accent.withValues(
                                                        alpha: 0.55 + 0.40 * pulse,
                                                      ),
                                                      width: 2.0,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: accent.withValues(
                                                          alpha: 0.30 * pulse,
                                                        ),
                                                        blurRadius: 14,
                                                        spreadRadius: 3,
                                                      ),
                                                    ],
                                                  ),
                                                  child: Center(
                                                    child: Transform.scale(
                                                      scale: mascotScale,
                                                      child: Text(
                                                        _mascotGlyph,
                                                        style: const TextStyle(
                                                          fontSize: 22,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 12),

                                        // Title, Subtitle, & Subheader Tag
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Top Micro-Header
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 1.5,
                                                    ),
                                                    decoration: edBox(
                                                      color: accent.withValues(alpha: 0.14),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(
                                                        color: accent.withValues(alpha: 0.3),
                                                        width: 0.7,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      _subHeaderText,
                                                      style: GoogleFonts.spaceGrotesk(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 0.8,
                                                        color: accent,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),

                                              // Main Headline
                                              Text(
                                                widget.item.title,
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryText,
                                                  height: 1.2,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),

                                              // Secondary Message
                                              if (widget.item.message.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  widget.item.message,
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 13,
                                                    color: secondaryText,
                                                    height: 1.25,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),

                                        // Optional Action Button (e.g. Check In, Focus, Undo)
                                        if (widget.item.actionLabel != null) ...[
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () {
                                              SanctuaryHapticEngine.dialDetent();
                                              widget.onAction?.call();
                                              widget.onDismiss();
                                            },
                                            borderRadius: BorderRadius.circular(12),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 11,
                                                vertical: 6,
                                              ),
                                              decoration: edBox(
                                                gradient: LinearGradient(
                                                  colors: [accent, const Color(0xFFC87A5B)],
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: accent.withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                widget.item.actionLabel!.toUpperCase(),
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.6,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],

                                        // Close Icon
                                        const SizedBox(width: 4),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 26,
                                            minHeight: 26,
                                          ),
                                          icon: Icon(
                                            LucideIcons.x,
                                            size: 14,
                                            color: secondaryText.withValues(alpha: 0.7),
                                          ),
                                          onPressed: () {
                                            SanctuaryHapticEngine.buttonPress();
                                            widget.onDismiss();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Depleting Duolingo-style Animated Progress Bar
                                  AnimatedBuilder(
                                    animation: Listenable.merge([widget.lifeController, _pulseController]),
                                    builder: (context, _) {
                                      final remainingFactor =
                                          (1.0 - widget.lifeController.value)
                                              .clamp(0.0, 1.0);
                                      return Container(
                                        height: 3.5,
                                        width: double.infinity,
                                        decoration: edBox(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.06)
                                              : Colors.black.withValues(alpha: 0.04),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: remainingFactor,
                                          child: Container(
                                            decoration: edBox(
                                              gradient: LinearGradient(
                                                colors: [
                                                  accent,
                                                  Color.lerp(accent, const Color(0xFFC87A5B), _pulseController.value * 0.5)!,
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(2),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: accent.withValues(alpha: 0.5 * _pulseController.value),
                                                  blurRadius: 6,
                                                  spreadRadius: 0,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single confetti particle definition.
class _ConfettiParticle {
  final double dx;
  final double dy;
  final double rotation;
  final double size;
  final Color color;

  const _ConfettiParticle({
    required this.dx,
    required this.dy,
    required this.rotation,
    required this.size,
    required this.color,
  });
}

/// Paints burst-style confetti particles emanating from the mascot area.
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;
  final double opacity;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final center = Offset(size.width * 0.12, size.height * 0.5);

    for (final p in particles) {
      final dist = progress * 60.0;
      final x = center.dx + p.dx * dist;
      final y = center.dy + p.dy * dist - progress * 30.0;
      final particleOpacity = (opacity * (1.0 - progress * 0.6)).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + progress * math.pi * 2);

      final paint = Paint()
        ..color = p.color.withValues(alpha: particleOpacity)
        ..style = PaintingStyle.fill;

      // Rounded rectangles for confetti shape
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress || old.opacity != opacity;
}
