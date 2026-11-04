import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';

class SanctuaryTimeline extends ConsumerWidget {
  const SanctuaryTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    final tasks = ref.watch(tasksProvider);
    final notes = ref.watch(notesProvider);
    final habits = ref.watch(habitsProvider);
    final expenses = ref.watch(expensesProvider).expenses;

    // Dynamically compile real user life logs
    final List<Map<String, dynamic>> logs = [];

    for (final t in tasks.take(4)) {
      logs.add({
        'time': DateLabels.relative(t.completedAt ?? t.createdAt),
        'title': t.isCompleted ? 'Task Completed' : 'Active Task',
        'desc': t.title,
        'icon': t.isCompleted ? LucideIcons.checkCheck : LucideIcons.circleDot,
        'color': t.isCompleted ? const Color(0xFF86CBB0) : accentColor,
      });
    }

    for (final n in notes.take(3)) {
      logs.add({
        'time': DateLabels.relative(n.updatedAt),
        'title': 'Note Saved · ${n.space}',
        'desc': n.title,
        'icon': LucideIcons.fileText,
        'color': const Color(0xFFEAB368),
      });
    }

    for (final h in habits.where((h) => h.completedDays.isNotEmpty).take(2)) {
      logs.add({
        'time': '${h.streak}d Streak',
        'title': 'Habit Completed',
        'desc': h.title,
        'icon': LucideIcons.flame,
        'color': const Color(0xFFB5C9BE),
      });
    }

    for (final e in expenses.take(2)) {
      logs.add({
        'time': DateLabels.relative(e.spentAt),
        'title': 'Expense · ${e.category}',
        'desc': '${e.title} (₹${e.amount.toInt()})',
        'icon': LucideIcons.receipt,
        'color': const Color(0xFF86CBB0),
      });
    }

    return BentoPod(
      style: PodTextureStyle.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'RECENT ACTIVITY',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.secondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE LOG',
                style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: subtextColor),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (logs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? accentColor : AppColors.secondary).withValues(alpha: 0.12),
                      ),
                      child: Icon(LucideIcons.compass, size: 20, color: accentColor),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your timeline is empty.',
                      style: GoogleFonts.bodoniModa(fontSize: 14.5, fontWeight: FontWeight.bold, color: primaryTextColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your saved notes, finished tasks, and daily habits will appear here.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spectral(fontSize: 12.5, fontStyle: FontStyle.italic, color: subtextColor),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: logs.take(5).map((log) {
                final color = log['color'] as Color;
                final icon = log['icon'] as IconData;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
                            child: Icon(icon, size: 14, color: color),
                          ),
                          Container(width: 2, height: 24, color: isDark ? const Color(0xFF1E1E1E) : AppColors.outlineVariant),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    log['title'] as String,
                                    style: GoogleFonts.bodoniModa(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(log['time'] as String, style: GoogleFonts.dmSans(fontSize: 10, color: subtextColor)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              log['desc'] as String,
                              style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
