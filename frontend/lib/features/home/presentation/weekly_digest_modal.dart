import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/state/sanctuary_state.dart';

class WeeklyDigestModal extends ConsumerWidget {
  const WeeklyDigestModal({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WeeklyDigestModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0C0B) : const Color(0xFFFAF6F2);
    final cardBg = isDark ? const Color(0xFF181514) : Colors.white;
    final border = isDark ? const Color(0xFF282421) : const Color(0xFFE8DFD7);
    final textColor = isDark ? const Color(0xFFF5EFEB) : const Color(0xFF1A1817);
    final subtextColor = isDark ? const Color(0xFF9E958E) : const Color(0xFF7A7067);
    const terracotta = Color(0xFF8E2433);
    final currencySymbol = ref.watch(appSettingsProvider.select((s) => s.currencySymbol));

    // Calculate Week Range
    final daysSinceMonday = now.weekday - 1;
    final startOfWeek = DateTime(now.year, now.month, now.day - daysSinceMonday);
    final prevWeekStart = startOfWeek.subtract(const Duration(days: 7));

    // 1. Task completions this week
    final allTasks = ref.watch(tasksProvider);
    final completedThisWeek = allTasks.where((t) => t.isCompleted).length;
    final pendingCount = allTasks.where((t) => !t.isCompleted).length;

    // 2. Habit Consistency
    final habits = ref.watch(habitsProvider);
    int habitDoneCount = 0;
    int habitTotalDue = 0;
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      if (day.isAfter(now)) continue;
      for (final h in habits) {
        if (h.isDueOn(day)) {
          habitTotalDue++;
          if (h.isDoneOn(day)) habitDoneCount++;
        }
      }
    }
    final habitScore = habitTotalDue > 0 ? ((habitDoneCount / habitTotalDue) * 100).round() : 100;

    // 3. Spending comparison
    final expensesState = ref.watch(expensesProvider);
    final thisWeekSpend = expensesState.items
        .where((e) => !e.spentAt.isBefore(startOfWeek) && !e.spentAt.isAfter(now))
        .fold(0.0, (sum, e) => sum + e.amount);
    final lastWeekSpend = expensesState.items
        .where((e) => !e.spentAt.isBefore(prevWeekStart) && e.spentAt.isBefore(startOfWeek))
        .fold(0.0, (sum, e) => sum + e.amount);

    final double spendDiff = thisWeekSpend - lastWeekSpend;
    final bool spentLess = spendDiff <= 0;

    // 4. Journal Mood Highlights
    final journals = ref.watch(journalProvider);
    final thisWeekJournals = journals.where((j) => !j.date.toLowerCase().contains('month') && !j.date.toLowerCase().contains('year')).toList();
    final moods = thisWeekJournals.map((j) => j.mood).toSet().toList();

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: subtextColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: terracotta.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.compass, size: 20, color: terracotta),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Executive Weekly Digest',
                      style: GoogleFonts.bodoniModa(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Sunday reflection & retrospective',
                      style: TextStyle(fontSize: 12.5, color: subtextColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.x, size: 18, color: subtextColor),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                // 1. Core Metrics Grid
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: LucideIcons.checkCheck,
                        value: '$completedThisWeek',
                        label: 'Tasks Sealed',
                        subtext: '$pendingCount open tasks remaining',
                        color: const Color(0xFF7A1F2B),
                        cardBg: cardBg,
                        border: border,
                        textColor: textColor,
                        subtextColor: subtextColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        icon: LucideIcons.flame,
                        value: '$habitScore%',
                        label: 'Habit Consistency',
                        subtext: '$habitDoneCount of $habitTotalDue rituals kept',
                        color: terracotta,
                        cardBg: cardBg,
                        border: border,
                        textColor: textColor,
                        subtextColor: subtextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2. Spending Insight Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: (spentLess ? const Color(0xFFB5505E) : terracotta).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          spentLess ? LucideIcons.trendingDown : LucideIcons.trendingUp,
                          size: 20,
                          color: spentLess ? const Color(0xFFB5505E) : terracotta,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Treasury: $currencySymbol${thisWeekSpend.toInt()} this week',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              spentLess
                                  ? 'Saved $currencySymbol${(-spendDiff).toInt()} compared to prior week'
                                  : '$currencySymbol${spendDiff.toInt()} higher outflow than last week',
                              style: TextStyle(fontSize: 12, color: subtextColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 3. Mental Sanctuary & Mood Reflections
                if (moods.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mental sanctuary moods',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.1,
                            color: terracotta,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            for (final m in moods)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: terracotta.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '✨ $m',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: terracotta),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // 4. Executive Perspective Closing Quote
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: terracotta.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: terracotta.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.sparkles, size: 14, color: terracotta),
                          const SizedBox(width: 8),
                          Text(
                            'Weekly meditation',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.1,
                              color: terracotta,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '“Calm mind brings inner strength and self-confidence, so that is very important for good health.”',
                        style: GoogleFonts.bodoniModa(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Clear your slate for Monday morning.',
                        style: TextStyle(fontSize: 11.5, color: subtextColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String subtext;
  final Color color;
  final Color cardBg;
  final Color border;
  final Color textColor;
  final Color subtextColor;

  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.subtext,
    required this.color,
    required this.cardBg,
    required this.border,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: subtextColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.dmSans(fontFeatures: const [FontFeature.tabularFigures()], fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: subtextColor),
          ),
        ],
      ),
    );
  }
}
