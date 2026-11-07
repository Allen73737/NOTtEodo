import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../performance/sanctuary_motion_engine.dart';
import '../state/sanctuary_state.dart';
import 'bento_pod.dart';

/// Daily Flow Time-Blocking Timeline Widget
/// 24-Hour visual schedule that integrates top tasks directly with the Watchmaker Focus Dial.
class DailyFlowTimelineWidget extends ConsumerWidget {
  final Function(TaskItem task)? onStartFocusForTask;
  final VoidCallback? onOpenFocusDial;

  const DailyFlowTimelineWidget({
    super.key,
    this.onStartFocusForTask,
    this.onOpenFocusDial,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? const Color(0xFFFAF7F0) : const Color(0xFF1C1917);
    final subtextColor = isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C);
    const terracotta = Color(0xFFD9725B);
    const gold = Color(0xFFD4AF37);
    const sage = Color(0xFF8FA878);

    final tasks = ref.watch(tasksProvider);
    final openTasks = tasks.where((t) => !t.completed).toList();

    final now = DateTime.now();
    final currentHour = now.hour;

    // Time slots for active day
    final slots = [
      {'time': '08:00', 'hour': 8, 'label': 'Morning Focus & Planning'},
      {'time': '10:00', 'hour': 10, 'label': 'Deep Work & Priority #1'},
      {'time': '12:00', 'hour': 12, 'label': 'Midday Reset & Lunch'},
      {'time': '14:00', 'hour': 14, 'label': 'Execution & Collaboration'},
      {'time': '16:00', 'hour': 16, 'label': 'Deep Work & Priority #2'},
      {'time': '18:00', 'hour': 18, 'label': 'Daily Review & Wrap-Up'},
      {'time': '20:00', 'hour': 20, 'label': 'Evening Rest & Reflection'},
    ];

    return BentoPod(
      style: PodTextureStyle.glass,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.clock, size: 14, color: gold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'DAILY FLOW TIME-BLOCKING',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (onOpenFocusDial != null)
                InkWell(
                  onTap: () {
                    SanctuaryHapticEngine.selection();
                    onOpenFocusDial!();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: gold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.watch, size: 11, color: gold),
                        const SizedBox(width: 4),
                        Text(
                          'FOCUS DIAL',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Vertical Time Slots
          ...slots.map((slot) {
            final hour = slot['hour'] as int;
            final isCurrentSlot = currentHour >= hour && currentHour < hour + 2;
            final isPast = currentHour >= hour + 2;

            // Associate with a task if available
            final taskIndex = (hour ~/ 2) % (openTasks.isNotEmpty ? openTasks.length : 1);
            final assignedTask = openTasks.isNotEmpty ? openTasks[taskIndex] : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isCurrentSlot
                      ? gold.withValues(alpha: isDark ? 0.12 : 0.08)
                      : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCurrentSlot
                        ? gold.withValues(alpha: 0.6)
                        : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
                    width: isCurrentSlot ? 1.4 : 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    // Time Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCurrentSlot ? gold : (isDark ? Colors.white10 : Colors.black12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        slot['time'] as String,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isCurrentSlot ? Colors.black : subtextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Block Label & Assigned Task
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isCurrentSlot) ...[
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: const BoxDecoration(
                                    color: gold,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  slot['label'] as String,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: isCurrentSlot ? FontWeight.bold : FontWeight.w600,
                                    color: isCurrentSlot ? gold : primaryText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (assignedTask != null && (isCurrentSlot || hour == 10 || hour == 16)) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Task: ${assignedTask.title}',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color: isCurrentSlot ? terracotta : subtextColor,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Quick Focus Trigger
                    if (isCurrentSlot && onStartFocusForTask != null && assignedTask != null) ...[
                      InkWell(
                        onTap: () {
                          SanctuaryHapticEngine.dialDetent();
                          onStartFocusForTask!(assignedTask);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: terracotta,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '⚡ FOCUS',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ] else if (isPast) ...[
                      const Icon(LucideIcons.check, size: 14, color: sage),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
