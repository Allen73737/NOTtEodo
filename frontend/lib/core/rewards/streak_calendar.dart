import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../editorial/editorial_kit.dart';
import '../editorial/editorial_mode.dart';
import '../state/app_settings.dart';
import '../widgets/bento_pod.dart';
import 'rewards_ledger.dart';
import 'weekly_recap.dart';

/// A month of the day streak: days the app was opened are filled, days a streak freeze
/// or repair covered are outlined with a snowflake, and today is ringed. Swipe through
/// earlier months with the arrows; the weekly recap opens from the corner.
class StreakCalendar extends ConsumerStatefulWidget {
  const StreakCalendar({super.key});

  @override
  ConsumerState<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends ConsumerState<StreakCalendar> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int by) => setState(() => _month = DateTime(_month.year, _month.month + by));

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appSettingsProvider);
    final ledger = RewardsLedger(s.rewards);
    final active = ledger.activeDays;
    final frozen = ledger.frozenDays;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final editorial = EditorialMode.active;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ed = editorial ? Ed.of(context) : null;
    final ink = ed?.ink ?? (dark ? const Color(0xFFF6F3ED) : const Color(0xFF1C1917));
    final muted = ed?.muted ?? (dark ? const Color(0xFFA6A096) : const Color(0xFF6B635A));
    final accent = ed?.accent ?? (dark ? const Color(0xFFD0485A) : const Color(0xFF8E2433));

    final first = _month;
    final daysIn = DateTime(first.year, first.month + 1, 0).day;
    final lead = (first.weekday - s.firstDayOfWeek + 7) % 7;
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final activeThisMonth = [for (var d = 1; d <= daysIn; d++) RewardsLedger.dayKey(DateTime(first.year, first.month, d))].where(active.contains).length;
    final canGoBack = active.isNotEmpty && RewardsLedger.dayKey(first).compareTo(active.reduce((a, b) => a.compareTo(b) < 0 ? a : b)) > 0;
    final canGoOn = first.isBefore(DateTime(now.year, now.month));

    Widget cell(int day) {
      final date = DateTime(first.year, first.month, day);
      final key = RewardsLedger.dayKey(date);
      final isActive = active.contains(key);
      final isFrozen = !isActive && frozen.contains(key);
      final isToday = date == today;
      final future = date.isAfter(today);
      return Semantics(
        label: '${DateFormat.MMMMd().format(date)}${isActive ? ', active' : isFrozen ? ', covered by a streak freeze' : ''}',
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? accent : null,
              border: isToday
                  ? Border.all(color: accent, width: 2)
                  : isFrozen
                      ? Border.all(color: muted.withValues(alpha: 0.7))
                      : null,
            ),
            alignment: Alignment.center,
            child: isFrozen
                ? Icon(LucideIcons.snowflake, size: 13, color: muted)
                : Text(
                    '$day',
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      fontWeight: isActive || isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? Colors.white : (future ? muted.withValues(alpha: 0.4) : muted),
                    ),
                  ),
          ),
        ),
      );
    }

    Widget arrow(IconData icon, bool enabled, VoidCallback onTap) => IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: enabled ? onTap : null,
          icon: Icon(icon, size: 18, color: enabled ? ink : muted.withValues(alpha: 0.3)),
        );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    editorial ? DateFormat.yMMMM().format(first) : DateFormat.yMMMM().format(first).toUpperCase(),
                    style: editorial
                        ? ed!.label.copyWith(color: ed.accent, letterSpacing: 1.2)
                        : GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: accent),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$activeThisMonth day${activeThisMonth == 1 ? '' : 's'} active · best run ${s.longestStreak}',
                    style: GoogleFonts.dmSans(fontSize: 12.5, color: muted),
                  ),
                ],
              ),
            ),
            arrow(LucideIcons.chevronLeft, canGoBack, () => _shift(-1)),
            arrow(LucideIcons.chevronRight, canGoOn, () => _shift(1)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(letters[(s.firstDayOfWeek - 1 + i) % 7], style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: muted)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          children: [
            for (var i = 0; i < lead; i++) const SizedBox.shrink(),
            for (var d = 1; d <= daysIn; d++) cell(d),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('Opened', style: GoogleFonts.dmSans(fontSize: 11.5, color: muted)),
            const SizedBox(width: 14),
            Icon(LucideIcons.snowflake, size: 11, color: muted),
            const SizedBox(width: 6),
            Text('Covered', style: GoogleFonts.dmSans(fontSize: 11.5, color: muted)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => WeeklyRecapSheet.show(context),
              icon: Icon(LucideIcons.chartColumn, size: 14, color: accent),
              label: Text('Your week', style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: accent)),
            ),
          ],
        ),
      ],
    );
    return editorial ? body : BentoPod(child: body);
  }
}
