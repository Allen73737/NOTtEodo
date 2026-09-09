import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class KineticAmbientCanvas extends StatelessWidget {
  final Widget child;
  final bool enableMouseInteraction;

  const KineticAmbientCanvas({
    super.key,
    required this.child,
    this.enableMouseInteraction = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomPaint(
      painter: _CleanKineticCanvasPainter(isDark: isDark),
      child: child,
    );
  }
}

class _CleanKineticCanvasPainter extends CustomPainter {
  final bool isDark;

  _CleanKineticCanvasPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (isDark) {
      // 100% Pure Pitch Black OLED Base Layer
      final bgPaint = Paint()..color = AppColors.darkBackground;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    } else {
      // Warm Serene Editorial Canvas
      final bgPaint = Paint()..color = AppColors.background;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CleanKineticCanvasPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
