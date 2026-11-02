import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/platform/browser_bridge.dart';
import '../../../core/services/ics_export.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entry_editor.dart';
import '../../../core/motion/motion.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accent = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

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
                    Text('WORKSPACE', style: AppTypography.labelSm),
                    const SizedBox(height: 4),
                    Text(
                      'Planner',
                      style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Pressable(
                pressedScale: 0.95,
                hoverLift: 0,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: () => _newEvent(hour: _selectedHour),
                  icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                  label: Text('New Event', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Week navigator
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(tooltip: 'Previous week', icon: const Icon(LucideIcons.chevronLeft, size: 18), onPressed: () => _shiftWeek(-1)),
                    Expanded(
                      child: Text(
                        DateFormat('MMMM y').format(_weekStart).toUpperCase(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: primaryTextColor),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _selectedDay = _today();
                        _selectedHour = null;
                      }),
                      child: const Text('Today'),
                    ),
                    IconButton(tooltip: 'Next week', icon: const Icon(LucideIcons.chevronRight, size: 18), onPressed: () => _shiftWeek(1)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Builder(builder: (context) {
                          final day = _weekStart.add(Duration(days: i));
                          final selected = DateLabels.isSameDay(day, _selectedDay);
                          final isToday = DateLabels.isSameDay(day, DateTime.now());
                          final busy = eventsOn(day).isNotEmpty || tasksOn(day).isNotEmpty || tripsOn(day).isNotEmpty;
                          return Semantics(
                            button: true,
                            selected: selected,
                            label: DateLabels.long(day),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => setState(() {
                                _selectedDay = day;
                                _selectedHour = null;
                              }),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected ? accent : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isToday && !selected ? accent : Colors.transparent),
                                ),
                                child: Column(
                                  children: [
                                    Text(DateFormat('E').format(day).substring(0, 1),
                                        style: GoogleFonts.dmSans(fontSize: 10, color: selected ? Colors.white : subtextColor)),
                                    const SizedBox(height: 2),
                                    Text('${day.day}',
                                        style: GoogleFonts.dmSans(
                                            fontSize: 15, fontWeight: FontWeight.bold, color: selected ? Colors.white : primaryTextColor)),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: busy ? (selected ? Colors.white : accent) : Colors.transparent,
                                      ),
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
          ),
          const SizedBox(height: 16),

          // Hour dial: tap a busy hour to focus it, an empty hour to schedule there.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(16, (i) {
                final hour = i + 6; // 6 AM to 9 PM
                final isSelected = _selectedHour == hour;
                final hasEvent = dayEvents.any((e) => e.startsAt.hour == hour);
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (!hasEvent) {
                        _newEvent(hour: hour);
                        return;
                      }
                      setState(() => _selectedHour = isSelected ? null : hour);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.secondary : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? AppColors.secondary : (isDark ? const Color(0xFF2E2E2E) : AppColors.outlineVariant)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('ha').format(DateTime(2000, 1, 1, hour)).toLowerCase(),
                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : primaryTextColor),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? Colors.white : (hasEvent ? AppColors.secondary : Colors.transparent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          // Agenda for the selected day
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('EEEE, MMMM d').format(_selectedDay).toUpperCase(),
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary),
                ),
              ),
              if (_selectedHour != null)
                TextButton(onPressed: () => setState(() => _selectedHour = null), child: const Text('Show whole day')),
            ],
          ),
          const SizedBox(height: 10),

          for (final trip in dayTrips)
            _AgendaTile(
              icon: LucideIcons.plane,
              title: trip.title,
              subtitle: '${trip.destination} · ${trip.date}',
              color: AppColors.themeTravel,
              onTap: () => openEntryEditor(context, EntryKind.trip, editing: trip),
            ),
          for (final e in visibleEvents)
            _AgendaTile(
              icon: LucideIcons.calendar,
              title: e.title,
              subtitle: '${DateLabels.time(e.startsAt)} – ${DateLabels.time(e.endsAt)}${e.notes.isEmpty ? '' : ' · ${e.notes}'}',
              color: AppColors.themePlanner,
              onTap: () => openEntryEditor(context, EntryKind.event, editing: e),
            ),
          if (_selectedHour == null)
            for (final t in dayTasks)
              _AgendaTile(
                icon: t.completed ? LucideIcons.checkCircle2 : LucideIcons.circle,
                title: t.title,
                subtitle: 'Task · ${DateLabels.time(t.dueAt!)}${t.completed ? ' · done' : ''}',
                color: AppColors.themeTasks,
                struck: t.completed,
                onIconTap: () => ref.read(tasksProvider.notifier).toggleTask(t.id),
                onTap: () => openEntryEditor(context, EntryKind.task, editing: t),
              ),

          if (visibleEvents.isEmpty && (dayTasks.isEmpty || _selectedHour != null) && dayTrips.isEmpty)
            EmptyState(
              icon: LucideIcons.calendarPlus,
              title: 'Nothing planned',
              message: 'Tap an hour above or "New Event" to add something to this day.',
              action: TextButton(onPressed: () => _newEvent(hour: _selectedHour), child: const Text('New event')),
            ),

          const SizedBox(height: 20),
          BentoPod(
            style: PodTextureStyle.paper,
            child: Row(
              children: [
                const Icon(LucideIcons.calendarCheck, size: 20, color: AppColors.secondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ADD TO YOUR CALENDAR',
                          style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: primaryTextColor)),
                      Text('Download events, due tasks and trips as an .ics file.',
                          style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _exportCalendar,
                  icon: Icon(LucideIcons.download, size: 12, color: primaryTextColor),
                  label: Text('Export .ics', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTextColor)),
                ),
              ],
            ),
          ),
        ].revealed(),
      ),
    );
  }
}

class _AgendaTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool struck;
  final VoidCallback onTap;
  final VoidCallback? onIconTap;

  const _AgendaTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.struck = false,
    this.onIconTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final sub = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final tone = isDark ? Color.lerp(color, Colors.white, 0.3)! : color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BentoPod(
        style: PodTextureStyle.paper,
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Row(
          children: [
            Container(width: 4, height: 36, decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            if (onIconTap != null)
              IconButton(
                tooltip: struck ? 'Mark not done' : 'Mark done',
                icon: Icon(icon, size: 18, color: tone),
                onPressed: onIconTap,
              )
            else
              Padding(padding: const EdgeInsets.only(right: 10), child: Icon(icon, size: 18, color: tone)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.bodoniModa(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: struck ? text.withValues(alpha: 0.45) : text,
                      decoration: struck ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.dmSans(fontSize: 11.5, color: sub)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
