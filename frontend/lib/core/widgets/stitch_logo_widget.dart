import 'package:flutter/material.dart';

class StitchMonogramNWidget extends StatelessWidget {
  final double size;

  const StitchMonogramNWidget({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final imageWidget = Image.asset(
      'assets/images/notteodo_emblem.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFD9725B),
          ),
          child: Center(
            child: Text(
              'N',
              style: TextStyle(
                fontFamily: 'Bodoni Moda',
                fontSize: size * 0.55,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );

    if (isDark) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(Color(0xFFF4F1EA), BlendMode.srcIn),
        child: imageWidget,
      );
    }

    return imageWidget;
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

    if (isDark) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(Color(0xFFF4F1EA), BlendMode.srcIn),
        child: logoWidget,
      );
    }

    return logoWidget;
  }
}
