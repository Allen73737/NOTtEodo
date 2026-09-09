import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class AmbientParticleCanvas extends StatelessWidget {
  final Widget child;

  const AmbientParticleCanvas({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomPaint(
      painter: _ArchitecturalCelestialPainter(isDark: isDark),
      child: child,
    );
  }
}

class _ArchitecturalCelestialPainter extends CustomPainter {
  final bool isDark;

  const _ArchitecturalCelestialPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base Layer: Pitch Black OLED (#000000) or Serene Cream (#FEF9EE)
    final bgPaint = Paint()..color = isDark ? const Color(0xFF000000) : AppColors.background;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Silky Aurora Mesh Glow (Pure static, serene light wash)
    final accentColor1 = isDark ? const Color(0xFFE8927C) : const Color(0xFFD9725B);
    final accentColor2 = isDark ? const Color(0xFF7E998A) : const Color(0xFF86CBB0);
    final accentColor3 = isDark ? const Color(0xFFC88552) : const Color(0xFFEAB368);

    final auroraPaint1 = Paint()
      ..color = accentColor1.withValues(alpha: isDark ? 0.035 : 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 110);

    final auroraPaint2 = Paint()
      ..color = accentColor2.withValues(alpha: isDark ? 0.025 : 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);

    final auroraPaint3 = Paint()
      ..color = accentColor3.withValues(alpha: isDark ? 0.020 : 0.035)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 130);

    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.25), size.width * 0.55, auroraPaint1);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.70), size.width * 0.60, auroraPaint2);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.50), size.width * 0.45, auroraPaint3);

    // 3. Architectural Celestial Grid Guidelines (Razor-thin hairline blueprint)
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : AppColors.primary).withValues(alpha: isDark ? 0.025 : 0.035)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    const step = 80.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 4. Sacred Geometry Compass Circles & Intersection Crosshairs
    final compassPaint = Paint()
      ..color = (isDark ? const Color(0xFFE8927C) : AppColors.secondary).withValues(alpha: isDark ? 0.03 : 0.04)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width * 0.5, size.height * 0.45);
    canvas.drawCircle(center, 140, compassPaint);
    canvas.drawCircle(center, 280, compassPaint);

    // Draw Crosshair Marks at key grid intersections
    final crossPaint = Paint()
      ..color = (isDark ? const Color(0xFFE8927C) : AppColors.primary).withValues(alpha: isDark ? 0.06 : 0.08)
      ..strokeWidth = 1.0;

    for (double x = step; x < size.width; x += step * 2) {
      for (double y = step; y < size.height; y += step * 3) {
        canvas.drawLine(Offset(x - 4, y), Offset(x + 4, y), crossPaint);
        canvas.drawLine(Offset(x, y - 4), Offset(x, y + 4), crossPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArchitecturalCelestialPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
