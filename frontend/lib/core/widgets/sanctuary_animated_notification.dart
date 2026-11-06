import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../performance/sanctuary_motion_engine.dart';
import 'app_toast_engine.dart';

/// Ultra-modern, sleek, dynamic floating notification pill.
/// Clean minimal footprint, frosted glass OLED blur, terracotta accent,
/// and smooth interactive gesture dismissal.
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

class _SanctuaryAnimatedNotificationCardState extends State<SanctuaryAnimatedNotificationCard> {
  double _dragOffsetY = 0.0;

  Color get _accentColor {
    switch (widget.item.type) {
      case ToastType.alert:
        return const Color(0xFFD9725B); // Terracotta flame
      case ToastType.info:
        return const Color(0xFFE8927C); // Soft terracotta
      case ToastType.success:
        return const Color(0xFFD9725B); // Signature terracotta
    }
  }

  IconData get _badgeIcon {
    switch (widget.item.type) {
      case ToastType.alert:
        return LucideIcons.bellRing;
      case ToastType.info:
        return LucideIcons.sparkles;
      case ToastType.success:
        return LucideIcons.check;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primaryText = isDark ? const Color(0xFFFAF7F0) : const Color(0xFF1C1917);
    final secondaryText = isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C);
    final cardBg = isDark ? const Color(0xFF141210) : const Color(0xFFFAF8F5);

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
            _dragOffsetY = (_dragOffsetY + details.delta.dy).clamp(-80.0, 20.0);
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
          animation: widget.entranceController,
          builder: (context, child) {
            final t = widget.entranceController.value;
            final slideY = (1.0 - t) * -60.0 + _dragOffsetY;
            final scale = 0.94 + 0.06 * t;

            return Transform.translate(
              offset: Offset(0.0, slideY),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: child,
                ),
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
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.14),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: _accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: cardBg.withValues(alpha: isDark ? 0.92 : 0.94),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Compact Icon Badge
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accentColor.withValues(alpha: 0.15),
                              border: Border.all(
                                color: _accentColor.withValues(alpha: 0.4),
                                width: 1.0,
                              ),
                            ),
                            child: Center(
                              child: Icon(_badgeIcon, size: 14, color: _accentColor),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Title & Message Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.item.title,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: primaryText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.item.message.isNotEmpty)
                                  Text(
                                    widget.item.message,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      color: secondaryText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),

                          // Optional Action Pill
                          if (widget.item.actionLabel != null) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                SanctuaryHapticEngine.dialDetent();
                                widget.onAction?.call();
                                widget.onDismiss();
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _accentColor,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  widget.item.actionLabel!.toUpperCase(),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          // Dismiss button
                          const SizedBox(width: 4),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                            icon: Icon(
                              LucideIcons.x,
                              size: 13,
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
