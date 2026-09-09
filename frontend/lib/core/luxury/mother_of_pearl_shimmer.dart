import 'dart:math';
import 'package:flutter/material.dart';

/// Opalescent Mother-of-Pearl Shimmer Card
/// Renders an iridescent pearlescent finish using dynamic HSL gradients
/// that shift between champagne, blush rose, and celestial mint as the user interacts.
class MotherOfPearlShimmer extends StatefulWidget {
  final Widget child;
  final BorderRadius? borderRadius;

  const MotherOfPearlShimmer({
    super.key,
    required this.child,
    this.borderRadius,
  });

  @override
  State<MotherOfPearlShimmer> createState() => _MotherOfPearlShimmerState();
}

class _MotherOfPearlShimmerState extends State<MotherOfPearlShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final br = widget.borderRadius ?? BorderRadius.circular(24);

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final phase = _shimmerController.value * 2 * pi;

        return Container(
          decoration: BoxDecoration(
            borderRadius: br,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HSLColor.fromAHSL(0.18, (35 + sin(phase) * 15) % 360, 0.45, 0.90).toColor(),
                HSLColor.fromAHSL(0.15, (330 + cos(phase) * 20) % 360, 0.40, 0.92).toColor(),
                HSLColor.fromAHSL(0.18, (160 + sin(phase) * 15) % 360, 0.35, 0.90).toColor(),
                HSLColor.fromAHSL(0.20, (45 + cos(phase) * 10) % 360, 0.50, 0.88).toColor(),
              ],
              stops: const [0.0, 0.35, 0.70, 1.0],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEAB368).withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: br,
            child: widget.child,
          ),
        );
      },
    );
  }
}
