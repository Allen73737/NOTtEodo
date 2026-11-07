import 'dart:math';
import 'package:flutter/material.dart';

enum StardustKind {
  star,
  diamond,
  ember,
  ribbon,
}

/// Multi-Stage Stardust, Confetti & Particle Physics Explosion Engine
class SparkleExplosion extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;
  final int particleCount;

  const SparkleExplosion({
    super.key,
    required this.position,
    required this.onComplete,
    this.particleCount = 32,
  });

  @override
  State<SparkleExplosion> createState() => _SparkleExplosionState();
}

class _SparkleExplosionState extends State<SparkleExplosion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_StardustParticle> _particles = [];
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    // Initialize cannon particles with varied angles, velocities, and spin
    for (int i = 0; i < widget.particleCount; i++) {
      final angle = _rand.nextDouble() * 2 * pi;
      final speed = 3.5 + _rand.nextDouble() * 8.5;
      final kind = StardustKind.values[i % StardustKind.values.length];

      _particles.add(_StardustParticle(
        velocity: Offset(cos(angle) * speed, sin(angle) * speed - 2.5),
        colorIndex: i % 4,
        size: 3.5 + _rand.nextDouble() * 5.5,
        spinSpeed: (_rand.nextDouble() - 0.5) * 0.35,
        kind: kind,
      ));
    }

    _controller.forward().then((_) {
      if (mounted) widget.onComplete();
    });
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
                painter: _StardustPainter(
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

class _StardustParticle {
  Offset velocity;
  final int colorIndex;
  final double size;
  final double spinSpeed;
  final StardustKind kind;
  double rotation = 0.0;

  _StardustParticle({
    required this.velocity,
    required this.colorIndex,
    required this.size,
    required this.spinSpeed,
    required this.kind,
  });
}

class _StardustPainter extends CustomPainter {
  final double progress;
  final Offset center;
  final List<_StardustParticle> particles;

  _StardustPainter({
    required this.progress,
    required this.center,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Warm luxury sanctuary colors (Zero cyan / zero blue)
    final colors = [
      const Color(0xFFD9725B), // Signature terracotta
      const Color(0xFFFE8F77), // Soft terracotta peach
      const Color(0xFF8FA878), // Olive sage
      const Color(0xFFD4AF37), // Executive warm gold
    ];

    final paint = Paint()..style = PaintingStyle.fill;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);
    const gravity = 0.18;

    for (final p in particles) {
      // Apply gravity physics, drag decay, and angular rotation
      p.velocity = Offset(p.velocity.dx * 0.95, p.velocity.dy * 0.95 + gravity);
      p.rotation += p.spinSpeed;

      final px = center.dx + (p.velocity.dx * progress * 38);
      final py = center.dy + (p.velocity.dy * progress * 38);

      paint.color = colors[p.colorIndex % colors.length].withValues(alpha: alpha);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation);

      final pSize = p.size * (progress < 0.2 ? (progress / 0.2) : 1.0) * alpha;

      switch (p.kind) {
        case StardustKind.star:
          // 4-point sparkle star
          final path = Path()
            ..moveTo(0, -pSize * 1.5)
            ..quadraticBezierTo(0, 0, pSize * 1.5, 0)
            ..quadraticBezierTo(0, 0, 0, pSize * 1.5)
            ..quadraticBezierTo(0, 0, -pSize * 1.5, 0)
            ..quadraticBezierTo(0, 0, 0, -pSize * 1.5)
            ..close();
          canvas.drawPath(path, paint);
          break;

        case StardustKind.diamond:
          // 45-degree diamond spark
          final d = pSize * 1.2;
          final path = Path()
            ..moveTo(0, -d)
            ..lineTo(d * 0.7, 0)
            ..lineTo(0, d)
            ..lineTo(-d * 0.7, 0)
            ..close();
          canvas.drawPath(path, paint);
          break;

        case StardustKind.ribbon:
          // Metallic parchment confetti flake
          final rect = Rect.fromCenter(
            center: Offset.zero,
            width: pSize * 2.2,
            height: pSize * 0.8,
          );
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
          break;

        case StardustKind.ember:
          // Glowing spherical ember
          canvas.drawCircle(Offset.zero, pSize, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _StardustPainter oldDelegate) => true;
}
