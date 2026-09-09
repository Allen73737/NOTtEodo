import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';
import 'stitch_logo_widget.dart';

class StitchSvgLoader extends StatefulWidget {
  final double size;
  final String label;

  const StitchSvgLoader({
    super.key,
    this.size = 72.0,
    this.label = 'Loading Sanctuary...',
  });

  @override
  State<StitchSvgLoader> createState() => _StitchSvgLoaderState();
}

class _StitchSvgLoaderState extends State<StitchSvgLoader> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Central Monogram N Emblem
              StitchMonogramNWidget(size: widget.size * 0.52),

              // Surrounding Rotating SVG Ring
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _SvgRingPainter(
                        color: accentColor,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (widget.label.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            widget.label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: isDark ? const Color(0xFFA5B2B5) : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _SvgRingPainter extends CustomPainter {
  final Color color;

  _SvgRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 1.4,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
