import 'package:flutter/material.dart';

/// Skeuomorphic Stitched Leather Binding Spine
/// Displays hand-stitched saddle leather with genuine cream linen thread knots
/// for book, journal, and reading sanctuary margins.
class StitchedLeatherSpine extends StatelessWidget {
  final Widget child;
  final double spineWidth;
  final Color leatherColor;
  final Color stitchColor;

  const StitchedLeatherSpine({
    super.key,
    required this.child,
    this.spineWidth = 32.0,
    this.leatherColor = const Color(0xFF3B281B), // Saddle Havana Brown
    this.stitchColor = const Color(0xFFFAF0E6),  // Cream Waxed Linen
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(left: spineWidth),
          child: child,
        ),
        // Leather Spine Bezel
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: spineWidth,
          child: Container(
            decoration: BoxDecoration(
              color: leatherColor,
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(2, 0)),
              ],
            ),
            child: CustomPaint(
              painter: _LeatherStitchPainter(stitchColor: stitchColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeatherStitchPainter extends CustomPainter {
  final Color stitchColor;

  _LeatherStitchPainter({required this.stitchColor});

  @override
  void paint(Canvas canvas, Size size) {
    final stitchPaint = Paint()
      ..color = stitchColor
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final knotPaint = Paint()
      ..color = Colors.black45
      ..style = PaintingStyle.fill;

    final xCenter = size.width * 0.5;

    // Alternating angled saddle stitches
    for (double y = 14; y < size.height - 14; y += 18) {
      // Pierced awl hole
      canvas.drawCircle(Offset(xCenter, y), 1.2, knotPaint);

      // Angled wax linen stitch
      canvas.drawLine(
        Offset(xCenter - 4, y - 4),
        Offset(xCenter + 4, y + 4),
        stitchPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
