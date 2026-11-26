import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../editorial/editorial_mode.dart';
import 'motion.dart';

/// Oxblood Luminescence Focus Scrubbing
///
/// Deep focus mode that eliminates visual clutter:
/// - Inactive lines or cards dim to 25% opacity.
/// - The focused item remains crisp Linen/Charcoal at 100% opacity.
/// - An oxblood luminescence halo breathes on a calm 4-second resting cadence.
///
/// Differentiated:
/// - Editorial Mode: Pure vertical margin razor-line glowing in oxblood, zero card boxes or shadows.
/// - Cards Mode: Tactile card border glow and ambient oxblood drop shadow.
class OxbloodFocusLuminescence extends StatefulWidget {
  final Widget child;
  final bool isFocused;
  final bool? isEditorial;

  const OxbloodFocusLuminescence({
    super.key,
    required this.child,
    this.isFocused = true,
    this.isEditorial,
  });

  @override
  State<OxbloodFocusLuminescence> createState() => _OxbloodFocusLuminescenceState();
}

class _OxbloodFocusLuminescenceState extends State<OxbloodFocusLuminescence>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // 4-second calm breathing cycle
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isFocused) {
      return AnimatedOpacity(
        duration: Motion.standard,
        curve: Motion.silk,
        opacity: 0.28,
        child: widget.child,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFD0485A) : AppColors.secondary;
    final editorial = widget.isEditorial ?? EditorialMode.active;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        // Sinusoidal pulse: 0.0 to 1.0
        final t = _pulseController.value;
        final pulse = (math.sin(t * 2 * math.pi) + 1.0) / 2.0;

        if (editorial) {
          // EDITORIAL MODE: Words on paper, razor margin indicator, zero shadow boxes
          return AnimatedOpacity(
            duration: Motion.standard,
            curve: Motion.silk,
            opacity: 1.0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 2.5,
                  height: 38,
                  margin: const EdgeInsets.only(right: 12, top: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.45 + (0.55 * pulse)),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                Expanded(child: widget.child),
              ],
            ),
          );
        }

        // CARDS MODE: Bento pod with ambient breathing oxblood glow
        final glowColor = isDark
            ? const Color(0xFFD0485A).withValues(alpha: 0.15 + (0.22 * pulse))
            : const Color(0xFF7A1F2B).withValues(alpha: 0.08 + (0.14 * pulse));

        return AnimatedOpacity(
          duration: Motion.standard,
          curve: Motion.silk,
          opacity: 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent.withValues(alpha: 0.35 + (0.45 * pulse)),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 14 + (10 * pulse),
                  spreadRadius: 1.5 * pulse,
                ),
              ],
            ),
            child: widget.child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
