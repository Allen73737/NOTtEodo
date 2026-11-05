import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../brand/notteodo_app_icon.dart';
import '../performance/sanctuary_motion_engine.dart';
import 'app_toast_engine.dart';

/// Luxury, app-themed on-screen heads-up notification card.
/// Features elastic spring entrance physics, 3D perspective pitch tilt,
/// specular light shimmer sweep, pitch-black OLED frosted glass,
/// the official NOTtEodo app logo badge, and animated countdown hairline.
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
  State<SanctuaryAnimatedNotificationCard> createState() => _SanctuaryAnimatedNotificationCardState();
}

class _SanctuaryAnimatedNotificationCardState extends State<SanctuaryAnimatedNotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  Timer? _shimmerTimer;
  double _dragOffsetY = 0.0;

  @override
  void initState() {
    super.initState();

    // Specular light shimmer sweep across the obsidian surface
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _shimmerAnimation = Tween<double>(begin: -1.2, end: 2.2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutCubic),
    );

    // Trigger shimmer wave shortly after spring settlement
    widget.entranceController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _shimmerTimer = Timer(const Duration(milliseconds: 120), () {
          if (mounted) _shimmerController.forward(from: 0.0);
        });
      }
    });

    if (widget.entranceController.isCompleted) {
      _shimmerController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _shimmerTimer?.cancel();
    _shimmerController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.item.type) {
      case ToastType.alert:
        return const Color(0xFFD9725B); // Terracotta flame
      case ToastType.info:
        return const Color(0xFFD4AF37); // Imperial Gold
      case ToastType.success:
        return const Color(0xFFD4AF37); // Imperial Gold
    }
  }

  String get _categoryEyebrow {
    switch (widget.item.type) {
      case ToastType.alert:
        return 'SANCTUARY // NOTICE';
      case ToastType.info:
        return 'NOTTEODO // SYSTEM';
      case ToastType.success:
        return 'NOTTEODO // SANCTUARY';
    }
  }

  IconData get _badgeIcon {
    switch (widget.item.type) {
      case ToastType.alert:
        return LucideIcons.bellRing;
      case ToastType.info:
        return LucideIcons.info;
      case ToastType.success:
        return LucideIcons.check;
    }
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const terracotta = Color(0xFFD9725B);
    final isDark = widget.isDark;

    final primaryText = isDark ? const Color(0xFFFAF7F0) : const Color(0xFF1E1E1E);
    final secondaryText = isDark ? const Color(0xFFB5AFA6) : const Color(0xFF6B655D);
    final cardBg = isDark ? const Color(0xFF000000) : const Color(0xFFF9F7F2);

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
            _dragOffsetY = (_dragOffsetY + details.delta.dy).clamp(-120.0, 30.0);
          });
        },
        onVerticalDragEnd: (details) {
          if (_dragOffsetY < -25 || details.velocity.pixelsPerSecond.dy < -300) {
            SanctuaryHapticEngine.dialDetent();
            widget.onDismiss();
          } else {
            setState(() => _dragOffsetY = 0.0);
          }
        },
        child: AnimatedBuilder(
          animation: widget.entranceController,
          builder: (context, child) {
            final t = widget.entranceController.value;

            // Elastic spring translation from top
            final slideY = (1.0 - t) * -110.0 + _dragOffsetY;
            final scale = 0.88 + 0.12 * t;

            // 3D perspective pitch tilt (swings down smoothly into alignment)
            final tiltAngle = (1.0 - t) * -0.22;

            return Transform(
              alignment: Alignment.topCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..translate(0.0, slideY)
                ..scale(scale)
                ..rotateX(tiltAngle),
              child: Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 440),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.8 : 0.25),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: _accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardBg.withValues(alpha: isDark ? 0.94 : 0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _accentColor.withValues(alpha: isDark ? 0.65 : 0.45),
                        width: 1.4,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Specular Light Sweep Shimmer
                        AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, _) {
                            final shimmerX = _shimmerAnimation.value;
                            return Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment(shimmerX - 0.5, -1.0),
                                      end: Alignment(shimmerX + 0.5, 1.0),
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: isDark ? 0.07 : 0.25),
                                        Colors.white.withValues(alpha: isDark ? 0.15 : 0.45),
                                        Colors.white.withValues(alpha: isDark ? 0.07 : 0.25),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Card Main Body
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Official NOTtEodo App Icon with Glowing Badge
                                  NotteodoAppIcon(
                                    size: 44,
                                    borderRadius: 11,
                                    withGlow: true,
                                    borderColor: _accentColor.withValues(alpha: 0.7),
                                    badge: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: _accentColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: cardBg, width: 2),
                                      ),
                                      child: Center(
                                        child: Icon(_badgeIcon, size: 8, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Text Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Header Row: Eyebrow + Timestamp
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _categoryEyebrow,
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 1.6,
                                                  color: _accentColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(LucideIcons.clock, size: 10, color: secondaryText),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'now',
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: secondaryText,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),

                                        // Notification Title
                                        Text(
                                          widget.item.title,
                                          style: GoogleFonts.bodoniModa(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.2,
                                            color: primaryText,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),

                                        // Notification Message Body
                                        Text(
                                          widget.item.message,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 11.5,
                                            height: 1.35,
                                            color: secondaryText,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Optional Action Pill
                                  if (widget.item.actionLabel != null) ...[
                                    const SizedBox(width: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            SanctuaryHapticEngine.dialDetent();
                                            widget.onAction?.call();
                                            widget.onDismiss();
                                          },
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _accentColor.withValues(alpha: 0.18),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: _accentColor.withValues(alpha: 0.5)),
                                            ),
                                            child: Text(
                                              widget.item.actionLabel!.toUpperCase(),
                                              style: GoogleFonts.dmSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.1,
                                                color: isDark ? const Color(0xFFF4F1EA) : _accentColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Countdown Hairline Progress Bar
                              AnimatedBuilder(
                                animation: widget.lifeController,
                                builder: (context, _) {
                                  final progress = 1.0 - widget.lifeController.value;
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: progress.clamp(0.0, 1.0),
                                      child: Container(
                                        height: 2.0,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(1),
                                          gradient: const LinearGradient(
                                            colors: [gold, terracotta],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: gold.withValues(alpha: 0.5),
                                              blurRadius: 4,
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
            ),
          ),
        ),
      ),
    );
  }
}
