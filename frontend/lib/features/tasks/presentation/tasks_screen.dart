import '../../../core/services/ai_copilot_service.dart';
import '../../../core/services/calendar_reminder_service.dart';
import '../../../core/widgets/sanctuary_clock_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/card_kit.dart';
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
import 'package:notteodo/core/editorial/editorial_mode.dart';

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
            side: const BorderSide(color: Color(0xFF8E2433), width: 1.5),
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
                      style: GoogleFonts.bodoniModa(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: const Color(0xFF8E2433),
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
                  style: GoogleFonts.dmSans(
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
            final textColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1C1917);
            final subColor = isDark ? const Color(0xFFA6A096) : const Color(0xFF635F59);
            final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E3D8);
            final accent = isDark ? const Color(0xFFD0485A) : const Color(0xFF8E2433);

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
                              decoration: edBox(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(LucideIcons.sparkles, size: 16, color: accent),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI subtask breakdown',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.1,
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
                      style: GoogleFonts.dmSans(
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
                              decoration: edBox(
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
                            child: Text('Cancel', style: GoogleFonts.dmSans(color: subColor)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
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
                              style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 12.5),
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

  Future<DateTime?> _showRescheduleSheet(BuildContext context, TaskItem task) async {
    final now = DateTime.now();
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF141211) : const Color(0xFFF7F3EE);
        final border = isDark ? const Color(0xFF282421) : const Color(0xFFE8DFD7);
        final textColor = isDark ? const Color(0xFFF5EFEB) : const Color(0xFF1A1817);
        final subtextColor = isDark ? const Color(0xFF9E958E) : const Color(0xFF7A7067);

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Text(
                'Reschedule Task',
                style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 4),
              Text(
                '"${task.title}"',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(LucideIcons.sun, color: Color(0xFF8E2433)),
                title: Text('Later Today · 6:00 PM', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, DateTime(now.year, now.month, now.day, 18, 0)),
              ),
              ListTile(
                leading: const Icon(LucideIcons.sunrise, color: Color(0xFFD0485A)),
                title: Text('Tomorrow Morning · 9:00 AM', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                onTap: () {
                  final tmrw = now.add(const Duration(days: 1));
                  Navigator.pop(ctx, DateTime(tmrw.year, tmrw.month, tmrw.day, 9, 0));
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.calendarDays, color: Color(0xFF7A1F2B)),
                title: Text('Next Week · 7 Days', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                onTap: () {
                  final nextWk = now.add(const Duration(days: 7));
                  Navigator.pop(ctx, DateTime(nextWk.year, nextWk.month, nextWk.day, 9, 0));
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.calendar, color: Color(0xFFB5505E)),
                title: Text('Pick a Date...', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now.subtract(const Duration(days: 1)),
                    lastDate: now.add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null && ctx.mounted) {
                    Navigator.pop(ctx, DateTime(picked.year, picked.month, picked.day, 9, 0));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _taskTile(BuildContext context, TaskItem task, int index, bool isDark, Color primaryTextColor, Color subtextColor,
      Color accentColor, DateTime now) {
    final isDone = task.isCompleted;
    final c = CardInk.of(context);

    return Dismissible(
      key: ValueKey('dismiss-${task.id}'),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF8E2433),
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const Icon(LucideIcons.calendar, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Reschedule',
              style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Move to Bin',
              style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          SanctuaryHapticEngine.selection();
          final newDate = await _showRescheduleSheet(context, task);
          if (newDate != null) {
            ref.read(tasksProvider.notifier).updateTask(task.id, dueAt: newDate);
            if (context.mounted) {
              AppToastEngine().showToast(
                context,
                title: 'Task Rescheduled',
                message: '"${task.title}" due ${DateLabels.dateTime(newDate)}',
                type: ToastType.info,
              );
            }
          }
          return false;
        } else {
          SanctuaryHapticEngine.sealImpression();
          ref.read(tasksProvider.notifier).removeTask(task.id);
          AppToastEngine().showToast(
            context,
            title: 'Moved to Bin',
            message: '"${task.title}" deleted.',
            type: ToastType.alert,
          );
          return true;
        }
      },
      child: Reveal(
        style: RevealStyle.slideIn,
        distance: 18,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => openEntryEditor(context, EntryKind.task, editing: task),
            child: BentoPod(
              style: PodTextureStyle.paper,
              showWaxSeal: isDone,
              padding: const EdgeInsets.fromLTRB(10, 12, 4, 12),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(LucideIcons.gripVertical, size: 15, color: c.muted.withValues(alpha: 0.35)),
                    ),
                  ),
                  LiquidCheckmark(
                    isChecked: isDone,
                    size: 22,
                    activeColor: c.fill,
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
                    child: AnimatedOpacity(
                      duration: Motion.standard,
                      opacity: isDone ? 0.45 : 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: Motion.standard,
                            curve: Motion.silk,
                            style: c.body.copyWith(
                              fontSize: 15.5,
                              decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                              decorationColor: c.muted,
                            ),
                            child: Text(task.title),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (task.repeat != TaskRepeat.none) ...[
                                Icon(LucideIcons.repeat, size: 12, color: c.muted),
                                const SizedBox(width: 5),
                              ],
                              Flexible(
                                child: Text(
                                  [
                                    if (task.isOverdue(now)) 'Overdue',
                                    task.dueAt == null ? task.timeSlot : DateLabels.dateTime(task.dueAt!),
                                    task.space,
                                    if (task.priority.toLowerCase().startsWith('high')) 'High priority',
                                  ].where((s) => s.trim().isNotEmpty).join(' · '),
                                  style: c.meta.copyWith(
                                    fontSize: 12.5,
                                    color: task.isOverdue(now) ? c.mark : c.muted,
                                    fontWeight: task.isOverdue(now) ? FontWeight.w700 : FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'More',
                    icon: Icon(LucideIcons.ellipsis, size: 18, color: c.muted),
                    color: isDark ? const Color(0xFF141111) : Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onSelected: (action) async {
                      switch (action) {
                        case 'breakdown':
                          _showAiTaskBreakdownModal(context, task, isDark);
                        case 'reminder':
                          await (() async {
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
                                })();
                        case 'calendar':
                          await (() async {
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
                                })();
                        case 'delete':
                          SanctuaryHapticEngine.sealImpression();
                          ref.read(tasksProvider.notifier).removeTask(task.id);
                      }
                    },
                    itemBuilder: (_) => [
                      for (final (value, label, icon) in [
                        ('breakdown', 'Break it into steps', LucideIcons.sparkles),
                        ('reminder', 'Set a reminder', LucideIcons.bellRing),
                        ('calendar', 'Add to Google Calendar', LucideIcons.calendarPlus),
                        ('delete', 'Delete task', LucideIcons.trash2),
                      ])
                        PopupMenuItem(
                          value: value,
                          child: Row(
                            children: [
                              Icon(icon, size: 16, color: value == 'delete' ? c.mark : c.muted),
                              const SizedBox(width: 12),
                              Text(label, style: c.body.copyWith(fontSize: 14, color: value == 'delete' ? c.mark : c.ink)),
                            ],
                          ),
                        ),
                    ],
                  ),
                            ],
                          ),
                        ),
                      ),
                    )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFD0485A) : AppColors.secondary;

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
              // Title, a one-line summary and the two actions.
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 560;
                  final c = CardInk.of(context);

                  final titleCol = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tasks',
                        style: GoogleFonts.bodoniModa(fontSize: isNarrow ? 32 : 36, fontWeight: FontWeight.bold, color: c.ink, height: 1.05),
                      ),
                      const SizedBox(height: 4),
                      RollingText('$pendingCount open · $completedCount done', style: c.meta.copyWith(fontSize: 14)),
                    ],
                  );

                  final buttonsRow = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CardLink(label: 'Check in', onTap: () => _showWaxSealModal(context, isDark)),
                      const SizedBox(width: 14),
                      CardAction(label: 'Add task', icon: LucideIcons.plus, onTap: () => _showAddTaskDialog(context, isDark)),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [titleCol, const SizedBox(height: 14), buttonsRow],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [Expanded(child: titleCol), const SizedBox(width: 12), buttonsRow],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Progress: one figure and one line.
              BentoPod(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CardLabel('All tasks', trailing: totalCount == 0 ? null : '${(ratio * 100).round()}%'),
                    CardFigure(totalCount == 0 ? '0' : '$completedCount of $totalCount', unit: 'done'),
                    CardMeter(fraction: ratio),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Filter words.
              CardTabs(
                options: _filters.where((f) => aiOn || f != 'Smart groups').toList(),
                selected: _selectedFilter,
                onSelected: (filter) {
                  SanctuaryHapticEngine.dialDetent();
                  setState(() => _selectedFilter = filter);
                },
              ),
              const SizedBox(height: 14),

              // Task List
              if (aiOn && _selectedFilter == 'Smart groups' && filteredTasks.isNotEmpty)
                SmartGroupsView<TaskItem>(
                  items: filteredTasks,
                  kind: 'tasks',
                  textOf: (t) => '${t.title} ${t.title} ${t.notes} ${t.space.replaceAll(' Space', '')}',
                  itemBuilder: (t) => Builder(
                    key: ValueKey('sg-${t.id}'),
                    builder: (context) => _taskTile(context, t, 0, isDark, primaryTextColor, subtextColor, accentColor, now),
                  ),
                )
              else if (filteredTasks.isEmpty)
                const EmptyState(
                  icon: LucideIcons.checkCircle2,
                  title: 'All clear',
                  message: 'No tasks match this filter. Enjoy the calm, or add a new priority.',
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: filteredTasks.length,
                  onReorder: (oldIdx, newIdx) {
                    SanctuaryHapticEngine.dialDetent();
                    final ids = [...filteredTasks.map((t) => t.id)];
                    if (oldIdx < newIdx) newIdx -= 1;
                    final movedId = ids.removeAt(oldIdx);
                    ids.insert(newIdx.clamp(0, ids.length), movedId);
                    ref.read(tasksProvider.notifier).reorderSubset(ids);
                  },
                  itemBuilder: (context, idx) => KeyedSubtree(
                    key: ValueKey('task-item-${filteredTasks[idx].id}'),
                    child: _taskTile(context, filteredTasks[idx], idx, isDark, primaryTextColor, subtextColor, accentColor, now),
                  ),
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
