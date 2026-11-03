import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entry_editor.dart';
import '../../../core/widgets/ultra_micro_interactions.dart';
import 'habit_rewards_sheet.dart';
import '../../../core/motion/motion.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  /// Days shown in the activity heatmap (20 weeks).
  static const int heatmapDays = 140;

  void _toggleHabit(BuildContext context, WidgetRef ref, HabitItem habit) {
    final justCompleted = ref.read(habitsProvider.notifier).toggleHabit(habit.id);
    if (!justCompleted) return;
    final updated = ref.read(habitsProvider).firstWhere((h) => h.id == habit.id);
    showSanctuaryDialog(
      context: context,
      builder: (ctx) => HabitRewardsSheet(habitTitle: updated.title, streakDays: updated.streak),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    final habits = ref.watch(habitsProvider);
    final now = DateTime.now();
    final doneToday = habits.where((h) => h.completedToday).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LIFESTYLE', style: AppTypography.labelSm),
                    const SizedBox(height: 4),
                    Text(
                      'Habits',
                      style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text('$doneToday of ${habits.length} done today',
                        style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor)),
                  ],
                ),
              ),
              Pressable(
                pressedScale: 0.95,
                hoverLift: 0,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => openEntryEditor(context, EntryKind.habit),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('New Habit', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          BentoPod(
            style: PodTextureStyle.glass,
            showWaxSeal: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LAST 20 WEEKS',
                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary)),
                const SizedBox(height: 12),
                _Heatmap(habits: habits, now: now, isDark: isDark),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (habits.isEmpty)
            EmptyState(
              icon: LucideIcons.flame,
              title: 'No habits yet',
              message: 'Add a small daily habit and check it off each day to build a streak.',
              action: TextButton(onPressed: () => openEntryEditor(context, EntryKind.habit), child: const Text('Add a habit')),
            )
          else
            for (final habit in habits)
              Reveal(
                key: ValueKey(habit.id),
                style: RevealStyle.slideIn,
                distance: 18,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HabitTile(
                    habit: habit,
                    now: now,
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    subtextColor: subtextColor,
                    onToggle: () => _toggleHabit(context, ref, habit),
                    onToggleDay: (day) => ref.read(habitsProvider.notifier).toggleHabit(habit.id, on: day),
                    onEdit: () => openEntryEditor(context, EntryKind.habit, editing: habit),
                  ),
                ),
              ),
        ].revealed(),
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  final HabitItem habit;
  final DateTime now;
  final bool isDark;
  final Color primaryTextColor;
  final Color subtextColor;
  final VoidCallback onToggle;
  final ValueChanged<DateTime> onToggleDay;
  final VoidCallback onEdit;

  const _HabitTile({
    required this.habit,
    required this.now,
    required this.isDark,
    required this.primaryTextColor,
    required this.subtextColor,
    required this.onToggle,
    required this.onToggleDay,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = habit.completedToday;
    final streak = habit.streakAt(now);
    final streakAccent = isDark ? AppColors.goldLight : AppColors.secondary;
    final today = DateTime(now.year, now.month, now.day);

    return BentoPod(
      style: PodTextureStyle.paper,
      padding: const EdgeInsets.all(16),
      onTap: onToggle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LiquidCheckmark(isChecked: isDone, size: 24, onChanged: (_) => onToggle()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: GoogleFonts.bodoniModa(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${habit.time} Â· best ${habit.bestStreak}d',
                      style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: streakAccent.withValues(alpha: isDark ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.flame, size: 14, color: streakAccent),
                    const SizedBox(width: 4),
                    Text('${streak}d', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: streakAccent)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit habit',
                icon: Icon(LucideIcons.pencil, size: 15, color: subtextColor),
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // The last 7 days; tap a day to fix a missed check-in.
          Row(
            children: [
              for (var i = 6; i >= 0; i--)
                Expanded(
                  child: Builder(builder: (context) {
                    final day = today.subtract(Duration(days: i));
                    final done = habit.isDoneOn(day);
                    final label = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1];
                    return Semantics(
                      button: true,
                      label: '${DateLabels.long(day)}: ${done ? 'done' : 'not done'}',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => onToggleDay(day),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: subtextColor)),
                              const SizedBox(height: 4),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: done ? streakAccent : Colors.transparent,
                                  border: Border.all(color: streakAccent.withValues(alpha: done ? 1 : 0.4), width: 1.4),
                                ),
                                child: done ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One square per day; darker means more of your habits were done that day.
class _Heatmap extends StatelessWidget {
  final List<HabitItem> habits;
  final DateTime now;
  final bool isDark;

  const _Heatmap({required this.habits, required this.now, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColors.goldLight : AppColors.secondary;
    final today = DateTime(now.year, now.month, now.day);
    const days = HabitsScreen.heatmapDays;
    final total = habits.length;
    return Semantics(
      label: 'Habit activity over the last 20 weeks',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: days,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 20,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemBuilder: (context, idx) {
          final day = today.subtract(Duration(days: days - 1 - idx));
          final done = habits.where((h) => h.isDoneOn(day)).length;
          final ratio = total == 0 ? 0.0 : done / total;
          return Tooltip(
            message: '${DateLabels.long(day)}: $done of $total',
            child: Container(
              decoration: BoxDecoration(
                color: ratio == 0
                    ? activeColor.withValues(alpha: isDark ? 0.12 : 0.1)
                    : activeColor.withValues(alpha: 0.3 + 0.7 * ratio),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        },
      ),
    );
  }
}
