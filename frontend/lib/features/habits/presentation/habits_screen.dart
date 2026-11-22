import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/card_kit.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entry_editor.dart';
import '../../../core/widgets/ultra_micro_interactions.dart';
import 'habit_rewards_sheet.dart';
import '../../../core/motion/motion.dart';
import '../../../core/services/streak_achievement_service.dart';
import 'habit_heatmap_widget.dart';
import '../../../core/tour/spotlight_tour.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  /// Days shown in the activity heatmap (20 weeks).
  static const int heatmapDays = 140;

  void _toggleHabit(BuildContext context, WidgetRef ref, HabitItem habit) {
    final justCompleted = ref.read(habitsProvider.notifier).toggleHabit(habit.id);
    if (!justCompleted) return;
    StreakAchievementService.checkAndUpdateStreak(ref, null);
    final updated = ref.read(habitsProvider).firstWhere((h) => h.id == habit.id);
    showSanctuaryDialog(
      context: context,
      builder: (ctx) => HabitRewardsSheet(habitTitle: updated.title, streakDays: updated.streak),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = CardInk.of(context);
    final isDark = c.dark;
    final habits = ref.watch(habitsProvider);
    final now = DateTime.now();
    final dueToday = habits.where((h) => h.isDueOn(now)).toList();
    final doneToday = dueToday.where((h) => h.completedToday).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Habits', style: GoogleFonts.bodoniModa(fontSize: 36, fontWeight: FontWeight.bold, color: c.ink, height: 1.05)),
                    const SizedBox(height: 4),
                    RollingText('${habits.length} ${habits.length == 1 ? 'habit' : 'habits'}', style: c.meta.copyWith(fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TourTarget(id: 'page.primary', child: CardAction(label: 'New habit', icon: LucideIcons.plus, onTap: () => openEntryEditor(context, EntryKind.habit))),
            ],
          ),
          const SizedBox(height: 20),

          // Today: one figure and one line, then the consistency grid.
          TourTarget(id: 'habits.today', child: BentoPod(
            style: PodTextureStyle.glass,
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardLabel('Today', trailing: dueToday.isEmpty ? null : (doneToday == dueToday.length ? 'All done' : '${dueToday.length - doneToday} left')),
                CardFigure(dueToday.isEmpty ? '0' : '$doneToday of ${dueToday.length}', unit: 'done'),
                if (dueToday.isNotEmpty) CardMeter(fraction: doneToday / dueToday.length),
                const CardRule(),
                HabitConsistencyHeatmap(habits: habits, now: now, isDark: isDark),
              ],
            ),
          )),
          const SizedBox(height: 20),

          if (habits.isEmpty)
            EmptyState(
              icon: LucideIcons.flame,
              title: 'No habits yet',
              message: 'Add a small daily habit and check it off each day to build a streak.',
              action: CardAction(label: 'Add a habit', icon: LucideIcons.plus, onTap: () => openEntryEditor(context, EntryKind.habit)),
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

/// One habit: a check, its name, the streak as a figure, and the last seven days as
/// circles you can tap to fix a missed day. Filling a circle pops a tick into it.
class _HabitTile extends StatelessWidget {
  final HabitItem habit;
  final DateTime now;
  final VoidCallback onToggle;
  final ValueChanged<DateTime> onToggleDay;
  final VoidCallback onEdit;

  const _HabitTile({
    required this.habit,
    required this.now,
    required this.onToggle,
    required this.onToggleDay,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final c = CardInk.of(context);
    final isDone = habit.completedToday;
    final streak = habit.streakAt(now);
    final today = DateTime(now.year, now.month, now.day);

    return BentoPod(
      style: PodTextureStyle.paper,
      padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
      onTap: onToggle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LiquidCheckmark(isChecked: isDone, size: 22, activeColor: c.fill, onChanged: (_) => onToggle()),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.title, style: c.body.copyWith(fontSize: 16), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      [habit.time, 'Best ${habit.bestStreak} ${habit.bestStreak == 1 ? 'day' : 'days'}'].where((s) => s.trim().isNotEmpty).join(' · '),
                      style: c.meta.copyWith(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RollingText('$streak', style: c.figureSmall.copyWith(fontSize: 24, color: streak > 0 ? c.ink : c.muted)),
                  Text(streak == 1 ? 'day' : 'days', style: c.meta.copyWith(fontSize: 11.5)),
                ],
              ),
              Tooltip(
                message: 'Edit habit',
                child: Pressable(
                  pressedScale: 0.85,
                  hoverLift: 0,
                  onTap: onEdit,
                  child: SizedBox(width: 40, height: 40, child: Center(child: Icon(LucideIcons.pencil, size: 15, color: c.muted))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: [
                for (var i = 6; i >= 0; i--)
                  Expanded(
                    child: Builder(builder: (context) {
                      final day = today.subtract(Duration(days: i));
                      final done = habit.isDoneOn(day);
                      final isToday = i == 0;
                      return Semantics(
                        button: true,
                        label: '${DateLabels.long(day)}: ${done ? 'done' : 'not done'}',
                        excludeSemantics: true,
                        child: Pressable(
                          pressedScale: 0.85,
                          hoverLift: 0,
                          onTap: () => onToggleDay(day),
                          child: Column(
                            children: [
                              Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1],
                                  style: c.meta.copyWith(fontSize: 11.5, color: isToday ? c.ink : c.muted, fontWeight: isToday ? FontWeight.w700 : FontWeight.w400)),
                              const SizedBox(height: 5),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 360),
                                curve: Motion.settle,
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: done ? c.fill : Colors.transparent,
                                  border: done ? null : Border.all(color: isToday ? c.mark : c.muted.withValues(alpha: 0.35), width: isToday ? 1.5 : 1.2),
                                ),
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 420),
                                  curve: Motion.settle,
                                  scale: done ? 1 : 0,
                                  child: Icon(Icons.check_rounded, size: 14, color: c.onFill),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
