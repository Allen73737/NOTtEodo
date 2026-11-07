import '../../../core/services/ai_copilot_service.dart';
import '../../../core/services/calendar_reminder_service.dart';
import '../../../core/widgets/sanctuary_clock_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/sparkle_explosion.dart';
import '../../../core/widgets/ultra_micro_interactions.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/widgets/app_toast_engine.dart';

import '../../../core/luxury/wax_melt_compression_ritual.dart';
import '../../../core/motion/motion.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entry_editor.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/ai/ai_widgets.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/services/streak_achievement_service.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  Offset? _explosionPos;
  String _selectedFilter = 'All';

  final List<String> _filters = ['Smart groups', 'All', 'Today', 'Upcoming', 'Overdue', 'Pending', 'Completed', 'Morning', 'Afternoon', 'Evening'];

  void _showWaxSealModal(BuildContext context, bool isDark) {
    showSanctuaryDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAF7F2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFD9725B), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SAVE TODAY\'S PROGRESS',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: const Color(0xFFD9725B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () => Navigator.pop(dialogCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  "Press and hold the stamp below to celebrate today's completed tasks.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spectral(
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                WaxMeltCompressionRitual(
                  monogramLetter: 'N',
                  onSealed: () {
                    Navigator.pop(dialogCtx);
                    AppToastEngine().showToast(
                      context,
                      title: 'Progress Saved',
                      message: 'Great job! Your completed tasks have been sealed.',
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context, bool isDark) {
    openEntryEditor(context, EntryKind.task);
  }

  void _showAiTaskBreakdownModal(BuildContext context, TaskItem task, bool isDark) {
    showSanctuaryDialog(
      context: context,
      builder: (dialogCtx) {
        List<String>? subtasks;
        bool isLoading = true;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (subtasks == null && isLoading) {
              AiCopilotService().breakdownTask(task.title).then((results) {
                if (dialogCtx.mounted) {
                  setDialogState(() {
                    subtasks = results;
                    isLoading = false;
                  });
                }
              });
            }

            final dialogBg = isDark ? const Color(0xFF0A0A0A) : Colors.white;
            final textColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF16282C);
            final subColor = isDark ? const Color(0xFFA6A096) : const Color(0xFF635F59);
            final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E3D8);
            final accent = isDark ? const Color(0xFFE8927C) : const Color(0xFFD9725B);

            return Dialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: borderColor, width: 1.2),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(LucideIcons.sparkles, size: 16, color: accent),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI SUBTASK BREAKDOWN',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.x, size: 18, color: subColor),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      task.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (isLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Breaking down task into sequential actions...',
                                style: GoogleFonts.dmSans(fontSize: 12, color: subColor),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (subtasks != null && subtasks!.isNotEmpty) ...[
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 260),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: subtasks!.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final sub = subtasks![idx];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF16181D) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.arrowRight, size: 13, color: accent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      sub,
                                      style: GoogleFonts.dmSans(fontSize: 13, color: textColor),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: Text('Cancel', style: GoogleFonts.spaceGrotesk(color: subColor)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onPressed: () {
                              for (final sub in subtasks!) {
                                ref.read(tasksProvider.notifier).addTask(
                                  title: sub,
                                  priority: task.priority,
                                  space: task.space,
                                  timeOfDay: task.timeOfDay,
                                  notes: 'Subtask of: "${task.title}"',
                                );
                              }
                              Navigator.pop(dialogCtx);
                              AppToastEngine().showToast(
                                context,
                                title: 'Subtasks Added',
                                message: '${subtasks!.length} subtasks added to your tasks.',
                              );
                            },
                            icon: const Icon(LucideIcons.listPlus, size: 14),
                            label: Text(
                              'Add All as Tasks',
                              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _taskTile(BuildContext context, TaskItem task, bool isDark, Color primaryTextColor, Color subtextColor,
      Color accentColor, DateTime now) {
                    final isDone = task.isCompleted;

                    return Reveal(style: RevealStyle.slideIn, distance: 18, child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => openEntryEditor(context, EntryKind.task, editing: task),
                        child: BentoPod(
                          style: PodTextureStyle.paper,
                          showWaxSeal: isDone,
                          child: Row(
                            children: [
                              LiquidCheckmark(
                                isChecked: isDone,
                                size: 24,
                                activeColor: accentColor,
                                onChanged: (val) {
                                  SanctuaryHapticEngine.escapementTick();
                                  final RenderBox? box = context.findRenderObject() as RenderBox?;
                                  final pos = box != null ? box.localToGlobal(Offset.zero) : Offset.zero;
                                  ref.read(tasksProvider.notifier).toggleTask(task.id);
                                  if (val) {
                                    StreakAchievementService.checkAndUpdateStreak(ref, null);
                                    setState(() {
                                      _explosionPos = Offset(pos.dx + 40, pos.dy + 20);
                                    });
                                  }
                                },
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: GoogleFonts.bodoniModa(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDone ? primaryTextColor.withValues(alpha: 0.4) : primaryTextColor,
                                        decoration: isDone ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD9725B).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFD9725B).withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            task.priority.toUpperCase(),
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFD9725B),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (task.repeat != TaskRepeat.none) ...[
                                          Icon(LucideIcons.repeat, size: 12, color: subtextColor),
                                          const SizedBox(width: 4),
                                        ],
                                        Flexible(
                                          child: Text(
                                            task.dueAt == null
                                                ? '${task.space} · ${task.timeSlot}'
                                                : '${task.space} · ${task.isOverdue(now) ? 'Overdue · ' : ''}${DateLabels.dateTime(task.dueAt!)}',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 11,
                                              color: task.isOverdue(now) ? AppColors.error : subtextColor,
                                              fontWeight: task.isOverdue(now) ? FontWeight.w700 : FontWeight.normal,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'AI Task Breakdown',
                                icon: Icon(LucideIcons.sparkles, size: 15, color: accentColor),
                                onPressed: () => _showAiTaskBreakdownModal(context, task, isDark),
                              ),
                              IconButton(
                                tooltip: 'Set Reminder (Clock Dial)',
                                icon: Icon(LucideIcons.bellRing, size: 15, color: accentColor),
                                onPressed: () async {
                                  SanctuaryHapticEngine.dialDetent();
                                  final initial = task.dueAt != null
                                      ? TimeOfDay.fromDateTime(task.dueAt!)
                                      : const TimeOfDay(hour: 9, minute: 30);
                                  final picked = await showSanctuaryClockPicker(
                                    context: context,
                                    initialTime: initial,
                                    helpText: 'SET REMINDER CLOCK',
                                  );
                                  if (picked != null && context.mounted) {
                                    final now = DateTime.now();
                                    final baseDate = task.dueAt ?? now;
                                    var sched = DateTime(baseDate.year, baseDate.month, baseDate.day, picked.hour, picked.minute);
                                    if (sched.isBefore(now)) {
                                      sched = sched.add(const Duration(days: 1));
                                    }
                                    await CalendarReminderService().scheduleDeviceReminder(
                                      id: task.id,
                                      title: task.title,
                                      scheduledTime: sched,
                                      body: task.notes.isNotEmpty ? task.notes : 'Task due: ${task.title}',
                                    );
                                    if (context.mounted) {
                                      AppToastEngine().showToast(
                                        context,
                                        title: 'Reminder Clock Set',
                                        message: 'Alarm set for ${picked.format(context)} (${sched.day == now.day ? "Today" : "Tomorrow"}).',
                                        type: ToastType.success,
                                      );
                                    }
                                  }
                                },
                              ),
                              IconButton(
                                tooltip: 'Add to Google Calendar',
                                icon: Icon(LucideIcons.calendarPlus, size: 15, color: subtextColor),
                                onPressed: () async {
                                  SanctuaryHapticEngine.dialDetent();
                                  final start = task.dueAt ?? DateTime.now();
                                  final end = start.add(const Duration(hours: 1));
                                  await CalendarReminderService().addToGoogleCalendar(
                                    title: task.title,
                                    startTime: start,
                                    endTime: end,
                                    description: task.notes,
                                  );
                                  if (context.mounted) {
                                    AppToastEngine().showToast(
                                      context,
                                      title: 'Google Calendar',
                                      message: 'Opened Google Calendar for "${task.title}".',
                                      type: ToastType.success,
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                tooltip: 'Delete task',
                                icon: Icon(LucideIcons.trash2, size: 16, color: isDark ? Colors.white30 : Colors.black26),
                                onPressed: () {
                                  SanctuaryHapticEngine.sealImpression();
                                  ref.read(tasksProvider.notifier).removeTask(task.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    final allTasks = ref.watch(tasksProvider);
    final aiOn = ref.watch(appSettingsProvider.select((s) => s.smartSuggestions));

    final now = DateTime.now();
    final filteredTasks = allTasks.where((task) {
      if (_selectedFilter == 'Today') return task.isDueOn(now) || (task.isOverdue(now));
      if (_selectedFilter == 'Upcoming') return !task.isCompleted && task.dueAt != null && task.dueAt!.isAfter(now);
      if (_selectedFilter == 'Overdue') return task.isOverdue(now);
      if (_selectedFilter == 'Pending') return !task.isCompleted;
      if (_selectedFilter == 'Completed') return task.isCompleted;
      if (_selectedFilter == 'Morning') return task.timeSlot == 'Morning';
      if (_selectedFilter == 'Afternoon') return task.timeSlot == 'Afternoon';
      if (_selectedFilter == 'Evening') return task.timeSlot == 'Evening';
      if (_selectedFilter == 'Smart groups') return !task.isCompleted;
      return true;
    }).toList()
      // Open work first, soonest due first; undated tasks after dated ones.
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        if (a.dueAt == null || b.dueAt == null) {
          if (a.dueAt == b.dueAt) return b.createdAt.compareTo(a.createdAt);
          return a.dueAt == null ? 1 : -1;
        }
        return a.dueAt!.compareTo(b.dueAt!);
      });

    final pendingCount = allTasks.where((t) => !t.isCompleted).length;
    final completedCount = allTasks.where((t) => t.isCompleted).length;
    final totalCount = allTasks.length;
    final ratio = totalCount == 0 ? 0.0 : (completedCount / totalCount);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title and Add Button
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 560;

                  final titleCol = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WORKSPACE', style: AppTypography.labelSm),
                      const SizedBox(height: 4),
                      Text(
                        'Tasks',
                        style: GoogleFonts.bodoniModa(fontSize: isNarrow ? 26 : 28, fontWeight: FontWeight.bold, color: primaryTextColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      RollingText(
                        '$pendingCount active tasks · $completedCount completed',
                        style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor),
                      ),
                    ],
                  );

                  final buttonsRow = Row(
                    mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
                    children: [
                      Expanded(
                        flex: isNarrow ? 1 : 0,
                        child: Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B2500),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _showWaxSealModal(context, isDark),
                          icon: const Icon(LucideIcons.stamp, size: 15),
                          label: const Text('Check-in', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        )),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: isNarrow ? 1 : 0,
                        child: Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _showAddTaskDialog(context, isDark),
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: const Text('Add Task', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        )),
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleCol,
                        const SizedBox(height: 14),
                        buttonsRow,
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: titleCol),
                      const SizedBox(width: 12),
                      buttonsRow,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Serene Daily Completion Progress
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF060606) : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE2DDD2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'DAILY TASKS PROGRESS',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.dmSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        RollingText(
                          '$completedCount OF $totalCount COMPLETED (${(ratio * 100).toInt()}%)',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF86CBB0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          Container(
                            height: 7,
                            width: double.infinity,
                            color: isDark ? const Color(0xFF21262D) : const Color(0xFFE5DFD4),
                          ),
                          FractionallySizedBox(
                            widthFactor: ratio,
                            child: Container(
                              height: 7,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: const Color(0xFF86CBB0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _filters.where((f) => aiOn || f != 'Smart groups').map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: filter == 'Smart groups'
                            ? Icon(LucideIcons.sparkles, size: 14, color: isSelected ? accentColor : subtextColor)
                            : null,
                        showCheckmark: filter != 'Smart groups',
                        label: Text(filter),
                        selected: isSelected,
                        selectedColor: accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white.withValues(alpha: 0.6),
                        labelStyle: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? accentColor : (isDark ? Colors.white70 : AppColors.onSurface),
                        ),
                        side: BorderSide(
                          color: isSelected ? accentColor : (isDark ? const Color(0xFF2C2C2C) : Colors.black12),
                        ),
                        onSelected: (val) {
                          SanctuaryHapticEngine.dialDetent();
                          setState(() => _selectedFilter = filter);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),

              // Task List
              if (aiOn && _selectedFilter == 'Smart groups' && filteredTasks.isNotEmpty)
                SmartGroupsView<TaskItem>(
                  items: filteredTasks,
                  kind: 'tasks',
                  textOf: (t) => '${t.title} ${t.title} ${t.notes} ${t.space.replaceAll(' Space', '')}',
                  itemBuilder: (t) => Builder(
                    key: ValueKey('sg-${t.id}'),
                    builder: (context) => _taskTile(context, t, isDark, primaryTextColor, subtextColor, accentColor, now),
                  ),
                )
              else if (filteredTasks.isEmpty)
                const EmptyState(
  icon: LucideIcons.checkCircle2,
  title: 'All clear',
  message: 'No tasks match this filter. Enjoy the calm, or add a new priority.',
)
              else
                MotionColumn(
  spacing: 0,
  children: [
    for (var idx = 0; idx < filteredTasks.length; idx++)
      Builder(
          key: ValueKey(filteredTasks[idx].id),
          builder: (context) => _taskTile(context, filteredTasks[idx], isDark, primaryTextColor, subtextColor, accentColor, now)),
  ],
),
            ].revealed(),
          ),
        ),

        // Particle Explosion Overlay
        if (_explosionPos != null)
          SparkleExplosion(
            position: _explosionPos!,
            onComplete: () => setState(() => _explosionPos = null),
          ),
      ],
    );
  }
}
