import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiquidWaxSeal extends StatefulWidget {
  final VoidCallback onStamped;

  const LiquidWaxSeal({super.key, required this.onStamped});

  @override
  State<LiquidWaxSeal> createState() => _LiquidWaxSealState();
}

class _LiquidWaxSealState extends State<LiquidWaxSeal> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _animController.forward().then((_) => widget.onStamped());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          painter: _LiquidWaxPainter(progress: _animController.value),
          size: const Size(60, 60),
        );
      },
    );
  }
}

class _LiquidWaxPainter extends CustomPainter {
  final double progress;

  _LiquidWaxPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = progress * 24.0;

    final waxPaint = Paint()
      ..color = const Color(0xFFD9725B)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = const Color(0xFFD9725B).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(center, radius + 4, glowPaint);
    canvas.drawCircle(center, radius, waxPaint);

    if (progress > 0.6) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'N',
          style: GoogleFonts.bodoniModa(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidWaxPainter oldDelegate) => true;
}
