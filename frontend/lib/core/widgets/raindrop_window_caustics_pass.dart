import 'dart:math';
import 'package:flutter/material.dart';

class RaindropWindowCausticsPass extends StatefulWidget {
  final Widget child;

  const RaindropWindowCausticsPass({super.key, required this.child});

  @override
  State<RaindropWindowCausticsPass> createState() => _RaindropWindowCausticsPassState();
}

class _RaindropWindowCausticsPassState extends State<RaindropWindowCausticsPass>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Offset> _drops = [];
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 15; i++) {
      _drops.add(Offset(_rand.nextDouble() * 360, _rand.nextDouble() * 700));
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
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
                  painter: _RaindropPainter(drops: _drops, progress: _controller.value),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RaindropPainter extends CustomPainter {
  final List<Offset> drops;
  final double progress;

  _RaindropPainter({required this.drops, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final dropPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < drops.length; i++) {
      final y = (drops[i].dy + progress * size.height) % size.height;
      final x = drops[i].dx % size.width;
      canvas.drawCircle(Offset(x, y), 3.5, dropPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
