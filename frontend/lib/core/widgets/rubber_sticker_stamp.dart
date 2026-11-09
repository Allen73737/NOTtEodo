import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

enum RubberStampStyle { confidential, urgent1984, curated, approved }

class RubberStickerStamp extends StatelessWidget {
  final RubberStampStyle style;

  const RubberStickerStamp({
    super.key,
    this.style = RubberStampStyle.curated,
  });

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;

    switch (style) {
      case RubberStampStyle.confidential:
        text = 'CONFIDENTIAL';
        color = const Color(0xFFD9725B);
        break;
      case RubberStampStyle.urgent1984:
        text = 'URGENT 1984';
        color = const Color(0xFFEAB368);
        break;
      case RubberStampStyle.curated:
        text = 'SANCTUARY CURATED';
        color = const Color(0xFF86CBB0);
        break;
      case RubberStampStyle.approved:
        text = 'APPROVED ★';
        color = const Color(0xFFB5C9BE);
        break;
    }

    return Transform.rotate(
      angle: -0.12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: edBox(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: color,
          ),
        ),
      ),
    );
  }
}
