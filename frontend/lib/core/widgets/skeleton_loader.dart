import 'package:flutter/material.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// A subtle, high-performance shimmer gradient animation for skeleton loaders.
class SkeletonShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const SkeletonShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? const Color(0xFF121212) : const Color(0xFFEBE6DC);
    final highlightColor = isDark ? const Color(0xFF222222) : const Color(0xFFFAF6EE);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value;
                        return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(slidePercent: t),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}

/// A rounded rectangle placeholder box with subtle skeleton colors.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: edBox(
        color: isDark ? const Color(0xFF161616) : const Color(0xFFEDE7DC),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A complete Bento Pod skeleton screen placeholder.
class SkeletonBentoPod extends StatelessWidget {
  final double height;
  const SkeletonBentoPod({super.key, this.height = 140});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: edBox(
        color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF9F5EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE2DDD2),
          width: 1.2,
        ),
      ),
      child: const SkeletonShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                SkeletonBox(width: 24, height: 24, borderRadius: 6),
                SizedBox(width: 10),
                SkeletonBox(width: 120, height: 14, borderRadius: 4),
                Spacer(),
                SkeletonBox(width: 60, height: 18, borderRadius: 9),
              ],
            ),
            SizedBox(height: 16),
            SkeletonBox(width: double.infinity, height: 18, borderRadius: 4),
            SizedBox(height: 8),
            SkeletonBox(width: 180, height: 12, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

/// A skeleton placeholder for photo pins and polaroid cards.
class SkeletonPolaroidCard extends StatelessWidget {
  const SkeletonPolaroidCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: edBox(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE2DDD2),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: const SkeletonShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 150, width: double.infinity, borderRadius: 10),
            SizedBox(height: 12),
            SkeletonBox(height: 14, width: 140, borderRadius: 4),
            SizedBox(height: 6),
            SkeletonBox(height: 10, width: 90, borderRadius: 3),
          ],
        ),
      ),
    );
  }
}

/// A skeleton row for tasks
class SkeletonTaskRow extends StatelessWidget {
  const SkeletonTaskRow({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: edBox(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE2DDD2),
        ),
      ),
      child: const SkeletonShimmer(
        child: Row(
          children: [
            SkeletonBox(width: 20, height: 20, borderRadius: 6),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 180, height: 14, borderRadius: 4),
                  SizedBox(height: 6),
                  SkeletonBox(width: 100, height: 10, borderRadius: 3),
                ],
              ),
            ),
            SizedBox(width: 12),
            SkeletonBox(width: 48, height: 16, borderRadius: 8),
          ],
        ),
      ),
    );
  }
}

/// A skeleton card for notes
class SkeletonNoteCard extends StatelessWidget {
  const SkeletonNoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: edBox(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE2DDD2),
        ),
      ),
      child: const SkeletonShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBox(width: 60, height: 14, borderRadius: 4),
                Spacer(),
                SkeletonBox(width: 50, height: 12, borderRadius: 3),
              ],
            ),
            SizedBox(height: 12),
            SkeletonBox(width: double.infinity, height: 16, borderRadius: 4),
            SizedBox(height: 8),
            SkeletonBox(width: 220, height: 12, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}
