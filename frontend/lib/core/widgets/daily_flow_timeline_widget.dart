import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../motion/motion.dart';
import '../performance/sanctuary_motion_engine.dart';
import '../state/sanctuary_state.dart';
import 'bento_pod.dart';
import 'card_kit.dart';

/// The day as a set of time blocks. Collapsed, it names the block you are in now; open,
/// it lays the day down a thin rail, with the current block marked by a breathing dot.
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

  static const _slots = [
    ('08:00', 8, 'Plan the day'),
    ('09:30', 9, 'Morning briefing'),
    ('10:00', 10, 'Deep work: first priority'),
    ('12:00', 12, 'Midday reset and lunch'),
    ('14:00', 14, 'Meetings and shared work'),
    ('16:00', 16, 'Deep work: second priority'),
    ('18:00', 18, 'Review and wrap up'),
    ('20:00', 20, 'Rest'),
    ('21:30', 21, 'Evening reflection'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = CardInk.of(context);
    final openTasks = ref.watch(tasksProvider).where((t) => !t.completed).toList();
    final hourNow = DateTime.now().hour;
    bool isNow(int h) => hourNow >= h && hourNow < h + 2;
    final current = _slots.firstWhere((s) => isNow(s.$2), orElse: () => _slots.first);

    return BentoPod(
      style: PodTextureStyle.glass,
      padding: const EdgeInsets.fromLTRB(22, 18, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: CardLabel('Your day', trailing: 'Now · ${current.$1}')),
              Tooltip(
                message: _isExpanded ? 'Collapse' : 'Expand',
                child: Pressable(
                  pressedScale: 0.85,
                  hoverLift: 0,
                  onTap: () {
                    SanctuaryHapticEngine.selection();
                    setState(() => _isExpanded = !_isExpanded);
                  },
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 420),
                        curve: Motion.settle,
                        child: Icon(LucideIcons.chevronDown, size: 18, color: c.muted),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: Motion.standard,
            child: Text(current.$3, key: ValueKey(current.$3), style: c.title.copyWith(fontSize: 21)),
          ),
          if (widget.onOpenFocusDial != null || (widget.onStartFocusForTask != null && openTasks.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Wrap(
                spacing: 18,
                children: [
                  if (widget.onStartFocusForTask != null && openTasks.isNotEmpty)
                    CardLink(
                      label: 'Focus on ${openTasks.first.title}',
                      onTap: () {
                        SanctuaryHapticEngine.dialDetent();
                        widget.onStartFocusForTask!(openTasks.first);
                      },
                    ),
                  if (widget.onOpenFocusDial != null)
                    CardLink(
                      label: 'Focus dial',
                      onTap: () {
                        SanctuaryHapticEngine.selection();
                        widget.onOpenFocusDial!();
                      },
                    ),
                ],
              ),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 420),
            curve: Motion.silk,
            alignment: Alignment.topCenter,
            child: !_isExpanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 14, right: 8),
                    child: Column(
                      children: [
                        for (var i = 0; i < _slots.length; i++)
                          _SlotRow(
                            time: _slots[i].$1,
                            label: _slots[i].$3,
                            now: isNow(_slots[i].$2),
                            past: hourNow >= _slots[i].$2 + 2,
                            last: i == _slots.length - 1,
                            task: openTasks.isEmpty || !(isNow(_slots[i].$2) || _slots[i].$2 == 10 || _slots[i].$2 == 16)
                                ? null
                                : openTasks[(_slots[i].$2 ~/ 2) % openTasks.length],
                            onFocus: widget.onStartFocusForTask,
                          ),
                      ].revealed(style: RevealStyle.slideIn, distance: 12),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final String time;
  final String label;
  final bool now;
  final bool past;
  final bool last;
  final TaskItem? task;
  final Function(TaskItem task)? onFocus;

  const _SlotRow({required this.time, required this.label, required this.now, required this.past, required this.last, this.task, this.onFocus});

  @override
  Widget build(BuildContext context) {
    final c = CardInk.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                time,
                style: c.meta.copyWith(
                  fontSize: 12.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: now ? c.ink : c.muted.withValues(alpha: past ? 0.6 : 1),
                  fontWeight: now ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ),
          // The rail: a dot per block joined by a hairline.
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const SizedBox(height: 5),
                now ? _BreathingDot(color: c.mark) : Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: past ? c.muted.withValues(alpha: 0.5) : c.hairline, border: Border.all(color: c.muted.withValues(alpha: 0.5)))),
                if (!last) Expanded(child: Container(width: 1, color: c.hairline)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: c.body.copyWith(
                      fontSize: 14,
                      fontWeight: now ? FontWeight.w700 : FontWeight.w500,
                      color: past ? c.muted : c.ink,
                    ),
                  ),
                  if (task != null) ...[
                    const SizedBox(height: 2),
                    Text(task!.title, style: c.meta.copyWith(fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  if (now && task != null && onFocus != null)
                    CardLink(label: 'Focus now', onTap: () => onFocus!(task!)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "you are here" mark: an oxblood dot with a soft ring that swells and fades.
class _BreathingDot extends StatefulWidget {
  final Color color;

  const _BreathingDot({required this.color});

  @override
  State<_BreathingDot> createState() => _BreathingDotState();
}

class _BreathingDotState extends State<_BreathingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Motion.reduced(context) && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 9,
      height: 9,
      child: OverflowBox(
        maxWidth: 24,
        maxHeight: 24,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = Curves.easeOut.transform(_c.value);
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 9 + 13 * t,
                  height: 9 + 13 * t,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withValues(alpha: 0.35 * (1 - t))),
                ),
                Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color)),
              ],
            );
          },
        ),
      ),
    );
  }
}
