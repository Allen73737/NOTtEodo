import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

enum TapeStyle { translucentCream, terracottaStripe, sageGreen, metallicClip }

class WashiTapePin extends StatelessWidget {
  final TapeStyle style;
  final double width;

  const WashiTapePin({
    super.key,
    this.style = TapeStyle.translucentCream,
    this.width = 60,
  });

  @override
  Widget build(BuildContext context) {
    if (style == TapeStyle.metallicClip) {
      return Container(
        width: 14,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD5CEBA), width: 2.5),
        ),
      );
    }

    Color tapeColor;
    switch (style) {
      case TapeStyle.translucentCream:
        tapeColor = const Color(0xFFF7F3E9).withValues(alpha: 0.75);
        break;
      case TapeStyle.terracottaStripe:
        tapeColor = AppColors.secondary.withValues(alpha: 0.65);
        break;
      case TapeStyle.sageGreen:
        tapeColor = const Color(0xFF86CBB0).withValues(alpha: 0.65);
        break;
      default:
        tapeColor = const Color(0xFFF7F3E9).withValues(alpha: 0.75);
    }

    return Transform.rotate(
      angle: -0.05,
      child: Container(
        width: width,
        height: 18,
        decoration: BoxDecoration(
          color: tapeColor,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}
