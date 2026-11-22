import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/platform/browser_bridge.dart';
import '../../../core/services/calendar_reminder_service.dart';
import '../../../core/services/ics_export.dart';
import '../../../core/services/ics_import.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/app_toast_engine.dart';
import '../../../core/widgets/sanctuary_clock_picker.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/card_kit.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entry_editor.dart';
import '../../../core/motion/motion.dart';
import '../../../core/tour/spotlight_tour.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  late DateTime _selectedDay = _today();
  int? _selectedHour;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime get _weekStart => _selectedDay.subtract(Duration(days: _selectedDay.weekday - 1));

  void _shiftWeek(int weeks) => setState(() {
        _selectedDay = _selectedDay.add(Duration(days: 7 * weeks));
        _selectedHour = null;
      });

  void _newEvent({int? hour}) {
    final now = DateTime.now();
    final h = hour ?? (DateLabels.isSameDay(_selectedDay, now) ? (now.hour + 1).clamp(0, 23) : 10);
    openEntryEditor(context, EntryKind.event,
        initialDate: DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, h));
  }

  Future<void> _exportCalendar() async {
    final ics = IcsExport.build(
      events: ref.read(eventsProvider),
      tasks: ref.read(tasksProvider),
      trips: ref.read(travelProvider),
    );
    final ok = await downloadTextFile('notteodo-calendar.ics', ics, mimeType: 'text/calendar');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(ok
          ? 'Calendar file saved. Import it in Google Calendar, Apple Calendar or Outlook.'
          : 'Calendar export is available in the web app.'),
    ));
  }

  Future<void> _importCalendar() async {
    final result = await IcsImport.pickAndImport(ref);
    if (!mounted || result == null) return;
    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(result.errorMessage ?? 'Calendar import failed.'),
      ));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text('Imported ${result.events.length} events and ${result.tasks.length} tasks from your calendar file.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = CardInk.of(context);

    final events = ref.watch(eventsProvider);
    final tasks = ref.watch(tasksProvider);
    final trips = ref.watch(travelProvider);

    List<PlannerEvent> eventsOn(DateTime d) =>
        events.where((e) => DateLabels.isSameDay(e.startsAt, d)).toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    List<TaskItem> tasksOn(DateTime d) => tasks.where((t) => t.isDueOn(d)).toList();
    List<TravelTrip> tripsOn(DateTime d) => trips.where((t) {
          if (t.startDate == null) return false;
          final end = t.endDate ?? t.startDate!;
          return !d.isBefore(DateTime(t.startDate!.year, t.startDate!.month, t.startDate!.day)) &&
              !d.isAfter(DateTime(end.year, end.month, end.day));
        }).toList();

    final dayEvents = eventsOn(_selectedDay);
    final dayTasks = tasksOn(_selectedDay);
    final dayTrips = tripsOn(_selectedDay);
    final visibleEvents =
        _selectedHour == null ? dayEvents : dayEvents.where((e) => e.startsAt.hour == _selectedHour).toList();
    final count = dayEvents.length + dayTasks.length + dayTrips.length;
    final isToday = DateLabels.isSameDay(_selectedDay, DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title, a one-line summary of the chosen day, and one action.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Planner', style: GoogleFonts.bodoniModa(fontSize: 36, fontWeight: FontWeight.bold, color: c.ink, height: 1.05)),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: Motion.standard,
                      child: Text(
                        count == 0
                            ? 'Nothing planned ${isToday ? 'today' : 'on ${DateFormat('EEE d MMM').format(_selectedDay)}'}'
                            : '$count ${count == 1 ? 'thing' : 'things'} ${isToday ? 'today' : 'on ${DateFormat('EEE d MMM').format(_selectedDay)}'}',
                        key: ValueKey('$count$_selectedDay'),
                        style: c.meta.copyWith(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TourTarget(id: 'page.primary', child: CardAction(label: 'New event', icon: LucideIcons.plus, onTap: () => _newEvent(hour: _selectedHour))),
            ],
          ),
          const SizedBox(height: 20),

          // The week: month name, arrows, and seven days. The chosen day is a filled
          // oxblood disc that glides between days; busy days carry a dot.
          TourTarget(id: 'planner.week', child: BentoPod(
            style: PodTextureStyle.glass,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    _RoundIcon(tooltip: 'Previous week', icon: LucideIcons.chevronLeft, onTap: () => _shiftWeek(-1)),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: Motion.standard,
                        child: Text(
                          DateFormat('MMMM y').format(_weekStart),
                          key: ValueKey(DateFormat('MMMM y').format(_weekStart)),
                          textAlign: TextAlign.center,
                          style: c.title.copyWith(fontSize: 18),
                        ),
                      ),
                    ),
                    if (!isToday)
                      CardLink(
                        label: 'Today',
                        onTap: () => setState(() {
                          _selectedDay = _today();
                          _selectedHour = null;
                        }),
                      ),
                    _RoundIcon(tooltip: 'Next week', icon: LucideIcons.chevronRight, onTap: () => _shiftWeek(1)),
                  ],
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  switchInCurve: Motion.silk,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(position: Tween(begin: const Offset(0.05, 0), end: Offset.zero).animate(a), child: child),
                  ),
                  child: Row(
                    key: ValueKey(_weekStart),
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Builder(builder: (context) {
                            final day = _weekStart.add(Duration(days: i));
                            final selected = DateLabels.isSameDay(day, _selectedDay);
                            final today = DateLabels.isSameDay(day, DateTime.now());
                            final busy = eventsOn(day).isNotEmpty || tasksOn(day).isNotEmpty || tripsOn(day).isNotEmpty;
                            return Semantics(
                              button: true,
                              selected: selected,
                              label: DateLabels.long(day),
                              excludeSemantics: true,
                              child: Pressable(
                                pressedScale: 0.9,
                                hoverLift: 0,
                                onTap: () => setState(() {
                                  _selectedDay = day;
                                  _selectedHour = null;
                                }),
                                child: Column(
                                  children: [
                                    Text(DateFormat('E').format(day).substring(0, 1), style: c.meta.copyWith(fontSize: 12)),
                                    const SizedBox(height: 6),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 380),
                                      curve: Motion.settle,
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: selected ? c.fill : Colors.transparent,
                                        border: today && !selected ? Border.all(color: c.mark, width: 1.4) : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${day.day}',
                                        style: c.body.copyWith(
                                          fontSize: 15,
                                          fontWeight: selected || today ? FontWeight.w700 : FontWeight.w500,
                                          color: selected ? c.onFill : c.ink,
                                          fontFeatures: const [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    AnimatedScale(
                                      duration: const Duration(milliseconds: 420),
                                      curve: Motion.settle,
                                      scale: busy ? 1 : 0,
                                      child: Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: c.mark)),
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
          )),
          const SizedBox(height: 16),

          // Hours: tap a busy hour to show only it, an empty hour to schedule there.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(16, (i) {
                final hour = i + 6; // 6 am to 9 pm
                final isSelected = _selectedHour == hour;
                final hasEvent = dayEvents.any((e) => e.startsAt.hour == hour);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Tooltip(
                    message: hasEvent ? 'Show this hour' : 'Add an event at this hour',
                    child: Pressable(
                      pressedScale: 0.9,
                      hoverLift: 0,
                      onTap: () {
                        if (!hasEvent) {
                          _newEvent(hour: hour);
                          return;
                        }
                        setState(() => _selectedHour = isSelected ? null : hour);
                      },
                      child: AnimatedContainer(
                        duration: Motion.standard,
                        curve: Motion.silk,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected ? c.fill : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('ha').format(DateTime(2000, 1, 1, hour)).toLowerCase(),
                              style: c.meta.copyWith(
                                fontSize: 13,
                                fontWeight: hasEvent || isSelected ? FontWeight.w700 : FontWeight.w400,
                                color: isSelected ? c.onFill : (hasEvent ? c.ink : c.muted),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasEvent ? (isSelected ? c.onFill : c.mark) : Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 18),

          // The chosen day's agenda.
          Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: Motion.standard,
                  child: Text(
                    DateFormat('EEEE d MMMM').format(_selectedDay),
                    key: ValueKey(_selectedDay),
                    style: c.title.copyWith(fontSize: 21),
                  ),
                ),
              ),
              if (_selectedHour != null) CardLink(label: 'Whole day', onTap: () => setState(() => _selectedHour = null)),
            ],
          ),
          const SizedBox(height: 10),

          for (final trip in dayTrips)
            _AgendaTile(
              key: ValueKey('trip-${trip.id}'),
              time: 'Trip',
              icon: LucideIcons.plane,
              title: trip.title,
              subtitle: '${trip.destination} · ${trip.date}',
              onTap: () => openEntryEditor(context, EntryKind.trip, editing: trip),
            ),
          for (final e in visibleEvents)
            _AgendaTile(
              key: ValueKey('event-${e.id}'),
              time: DateLabels.time(e.startsAt),
              icon: LucideIcons.calendar,
              title: e.title,
              subtitle: 'Until ${DateLabels.time(e.endsAt)}${e.notes.isEmpty ? '' : ' · ${e.notes}'}',
              startTime: e.startsAt,
              endTime: e.endsAt,
              itemId: e.id,
              onTap: () => openEntryEditor(context, EntryKind.event, editing: e),
            ),
          if (_selectedHour == null)
            for (final t in dayTasks)
              _AgendaTile(
                key: ValueKey('task-${t.id}'),
                time: DateLabels.time(t.dueAt!),
                icon: t.completed ? LucideIcons.checkCircle2 : LucideIcons.circle,
                title: t.title,
                subtitle: t.completed ? 'Task · done' : 'Task',
                struck: t.completed,
                startTime: t.dueAt,
                endTime: t.dueAt?.add(const Duration(hours: 1)),
                itemId: t.id,
                onIconTap: () => ref.read(tasksProvider.notifier).toggleTask(t.id),
                onTap: () => openEntryEditor(context, EntryKind.task, editing: t),
              ),

          if (visibleEvents.isEmpty && (dayTasks.isEmpty || _selectedHour != null) && dayTrips.isEmpty)
            EmptyState(
              icon: LucideIcons.calendarPlus,
              title: 'Nothing planned',
              message: 'Tap an hour above or "New event" to add something to this day.',
              action: TextButton(onPressed: () => _newEvent(hour: _selectedHour), child: const Text('New event')),
            ),

          const SizedBox(height: 20),
          BentoPod(
            style: PodTextureStyle.paper,
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardLabel('Calendar files'),
                const SizedBox(height: 4),
                Text('Bring events in from Google, Apple or Outlook calendars, or take yours with you, as .ics files.', style: c.body.copyWith(fontSize: 14, fontWeight: FontWeight.w400)),
                const SizedBox(height: 4),
                TourTarget(id: 'planner.files', child: Wrap(
                  spacing: 20,
                  children: [
                    CardLink(label: 'Import', onTap: _importCalendar),
                    CardLink(label: 'Export', onTap: _exportCalendar),
                  ],
                )),
              ],
            ),
          ),
        ].revealed(),
      ),
    );
  }
}

/// A quiet round icon button that sinks when pressed.
class _RoundIcon extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIcon({required this.tooltip, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Pressable(
          pressedScale: 0.85,
          hoverLift: 0,
          onTap: onTap,
          child: SizedBox(width: 40, height: 40, child: Center(child: Icon(icon, size: 18, color: CardInk.of(context).muted))),
        ),
      );
}

/// One item on the day's agenda: time on the left, title and detail, and a menu for
/// reminders and Google Calendar.
class _AgendaTile extends StatelessWidget {
  final String time;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool struck;
  final VoidCallback onTap;
  final VoidCallback? onIconTap;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? itemId;

  const _AgendaTile({
    super.key,
    required this.time,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.struck = false,
    this.onIconTap,
    this.startTime,
    this.endTime,
    this.itemId,
  });

  Future<void> _remind(BuildContext context) async {
    SanctuaryHapticEngine.dialDetent();
    final initial = startTime != null ? TimeOfDay.fromDateTime(startTime!) : const TimeOfDay(hour: 9, minute: 30);
    final picked = await showSanctuaryClockPicker(context: context, initialTime: initial, helpText: 'Set a reminder');
    if (picked == null || !context.mounted) return;
    final now = DateTime.now();
    final baseDate = startTime ?? now;
    var sched = DateTime(baseDate.year, baseDate.month, baseDate.day, picked.hour, picked.minute);
    if (sched.isBefore(now)) sched = sched.add(const Duration(days: 1));
    await CalendarReminderService().scheduleDeviceReminder(
      id: itemId ?? 'planner_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      scheduledTime: sched,
      body: subtitle,
    );
    if (context.mounted) {
      AppToastEngine().showToast(
        context,
        title: 'Reminder set',
        message: '${picked.format(context)} ${sched.day == now.day ? 'today' : 'tomorrow'}.',
        type: ToastType.success,
      );
    }
  }

  Future<void> _addToGoogle(BuildContext context) async {
    SanctuaryHapticEngine.dialDetent();
    final effectiveStart = startTime ?? DateTime.now();
    final ok = await CalendarReminderService().addToGoogleCalendar(
      title: title,
      startTime: effectiveStart,
      endTime: endTime ?? effectiveStart.add(const Duration(hours: 1)),
      description: subtitle,
    );
    if (context.mounted) {
      AppToastEngine().showToast(
        context,
        title: ok ? 'Google Calendar' : 'Google Calendar did not open',
        message: ok ? 'Opening Google Calendar with "$title" filled in.' : 'Check that a browser is available and try again.',
        type: ok ? ToastType.success : ToastType.alert,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = CardInk.of(context);
    final isDark = c.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BentoPod(
        style: PodTextureStyle.paper,
        padding: const EdgeInsets.fromLTRB(18, 14, 4, 14),
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 58,
              child: Text(time, style: c.meta.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: c.ink, fontFeatures: const [FontFeature.tabularFigures()])),
            ),
            if (onIconTap != null)
              Tooltip(
                message: struck ? 'Mark not done' : 'Mark done',
                child: Pressable(
                  pressedScale: 0.8,
                  hoverLift: 0,
                  onTap: onIconTap,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: AnimatedSwitcher(
                      duration: Motion.standard,
                      transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                      child: Icon(icon, key: ValueKey(struck), size: 19, color: struck ? c.mark : c.muted),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: AnimatedOpacity(
                duration: Motion.standard,
                opacity: struck ? 0.45 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: c.body.copyWith(fontSize: 15, decoration: struck ? TextDecoration.lineThrough : null, decorationColor: c.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: c.meta.copyWith(fontSize: 12.5)),
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
              onSelected: (v) => v == 'remind' ? _remind(context) : _addToGoogle(context),
              itemBuilder: (_) => [
                for (final (value, label, ic) in [
                  ('remind', 'Set a reminder', LucideIcons.bellRing),
                  ('google', 'Add to Google Calendar', LucideIcons.calendarPlus),
                ])
                  PopupMenuItem(
                    value: value,
                    child: Row(
                      children: [
                        Icon(ic, size: 16, color: c.muted),
                        const SizedBox(width: 12),
                        Text(label, style: c.body.copyWith(fontSize: 14)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
