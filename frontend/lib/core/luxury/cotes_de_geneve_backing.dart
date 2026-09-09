import 'package:flutter/material.dart';

/// Damaskeened Côtes de Genève Modal Backing
/// Authentic Haute Horlogerie parallel circular graining (Geneva waves)
/// on rhodium/platinum plates for modals and drawer panels.
class CotesDeGeneveBacking extends StatelessWidget {
  final Widget child;
  final double stripeWidth;

  const CotesDeGeneveBacking({
    super.key,
    required this.child,
    this.stripeWidth = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _GenevaStripesPainter(stripeWidth: stripeWidth),
          ),
        ),
        child,
      ],
    );
  }
}

class _GenevaStripesPainter extends CustomPainter {
  final double stripeWidth;

  _GenevaStripesPainter({required this.stripeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final count = (size.width / stripeWidth).ceil() + 1;

    for (int i = 0; i < count; i++) {
      final rect = Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, size.height);
      final isEven = i % 2 == 0;

      final stripePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isEven
              ? [const Color(0xFF1C1C1F), const Color(0xFF26262A), const Color(0xFF1C1C1F)]
              : [const Color(0xFF242428), const Color(0xFF2F2F34), const Color(0xFF242428)],
        ).createShader(rect);

      canvas.drawRect(rect, stripePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GenevaStripesPainter oldDelegate) =>
      oldDelegate.stripeWidth != stripeWidth;
}
