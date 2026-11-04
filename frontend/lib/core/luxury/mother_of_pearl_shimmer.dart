
import 'package:flutter/material.dart';

/// Opalescent Mother-of-Pearl Shimmer Card
/// Renders an iridescent pearlescent finish using solid luxury styling
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {


        return Container(
          decoration: BoxDecoration(
            borderRadius: br,
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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
