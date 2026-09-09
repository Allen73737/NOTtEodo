import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/sparkle_explosion.dart';
import '../../../core/widgets/ultra_micro_interactions.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  Offset? _explosionPos;
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Pending', 'Completed', 'Morning', 'Afternoon', 'Evening'];

  void _showAddTaskDialog(BuildContext context, bool isDark) {
    final titleController = TextEditingController();
    String priority = 'High';
    String timeSlot = 'Morning';
    String space = 'Academic Space';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dialogBg = isDark ? const Color(0xFF000000) : AppColors.surfaceContainerHigh;
            final textColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
            final borderColor = isDark ? const Color(0xFF1E1E1E) : AppColors.outlineVariant;

            return Dialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Seal New Priority', style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                        IconButton(
                          icon: Icon(LucideIcons.x, color: isDark ? Colors.white70 : AppColors.onSurface, size: 20),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Priority description...',
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : AppColors.onSurfaceVariant),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFFE8927C) : AppColors.secondary)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: priority,
                            dropdownColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              labelText: 'Priority',
                              labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.onSurfaceVariant),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: ['Urgent', 'High', 'Medium', 'Low']
                                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => priority = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: timeSlot,
                            dropdownColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              labelText: 'Time Slot',
                              labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.onSurfaceVariant),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: ['Morning', 'Afternoon', 'Evening']
                                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => timeSlot = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFFE8927C) : AppColors.primary,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (titleController.text.trim().isNotEmpty) {
                            ref.read(tasksProvider.notifier).addTask(
                                  title: titleController.text.trim(),
                                  priority: priority,
                                  space: space,
                                  timeSlot: timeSlot,
                                );
                            Navigator.pop(dialogCtx);
                          }
                        },
                        child: const Text('Add Priority to Rhythm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    final allTasks = ref.watch(tasksProvider);

    final filteredTasks = allTasks.where((task) {
      if (_selectedFilter == 'Pending') return !task.isCompleted;
      if (_selectedFilter == 'Completed') return task.isCompleted;
      if (_selectedFilter == 'Morning') return task.timeSlot == 'Morning';
      if (_selectedFilter == 'Afternoon') return task.timeSlot == 'Afternoon';
      if (_selectedFilter == 'Evening') return task.timeSlot == 'Evening';
      return true;
    }).toList();

    final pendingCount = allTasks.where((t) => !t.isCompleted).length;
    final completedCount = allTasks.where((t) => t.isCompleted).length;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title and Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TACTILE PRIORITIES SANCTUARY', style: AppTypography.labelSm),
                        const SizedBox(height: 4),
                        Text(
                          'Tasks & Wax Stamps',
                          style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$pendingCount active rhythm priorities · $completedCount sealed',
                          style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showAddTaskDialog(context, isDark),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Add Task', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
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
                          setState(() => _selectedFilter = filter);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),

              // Task List
              if (filteredTasks.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF000000) : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : Colors.black12),
                  ),
                  child: Column(
                    children: [
                      Icon(LucideIcons.checkCircle2, size: 40, color: accentColor.withValues(alpha: 0.6)),
                      const SizedBox(height: 12),
                      Text('No tasks match the filter', style: GoogleFonts.bodoniModa(fontSize: 18, color: primaryTextColor)),
                      const SizedBox(height: 4),
                      Text('All caught up or ready to curate a new priority!', style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor)),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, idx) {
                    final task = filteredTasks[idx];
                    final isDone = task.isCompleted;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTapUp: (details) {
                          ref.read(tasksProvider.notifier).toggleTask(task.id);
                          if (!isDone) {
                            setState(() {
                              _explosionPos = details.globalPosition;
                            });
                          }
                        },
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
                                  final RenderBox? box = context.findRenderObject() as RenderBox?;
                                  final pos = box != null ? box.localToGlobal(Offset.zero) : Offset.zero;
                                  ref.read(tasksProvider.notifier).toggleTask(task.id);
                                  if (val) {
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
                                    const SizedBox(height: 2),
                                    Text(
                                      '${task.priority} Priority · ${task.space} · ${task.timeSlot}',
                                      style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(LucideIcons.trash2, size: 16, color: isDark ? Colors.white30 : Colors.black26),
                                onPressed: () {
                                  ref.read(tasksProvider.notifier).removeTask(task.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
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
