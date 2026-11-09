import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/motion/motion.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Layers NOTtEodo's interaction feel onto a base theme: depth-aware page transitions,
/// neutral ink and hover states in the app palette, a slim scrollbar and unhurried tooltips.
abstract class AppMotionTheme {
  static ThemeData apply(ThemeData base, {required bool dark}) {
    // Interaction states stay neutral; only keyboard focus picks up the app's terracotta.
    final ink = dark ? Colors.white : const Color(0xFF1C1917);
    final accent = dark ? const Color(0xFFE8927C) : const Color(0xFFD9725B);
    const transitions = SanctuaryPageTransitionsBuilder();

    return base.copyWith(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: transitions,
          TargetPlatform.iOS: transitions,
          TargetPlatform.macOS: transitions,
          TargetPlatform.windows: transitions,
          TargetPlatform.linux: transitions,
          TargetPlatform.fuchsia: transitions,
        },
      ),
      splashFactory: InkRipple.splashFactory,
      splashColor: ink.withValues(alpha: dark ? 0.10 : 0.08),
      highlightColor: ink.withValues(alpha: dark ? 0.05 : 0.04),
      hoverColor: ink.withValues(alpha: dark ? 0.06 : 0.04),
      focusColor: accent.withValues(alpha: 0.18),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.hovered) ? 7 : 4),
        radius: const Radius.circular(8),
        thumbColor: WidgetStateProperty.all(ink.withValues(alpha: 0.28)),
        crossAxisMargin: 2,
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 450),
        showDuration: const Duration(milliseconds: 1800),
        decoration: edBox(
          color: dark ? const Color(0xFF141414) : const Color(0xFF1C1917),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        textStyle: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFFF7F4ED)),
      ),
    );
  }
}
