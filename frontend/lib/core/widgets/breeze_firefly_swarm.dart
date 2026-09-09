import 'dart:math' as math;
import 'dart:math';
import 'package:flutter/material.dart';

class BreezeFireflySwarm extends StatefulWidget {
  final Widget child;

  const BreezeFireflySwarm({super.key, required this.child});

  @override
  State<BreezeFireflySwarm> createState() => _BreezeFireflySwarmState();
}

class _BreezeFireflySwarmState extends State<BreezeFireflySwarm>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Offset> _fireflies = [];
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 12; i++) {
      _fireflies.add(Offset(_rand.nextDouble() * 320, _rand.nextDouble() * 500));
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _FireflyPainter(fireflies: _fireflies, t: _controller.value),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FireflyPainter extends CustomPainter {
  final List<Offset> fireflies;
  final double t;

  _FireflyPainter({required this.fireflies, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (int i = 0; i < fireflies.length; i++) {
      final dx = fireflies[i].dx + math.sin(t * math.pi * 2 + i) * 15;
      final dy = fireflies[i].dy + math.cos(t * math.pi * 2 + i) * 15;
      canvas.drawCircle(Offset(dx, dy), 4.0, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
