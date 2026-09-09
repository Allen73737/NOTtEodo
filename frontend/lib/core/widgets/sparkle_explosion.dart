import 'dart:math';
import 'package:flutter/material.dart';

/// Multi-Stage Confetti & Particle Cannon Explosion Engine
class SparkleExplosion extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;
  final int particleCount;

  const SparkleExplosion({
    super.key,
    required this.position,
    required this.onComplete,
    this.particleCount = 28,
  });

  @override
  State<SparkleExplosion> createState() => _SparkleExplosionState();
}

class _SparkleExplosionState extends State<SparkleExplosion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Initialize cannon particles with varied angles, velocities, and spin
    for (int i = 0; i < widget.particleCount; i++) {
      final angle = _rand.nextDouble() * 2 * pi;
      final speed = 3.0 + _rand.nextDouble() * 7.0;
      _particles.add(_ConfettiParticle(
        velocity: Offset(cos(angle) * speed, sin(angle) * speed - 2.0),
        colorIndex: i % 4,
        size: 4.0 + _rand.nextDouble() * 5.0,
        spinSpeed: (_rand.nextDouble() - 0.5) * 0.3,
        isRibbon: i % 3 == 0,
      ));
    }

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _ConfettiPainter(
                  progress: _controller.value,
                  center: widget.position,
                  particles: _particles,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  Offset velocity;
  final int colorIndex;
  final double size;
  final double spinSpeed;
  final bool isRibbon;
  double rotation = 0.0;

  _ConfettiParticle({
    required this.velocity,
    required this.colorIndex,
    required this.size,
    required this.spinSpeed,
    required this.isRibbon,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Offset center;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({
    required this.progress,
    required this.center,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFFD9725B), // Terracotta
      const Color(0xFFFE8F77), // Soft Terracotta
      const Color(0xFF7E998A), // Sage
      const Color(0xFFEAB368), // Gold Amber
    ];

    final paint = Paint()..style = PaintingStyle.fill;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);
    const gravity = 0.15;

    for (final p in particles) {
      // Apply gravity physics and velocity decay
      p.velocity = Offset(p.velocity.dx * 0.96, p.velocity.dy * 0.96 + gravity);
      p.rotation += p.spinSpeed;

      final px = center.dx + (p.velocity.dx * progress * 35);
      final py = center.dy + (p.velocity.dy * progress * 35);

      paint.color = colors[p.colorIndex % colors.length].withValues(alpha: alpha);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation);

      if (p.isRibbon) {
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: p.size * 2.2,
          height: p.size * 0.8,
        );
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
      } else {
        canvas.drawCircle(Offset.zero, p.size * alpha, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
