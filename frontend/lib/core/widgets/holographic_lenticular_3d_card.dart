import 'dart:math' as math;
import 'package:flutter/material.dart';

class HolographicLenticular3DCard extends StatefulWidget {
  final Widget frontChild;
  final Widget backChild;

  const HolographicLenticular3DCard({
    super.key,
    required this.frontChild,
    required this.backChild,
  });

  @override
  State<HolographicLenticular3DCard> createState() => _HolographicLenticular3DCardState();
}

class _HolographicLenticular3DCardState extends State<HolographicLenticular3DCard> {
  double _tiltAngle = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _tiltAngle += details.delta.dx * 0.01;
        });
      },
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(_tiltAngle),
        alignment: Alignment.center,
        child: math.cos(_tiltAngle) >= 0 ? widget.frontChild : widget.backChild,
      ),
    );
  }
}
