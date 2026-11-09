import 'package:flutter/material.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Tortoiseshell & Amber Resin Glassmorphic Container
/// Warm organic optical acetate and cognac amber resin layers providing
/// luxurious depth with zero blue-light ocular fatigue.
class AmberTortoiseshellContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const AmberTortoiseshellContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18.0),
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: edBox(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: const Color(0xFFB87828).withValues(alpha: 0.35),
          width: 1.2,
        ),
        color: const Color(0xFF1E1712),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A4B08).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: Colors.black45,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}
