import 'package:flutter/material.dart';

/// Vellum Parchment Layer Opacity Depth Stacking
/// Simulates authentic calfskin vellum translucency where background
/// sheets undergo progressive depth-of-field blur and subtle ink bleed-through.
class VellumDepthStack extends StatelessWidget {
  final List<Widget> children;
  final int activeIndex;
  final double cardElevationOffset;
  final ValueChanged<int>? onSelectIndex;

  const VellumDepthStack({
    super.key,
    required this.children,
    this.activeIndex = 0,
    this.cardElevationOffset = 22.0,
    this.onSelectIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: List.generate(children.length, (idx) {
        final depthFromActive = idx - activeIndex;
        final isBehind = depthFromActive < 0;
        final isAhead = depthFromActive > 0;
        final isCurrent = depthFromActive == 0;

        final double yOffset = depthFromActive * cardElevationOffset;
        final double scale = 1.0 - (depthFromActive.abs() * 0.04);
        final double opacity = (1.0 - (depthFromActive.abs() * 0.22)).clamp(0.2, 1.0);

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          top: isBehind ? yOffset : (isAhead ? yOffset * 1.5 : 0),
          left: 0,
          right: 0,
          child: AnimatedScale(
            scale: scale.clamp(0.85, 1.0),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            child: GestureDetector(
              onTap: () => onSelectIndex?.call(idx),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.45 : (isCurrent ? 0.12 : 0.05),
                        ),
                        blurRadius: isCurrent ? 24 : 10,
                        offset: Offset(0, isCurrent ? 10 : 4),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF141416)
                          : const Color(0xFFFBF8F2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: isCurrent ? 0.25 : 0.08)
                            : const Color(0xFFE4DDD2).withValues(alpha: isCurrent ? 0.9 : 0.4),
                        width: isCurrent ? 1.4 : 0.9,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Faint parchment cellulose paper fibers
                        Positioned.fill(
                          child: Opacity(
                            opacity: isDark ? 0.04 : 0.08,
                            child: CustomPaint(painter: _VellumFiberPainter()),
                          ),
                        ),
                        // Content
                        children[idx],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _VellumFiberPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B6508)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Procedural delicate vellum grain marks
    for (double y = 8; y < size.height; y += 18) {
      canvas.drawLine(
        Offset(12, y),
        Offset(size.width - 12, y + (y % 5 == 0 ? 1.5 : -1.0)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
