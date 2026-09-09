import 'package:flutter/material.dart';

/// Gilded Book Edge Bezel Sweep
/// Simulates 22K gold leaf hand-burnished page edges that shimmer along screen bezels.
class GildedEdgeSweep extends StatelessWidget {
  final Widget child;
  final bool showGoldEdge;
  final AxisDirection edgeDirection;

  const GildedEdgeSweep({
    super.key,
    required this.child,
    this.showGoldEdge = true,
    this.edgeDirection = AxisDirection.left,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showGoldEdge)
          Positioned(
            left: edgeDirection == AxisDirection.left ? 0 : null,
            right: edgeDirection == AxisDirection.right ? 0 : null,
            top: 0,
            bottom: 0,
            width: 3.5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF8A7322),
                    Color(0xFFFFF3C4),
                    Color(0xFFD4AF37),
                    Color(0xFF6B5817),
                    Color(0xFFFFDF73),
                    Color(0xFFD4AF37),
                  ],
                  stops: [0.0, 0.2, 0.45, 0.65, 0.85, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x66D4AF37),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
