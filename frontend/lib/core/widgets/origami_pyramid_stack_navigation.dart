import 'dart:math' as math;
import 'package:flutter/material.dart';

class OrigamiPyramidStackNavigation extends StatelessWidget {
  final Widget child;
  final bool isFolded;

  const OrigamiPyramidStackNavigation({
    super.key,
    required this.child,
    this.isFolded = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(isFolded ? math.pi * 0.15 : 0.0),
      alignment: Alignment.center,
      child: child,
    );
  }
}
