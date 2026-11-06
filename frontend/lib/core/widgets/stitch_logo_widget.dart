import 'package:flutter/material.dart';
import '../brand/notteodo_monogram.dart';

class StitchMonogramNWidget extends StatelessWidget {
  final double size;

  const StitchMonogramNWidget({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Vector mark: pixel-crisp at every size, white in dark theme and black in light theme.
    return NotteodoMonogram(
      size: size,
      color: isDark ? Colors.white : Colors.black,
    );
  }
}

class StitchLogoWidget extends StatelessWidget {
  final double fontSize;
  final bool showTagline;
  final bool showMonogramN;

  const StitchLogoWidget({
    super.key,
    this.fontSize = 24,
    this.showTagline = false,
    this.showMonogramN = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoHeight = fontSize * 1.5; // Large, prominent 36px-48px height

    final logoWidget = Image.asset(
      'assets/images/notteodo_logo_horizontal.png',
      height: logoHeight,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return StitchMonogramNWidget(size: fontSize * 1.2);
      },
    );

    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        isDark ? Colors.white : Colors.black,
        BlendMode.srcIn,
      ),
      child: logoWidget,
    );
  }
}
