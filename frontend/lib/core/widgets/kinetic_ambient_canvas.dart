import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Ultra-Premium Kinetic Ambient Atmosphere Canvas
/// Silky continuous golden starlight dust motes drifting across the architectural
/// canvas with depth parallax and subtle incandescent breathing.
class KineticAmbientCanvas extends StatefulWidget {
  final Widget child;
  final bool enableMouseInteraction;

  const KineticAmbientCanvas({
    super.key,
    required this.child,
    this.enableMouseInteraction = true,
  });

  @override
  State<KineticAmbientCanvas> createState() => _KineticAmbientCanvasState();
}

class _KineticAmbientCanvasState extends State<KineticAmbientCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _driftController;
  final List<_MoteData> _motes = [];

  @override
  void initState() {
    super.initState();
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    // Deterministic random seed for consistent aesthetic positioning
    final rnd = math.Random(108);
    for (int i = 0; i < 32; i++) {
      _motes.add(_MoteData(
        relX: rnd.nextDouble(),
        relY: rnd.nextDouble(),
        radius: 0.8 + rnd.nextDouble() * 1.8,
        speed: 0.3 + rnd.nextDouble() * 0.7,
        phase: rnd.nextDouble() * 2 * math.pi,
        alphaMultiplier: 0.4 + rnd.nextDouble() * 0.6,
      ));
    }
  }

  @override
  void dispose() {
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Kinetic Atmosphere
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _driftController,
            builder: (context, _) {
              return CustomPaint(
                painter: _KineticAtmospherePainter(
                  isDark: isDark,
                  progress: _driftController.value,
                  motes: _motes,
                ),
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _MoteData {
  final double relX;
  final double relY;
  final double radius;
  final double speed;
  final double phase;
  final double alphaMultiplier;

  _MoteData({
    required this.relX,
    required this.relY,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.alphaMultiplier,
  });
}

class _KineticAtmospherePainter extends CustomPainter {
  final bool isDark;
  final double progress;
  final List<_MoteData> motes;

  _KineticAtmospherePainter({
    required this.isDark,
    required this.progress,
    required this.motes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background Fill
    final bgPaint = Paint()..color = isDark ? AppColors.darkBackground : AppColors.background;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Floating Champagne Gold / Starlight Motes
    final goldColor = isDark ? const Color(0xFFEAB368) : const Color(0xFFC88552);
    final motePaint = Paint()..style = PaintingStyle.fill;

    for (final mote in motes) {
      // Gentle vertical upward drift with horizontal sinusoidal sway
      final t = (progress * mote.speed + mote.relY) % 1.0;
      final y = size.height * (1.0 - t);
      final sway = math.sin(progress * 2 * math.pi + mote.phase) * 18.0;
      final x = (size.width * mote.relX + sway) % size.width;

      // Breathing shimmer opacity
      final shimmer = (math.sin(progress * 4 * math.pi + mote.phase) + 1.0) / 2.0;
      final alpha = (isDark ? 0.08 : 0.05) * mote.alphaMultiplier * (0.6 + shimmer * 0.4);

      motePaint.color = goldColor.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), mote.radius, motePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _KineticAtmospherePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
