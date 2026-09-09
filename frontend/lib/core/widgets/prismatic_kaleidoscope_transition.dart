import 'dart:math' as math;
import 'package:flutter/material.dart';

class PrismaticKaleidoscopeTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const PrismaticKaleidoscopeTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = animation.value;
        final rotation = progress * math.pi * 0.25;
        final scale = 0.8 + (progress * 0.2);

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateZ(rotation)
            ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0)),
          alignment: Alignment.center,
          child: Opacity(
            opacity: progress.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
