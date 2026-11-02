import 'dart:math';
import 'package:flutter/material.dart';

enum WeatherType { sunnySunbeams, fallingSnow, rainMist }

class WeatherParticleOverlay extends StatefulWidget {
  final WeatherType weather;

  const WeatherParticleOverlay({
    super.key,
    this.weather = WeatherType.sunnySunbeams,
  });

  @override
  State<WeatherParticleOverlay> createState() => _WeatherParticleOverlayState();
}

class _WeatherParticleOverlayState extends State<WeatherParticleOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
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
          painter: _WeatherPainter(progress: _animController.value, weather: widget.weather),
          size: Size.infinite,
        );
      },
    );
  }
}

class _WeatherPainter extends CustomPainter {
  final double progress;
  final WeatherType weather;

  _WeatherPainter({required this.progress, required this.weather});

  @override
  void paint(Canvas canvas, Size size) {
    final Random rand = Random(42);

    if (weather == WeatherType.sunnySunbeams) {
      final sunbeamPaint = Paint()
        ..color = const Color(0xFFEAB368).withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

      canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 60 + sin(progress * 2 * pi) * 10, sunbeamPaint);
    } else if (weather == WeatherType.fallingSnow) {
      final snowPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
      for (int i = 0; i < 15; i++) {
        final x = (rand.nextDouble() * size.width + sin(progress * 2 * pi + i) * 10) % size.width;
        final y = (progress * size.height + i * 20) % size.height;
        canvas.drawCircle(Offset(x, y), 2.5, snowPaint);
      }
    } else if (weather == WeatherType.rainMist) {
      final rainPaint = Paint()
        ..color = const Color(0xFFB5C9BE).withValues(alpha: 0.4)
        ..strokeWidth = 1.2;
      for (int i = 0; i < 20; i++) {
        final x = (rand.nextDouble() * size.width) % size.width;
        final y = (progress * size.height + i * 15) % size.height;
        canvas.drawLine(Offset(x, y), Offset(x - 2, y + 10), rainPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherPainter oldDelegate) => true;
}
