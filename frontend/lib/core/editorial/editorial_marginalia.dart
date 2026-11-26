import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';
import 'editorial_kit.dart';
import 'editorial_mode.dart';

/// Editorial Marginalia & Gutter Callouts
///
/// In Editorial Mode ("Words on paper"), metadata, priorities, and status indicators
/// live in the margins/gutters as quiet typographic markings rather than intrusive
/// boxy card badges.
///
/// In Cards Mode, gracefully renders as a compact card badge complication.
class EditorialMarginalia extends StatelessWidget {
  /// The main item or content beside this marginalia gutter
  final Widget child;

  /// Text or time shown in the gutter (e.g. '09:30', 'P1', 'Due')
  final String? gutterLabel;

  /// Roman numeral index marker (e.g. 'I', 'II', 'IV')
  final String? romanIndex;

  /// Whether this item has high priority or urgency (renders a fine oxblood hairline tick)
  final bool isUrgent;

  /// Optional trailing annotation note placed at the far edge
  final String? trailingNote;

  const EditorialMarginalia({
    super.key,
    required this.child,
    this.gutterLabel,
    this.romanIndex,
    this.isUrgent = false,
    this.trailingNote,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFD0485A) : AppColors.secondary;
    final isEditorial = EditorialMode.active;

    if (isEditorial) {
      final ed = Ed.of(context);
      final hasGutter = gutterLabel != null || romanIndex != null || isUrgent;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (hasGutter)
              Container(
                width: 44,
                padding: const EdgeInsets.only(right: 10),
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isUrgent)
                      Container(
                        width: 2,
                        height: 12,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: ed.accent,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    if (romanIndex != null)
                      Text(
                        romanIndex!,
                        style: GoogleFonts.bodoniModa(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isUrgent ? ed.accent : ed.faint,
                        ),
                      ),
                    if (gutterLabel != null) ...[
                      if (romanIndex != null) const SizedBox(width: 4),
                      Text(
                        gutterLabel!,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isUrgent ? ed.accent : ed.muted,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            Expanded(child: child),
            if (trailingNote != null)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  trailingNote!,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: ed.faint,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // CARDS MODE: Compact badge complication
    final muted = isDark ? const Color(0xFFA89C9C) : const Color(0xFF6B605A);
    final cardPillBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEDE6DF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (gutterLabel != null || romanIndex != null || isUrgent)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isUrgent)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                if (romanIndex != null || gutterLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isUrgent ? accent.withValues(alpha: 0.14) : cardPillBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      [
                        if (romanIndex != null) romanIndex!,
                        if (gutterLabel != null) gutterLabel!,
                      ].join(' · '),
                      style: GoogleFonts.dmSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isUrgent ? accent : muted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                if (trailingNote != null) ...[
                  const Spacer(),
                  Text(
                    trailingNote!,
                    style: GoogleFonts.dmSans(fontSize: 11, color: muted),
                  ),
                ],
              ],
            ),
          ),
        child,
      ],
    );
  }
}
