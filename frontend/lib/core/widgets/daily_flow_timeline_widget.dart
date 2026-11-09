import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../performance/sanctuary_motion_engine.dart';
import '../state/sanctuary_state.dart';
import 'bento_pod.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Daily Flow Time-Blocking Timeline Widget
/// Visual schedule that integrates top tasks directly with the Watchmaker Focus Dial.
/// Default state is collapsed to maintain an uncluttered home view.
class DailyFlowTimelineWidget extends ConsumerStatefulWidget {
  final Function(TaskItem task)? onStartFocusForTask;
  final VoidCallback? onOpenFocusDial;

  const DailyFlowTimelineWidget({
    super.key,
    this.onStartFocusForTask,
    this.onOpenFocusDial,
  });

  @override
  ConsumerState<DailyFlowTimelineWidget> createState() => _DailyFlowTimelineWidgetState();
}

class _DailyFlowTimelineWidgetState extends ConsumerState<DailyFlowTimelineWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? const Color(0xFFFAF7F0) : const Color(0xFF1C1917);
    final subtextColor = isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C);
    const terracotta = Color(0xFFD9725B);
    const gold = Color(0xFFD9725B);

    final tasks = ref.watch(tasksProvider);
    final openTasks = tasks.where((t) => !t.completed).toList();

    final now = DateTime.now();
    final currentHour = now.hour;

    // Time slots for active day
    final slots = [
      {'time': '08:00', 'hour': 8, 'label': 'Morning Focus & Planning'},
      {'time': '09:30', 'hour': 9, 'label': 'Morning Briefing & Focus Kickoff'},
      {'time': '10:00', 'hour': 10, 'label': 'Deep Work & Priority #1'},
      {'time': '12:00', 'hour': 12, 'label': 'Midday Reset & Lunch'},
      {'time': '14:00', 'hour': 14, 'label': 'Execution & Collaboration'},
      {'time': '16:00', 'hour': 16, 'label': 'Deep Work & Priority #2'},
      {'time': '18:00', 'hour': 18, 'label': 'Daily Review & Wrap-Up'},
      {'time': '20:00', 'hour': 20, 'label': 'Evening Rest & Unwind'},
      {'time': '21:30', 'hour': 21, 'label': 'Evening Reflection & Recap'},
    ];

    // Identify current slot
    final currentSlot = slots.firstWhere(
      (s) {
        final h = s['hour'] as int;
        return currentHour >= h && currentHour < h + 2;
      },
      orElse: () => slots.first,
    );

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
                      decoration: edBox(
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
                          fontSize: 11,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onOpenFocusDial != null) ...[
                    InkWell(
                      onTap: () {
                        SanctuaryHapticEngine.selection();
                        widget.onOpenFocusDial!();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: edBox(
                          color: gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: gold.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.timer, size: 12, color: gold),
                            const SizedBox(width: 4),
                            Text(
                              'FOCUS DIAL',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Expand / Collapse Toggle
                  InkWell(
                    onTap: () {
                      SanctuaryHapticEngine.selection();
                      setState(() => _isExpanded = !_isExpanded);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: edBox(
                        color: terracotta.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: terracotta.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                            size: 13,
                            color: terracotta,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isExpanded ? 'Collapse' : 'Expand',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: terracotta,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Collapsed 1-Line Teaser
          if (!_isExpanded)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: edBox(
                    color: gold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: gold.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    currentSlot['time'] as String,
                    style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: FontWeight.bold, color: gold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Now: ${currentSlot['label']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                  ),
                ),
                if (widget.onStartFocusForTask != null && openTasks.isNotEmpty)
                  InkWell(
                    onTap: () {
                      SanctuaryHapticEngine.dialDetent();
                      widget.onStartFocusForTask!(openTasks.first);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: edBox(
                        color: terracotta,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '⚡ FOCUS',
                        style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            )
          else ...[
            // Full Vertical Time Slots when expanded
            ...slots.map((slot) {
              final hour = slot['hour'] as int;
              final isCurrentSlot = currentHour >= hour && currentHour < hour + 2;
              final isPast = currentHour >= hour + 2;

              final taskIndex = (hour ~/ 2) % (openTasks.isNotEmpty ? openTasks.length : 1);
              final assignedTask = openTasks.isNotEmpty ? openTasks[taskIndex] : null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: edBox(
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: edBox(
                          color: isCurrentSlot ? gold : (isDark ? Colors.white10 : Colors.black12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          slot['time'] as String,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCurrentSlot ? Colors.black : subtextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                                    decoration: edBox(
                                      color: gold,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                                Expanded(
                                  child: Text(
                                    slot['label'] as String,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
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
                                  fontSize: 11,
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
                      if (isCurrentSlot && widget.onStartFocusForTask != null && assignedTask != null) ...[
                        InkWell(
                          onTap: () {
                            SanctuaryHapticEngine.dialDetent();
                            widget.onStartFocusForTask!(assignedTask);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: edBox(
                              color: terracotta,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '⚡ FOCUS',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ] else if (isPast) ...[
                        const Icon(LucideIcons.check, size: 14, color: gold),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
