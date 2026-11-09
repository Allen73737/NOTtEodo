import 'package:flutter/material.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

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
              decoration: edBox(
                color: const Color(0xFFEAB368),
                boxShadow: [
                  const BoxShadow(
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
