import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import 'sanctuary_timeline.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Function(String) onOpenAiModal;

  const HomeScreen({super.key, required this.onOpenAiModal});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<int> _podOrder = [0, 1, 2];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    const accentColor = Color(0xFFEAB368);

    final tasks = ref.watch(tasksProvider);
    final activeTasks = tasks.where((t) => !t.isCompleted).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 920;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1360),
            child: SingleChildScrollView(
              physics: SanctuaryMotionEngine.fluidPhysics,
              padding: EdgeInsets.fromLTRB(
                isWide ? 36 : 20,
                16,
                isWide ? 36 : 20,
                120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & Circadian Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CIRCADIAN CYCLE · SERENE WORKSPACE',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Good day, Allen.',
                              style: GoogleFonts.bodoniModa(
                                fontSize: isWide ? 38 : 28,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '"Order and precision are the quiet luxuries of life."',
                              style: GoogleFonts.spectral(
                                fontSize: 13.5,
                                fontStyle: FontStyle.italic,
                                color: subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isWide) ...[
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            _statusChip('VAULT SECURED', const Color(0xFF86CBB0), isDark),
                            const SizedBox(width: 8),
                            _statusChip('18D STREAK', accentColor, isDark),
                          ],
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Responsive Bento Grid Layout
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Today's Rhythm & Priorities
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              _buildPodByIndex(0, isDark, primaryTextColor, subtextColor, tasks, activeTasks),
                              _buildPodByIndex(2, isDark, primaryTextColor, subtextColor, tasks, activeTasks),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Right Column: Sanctuary Timeline & Complications
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              _buildPodByIndex(1, isDark, primaryTextColor, subtextColor, tasks, activeTasks),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    // Mobile Single Column Stack
                    ..._podOrder.map(
                      (index) => _buildPodByIndex(index, isDark, primaryTextColor, subtextColor, tasks, activeTasks),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statusChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPodByIndex(
    int idx,
    bool isDark,
    Color primaryTextColor,
    Color subtextColor,
    List<TaskItem> tasks,
    List<TaskItem> activeTasks,
  ) {
    switch (idx) {
      case 0:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: BentoPod(
            style: PodTextureStyle.glass,
            showWaxSeal: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Rhythm",
                      style: GoogleFonts.bodoniModa(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFFE8927C) : AppColors.secondary).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${activeTasks.length} PRIORITIES',
                        style: AppTypography.labelSm.copyWith(
                          color: isDark ? const Color(0xFFE8927C) : AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No active rhythm tasks. Add one with the + dial below.',
                      style: GoogleFonts.dmSans(fontStyle: FontStyle.italic, color: subtextColor),
                    ),
                  )
                else
                  ...tasks.take(4).map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _taskTile(task, isDark),
                      )),
              ],
            ),
          ),
        );
      case 1:
        return const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: SanctuaryTimeline(),
        );
      case 2:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: BentoPod(
            style: PodTextureStyle.paper,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACTIVE KNOWLEDGE SPACE', style: AppTypography.labelSm),
                const SizedBox(height: 6),
                Text(
                  'Computer Networks — Unit 1',
                  style: GoogleFonts.bodoniModa(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                Text('4 PDFs · 2 DOCX · 5 Notes', style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFFE8927C) : AppColors.primary,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: () {
                    SanctuaryHapticEngine.dialDetent();
                    widget.onOpenAiModal('Computer Networks');
                  },
                  icon: Icon(LucideIcons.sparkles, size: 14, color: isDark ? Colors.black : Colors.white),
                  label: const Text('Ask Collection AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _taskTile(TaskItem task, bool isDark) {
    final completed = task.isCompleted;
    return InkWell(
      onTap: () {
        SanctuaryHapticEngine.escapementTick();
        ref.read(tasksProvider.notifier).toggleTask(task.id);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF000000) : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed ? (isDark ? const Color(0xFFE8927C) : AppColors.secondary) : Colors.transparent,
                border: Border.all(
                  color: completed
                      ? (isDark ? const Color(0xFFE8927C) : AppColors.secondary)
                      : (isDark ? Colors.white38 : AppColors.primary),
                  width: 2,
                ),
              ),
              child: completed ? const Icon(Icons.check, size: 14, color: Colors.black) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration: completed ? TextDecoration.lineThrough : null,
                      color: completed
                          ? (isDark ? Colors.white30 : AppColors.onSurface.withValues(alpha: 0.4))
                          : (isDark ? AppColors.darkTextPrimary : AppColors.onSurface),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Time: ${task.timeSlot} · Priority: ${task.priority}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
