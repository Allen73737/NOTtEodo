import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Lapis Lazuli & Pyrite Gold Dust Shimmer Card
/// Polished Afghan ultramarine lapis lazuli stone plate speckled with glittering
/// natural pyrite gold flecks for high-tier vault items and pinned notes.
class LapisLazuliShimmerCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const LapisLazuliShimmerCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18.0),
  });

  @override
  State<LapisLazuliShimmerCard> createState() => _LapisLazuliShimmerCardState();
}

class _LapisLazuliShimmerCardState extends State<LapisLazuliShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
          width: 1.5,
        ),
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3322363A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black45,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _sparkleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _PyriteDustPainter(sparkle: _sparkleController.value),
                );
              },
            ),
          ),
          Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _PyriteDustPainter extends CustomPainter {
  final double sparkle;

  _PyriteDustPainter({required this.sparkle});

  @override
  void paint(Canvas canvas, Size size) {
    final goldPaint = Paint()
      ..color = const Color(0xFFFFDF73).withValues(alpha: 0.25 + (sparkle * 0.35))
      ..style = PaintingStyle.fill;

    // Deterministic procedural pyrite dust flecks
    final rand = math.Random(42);
    for (int i = 0; i < 35; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      final r = 0.8 + rand.nextDouble() * 1.5;
      canvas.drawCircle(Offset(x, y), r, goldPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PyriteDustPainter oldDelegate) =>
      oldDelegate.sparkle != sparkle;
}
