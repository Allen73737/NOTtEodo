import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform/cross_file_reader.dart';
import '../state/sanctuary_state.dart';

/// Result summary of an iCalendar (.ics) import operation.
class IcsImportResult {
  final List<PlannerEvent> events;
  final List<TaskItem> tasks;
  final int skippedCount;
  final String? errorMessage;

  const IcsImportResult({
    required this.events,
    required this.tasks,
    this.skippedCount = 0,
    this.errorMessage,
  });

  int get totalImported => events.length + tasks.length;
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

/// Parses iCalendar (.ics) files and imports events/tasks into NOTtEodo.
/// Complies with RFC 5545 (line unfolding, parameter stripping, UTC/local timestamps).
class IcsImport {
  IcsImport._();

  /// Unfolds lines wrapped according to RFC 5545 (lines beginning with whitespace).
  static String _unfold(String ics) {
    return ics.replaceAll(RegExp(r'\r?\n[ \t]'), '');
  }

  /// Unescapes RFC 5545 escaped characters.
  static String _unescape(String s) {
    return s
        .replaceAll('\\n', '\n')
        .replaceAll('\\N', '\n')
        .replaceAll('\\,', ',')
        .replaceAll('\\;', ';')
        .replaceAll('\\\\', '\\');
  }

  /// Parses an iCalendar date/time string (e.g. 20261116T143000Z or 20261116).
  static DateTime? _parseIcsDate(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return null;

    try {
      // Form 1: UTC datetime (e.g. 20261116T143000Z)
      if (clean.contains('T') && clean.endsWith('Z')) {
        final digits = clean.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length >= 14) {
          final year = int.parse(digits.substring(0, 4));
          final month = int.parse(digits.substring(4, 6));
          final day = int.parse(digits.substring(6, 8));
          final hour = int.parse(digits.substring(8, 10));
          final minute = int.parse(digits.substring(10, 12));
          final second = int.parse(digits.substring(12, 14));
          return DateTime.utc(year, month, day, hour, minute, second).toLocal();
        }
      }

      // Form 2: Local datetime (e.g. 20261116T143000)
      if (clean.contains('T')) {
        final digits = clean.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length >= 12) {
          final year = int.parse(digits.substring(0, 4));
          final month = int.parse(digits.substring(4, 6));
          final day = int.parse(digits.substring(6, 8));
          final hour = int.parse(digits.substring(8, 10));
          final minute = int.parse(digits.substring(10, 12));
          final second = digits.length >= 14 ? int.parse(digits.substring(12, 14)) : 0;
          return DateTime(year, month, day, hour, minute, second);
        }
      }

      // Form 3: Date only (e.g. 20261116)
      final digits = clean.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 8) {
        final year = int.parse(digits.substring(0, 4));
        final month = int.parse(digits.substring(4, 6));
        final day = int.parse(digits.substring(6, 8));
        return DateTime(year, month, day, 9, 0); // default 9:00 AM for all-day events
      }
    } catch (e) {
      debugPrint('[IcsImport] Could not parse date: "$raw" ($e)');
    }

    return null;
  }

  /// Parses a raw iCalendar string into [IcsImportResult].
  static IcsImportResult parse(String icsContent) {
    if (icsContent.trim().isEmpty) {
      return const IcsImportResult(events: [], tasks: [], errorMessage: 'Calendar file is empty.');
    }

    final unfolded = _unfold(icsContent);
    final lines = unfolded.split(RegExp(r'\r?\n'));

    final importedEvents = <PlannerEvent>[];
    final importedTasks = <TaskItem>[];
    int skipped = 0;

    Map<String, String>? currentProps;
    String? currentComponent; // VEVENT or VTODO

    void commitCurrent() {
      final props = currentProps;
      if (props == null || currentComponent == null) return;

      final summary = _unescape(props['SUMMARY'] ?? 'Imported Event').trim();
      final description = _unescape(props['DESCRIPTION'] ?? '').trim();
      final location = _unescape(props['LOCATION'] ?? '').trim();

      final fullNotes = [
        if (description.isNotEmpty) description,
        if (location.isNotEmpty) 'Location: $location',
      ].join('\n\n');

      final dtStartRaw = props['DTSTART'];
      final dtEndRaw = props['DTEND'];

      final dtStart = dtStartRaw != null ? _parseIcsDate(dtStartRaw) : null;
      final dtEnd = dtEndRaw != null ? _parseIcsDate(dtEndRaw) : null;

      if (dtStart == null) {
        skipped++;
        return;
      }

      // Check whether this event represents a task (VTODO or SUMMARY starts with "Task: ")
      final isTask = currentComponent == 'VTODO' || summary.toLowerCase().startsWith('task:');

      if (isTask) {
        final taskTitle = summary.replaceFirst(RegExp(r'^task:\s*', caseSensitive: false), '').trim();
        final hour = dtStart.hour;
        final timeOfDay = hour < 12 ? 'Morning' : (hour < 17 ? 'Afternoon' : 'Evening');
        importedTasks.add(TaskItem(
          id: newId(),
          title: taskTitle.isNotEmpty ? taskTitle : 'Imported Task',
          dueAt: dtStart,
          notes: fullNotes,
          space: 'General Space',
          priority: 'Medium Priority',
          timeOfDay: timeOfDay,
        ));
      } else {
        var durationMinutes = 60;
        if (dtEnd != null && dtEnd.isAfter(dtStart)) {
          durationMinutes = dtEnd.difference(dtStart).inMinutes;
          if (durationMinutes <= 0) durationMinutes = 60;
        }

        importedEvents.add(PlannerEvent(
          id: newId(),
          title: summary,
          startsAt: dtStart,
          durationMinutes: durationMinutes,
          notes: fullNotes,
        ));
      }
    }

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed == 'BEGIN:VEVENT' || trimmed == 'BEGIN:VTODO') {
        commitCurrent();
        currentComponent = trimmed.substring(6);
        currentProps = {};
        continue;
      }

      if (trimmed == 'END:VEVENT' || trimmed == 'END:VTODO') {
        commitCurrent();
        currentComponent = null;
        currentProps = null;
        continue;
      }

      final props = currentProps;
      if (props != null) {
        final colonIdx = trimmed.indexOf(':');
        if (colonIdx > 0) {
          var key = trimmed.substring(0, colonIdx);
          final value = trimmed.substring(colonIdx + 1);

          // Strip parameter attributes (e.g. DTSTART;VALUE=DATE -> DTSTART)
          final semiIdx = key.indexOf(';');
          if (semiIdx > 0) {
            key = key.substring(0, semiIdx);
          }

          props[key.toUpperCase()] = value;
        }
      }
    }

    // Commit any trailing item
    commitCurrent();

    return IcsImportResult(
      events: importedEvents,
      tasks: importedTasks,
      skippedCount: skipped,
    );
  }

  /// Interactive picker: lets user choose an `.ics` file, parses it, and commits to Riverpod state.
  static Future<IcsImportResult?> pickAndImport(WidgetRef ref) async {
    try {
      final icsText = await pickAndReadTextFile(allowedExtensions: ['ics', 'ical']);
      if (icsText == null) return null;

      if (icsText.trim().isEmpty) {
        return const IcsImportResult(events: [], tasks: [], errorMessage: 'Could not read calendar file contents.');
      }

      final parsed = parse(icsText);

      // Commit to Riverpod state
      for (final ev in parsed.events) {
        ref.read(eventsProvider.notifier).addEvent(
          title: ev.title,
          startsAt: ev.startsAt,
          durationMinutes: ev.durationMinutes,
          notes: ev.notes,
        );
      }

      for (final t in parsed.tasks) {
        ref.read(tasksProvider.notifier).addTask(
          title: t.title,
          dueAt: t.dueAt,
          notes: t.notes,
          priority: t.priority,
          space: t.space,
        );
      }

      return parsed;
    } catch (e) {
      return IcsImportResult(events: [], tasks: [], errorMessage: 'Import failed: $e');
    }
  }
}
