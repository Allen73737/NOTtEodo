import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';

/// Full GitHub-style 52-week / 365-day habit consistency matrix
class HabitConsistencyHeatmap extends StatelessWidget {
  final List<HabitItem> habits;
  final DateTime now;
  final bool isDark;

  const HabitConsistencyHeatmap({
    super.key,
    required this.habits,
    required this.now,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const totalWeeks = 52;
    final today = DateTime(now.year, now.month, now.day);
    // Find the end of current week (Sunday)
    final daysUntilSunday = DateTime.sunday - today.weekday;
    final endOfWeek = today.add(Duration(days: daysUntilSunday));
    // Start of 52 weeks ago (Monday)
    final startOfGrid = endOfWeek.subtract(const Duration(days: (totalWeeks * 7) - 1));

    final totalHabits = habits.length;

    // Build weeks
    final List<List<DateTime>> weeks = [];
    for (int w = 0; w < totalWeeks; w++) {
      final List<DateTime> week = [];
      for (int d = 0; d < 7; d++) {
        week.add(startOfGrid.add(Duration(days: (w * 7) + d)));
      }
      weeks.add(week);
    }

    const terracotta = Color(0xFFD9725B);
    final emptyCellColor = isDark
        ? const Color(0xFF1E1A18)
        : const Color(0xFFEFE8E1);
    final subtextColor = isDark ? const Color(0xFF9E958E) : const Color(0xFF7A7067);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary & Legend Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '52-WEEK ANNUAL CONSISTENCY',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: terracotta,
              ),
            ),
            Row(
              children: [
                Text('Less', style: TextStyle(fontSize: 10, color: subtextColor)),
                const SizedBox(width: 4),
                _legendSquare(emptyCellColor),
                const SizedBox(width: 3),
                _legendSquare(terracotta.withValues(alpha: 0.35)),
                const SizedBox(width: 3),
                _legendSquare(terracotta.withValues(alpha: 0.65)),
                const SizedBox(width: 3),
                _legendSquare(terracotta),
                const SizedBox(width: 4),
                Text('More', style: TextStyle(fontSize: 10, color: subtextColor)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Scrollable 52-week grid
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true, // Scroll to recent weeks by default
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day of week labels (Mon, Wed, Fri)
              Padding(
                padding: const EdgeInsets.only(top: 20, right: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _dayLabel('M', subtextColor),
                    const SizedBox(height: 14),
                    _dayLabel('W', subtextColor),
                    const SizedBox(height: 14),
                    _dayLabel('F', subtextColor),
                    const SizedBox(height: 6),
                  ],
                ),
              ),

              // Columns for 52 weeks
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month labels row
                  Row(
                    children: [
                      for (int w = 0; w < totalWeeks; w++)
                        SizedBox(
                          width: 14,
                          child: (weeks[w].first.day <= 7)
                              ? Text(
                                  DateFormat('MMM').format(weeks[w].first)[0],
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: subtextColor,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // 7 Days Grid
                  Row(
                    children: [
                      for (int w = 0; w < totalWeeks; w++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: Column(
                            children: [
                              for (int d = 0; d < 7; d++) ...[
                                Builder(builder: (context) {
                                  final day = weeks[w][d];
                                  final isFuture = day.isAfter(today);
                                  if (isFuture) {
                                    return Container(
                                      width: 11,
                                      height: 11,
                                      margin: const EdgeInsets.symmetric(vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    );
                                  }

                                  final doneCount = habits.where((h) => h.isDoneOn(day)).length;
                                  final ratio = totalHabits == 0 ? 0.0 : doneCount / totalHabits;

                                  final cellColor = ratio == 0
                                      ? emptyCellColor
                                      : (ratio < 0.35
                                          ? terracotta.withValues(alpha: 0.35)
                                          : (ratio < 0.7
                                              ? terracotta.withValues(alpha: 0.68)
                                              : terracotta));

                                  return Tooltip(
                                    message: '${DateLabels.long(day)}: $doneCount/$totalHabits completed',
                                    child: Container(
                                      width: 11,
                                      height: 11,
                                      margin: const EdgeInsets.symmetric(vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: cellColor,
                                        borderRadius: BorderRadius.circular(2.5),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dayLabel(String label, Color color) {
    return SizedBox(
      height: 11,
      child: Text(
        label,
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _legendSquare(Color color) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
