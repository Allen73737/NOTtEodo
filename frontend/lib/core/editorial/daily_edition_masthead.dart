import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../motion/motion.dart';
import '../state/app_settings.dart';
import '../state/sanctuary_state.dart';
import 'editorial_kit.dart';
import 'editorial_mode.dart';

/// The Daily Edition Dynamic Masthead
///
/// A living publication header inspired by bespoke literary gazettes and horology.
/// Can be toggled on/off in Settings (off by default via [UiPrefs.dailyEdition]).
///
/// Differentiates cleanly between:
/// - Editorial View: Words on paper, hairline dividers, typography rhythm.
/// - Cards View: Tactile bento pod, rounded chamfers, subtle obsidian/ivory surface.
class DailyEditionMasthead extends ConsumerStatefulWidget {
  final bool isEditorial;

  const DailyEditionMasthead({super.key, required this.isEditorial});

  @override
  ConsumerState<DailyEditionMasthead> createState() => _DailyEditionMastheadState();
}

class _DailyEditionMastheadState extends ConsumerState<DailyEditionMasthead> {
  bool _expanded = false;

  static String editionLabel(int hour) {
    if (hour >= 4 && hour < 8) return 'DAWN EDITION';
    if (hour >= 8 && hour < 12) return 'MORNING EDITION';
    if (hour >= 12 && hour < 17) return 'AFTERNOON EDITION';
    if (hour >= 17 && hour < 21) return 'TWILIGHT EDITION';
    return 'NOCTURNE EDITION';
  }

  static String toRomanNumeral(int n) {
    const roman = {
      10: 'X',
      9: 'IX',
      5: 'V',
      4: 'IV',
      1: 'I',
    };
    var result = '';
    var val = n;
    for (final entry in roman.entries) {
      while (val >= entry.key) {
        result += entry.value;
        val -= entry.key;
      }
    }
    return result.isEmpty ? 'I' : result;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFD0485A) : AppColors.secondary;
    final ink = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final muted = isDark ? const Color(0xFFA89C9C) : const Color(0xFF6B605A);
    final border = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEDE6DF);
    final cardBg = isDark ? const Color(0xFF000000) : Colors.white;

    final daysEpoch = now.difference(DateTime(2025, 1, 1)).inDays + 1;
    final issueNumber = daysEpoch > 0 ? daysEpoch : 1;
    final volume = toRomanNumeral(((now.year - 2024)).clamp(1, 10));
    final edition = editionLabel(now.hour);
    final dateFormatted = DateFormat('EEEE, d MMMM yyyy').format(now);

    final tasks = ref.watch(tasksProvider);
    final activeTasks = tasks.where((t) => !t.isCompleted).length;
    final streak = ref.watch(appSettingsProvider.select((s) => s.activeStreak));

    final poeticSummary = activeTasks == 0
        ? 'All commitments for today are fulfilled. Enjoy the quiet pause.'
        : '$activeTasks active intentions awaiting focus · $streak day streak in rhythm.';

    if (widget.isEditorial) {
      final ed = Ed.of(context);
      return Semantics(
        container: true,
        label: 'Daily Edition: Issue $issueNumber, $edition',
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _expanded = !_expanded);
          },
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Publication Kicker & Cadence
                Row(
                  children: [
                    Text(
                      'NOTtEodo · ISSUE NO. $issueNumber · VOL. $volume',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                        color: ed.faint,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: ed.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      edition,
                      style: GoogleFonts.dmSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: ed.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // 2. Main Gazette Subhead
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        dateFormatted,
                        style: GoogleFonts.bodoniModa(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: ed.ink,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      size: 14,
                      color: ed.faint,
                    ),
                  ],
                ),

                // 3. Unfoldable Daily Poetic Summary
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      poeticSummary,
                      style: GoogleFonts.dmSans(
                        fontSize: 13.5,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                        color: ed.muted,
                      ),
                    ),
                  ),
                  crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: Motion.standard,
                ),

                const SizedBox(height: 12),
                // Razor Hairline Rule
                Divider(
                  height: 1,
                  thickness: 1,
                  color: ed.ink.withValues(alpha: isDark ? 0.14 : 0.12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // CARDS VIEW (Architectural Bento Pod)
    return Semantics(
      container: true,
      label: 'Daily Edition Card: Issue $issueNumber, $edition',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _expanded = !_expanded);
        },
        child: AnimatedContainer(
          duration: Motion.standard,
          curve: Motion.settle,
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: edBox(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.16 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          edition,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ISSUE NO. $issueNumber · VOL. $volume',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: muted,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 14,
                    color: muted,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                dateFormatted,
                style: GoogleFonts.bodoniModa(
                  fontSize: 16.5,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    poeticSummary,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      height: 1.45,
                      color: muted,
                    ),
                  ),
                ),
                crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: Motion.standard,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
