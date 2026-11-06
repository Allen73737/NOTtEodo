import 'package:flutter/material.dart';
import 'notteodo_monogram.dart';

/// The official NOTtEodo Haute Horlogerie & Sovereign App Icon widget.
/// Renders the master brand icon asset with anti-aliased squircle geometry,
/// deep pitch-black OLED backing, glowing hairline border, and optional ambient pulse.
class NotteodoAppIcon extends StatelessWidget {
  final double size;
  final double? borderRadius;
  final bool withGlow;
  final bool withBorder;
  final Color? borderColor;
  final Color? backgroundColor;
  final Widget? badge;
  final VoidCallback? onTap;

  const NotteodoAppIcon({
    super.key,
    this.size = 48,
    this.borderRadius,
    this.withGlow = false,
    this.withBorder = false,
    this.borderColor,
    this.backgroundColor,
    this.badge,
    this.onTap,
  });

  const NotteodoAppIcon.small({
    super.key,
    this.withGlow = false,
    this.withBorder = false,
    this.borderColor,
    this.backgroundColor,
    this.badge,
    this.onTap,
  })  : size = 28,
        borderRadius = 7;

  const NotteodoAppIcon.medium({
    super.key,
    this.withGlow = false,
    this.withBorder = false,
    this.borderColor,
    this.backgroundColor,
    this.badge,
    this.onTap,
  })  : size = 44,
        borderRadius = 11;

  const NotteodoAppIcon.large({
    super.key,
    this.withGlow = false,
    this.withBorder = false,
    this.borderColor,
    this.backgroundColor,
    this.badge,
    this.onTap,
  })  : size = 64,
        borderRadius = 16;

  const NotteodoAppIcon.hero({
    super.key,
    this.withGlow = false,
    this.withBorder = false,
    this.borderColor,
    this.backgroundColor,
    this.badge,
    this.onTap,
  })  : size = 96,
        borderRadius = 24;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final markColor = isDark ? Colors.white : Colors.black;

    Widget iconContent = SizedBox(
      width: size,
      height: size,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(markColor, BlendMode.srcIn),
        child: Image.asset(
          'assets/images/notteodo_n_logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: NotteodoMonogram(
                size: size,
                color: markColor,
              ),
            );
          },
        ),
      ),
    );

    Widget decorated = onTap != null
        ? GestureDetector(onTap: onTap, child: iconContent)
        : iconContent;

    if (badge != null) {
      decorated = Stack(
        clipBehavior: Clip.none,
        children: [
          decorated,
          Positioned(
            right: -2,
            bottom: -2,
            child: badge!,
          ),
        ],
      );
    }

    return decorated;
  }
}

