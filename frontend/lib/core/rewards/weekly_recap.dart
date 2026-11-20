import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../editorial/editorial_kit.dart';
import '../editorial/editorial_mode.dart';
import '../state/app_settings.dart';
import '../state/sanctuary_state.dart';
import 'rewards_ledger.dart';

/// What happened in one seven-day stretch.
class WeekStats {
  final DateTime start;
  final DateTime end;
  final int tasksDone;
  final int habitsKept;
  final int journal;
  final int notes;
  final int activeDays;
  final double spent;
  final List<BadgeDef> badges;

  const WeekStats({
    required this.start,
    required this.end,
    this.tasksDone = 0,
    this.habitsKept = 0,
    this.journal = 0,
    this.notes = 0,
    this.activeDays = 0,
    this.spent = 0,
    this.badges = const [],
  });

  int get total => tasksDone + habitsKept + journal + notes;
}

/// The last seven days (today included) beside the seven before them.
class WeeklyRecap {
  final WeekStats week;
  final WeekStats last;

  const WeeklyRecap(this.week, this.last);

  static WeeklyRecap compute({
    required DateTime now,
    required List<TaskItem> tasks,
    required List<HabitItem> habits,
    required List<MemoirItem> journal,
    required List<NoteItem> notes,
    required List<ExpenseItem> expenses,
    required RewardsLedger ledger,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    WeekStats stretch(DateTime start) {
      final end = start.add(const Duration(days: 7));
      bool inside(DateTime? d) => d != null && !d.isBefore(start) && d.isBefore(end);
      bool keyInside(String key) => inside(DateTime.tryParse(key));
      return WeekStats(
        start: start,
        end: end.subtract(const Duration(days: 1)),
        tasksDone: tasks.where((t) => t.completed && !isSampleId(t.id) && inside(t.completedAt)).length,
        habitsKept: habits.where((h) => !isSampleId(h.id)).fold(0, (p, h) => p + h.completedDays.where(keyInside).length),
        journal: journal.where((j) => !isSampleId(j.id) && inside(j.createdAt)).length,
        notes: notes.where((n) => !isSampleId(n.id) && inside(n.createdAt)).length,
        activeDays: ledger.activeDays.where(keyInside).length,
        spent: expenses.where((e) => !isSampleId(e.id) && inside(e.spentAt)).fold(0.0, (p, e) => p + e.amount),
        badges: [for (final b in Badges.all) if (ledger.badges[b.id] != null && keyInside(ledger.badges[b.id]!)) b],
      );
    }

    final start = today.subtract(const Duration(days: 6));
    return WeeklyRecap(stretch(start), stretch(start.subtract(const Duration(days: 7))));
  }

  /// One sentence for the notification and the top of the sheet.
  String get headline {
    final w = week;
    if (w.total == 0 && w.activeDays == 0) return 'A quiet week. Next week is a clean page.';
    final parts = <String>[
      if (w.tasksDone > 0) '${w.tasksDone} task${w.tasksDone == 1 ? '' : 's'} done',
      if (w.habitsKept > 0) 'habits kept ${w.habitsKept} time${w.habitsKept == 1 ? '' : 's'}',
      if (w.journal > 0) '${w.journal} journal entr${w.journal == 1 ? 'y' : 'ies'}',
    ];
    final diff = w.total - last.total;
    final trend = last.total == 0
        ? ''
        : diff > 0
            ? ' More than last week.'
            : diff < 0
                ? ' A little less than last week.'
                : ' Level with last week.';
    if (parts.isEmpty) return 'You showed up ${w.activeDays} of 7 days.$trend';
    final joined = parts.length == 1 ? parts.first : '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}';
    return '${joined[0].toUpperCase()}${joined.substring(1)}.$trend';
  }
}

WeeklyRecap _recapFrom(WidgetRef ref) => WeeklyRecap.compute(
      now: DateTime.now(),
      tasks: ref.read(tasksProvider),
      habits: ref.read(habitsProvider),
      journal: ref.read(journalProvider),
      notes: ref.read(notesProvider),
      expenses: ref.read(expensesProvider).expenses,
      ledger: RewardsLedger(ref.read(appSettingsProvider).rewards),
    );

/// The week at a glance: what got done, compared with the week before, and the badges
/// earned along the way.
class WeeklyRecapSheet extends ConsumerWidget {
  const WeeklyRecapSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const WeeklyRecapSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = _recapFrom(ref);
    final s = ref.watch(appSettingsProvider);
    final editorial = EditorialMode.active;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ed = editorial ? Ed.of(context) : null;
    final paper = ed?.paper ?? (dark ? const Color(0xFF141010) : const Color(0xFFFBF8F4));
    final ink = ed?.ink ?? (dark ? const Color(0xFFF6F3ED) : const Color(0xFF1C1917));
    final muted = ed?.muted ?? (dark ? const Color(0xFFA6A096) : const Color(0xFF6B635A));
    final accent = ed?.accent ?? (dark ? const Color(0xFFD0485A) : const Color(0xFF8E2433));
    final range = '${DateFormat.MMMd().format(r.week.start)} – ${DateFormat.MMMd().format(r.week.end)}';
    final title = editorial ? ed!.title : GoogleFonts.dmSans(fontSize: 26, fontWeight: FontWeight.w800, color: ink);

    Widget stat(IconData icon, String label, num now, num before, {String Function(num)? show, bool lessIsBetter = false}) {
      final fmt = show ?? (n) => '${n.round()}';
      final diff = now - before;
      final better = lessIsBetter ? diff < 0 : diff > 0;
      final delta = diff == 0 ? 'same as last week' : '${diff > 0 ? '+' : '−'}${fmt(diff.abs())} vs last week';
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(editorial ? 4 : 18),
          border: Border.all(color: muted.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(height: 10),
            Text(fmt(now), style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w800, color: ink)),
            Text(label, style: GoogleFonts.dmSans(fontSize: 12.5, color: muted)),
            const SizedBox(height: 4),
            Text(
              delta,
              style: GoogleFonts.dmSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: diff == 0 ? muted : (better ? accent : muted)),
            ),
          ],
        ),
      );
    }

    final money = NumberFormat.compactCurrency(symbol: s.currencySymbol, decimalDigits: 0);
    return Container(
      decoration: BoxDecoration(color: paper, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(width: 36, height: 4, decoration: BoxDecoration(color: muted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 18),
            Text('YOUR WEEK · ${range.toUpperCase()}', style: GoogleFonts.dmSans(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: accent)),
            const SizedBox(height: 8),
            Text(r.headline, style: title),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: [
                stat(LucideIcons.checkCheck, 'tasks done', r.week.tasksDone, r.last.tasksDone),
                stat(LucideIcons.repeat, 'habits kept', r.week.habitsKept, r.last.habitsKept),
                stat(LucideIcons.flame, 'days active of 7', r.week.activeDays, r.last.activeDays),
                stat(LucideIcons.bookOpen, 'journal entries', r.week.journal, r.last.journal),
                stat(LucideIcons.penLine, 'notes written', r.week.notes, r.last.notes),
                stat(LucideIcons.wallet, 'spent', r.week.spent, r.last.spent, show: (n) => money.format(n), lessIsBetter: true),
              ],
            ),
            if (r.week.badges.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('BADGES THIS WEEK', style: GoogleFonts.dmSans(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: muted)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final b in r.week.badges)
                    Chip(
                      avatar: Icon(b.icon, size: 14, color: accent),
                      label: Text(b.title, style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: ink)),
                      backgroundColor: accent.withValues(alpha: 0.08),
                      side: BorderSide(color: accent.withValues(alpha: 0.2)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Streak: ${s.activeStreak} day${s.activeStreak == 1 ? '' : 's'} · Level ${RewardsLedger(s.rewards).level.level}, ${RewardsLedger(s.rewards).level.title}',
              style: GoogleFonts.dmSans(fontSize: 13, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
