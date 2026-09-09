import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class RibbonBookmark extends StatelessWidget {
  final Color color;
  final double height;

  const RibbonBookmark({
    super.key,
    this.color = AppColors.secondary,
    this.height = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: height,
      decoration: BoxDecoration(
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _RibbonTailPainter(color: color),
      ),
    );
  }
}

class _RibbonTailPainter extends CustomPainter {
  final Color color;

  _RibbonTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, size.height - 8)
      ..lineTo(size.width, size.height)
      ..close();

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RibbonTailPainter oldDelegate) => false;
}
