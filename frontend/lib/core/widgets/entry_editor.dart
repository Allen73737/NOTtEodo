import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'markdown_accessory_toolbar.dart';
import '../services/cloudinary_media_service.dart';
import '../services/sanctuary_supabase_service.dart';
import '../ai/ai_widgets.dart';
import '../ai/smart_classifier.dart';
import '../ai/wardrobe_classifier.dart';
import '../services/device_media_service.dart';
import '../services/ai_copilot_service.dart';
import '../services/calendar_reminder_service.dart';
import '../performance/sanctuary_motion_engine.dart';
import 'app_toast_engine.dart';
import 'workflow_evolution_dialog.dart';
import 'pressure_test_dialog.dart';
import 'omni_capture_modal.dart';
import '../../features/notes/presentation/notes_rag_modal.dart';
import '../services/document_ingestion_service.dart';
import 'package:flutter/material.dart';
import 'any_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../motion/motion.dart';
import '../services/nlp_date_parser.dart';
import '../state/app_settings.dart';
import '../state/sanctuary_state.dart';
import '../utils/date_labels.dart';
import 'stitch_logo_widget.dart';
import 'audio_cassette_player.dart';
import 'sanctuary_clock_picker.dart';
import 'rich_note_text.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';
import 'package:notteodo/core/editorial/editorial_kit.dart' show copyToClipboard;

/// Every kind of item the editor can create or change.
enum EntryKind { note, task, event, outfit, expense, trip, memoir, pin, habit, shopping }

extension EntryKindInfo on EntryKind {
  String get label => switch (this) {
        EntryKind.note => 'Note',
        EntryKind.task => 'Task',
        EntryKind.event => 'Event',
        EntryKind.outfit => 'Outfit',
        EntryKind.expense => 'Expense',
        EntryKind.trip => 'Trip',
        EntryKind.memoir => 'Journal Entry',
        EntryKind.pin => 'Pin',
        EntryKind.habit => 'Habit',
        EntryKind.shopping => 'Shopping Item',
      };

  /// Module the shell shows this kind in.
  static EntryKind forModule(int index) => switch (index) {
        2 => EntryKind.task,
        3 => EntryKind.event,
        4 => EntryKind.outfit,
        5 => EntryKind.expense,
        6 => EntryKind.trip,
        7 => EntryKind.memoir,
        8 => EntryKind.pin,
        9 => EntryKind.habit,
        10 => EntryKind.shopping,
        _ => EntryKind.note,
      };
}

const noteSpaces = ['General Space', 'Academic Space', 'Design Space', 'Personal Space', 'Travel Space'];
const taskPriorities = ['Urgent & Critical', 'High Priority', 'Medium Priority', 'Low Priority'];
const taskSlots = ['Morning', 'Afternoon', 'Evening', 'Later'];
const expenseCategories = [
  'Food & Dining',
  'Clothing',
  'Travel & Stay',
  'Study & Books',
  'Shopping',
  'Home',
  'Health',
  'Transport',
  'Bills',
  'General',
];
const memoirMoods = ['Reflective', 'Grateful', 'Adventurous', 'Calm', 'Energised', 'Tired', 'Anxious'];

/// Opens the editor as a full-screen sheet. Pass [editing] to open an existing item:
/// it shows first as an expanded, read-only page, and its editing tools appear only
/// after Edit is tapped. [startEditing] skips straight to the form.
///
/// In the card view the editor zooms out of the card it was opened from, and back into
/// it on close.
Future<void> openEntryEditor(BuildContext context, EntryKind kind, {Object? editing, DateTime? initialDate, bool startEditing = false}) {
  final zoom = !EditorialMode.active && !Motion.reduced(context);
  final origin = zoom ? CardOrigin.take() : null;
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: zoom ? Colors.transparent : overlayScrim(context),
    transitionDuration: Duration(milliseconds: zoom ? 480 : 260),
    pageBuilder: (ctx, _, __) => EntryEditor(
      kind: kind,
      editing: editing,
      initialDate: initialDate,
      readFirst: editing != null && !startEditing,
      onClose: () => Navigator.of(ctx).pop(),
    ),
    transitionBuilder: (ctx, anim, _, child) => zoom
        ? ZoomThrough(animation: anim, origin: origin?.$1, scrim: true, child: child)
        : FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  );
}

/// Create/edit form for every module, with real fields and validation.
class EntryEditor extends ConsumerStatefulWidget {
  final EntryKind kind;
  final Object? editing;
  final DateTime? initialDate;
  final String? initialTitle;
  final VoidCallback onClose;
  final ValueChanged<String>? onSaved;
  final ValueChanged<String>? onTitleChanged;
  final ValueChanged<EntryKind>? onKindChanged;

  /// Shows an existing item read-only first; Edit switches to the form.
  final bool readFirst;

  const EntryEditor({
    super.key,
    required this.kind,
    required this.onClose,
    this.editing,
    this.initialDate,
    this.initialTitle,
    this.onSaved,
    this.onTitleChanged,
    this.onKindChanged,
    this.readFirst = false,
  });

  @override
  ConsumerState<EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends ConsumerState<EntryEditor> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _a = TextEditingController(); // tag / items / store / destination / image URL
  final _b = TextEditingController(); // weather / flight
  final _c = TextEditingController(); // fabric
  final _amount = TextEditingController();
  final _when = TextEditingController();
  final _buyingLink = TextEditingController();
  final _bodyFocus = FocusNode();
  final _formScroll = ScrollController();
  final _readScroll = ScrollController();

  /// Showing the expanded, read-only view rather than the form.
  late bool _reading = widget.readFirst && widget.editing != null;

  String? _garmentImagePath;
  bool _isAnalyzingGarment = false;
  String? _coverUrl;
  String? _audioAttachmentUrl;
  int? _audioAttachmentDuration;

  String _choice = '';
  String _choice2 = '';
  DateTime? _date;
  DateTime? _endDate;
  TaskRepeat _repeat = TaskRepeat.none;
  int _duration = 60;
  bool _private = false;

  /// An expense that comes back every month (rent, subscriptions).
  bool _recurring = false;
  String? _whenHint;
  bool _setDeviceReminder = false;
  String _reminderOffset = 'at_time'; // 'at_time', '15m_before', '1h_before', '1d_before'
  TimeOfDay _reminderClockTime = const TimeOfDay(hour: 9, minute: 30);

  // --- On-device AI suggestions ---------------------------------------------
  /// Fields the user chose by hand; AI never overrides these.
  final Set<String> _touched = {};

  /// Current suggestion per field ('choice', 'choice2').
  final Map<String, Suggestion> _suggestions = {};

  bool get _isEdit => widget.editing != null;

  bool get _aiOn => ref.read(appSettingsProvider).smartSuggestions;

  void _pick(String field, String value) => setState(() {
        _touched.add(field);
        if (field == 'choice') _choice = value;
        if (field == 'choice2') _choice2 = value;
      });

  /// Recomputes suggestions as the user types. New items take a confident
  /// suggestion automatically until the user picks something themselves.
  void _suggest() {
    if (!mounted || !_aiOn) return;
    final title = _title.text.trim();
    final body = _body.text.trim();
    final next = <String, Suggestion?>{};
    switch (widget.kind) {
      case EntryKind.expense:
        final history = [
          for (final e in ref.read(expensesProvider).expenses)
            if (e.id != (widget.editing as ExpenseItem?)?.id) ('${e.title} ${e.note}', e.category),
        ];
        next['choice'] = ExpenseCategorizer.suggest('$title $body', history: history);
      case EntryKind.task:
        next['choice'] = TaskTriage.priority(title, dueAt: _date);
        final tasks = ref.read(tasksProvider);
        next['choice2'] = TaskTriage.space(title,
            history: [for (final t in tasks) if (t.id != (widget.editing as TaskItem?)?.id) (t.title, t.space)],
            spaces: noteSpaces);
      case EntryKind.note:
        final notes = ref.read(notesProvider).where((n) => n.id != (widget.editing as NoteItem?)?.id).toList();
        next['choice'] = TaskTriage.space('$title $body',
            history: [for (final n in notes) ('${n.title} ${n.body}', n.space)], spaces: noteSpaces);
      case EntryKind.memoir:
        next['choice'] = MoodSense.mood('$title $body');
      default:
        return;
    }
    setState(() {
      next.forEach((field, s) {
        if (s == null || s.confidence < 0.45) {
          _suggestions.remove(field);
          return;
        }
        _suggestions[field] = s;
        if (!_isEdit && !_touched.contains(field) && s.confidence >= 0.55) {
          if (field == 'choice') _choice = s.value;
          if (field == 'choice2') _choice2 = s.value;
        }
      });
    });
  }

  /// The ✦ chip under a choice row: confirms an AI pick, or offers a different one.
  Widget _aiHint(String field, String current) {
    final s = _suggestions[field];
    if (s == null) return const SizedBox.shrink();
    final applied = s.value == current;
    if (applied && _touched.contains(field)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AiSuggestionChip(
          suggestion: s,
          applied: applied,
          label: 'Use ${s.value}',
          onApply: () => _pick(field, s.value),
        ),
      ),
    );
  }

  Widget _buildKindSelectorChip(EntryKind k, bool isDark, Color accent) {
    final selected = widget.kind == k;
    final iconData = switch (k) {
      EntryKind.note => LucideIcons.fileText,
      EntryKind.task => LucideIcons.checkSquare,
      EntryKind.event => LucideIcons.calendar,
      EntryKind.expense => LucideIcons.receipt,
      EntryKind.memoir => LucideIcons.bookOpen,
      EntryKind.habit => LucideIcons.sprout,
      EntryKind.shopping => LucideIcons.shoppingBag,
      EntryKind.outfit => LucideIcons.shirt,
      EntryKind.trip => LucideIcons.compass,
      EntryKind.pin => LucideIcons.pin,
    };
    final label = switch (k) {
      EntryKind.memoir => 'Journal',
      EntryKind.shopping => 'Shopping',
      _ => k.label,
    };

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        SanctuaryHapticEngine.selection();
        widget.onKindChanged?.call(k);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? accent
              : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEDE8DF)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? accent
                : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFDDD7CC)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              size: 13,
              color: selected
                  ? Colors.white
                  : (isDark ? const Color(0xFFCCCCCC) : const Color(0xFF444444)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected
                    ? Colors.white
                    : (isDark ? const Color(0xFFEEEEEE) : const Color(0xFF222222)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Rebuild so the formatting toolbar can dock above the keyboard while the body is focused.
    _bodyFocus.addListener(() => setState(() {}));
    _loadFields();
    // A title handed over (e.g. from quick capture) seeds a new item only.
    if (widget.editing == null && widget.initialTitle != null && widget.initialTitle!.isNotEmpty) {
      _title.text = widget.initialTitle!;
    }
    _title.addListener(() {
      widget.onTitleChanged?.call(_title.text);
    });
    _wireSuggestions();
    _saved = _snapshot();
  }

  /// Fills the fields from the item being edited (or the defaults for a new one).
  void _loadFields() {
    final e = widget.editing;
    switch (widget.kind) {
      case EntryKind.note:
        final n = e as NoteItem?;
        _title.text = n?.title ?? '';
        _body.text = n?.body ?? '';
        _a.text = n?.tag ?? '';
        _choice = n?.space ?? noteSpaces.first;
        _coverUrl = n?.coverUrl;
        _audioAttachmentUrl = n?.audioAttachmentUrl;
        _audioAttachmentDuration = n?.audioAttachmentDuration;
      case EntryKind.task:
        final t = e as TaskItem?;
        _title.text = t?.title ?? '';
        _body.text = t?.notes ?? '';
        _choice = t?.priority ?? 'Medium Priority';
        _choice2 = t?.space ?? 'General Space';
        _date = t?.dueAt ?? widget.initialDate;
        if (_date != null) {
          _reminderClockTime = TimeOfDay.fromDateTime(_date!);
        }
        _repeat = t?.repeat ?? TaskRepeat.none;
      case EntryKind.event:
        final ev = e as PlannerEvent?;
        _title.text = ev?.title ?? '';
        _body.text = ev?.notes ?? '';
        _date = ev?.startsAt ?? widget.initialDate ?? _nextHour();
        if (_date != null) {
          _reminderClockTime = TimeOfDay.fromDateTime(_date!);
        }
        _duration = ev?.durationMinutes ?? 60;
      case EntryKind.outfit:
        final o = e as WardrobeOutfit?;
        _title.text = o?.title ?? '';
        _a.text = o?.items ?? '';
        _b.text = o?.weather ?? '';
        _c.text = o?.fabric ?? '';
        _body.text = o?.tag ?? '';
        _garmentImagePath = o?.imageUrl;
      case EntryKind.expense:
        final x = e as ExpenseItem?;
        _title.text = x?.title ?? '';
        _amount.text = x == null ? '' : _trimZeros(x.amount);
        _choice = x?.category ?? 'General';
        _body.text = x?.note ?? '';
        _date = x?.spentAt ?? DateTime.now();
        _recurring = x?.recurring ?? false;
      case EntryKind.trip:
        final t = e as TravelTrip?;
        _title.text = t?.title ?? '';
        _a.text = t?.destination ?? '';
        _b.text = t?.flight ?? '';
        _date = t?.startDate;
        _endDate = t?.endDate;
        _coverUrl = t?.coverUrl;
      case EntryKind.memoir:
        final m = e as MemoirItem?;
        _title.text = m?.title ?? '';
        _body.text = m?.excerpt ?? '';
        _choice = m?.mood ?? memoirMoods.first;
        _private = m?.isPrivate ?? false;
      case EntryKind.pin:
        final p = e as MoodboardPin?;
        _title.text = p?.title ?? '';
        _a.text = p?.imageUrl ?? '';
        _body.text = p?.note ?? '';
      case EntryKind.habit:
        final h = e as HabitItem?;
        _title.text = h?.title ?? '';
        _choice = h?.time ?? '08:00 AM';
      case EntryKind.shopping:
        final s = e as ShoppingItem?;
        _title.text = s?.name ?? '';
        _a.text = s?.store ?? '';
        _amount.text = s == null ? '' : '${s.price}';
        _buyingLink.text = s?.url ?? '';
    }
  }

  /// Leaves the form without saving and goes back to the expanded view.
  void _cancelEditing() {
    FocusScope.of(context).unfocus();
    setState(() {
      _loadFields();
      _touched.clear();
      _reading = true;
    });
  }

  // --- Unsaved changes ---------------------------------------------------------

  /// Every value the form can change, so leaving can tell whether anything would be lost.
  String _snapshot() => [
        _title.text, _body.text, _a.text, _b.text, _c.text, _amount.text, _buyingLink.text, _choice, _choice2,
        _date, _endDate, _repeat, _duration, _private, _recurring, _coverUrl, _audioAttachmentUrl, _garmentImagePath,
      ].join('\u0001');

  /// The form as it was opened (or last reset).
  String _saved = '';

  /// Set once the item is saved or deleted, so closing never asks.
  bool _done = false;

  bool get _hasUnsavedChanges => !_done && !_reading && _snapshot() != _saved;

  /// Close, Escape and Back all come here: unsaved typing is never thrown away silently.
  Future<void> _requestClose() async {
    if (!_hasUnsavedChanges) return widget.onClose();
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: Text(_isEdit ? 'Your edits to this ${widget.kind.label.toLowerCase()} have not been saved.' : 'This ${widget.kind.label.toLowerCase()} has not been saved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
        ],
      ),
    );
    if (discard == true && mounted) {
      _done = true;
      widget.onClose();
    }
  }

  void _wireSuggestions() {
    for (final c in [_title, _body]) {
      c.addListener(_suggest);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _suggest());
  }

  static DateTime _nextHour() {
    final n = DateTime.now().add(const Duration(hours: 1));
    return DateTime(n.year, n.month, n.day, n.hour);
  }

  static String _trimZeros(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  void dispose() {
    for (final c in [_title, _body, _a, _b, _c, _amount, _when, _buyingLink]) {
      c.dispose();
    }
    _bodyFocus.dispose();
    _formScroll.dispose();
    _readScroll.dispose();
    super.dispose();
  }

  // --- Saving ----------------------------------------------------------------

  double? get _parsedAmount => double.tryParse(_amount.text.replaceAll(',', '').trim());

  /// Device reminders are fire-and-forget, but a time that has already passed is
  /// reported rather than quietly moved to another day.
  void _scheduleReminder(String id, String title, DateTime at, String body) {
    CalendarReminderService().scheduleDeviceReminder(id: id, title: title, scheduledTime: at, body: body).then((ok) {
      if (!ok && !at.isAfter(DateTime.now())) {
        AppToastEngine().notify(
          title: 'Reminder not set',
          message: 'That reminder time has already passed. Pick a later time.',
          type: ToastType.alert,
        );
      }
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final title = _title.text.trim();
    final body = _body.text.trim();
    final e = widget.editing;

    switch (widget.kind) {
      case EntryKind.note:
        final n = ref.read(notesProvider.notifier);
        if (e is NoteItem) {
          n.updateNote(
            e.id,
            title: title,
            space: _choice,
            tag: _a.text.trim().isEmpty ? 'Note' : _a.text.trim(),
            content: body,
            coverUrl: _coverUrl,
            clearCoverUrl: _coverUrl == null,
            audioAttachmentUrl: _audioAttachmentUrl,
            clearAudioAttachment: _audioAttachmentUrl == null,
            audioAttachmentDuration: _audioAttachmentDuration,
          );
        } else {
          n.addNote(
            title: title,
            space: _choice,
            tag: _a.text.trim(),
            excerpt: '',
            content: body,
            coverUrl: _coverUrl,
            audioAttachmentUrl: _audioAttachmentUrl,
            audioAttachmentDuration: _audioAttachmentDuration,
          );
        }
      case EntryKind.task:
        final n = ref.read(tasksProvider.notifier);
        final taskId = (e is TaskItem) ? e.id : 'task_${DateTime.now().millisecondsSinceEpoch}';
        if (e is TaskItem) {
          n.updateTask(e.id,
              title: title,
              priority: _choice,
              space: _choice2,
              notes: body,
              dueAt: _date,
              clearDueAt: _date == null,
              repeat: _repeat);
        } else {
          n.addTask(title: title, priority: _choice, space: _choice2, notes: body, dueAt: _date, repeat: _repeat);
        }
        if (_setDeviceReminder) {
          final targetBase = _date ?? DateTime.now();
          final baseWithClock = DateTime(
            targetBase.year,
            targetBase.month,
            targetBase.day,
            _reminderClockTime.hour,
            _reminderClockTime.minute,
          );
          final reminderTime = _calculateReminderTime(baseWithClock, _reminderOffset);
          _scheduleReminder(taskId, title, reminderTime, body.isNotEmpty ? body : 'Task due: $title');
        }
      case EntryKind.event:
        final n = ref.read(eventsProvider.notifier);
        final eventId = (e is PlannerEvent) ? e.id : 'event_${DateTime.now().millisecondsSinceEpoch}';
        if (e is PlannerEvent) {
          n.updateEvent(e.id, title: title, startsAt: _date, durationMinutes: _duration, notes: body);
        } else {
          n.addEvent(title: title, startsAt: _date!, durationMinutes: _duration, notes: body);
        }
        if (_setDeviceReminder) {
          final targetBase = _date ?? DateTime.now();
          final baseWithClock = DateTime(
            targetBase.year,
            targetBase.month,
            targetBase.day,
            _reminderClockTime.hour,
            _reminderClockTime.minute,
          );
          final reminderTime = _calculateReminderTime(baseWithClock, _reminderOffset);
          _scheduleReminder(eventId, title, reminderTime, body.isNotEmpty ? body : 'Event starting: $title');
        }
      case EntryKind.outfit:
        final n = ref.read(wardrobeProvider.notifier);
        final items = _a.text.trim(), weather = _b.text.trim(), fabric = _c.text.trim();
        final tag = body.isEmpty ? 'Casual' : body;
        if (e is WardrobeOutfit) {
          n.updateOutfit(e.id, title: title, items: items, weather: weather, fabric: fabric, tag: tag, imageUrl: _garmentImagePath);
        } else {
          n.addOutfit(
            title: title,
            items: items.isEmpty ? null : items,
            weather: weather.isEmpty ? null : weather,
            fabric: fabric.isEmpty ? null : fabric,
            tag: tag,
            imageUrl: _garmentImagePath,
          );
        }
      case EntryKind.expense:
        final n = ref.read(expensesProvider.notifier);
        final amount = _parsedAmount!;
        if (e is ExpenseItem) {
          n.updateExpense(e.id, title: title, amount: amount, category: _choice, note: body, spentAt: _date, recurring: _recurring);
        } else {
          n.addExpense(title: title, amount: amount, category: _choice, note: body, spentAt: _date, recurring: _recurring);
          _warnIfOverBudget();
        }
      case EntryKind.trip:
        final n = ref.read(travelProvider.notifier);
        if (e is TravelTrip) {
          n.updateTrip(
            e.id,
            title: title,
            destination: _a.text.trim(),
            flight: _b.text.trim(),
            startDate: _date,
            endDate: _endDate,
            coverUrl: _coverUrl,
            clearCoverUrl: _coverUrl == null,
          );
        } else {
          n.addTrip(
            title: title,
            destination: _a.text.trim(),
            flight: _b.text.trim(),
            startDate: _date,
            endDate: _endDate,
            coverUrl: _coverUrl,
          );
        }
      case EntryKind.memoir:
        final n = ref.read(journalProvider.notifier);
        if (e is MemoirItem) {
          n.updateMemoir(e.id, title: title, excerpt: body, mood: _choice, isPrivate: _private);
        } else {
          n.addMemoir(title: title, excerpt: body, mood: _choice, isPrivate: _private);
        }
      case EntryKind.pin:
        final n = ref.read(moodboardProvider.notifier);
        final MoodboardPin? savedPin;
        if (e is MoodboardPin) {
          savedPin = n.updatePin(e.id, title: title, imageUrl: _a.text.trim(), note: body);
        } else {
          savedPin = n.addPin(title: title, imageUrl: _a.text.trim(), note: body);
        }
        final targetPin = savedPin;
        if (targetPin != null && !targetPin.imageUrl.startsWith('http') && SanctuarySupabaseService().isConnectedToCloud) {
          unawaited(() async {
            try {
              final file = File(targetPin.imageUrl);
              if (await file.exists()) {
                final cloudRes = await CloudinaryMediaService().uploadFile(
                  file: file,
                  category: 'moodboard',
                );
                if (cloudRes != null && cloudRes.secureUrl.isNotEmpty) {
                  n.updatePin(targetPin.id, title: targetPin.title, imageUrl: cloudRes.secureUrl, note: targetPin.note);
                }
              }
            } catch (err) {
              debugPrint('[EntryEditor] Cloudinary sync deferred for pin ${targetPin.id}: $err');
            }
          }());
        }
      case EntryKind.habit:
        final n = ref.read(habitsProvider.notifier);
        if (e is HabitItem) {
          n.updateHabit(e.id, title: title, time: _choice);
        } else {
          n.addHabit(title: title, time: _choice);
        }
      case EntryKind.shopping:
        final n = ref.read(shoppingProvider.notifier);
        final price = _parsedAmount!.round();
        final rawUrl = _buyingLink.text.trim();
        final url = rawUrl.isEmpty ? null : rawUrl;
        if (e is ShoppingItem) {
          n.updateItem(e.id, name: title, store: _a.text.trim(), price: price, url: url);
        } else {
          n.addItem(name: title, store: _a.text.trim(), price: price, url: url);
        }
    }

    HapticFeedback.lightImpact();
    _done = true;
    widget.onSaved?.call(title);
    widget.onClose();
  }

  void _warnIfOverBudget() {
    final settings = ref.read(appSettingsProvider);
    final limit = settings.monthlyBudget;
    if (limit == null) return;
    final spent = ref.read(expensesProvider).spendInMonth(DateTime.now());
    if (spent <= limit * 0.8) return;
    final over = spent > limit;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(over
          ? 'Over this month\'s budget: ${formatMoney(spent, settings.currencySymbol)} of ${formatMoney(limit, settings.currencySymbol)}.'
          : '${(spent / limit * 100).round()}% of this month\'s budget used.'),
    ));
  }

  Future<void> _delete() async {
    final e = widget.editing;
    if (e == null) return;
    switch (e) {
      case NoteItem n:
        ref.read(notesProvider.notifier).deleteNote(n.id);
      case TaskItem t:
        ref.read(tasksProvider.notifier).deleteTask(t.id);
      case PlannerEvent ev:
        ref.read(eventsProvider.notifier).deleteEvent(ev.id);
      case WardrobeOutfit o:
        ref.read(wardrobeProvider.notifier).removeOutfit(o.id);
      case ExpenseItem x:
        ref.read(expensesProvider.notifier).deleteExpense(x.id);
      case TravelTrip t:
        ref.read(travelProvider.notifier).deleteTrip(t.id);
      case MemoirItem m:
        ref.read(journalProvider.notifier).deleteMemoir(m.id);
      case MoodboardPin p:
        ref.read(moodboardProvider.notifier).deletePin(p.id);
      case HabitItem h:
        ref.read(habitsProvider.notifier).deleteHabit(h.id);
      case ShoppingItem s:
        ref.read(shoppingProvider.notifier).deleteItem(s.id);
    }
    _done = true;
    widget.onClose();
  }

  // --- Date helpers ----------------------------------------------------------

  Future<DateTime?> _pickDate(DateTime? initial, {DateTime? first}) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: first ?? DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
  }

  void _applyWhenText(String text) {
    final parsed = NlpDateParser.tryParse(text);
    setState(() {
      if (parsed == null) {
        _whenHint = text.trim().isEmpty ? null : 'Try "tomorrow 3pm", "fri 9:30" or "in 2 hours"';
      } else {
        _date = parsed;
        _whenHint = null;
      }
    });
  }

  // --- UI --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF000000) : AppColors.background;
    final text = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final sub = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accent = isDark ? const Color(0xFFD0485A) : AppColors.secondary;
    final kindLabel = widget.kind.label;
    // The editor is hosted by a dialog route (no Scaffold to resize it) or a Scaffold body
    // (which already strips the inset), so padding by the inset never double-counts.
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardOpen = keyboardInset > 0;
    final dockToolbar = !_reading && keyboardOpen && _bodyFocus.hasFocus && _hasMarkdownToolbar;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        SingleActivator(LogicalKeyboardKey.enter, control: true): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter, meta: true): ActivateIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(onInvoke: (_) => _requestClose()),
          // Ctrl/Cmd+Enter saves the form; there is nothing to save while reading.
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _reading ? null : _save()),
        },
        child: PopScope(
          // The system Back gesture asks first when there is unsaved typing.
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _requestClose();
          },
          child: Container(
          color: overlayScrim(context),
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: keyboardOpen ? 6 : 12),
                  child: Material(
                    color: surface,
                    borderRadius: BorderRadius.circular(28),
                    elevation: 24,
                    clipBehavior: Clip.antiAlias,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                            child: Row(
                              children: [
                                const StitchMonogramNWidget(size: 26),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_reading ? 'VIEW' : (_isEdit ? 'EDIT' : 'NEW ENTRY'),
                                          style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: accent)),
                                      Text(kindLabel,
                                          style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: text),
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                if (_reading && widget.editing is NoteItem)
                                  IconButton(
                                    tooltip: 'Ask AI about this note',
                                    icon: Icon(LucideIcons.brain, color: text, size: 19),
                                    onPressed: () => showNotesRagModal(context, notes: [_liveNote ?? widget.editing as NoteItem]),
                                  ),
                                IconButton(
                                  tooltip: 'Copy text',
                                  icon: Icon(LucideIcons.copy, color: text, size: 19),
                                  onPressed: () => copyToClipboard(
                                    [_title.text.trim(), _body.text.trim()].where((t) => t.isNotEmpty).join('\n\n'),
                                    what: kindLabel,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Close',
                                  icon: Icon(LucideIcons.x, color: text, size: 22),
                                  onPressed: _requestClose,
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5DFC9)),
                          // The kind switcher folds away while typing to give the text more room.
                          if (!_isEdit && !keyboardOpen) ...[
                            Container(
                              width: double.infinity,
                              color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF7F4EE),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    for (final k in EntryKind.values)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: _buildKindSelectorChip(k, isDark, accent),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () {
                                          SanctuaryHapticEngine.selection();
                                          widget.onClose();
                                          OmniCaptureModal.show(context);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF231B15) : const Color(0xFFFBF0EC),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: accent.withValues(alpha: 0.6), width: 1),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(LucideIcons.sparkles, size: 13, color: accent),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Omni NLP',
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: accent,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(height: 1, color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5DFC9)),
                          ],
                          Expanded(
                            child: _reading
                                ? _readerView(text, sub, accent, isDark)
                                : _formView(text, sub, accent, isDark),
                          ),
                          if (dockToolbar)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                              child: MarkdownAccessoryToolbar(controller: _body, onAttachImage: _pickAndInsertImage),
                            ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: keyboardOpen ? 6 : 12),
                            color: isDark ? const Color(0xFF000000) : AppColors.surfaceContainerHigh,
                            child: _reading
                                ? Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: _delete,
                                        icon: const Icon(LucideIcons.trash2, size: 14, color: AppColors.error),
                                        label: Text('Delete', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.error)),
                                      ),
                                      const Spacer(),
                                      Pressable(
                                        pressedScale: 0.94,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: accent,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                          ),
                                          onPressed: () {
                                            SanctuaryHapticEngine.selection();
                                            setState(() => _reading = false);
                                          },
                                          icon: const Icon(LucideIcons.pencil, size: 14, color: Colors.white),
                                          label: Text('Edit', style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                              children: [
                                if (_isEdit && widget.readFirst)
                                  TextButton(
                                    onPressed: _cancelEditing,
                                    child: Text('Cancel', style: GoogleFonts.dmSans(fontSize: 12, color: accent)),
                                  )
                                else if (_isEdit)
                                  TextButton.icon(
                                    onPressed: _delete,
                                    icon: const Icon(LucideIcons.trash2, size: 14, color: AppColors.error),
                                    label: Text('Delete', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.error)),
                                  )
                                else
                                  TextButton(
                                    onPressed: widget.onClose,
                                    child: Text('Discard', style: GoogleFonts.dmSans(fontSize: 12, color: accent)),
                                  ),
                                const Spacer(),
                                Pressable(
                                  pressedScale: 0.94,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                    ),
                                    onPressed: _save,
                                    icon: const Icon(LucideIcons.check, size: 14, color: Colors.white),
                                    label: Text(_isEdit ? 'Save changes' : 'Save $kindLabel',
                                        style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  /// The editing form, scrollable however long the text grows.
  Widget _formView(Color text, Color sub, Color accent, bool isDark) {
    return Scrollbar(
      controller: _formScroll,
      child: SingleChildScrollView(
        controller: _formScroll,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _title,
              autofocus: !_isEdit,
              textInputAction: TextInputAction.next,
              maxLength: 200,
              style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: text),
              decoration: InputDecoration(
                hintText: widget.kind == EntryKind.shopping ? 'Item name' : '${widget.kind.label} title',
                hintStyle: GoogleFonts.bodoniModa(fontSize: 20, color: sub.withValues(alpha: 0.5)),
                border: InputBorder.none,
                counterText: '',
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Give it a title' : null,
            ),
            const SizedBox(height: 8),
            ..._fieldsFor(text, sub, accent, isDark),
          ],
        ),
      ),
    );
  }

  // --- Expanded (read-only) view ---------------------------------------------

  /// The note as it is now, so pins and groups made elsewhere show up here.
  NoteItem? get _liveNote {
    final e = widget.editing;
    if (e is! NoteItem) return null;
    return ref.read(notesProvider).where((n) => n.id == e.id).firstOrNull ?? e;
  }

  /// Ticks a checklist line in the expanded view and saves it straight away.
  void _toggleReadLine(int index) {
    final next = RichNoteText.toggleLine(_body.text, index);
    setState(() => _body.text = next);
    HapticFeedback.selectionClick();
    switch (widget.editing) {
      case NoteItem n:
        ref.read(notesProvider.notifier).updateNote(n.id, content: next);
      case TaskItem t:
        ref.read(tasksProvider.notifier).updateTask(t.id, notes: next);
      case MemoirItem m:
        ref.read(journalProvider.notifier).updateMemoir(m.id, excerpt: next);
      case PlannerEvent ev:
        ref.read(eventsProvider.notifier).updateEvent(ev.id, notes: next);
    }
  }

  /// One line of facts about the item: space, priority, due date, mood and so on.
  List<String> _readFacts() {
    final currency = ref.read(appSettingsProvider).currencySymbol;
    String? due(DateTime? d) => d == null ? null : '${DateLabels.long(d)} · ${DateLabels.time(d)}';
    final e = widget.editing;
    return [
      ...switch (widget.kind) {
        EntryKind.note => [
            _choice,
            if (_a.text.trim().isNotEmpty && _a.text.trim() != 'Note') '#${_a.text.trim()}',
            if (_liveNote?.group != null) 'Group: ${_liveNote!.group}',
            if (e is NoteItem) 'Edited ${e.date}',
          ],
        EntryKind.task => [
            _choice,
            _choice2,
            if (_date != null) 'Due ${due(_date)}',
            if (_repeat != TaskRepeat.none) _repeat.label,
            if (e is TaskItem && e.completed) 'Done',
          ],
        EntryKind.event => [
            if (_date != null) due(_date)!,
            _durationLabel(_duration),
          ],
        EntryKind.memoir => [
            _choice,
            if (e is MemoirItem) DateLabels.dateTime(e.createdAt),
            if (_private) 'Private',
          ],
        EntryKind.habit => ['Every day at $_choice'],
        EntryKind.expense => [
            if (_parsedAmount != null) formatMoney(_parsedAmount!, currency),
            _choice,
            if (_date != null) DateLabels.long(_date!),
            if (_recurring) 'Every month',
          ],
        EntryKind.trip => [
            if (_a.text.trim().isNotEmpty) _a.text.trim(),
            if (_date != null) DateLabels.range(_date!, _endDate),
            if (_b.text.trim().isNotEmpty) 'Flight ${_b.text.trim()}',
          ],
        EntryKind.outfit => [_a.text, _b.text, _c.text, _body.text],
        EntryKind.shopping => [
            if (_a.text.trim().isNotEmpty) _a.text.trim(),
            if (_parsedAmount != null) formatMoney(_parsedAmount!, currency),
          ],
        EntryKind.pin => const <String>[],
      },
    ].where((f) => f.trim().isNotEmpty).toList();
  }

  String get _readBody => switch (widget.kind) {
        EntryKind.note || EntryKind.task || EntryKind.event || EntryKind.memoir || EntryKind.pin || EntryKind.expense => _body.text,
        EntryKind.shopping => _buyingLink.text,
        _ => '',
      };

  String? get _readImage => switch (widget.kind) {
        EntryKind.note || EntryKind.trip => _coverUrl,
        EntryKind.outfit => _garmentImagePath,
        EntryKind.pin => _a.text.trim(),
        _ => null,
      };

  Widget _readerView(Color text, Color sub, Color accent, bool isDark) {
    final notesFont = ref.watch(appSettingsProvider.select((s) => s.fontFamilyNotes));
    final bodyStyle = widget.kind == EntryKind.note && notesFont != 'Default'
        ? AppTypography.getStyle(notesFont, fontSize: 16.5, color: text, height: 1.65)
        : GoogleFonts.dmSans(fontSize: 16.5, color: text, height: 1.65);
    final facts = _readFacts();
    final body = _readBody.trim();
    final image = _readImage;
    final task = widget.editing is TaskItem ? ref.watch(tasksProvider).where((t) => t.id == (widget.editing as TaskItem).id).firstOrNull : null;
    final habit = widget.editing is HabitItem ? ref.watch(habitsProvider).where((h) => h.id == (widget.editing as HabitItem).id).firstOrNull : null;
    final hasAudio = _audioAttachmentUrl != null && _audioAttachmentUrl!.isNotEmpty;

    return Scrollbar(
      controller: _readScroll,
      child: SingleChildScrollView(
        controller: _readScroll,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (image != null && image.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: AnyImage(image, fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              Text(
                _title.text.trim().isEmpty ? 'Untitled' : _title.text.trim(),
                style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: text, height: 1.15),
              ),
              if (facts.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final f in facts)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: edBox(
                          color: isDark ? const Color(0xFF141111) : const Color(0xFFF1EBE3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(f, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: sub)),
                      ),
                  ],
                ),
              ],
              if (hasAudio) ...[
                const SizedBox(height: 16),
                AudioCassettePlayer(
                  title: _title.text,
                  audioPath: _audioAttachmentUrl,
                  totalDuration: Duration(seconds: _audioAttachmentDuration ?? 30),
                ),
              ],
              if (task != null && task.subtasks.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('STEPS', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.4, color: sub)),
                const SizedBox(height: 6),
                for (final st in task.subtasks)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 26, child: Text(st.done ? '☑' : '☐', style: bodyStyle.copyWith(color: st.done ? accent : sub))),
                        Expanded(
                          child: Text(st.title,
                              style: bodyStyle.copyWith(color: st.done ? sub : text, decoration: st.done ? TextDecoration.lineThrough : null)),
                        ),
                      ],
                    ),
                  ),
              ],
              if (habit != null) ...[
                const SizedBox(height: 18),
                Text('${habit.streak}-day streak', style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: accent)),
                const SizedBox(height: 10),
                Text('LAST TWO WEEKS', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.4, color: sub)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var d = 13; d >= 0; d--)
                      Builder(builder: (context) {
                        final day = DateTime.now().subtract(Duration(days: d));
                        final done = habit.isDoneOn(day);
                        return Tooltip(
                          message: DateLabels.long(day),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done ? accent : Colors.transparent,
                              border: Border.all(color: done ? accent : sub.withValues(alpha: 0.4)),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ],
              const SizedBox(height: 22),
              if (body.isNotEmpty)
                widget.kind == EntryKind.shopping
                    ? Text(body, style: bodyStyle.copyWith(color: accent))
                    : RichNoteText(text: _readBody, style: bodyStyle, accent: accent, muted: sub, onToggleLine: _toggleReadLine)
              else if (widget.kind != EntryKind.habit)
                Text('Nothing written here yet. Tap Edit to add more.', style: GoogleFonts.dmSans(fontSize: 14, color: sub)),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoteAiTools(BuildContext context, Color text, Color sub, Color accent, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F0E0D) : const Color(0xFFFAF7F2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.sparkles, size: 16, color: accent),
                    const SizedBox(width: 8),
                    Text(
                      'AI & productivity tools',
                      style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.1, color: accent),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: edBox(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                    child: Icon(LucideIcons.brain, size: 18, color: accent),
                  ),
                  title: Text('Semantic Note RAG', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
                  subtitle: Text('Search and synthesize knowledge across your vault', style: GoogleFonts.dmSans(fontSize: 12, color: sub)),
                  onTap: () {
                    Navigator.pop(ctx);
                    final bodyText = _body.text.trim();
                    final titleText = _title.text.trim().isNotEmpty ? _title.text.trim() : 'Current Note';
                    final tempNote = NoteItem(
                      id: 'temp-active',
                      title: titleText,
                      space: _choice,
                      tag: _a.text.isNotEmpty ? _a.text : 'NOTE',
                      excerpt: bodyText.length > 120 ? bodyText.substring(0, 120) : bodyText,
                      content: bodyText,
                      updatedAt: DateTime.now(),
                    );
                    showNotesRagModal(context, notes: [tempNote]);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: edBox(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                    child: Icon(LucideIcons.arrowUpRight, size: 18, color: accent),
                  ),
                  title: Text('Evolve Workflows', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
                  subtitle: Text('Convert natural language action items into real tasks & expenses', style: GoogleFonts.dmSans(fontSize: 12, color: sub)),
                  onTap: () {
                    Navigator.pop(ctx);
                    final bodyText = _body.text.trim();
                    if (bodyText.isEmpty) {
                      AppToastEngine().showToast(context, title: 'Empty Note', message: 'Write some content first to evolve workflows.');
                      return;
                    }
                    HapticFeedback.selectionClick();
                    showWorkflowEvolutionDialog(
                      context,
                      title: _title.text.trim().isNotEmpty ? _title.text.trim() : 'Untitled Thought',
                      content: bodyText,
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: edBox(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                    child: Icon(LucideIcons.crosshair, size: 18, color: accent),
                  ),
                  title: Text('Strategic Pressure-Test', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
                  subtitle: Text('Identify blind spots, hidden assumptions, and execution risks', style: GoogleFonts.dmSans(fontSize: 12, color: sub)),
                  onTap: () {
                    Navigator.pop(ctx);
                    final bodyText = _body.text.trim();
                    if (bodyText.isEmpty) {
                      AppToastEngine().showToast(context, title: 'Empty Note', message: 'Write some thoughts first to pressure-test.');
                      return;
                    }
                    HapticFeedback.selectionClick();
                    showPressureTestDialog(
                      context,
                      title: _title.text.trim().isNotEmpty ? _title.text.trim() : 'Project Hypothesis',
                      content: bodyText,
                      onAppendToNote: (t) => setState(() => _body.text = '${_body.text}$t'),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: edBox(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                    child: Icon(LucideIcons.sparkles, size: 18, color: accent),
                  ),
                  title: Text('Summarize & Extract Actions', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
                  subtitle: Text('Distill executive summary and checkbox action items', style: GoogleFonts.dmSans(fontSize: 12, color: sub)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final bodyText = _body.text.trim();
                    if (bodyText.isEmpty) {
                      AppToastEngine().showToast(context, title: 'Empty Note', message: 'Please write note content first to summarize.');
                      return;
                    }
                    HapticFeedback.selectionClick();
                    final res = await AiCopilotService().summarizeNoteAndExtractActions(bodyText);
                    if (mounted && res.actionItems.isNotEmpty || res.summary.isNotEmpty) {
                      setState(() {
                        final buf = StringBuffer(bodyText);
                        if (res.summary.isNotEmpty) {
                          buf.writeln('\n\n📌 **Executive Summary**: ${res.summary}');
                        }
                        if (res.actionItems.isNotEmpty) {
                          buf.writeln('\n✅ **Action Items**:');
                          for (final a in res.actionItems) {
                            buf.writeln('- [ ] $a');
                          }
                        }
                        _body.text = buf.toString();
                        if (_a.text.isEmpty && res.tags.isNotEmpty) {
                          _a.text = res.tags.first;
                        }
                      });
                      HapticFeedback.mediumImpact();
                      if (context.mounted) {
                        AppToastEngine().showToast(
                          context,
                          title: 'Note Enhanced',
                          message: 'Summary & ${res.actionItems.length} action items extracted.',
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickCoverPhoto() async {
    try {
      final List<PlatformFile> files = await FilePicker.pickFiles(type: FileType.image);
      if (mounted && files.isNotEmpty && files.first.path != null) {
        setState(() => _coverUrl = files.first.path);
      }
    } catch (_) {}
  }

  Future<void> _pickAudioAttachment() async {
    try {
      final List<PlatformFile> files = await FilePicker.pickFiles(type: FileType.audio);
      if (mounted && files.isNotEmpty && files.first.path != null) {
        setState(() {
          _audioAttachmentUrl = files.first.path;
          _audioAttachmentDuration = 30;
        });
      }
    } catch (_) {}
  }

  List<Widget> _fieldsFor(Color text, Color sub, Color accent, bool isDark) {
    final currency = ref.watch(appSettingsProvider.select((s) => s.currencySymbol));
    switch (widget.kind) {
      case EntryKind.note:
        final isVoiceNote = _title.text.contains('🎙️') || _body.text.contains('🎙️') || _b.text.contains('🎙️');
        return [
          if (_coverUrl != null && _coverUrl!.isNotEmpty) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: AnyImage(_coverUrl!, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () => setState(() => _coverUrl = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (_audioAttachmentUrl != null && _audioAttachmentUrl!.isNotEmpty) ...[
            Stack(
              children: [
                AudioCassettePlayer(
                  title: _title.text.isNotEmpty ? _title.text : 'Attached Audio Memo',
                  audioPath: _audioAttachmentUrl,
                  totalDuration: Duration(seconds: _audioAttachmentDuration ?? 30),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () => setState(() {
                      _audioAttachmentUrl = null;
                      _audioAttachmentDuration = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else if (isVoiceNote) ...[
            AudioCassettePlayer(
              title: _title.text.isNotEmpty ? _title.text : 'Voice Note',
              totalDuration: AudioCassettePlayer.parseDuration('${_title.text} ${_body.text} ${_b.text}'),
            ),
            const SizedBox(height: 10),
          ],
          // 1. Serene, distraction-free writing canvas immediately under the title
          _bodyField('Write your thoughts, reflections, or plans…', isDark, text, sub, minLines: 12),
          const SizedBox(height: 14),

          // 2. Minimal, elegant utility bar: Space selector, Attach, Import Doc, and AI Tools
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Minimal Space selector pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: edBox(
                  color: isDark ? const Color(0xFF141210) : const Color(0xFFF3EDE2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? const Color(0xFF262320) : const Color(0xFFE6DED6)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _choice.isEmpty ? noteSpaces.first : _choice,
                    isDense: true,
                    dropdownColor: isDark ? const Color(0xFF141210) : const Color(0xFFFEF9EE),
                    icon: Icon(LucideIcons.chevronDown, size: 12, color: sub),
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: text),
                    items: noteSpaces.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) {
                      if (v != null) _pick('choice', v);
                    },
                  ),
                ),
              ),

              // Cover Banner button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: text,
                  side: BorderSide(color: isDark ? const Color(0xFF262320) : const Color(0xFFE6DED6)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _pickCoverPhoto,
                icon: Icon(LucideIcons.image, size: 12, color: sub),
                label: Text(_coverUrl != null ? 'Change Cover' : 'Cover Banner', style: GoogleFonts.dmSans(fontSize: 11.5, color: text)),
              ),

              // Audio Memo button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: text,
                  side: BorderSide(color: isDark ? const Color(0xFF262320) : const Color(0xFFE6DED6)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _pickAudioAttachment,
                icon: Icon(LucideIcons.mic, size: 12, color: sub),
                label: Text(_audioAttachmentUrl != null ? 'Change Audio' : 'Voice Memo', style: GoogleFonts.dmSans(fontSize: 11.5, color: text)),
              ),

              // Attachment button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: text,
                  side: BorderSide(color: isDark ? const Color(0xFF262320) : const Color(0xFFE6DED6)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final media = await DeviceMediaService().pickImage();
                  if (mounted && media != null) {
                    setState(() {
                      final tag = '\n\n📎 Attachment: ${media.name} (${media.path})';
                      _body.text = '${_body.text}$tag';
                    });
                    if (mounted) {
                      AppToastEngine().showToast(context, title: 'Attachment Added', message: 'Attached: ${media.name}');
                    }
                  }
                },
                icon: Icon(LucideIcons.paperclip, size: 12, color: sub),
                label: Text('Attach', style: GoogleFonts.dmSans(fontSize: 11.5, color: text)),
              ),

              // Document import button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: text,
                  side: BorderSide(color: isDark ? const Color(0xFF262320) : const Color(0xFFE6DED6)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final doc = await DocumentIngestionService().pickAndParseDocument();
                  if (mounted && doc != null) {
                    setState(() {
                      if (_title.text.isEmpty) _title.text = doc.title;
                      _body.text = _body.text.isEmpty ? doc.content : '${_body.text}\n\n${doc.content}';
                      if (_a.text.isEmpty && doc.extension.isNotEmpty) _a.text = doc.extension.toUpperCase();
                    });
                    if (mounted) {
                      AppToastEngine().showToast(
                        context,
                        title: 'Document Ingested',
                        message: 'Ingested ${doc.fileName} (${doc.content.length} characters).',
                      );
                    }
                  }
                },
                icon: Icon(LucideIcons.fileUp, size: 12, color: sub),
                label: Text('Import Doc', style: GoogleFonts.dmSans(fontSize: 11.5, color: text)),
              ),

              // AI Tools Sheet trigger
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent.withValues(alpha: 0.12),
                  foregroundColor: accent,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  side: BorderSide(color: accent.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showNoteAiTools(context, text, sub, accent, isDark),
                icon: Icon(LucideIcons.sparkles, size: 12, color: accent),
                label: Text('AI Tools ▾', style: GoogleFonts.dmSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: accent)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Optional Tag field
          _field(_a, 'Tag (optional)', icon: LucideIcons.tag),
        ];
      case EntryKind.task:
        return [
          _label('PRIORITY', sub),
          _chips(taskPriorities, _choice, (v) => _pick('choice', v), text),
          const SizedBox(height: 14),
          _label('SPACE', sub),
          _chips(noteSpaces, _choice2, (v) => _pick('choice2', v), text),
          const SizedBox(height: 14),
          _label('DUE', sub),
          _whenRow(text, sub, accent, allowClear: true),
          const SizedBox(height: 14),
          _label('REPEAT', sub),
          _chips(TaskRepeat.values.map((r) => r.label).toList(), _repeat.label,
              (v) => setState(() => _repeat = TaskRepeat.values.firstWhere((r) => r.label == v)), text),
          const SizedBox(height: 14),
          _bodyField('Notes (optional)', isDark, text, sub),
          _calendarAndReminderSection(text, sub, accent, isDark),
        ];
      case EntryKind.event:
        return [
          _label('STARTS', sub),
          _whenRow(text, sub, accent),
          const SizedBox(height: 14),
          _label('DURATION', sub),
          _chips(const ['15 min', '30 min', '45 min', '1 h', '1.5 h', '2 h', '3 h'], _durationLabel(_duration),
              (v) => setState(() => _duration = _durationFrom(v)), text),
          const SizedBox(height: 14),
          _bodyField('Notes (optional)', isDark, text, sub),
          _calendarAndReminderSection(text, sub, accent, isDark),
        ];
      case EntryKind.outfit:
        return [
          if (_garmentImagePath != null && _garmentImagePath!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    color: isDark ? Colors.black26 : Colors.black12,
                    child: _buildLocalOrRemoteImage(_garmentImagePath!),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: InkWell(
                      onTap: () => setState(() => _garmentImagePath = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: edBox(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: edBox(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: edBox(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isAnalyzingGarment
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: accent))
                      : Icon(LucideIcons.sparkles, size: 16, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Garment Recognition', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: text)),
                      Text(
                        _isAnalyzingGarment ? 'Analyzing fabric, color & garment cut...' : 'Upload photo to auto-detect piece, fabric & style',
                        style: GoogleFonts.dmSans(fontSize: 11, color: sub),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isAnalyzingGarment
                      ? null
                      : () async {
                          final media = await DeviceMediaService().pickImage();
                          if (mounted && media != null) {
                            setState(() {
                              _isAnalyzingGarment = true;
                              _garmentImagePath = media.path;
                            });
                            try {
                              final analysis = await WardrobeClassifier.analyzeGarment(filePath: media.path, fileName: media.name);
                              if (mounted) {
                                setState(() {
                                  if (_title.text.isEmpty || _title.text == 'Outfit') {
                                    _title.text = analysis.suggestedTitle;
                                  }
                                  if (_a.text.isEmpty) _a.text = analysis.suggestedItems;
                                  if (_b.text.isEmpty) _b.text = analysis.weather;
                                  if (_c.text.isEmpty) _c.text = analysis.fabric;
                                  if (_body.text.isEmpty) _body.text = analysis.occasion;
                                  _isAnalyzingGarment = false;
                                });
                                SanctuaryHapticEngine.sealImpression();
                                AppToastEngine().showToast(
                                  context,
                                  title: '✨ AI Garment Identified',
                                  message: '${analysis.color} ${analysis.productType} · ${analysis.fabric}',
                                );
                              }
                            } catch (_) {
                              if (mounted) {
                                setState(() => _isAnalyzingGarment = false);
                              }
                            }
                          }
                        },
                  icon: const Icon(LucideIcons.camera, size: 14),
                  label: const Text('Scan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _field(_a, 'Pieces, e.g. Linen shirt · Chinos · Loafers', icon: LucideIcons.shirt),
          const SizedBox(height: 12),
          _field(_b, 'Weather, e.g. Sunny · 24°C', icon: LucideIcons.sun),
          const SizedBox(height: 12),
          _field(_c, 'Main fabric, e.g. Linen', icon: LucideIcons.layers),
          const SizedBox(height: 12),
          _field(_body, 'Occasion, e.g. College Casual', icon: LucideIcons.tag),
        ];
      case EntryKind.expense:
        return [
          _amountField(currency, 'Amount'),
          const SizedBox(height: 14),
          _label('CATEGORY', sub),
          _chips(expenseCategories, _choice, (v) => _pick('choice', v), text),
          _aiHint('choice', _choice),
          const SizedBox(height: 14),
          _label('DATE', sub),
          _dateButton(_date, 'Pick date', (d) => setState(() => _date = d), text, accent),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _recurring,
            onChanged: (v) => setState(() => _recurring = v),
            title: Text('Repeats every month', style: GoogleFonts.dmSans(fontSize: 13, color: text)),
            subtitle: Text('Rent, bills, subscriptions. A copy is added on this day each month.',
                style: GoogleFonts.dmSans(fontSize: 11.5, color: sub)),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                backgroundColor: accent.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final media = await DeviceMediaService().pickImage();
                if (mounted && media != null) {
                  setState(() {
                    _body.text = _body.text.isEmpty ? 'Receipt: ${media.name}' : '${_body.text} · Receipt: ${media.name}';
                  });
                  if (mounted) {
                    AppToastEngine().showToast(
                      context,
                      title: 'Receipt Attached',
                      message: 'Attached: ${media.name}',
                    );
                  }
                }
              },
              icon: const Icon(LucideIcons.uploadCloud, size: 13),
              label: Text('Upload Receipt from Device', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 6),
          _bodyField('Note (optional)', isDark, text, sub),
        ];
      case EntryKind.trip:
        return [
          if (_coverUrl != null && _coverUrl!.isNotEmpty) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: AnyImage(_coverUrl!, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () => setState(() => _coverUrl = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          _field(_a, 'Destination', icon: LucideIcons.mapPin, required: true),
          const SizedBox(height: 12),
          _field(_b, 'Flight / train number (optional)', icon: LucideIcons.plane),
          const SizedBox(height: 14),
          _label('DATES', sub),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _dateButton(_date, 'Start date', (d) {
                setState(() {
                  _date = d;
                  if (_endDate != null && _endDate!.isBefore(d)) _endDate = d;
                });
              }, text, accent),
              _dateButton(_endDate, 'End date', (d) => setState(() => _endDate = d), text, accent, first: _date),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: text,
                  side: BorderSide(color: isDark ? const Color(0xFF262320) : const Color(0xFFE6DED6)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _pickCoverPhoto,
                icon: Icon(LucideIcons.image, size: 13, color: sub),
                label: Text(_coverUrl != null ? 'Change Cover' : 'Add Cover Banner', style: GoogleFonts.dmSans(fontSize: 12, color: text)),
              ),
            ],
          ),
        ];
      case EntryKind.memoir:
        final isVoiceMemoir = _title.text.contains('🎙️') || _body.text.contains('🎙️') || _b.text.contains('🎙️');
        return [
          if (isVoiceMemoir) ...[
            AudioCassettePlayer(
              title: _title.text.isNotEmpty ? _title.text : 'Voice Reflection',
              totalDuration: AudioCassettePlayer.parseDuration('${_title.text} ${_body.text} ${_b.text}'),
            ),
            const SizedBox(height: 10),
          ],
          _label('MOOD', sub),
          _chips(memoirMoods, _choice, (v) => _pick('choice', v), text),
          _aiHint('choice', _choice),
          const SizedBox(height: 14),
          _bodyField('What happened today?', isDark, text, sub, minLines: 10, required: true),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _private,
            onChanged: (v) => setState(() => _private = v),
            title: Text('Keep in the private vault', style: GoogleFonts.dmSans(fontSize: 13, color: text)),
            subtitle: Text('Hidden from the journal list; opens with your app PIN.',
                style: GoogleFonts.dmSans(fontSize: 11.5, color: sub)),
          ),
        ];
      case EntryKind.pin:
        return [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Image source', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.1, color: sub)),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  backgroundColor: accent.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final media = await DeviceMediaService().pickImage();
                  if (mounted && media != null) {
                    setState(() {
                      _a.text = media.path;
                      if (_title.text.isEmpty) _title.text = media.name;
                    });
                    if (mounted) {
                      AppToastEngine().showToast(
                        context,
                        title: 'Photo Selected',
                        message: 'Attached: ${media.name}',
                      );
                    }
                    if (media.bytes != null && SanctuarySupabaseService().isConnectedToCloud) {
                      unawaited(() async {
                        try {
                          final cloudRes = await CloudinaryMediaService().uploadBytes(
                            bytes: media.bytes!,
                            filename: media.name.isNotEmpty ? media.name : 'pin_${DateTime.now().millisecondsSinceEpoch}.jpg',
                            category: 'moodboard',
                          );
                          if (cloudRes != null && cloudRes.secureUrl.isNotEmpty && mounted) {
                            setState(() {
                              _a.text = cloudRes.secureUrl;
                            });
                            AppToastEngine().notifyAnimated(
                              title: 'Cloud Synced',
                              message: 'Permanent CDN image link secured.',
                              type: ToastType.success,
                            );
                          }
                        } catch (e) {
                          debugPrint('[EntryEditor] Cloudinary background sync deferred: $e');
                        }
                      }());
                    }
                  }
                },
                icon: const Icon(LucideIcons.uploadCloud, size: 13),
                label: Text('Upload from Device', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _field(_a, 'Image link or device photo path', icon: LucideIcons.image, required: true, validator: (v) {
            final t = (v ?? '').trim();
            if (t.isEmpty) return 'Please provide an image link or upload from device';
            return null;
          }),
          const SizedBox(height: 12),
          _bodyField('Why you saved it (optional)', isDark, text, sub),
        ];
      case EntryKind.habit:
        final parsed = DateTime.tryParse('2000-01-01 ${_to24(_choice)}');
        final currentTod = parsed == null ? const TimeOfDay(hour: 8, minute: 0) : TimeOfDay.fromDateTime(parsed);
        return [
          _label('REMIND ME AT (CLOCK DIAL)', sub),
          const SizedBox(height: 6),
          Row(
            children: [
              HorologicalClockBadge(
                time: currentTod,
                label: 'Habit Time',
                onTimeChanged: (t) {
                  setState(() => _choice = DateLabels.time(DateTime(2000, 1, 1, t.hour, t.minute)));
                },
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: Icon(LucideIcons.clock, size: 14, color: accent),
                label: Text('Change on Clock', style: GoogleFonts.dmSans(color: text, fontSize: 12)),
                onPressed: () async {
                  final t = await showSanctuaryClockPicker(
                    context: context,
                    initialTime: currentTod,
                    helpText: 'SELECT HABIT TIME',
                  );
                  if (t == null) return;
                  setState(() => _choice = DateLabels.time(DateTime(2000, 1, 1, t.hour, t.minute)));
                },
              ),
            ],
          ),
        ];
      case EntryKind.shopping:
        return [
          _field(_a, 'Store (optional)', icon: LucideIcons.store),
          const SizedBox(height: 12),
          _amountField(currency, 'Estimated price'),
          const SizedBox(height: 12),
          _field(_buyingLink, 'Buying link / Web URL (optional)', icon: LucideIcons.externalLink),
        ];
    }
  }

  Widget _buildLocalOrRemoteImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Icon(LucideIcons.image, color: Colors.grey)),
      );
    }
    try {
      final f = File(path);
      if (f.existsSync()) {
        return Image.file(
          f,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(child: Icon(LucideIcons.image, color: Colors.grey)),
        );
      }
    } catch (_) {}
    return const Center(child: Icon(LucideIcons.image, color: Colors.grey));
  }

  DateTime _calculateReminderTime(DateTime base, String offset) {
    switch (offset) {
      case '15m_before':
        return base.subtract(const Duration(minutes: 15));
      case '1h_before':
        return base.subtract(const Duration(hours: 1));
      case '1d_before':
        return base.subtract(const Duration(days: 1));
      case 'at_time':
      default:
        return base;
    }
  }

  Widget _reminderOffsetChip(String label, String value, Color text, Color accent) {
    final sel = _reminderOffset == value;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      selected: sel,
      selectedColor: accent.withValues(alpha: 0.2),
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _reminderOffset = value);
      },
    );
  }

  Widget _calendarAndReminderSection(Color text, Color sub, Color accent, bool isDark) {
    final targetBase = _date ?? DateTime.now();
    final baseWithClock = DateTime(
      targetBase.year,
      targetBase.month,
      targetBase.day,
      _reminderClockTime.hour,
      _reminderClockTime.minute,
    );
    final alertTime = _calculateReminderTime(baseWithClock, _reminderOffset);
    final isTomorrow = alertTime.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: edBox(
        color: isDark ? const Color(0xFF141210) : const Color(0xFFFAF7F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF262220) : const Color(0xFFE5DDD0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.bellRing, size: 14, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    'Device system reminder',
                    style: GoogleFonts.dmSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.1,
                      color: sub,
                    ),
                  ),
                ],
              ),
              Switch.adaptive(
                value: _setDeviceReminder,
                activeColor: accent,
                onChanged: (v) {
                  SanctuaryHapticEngine.dialDetent();
                  setState(() => _setDeviceReminder = v);
                },
              ),
            ],
          ),
          if (_setDeviceReminder) ...[
            const SizedBox(height: 10),
            Text(
              'Select reminder time on clock:',
              style: GoogleFonts.dmSans(fontSize: 11, color: sub),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                HorologicalClockBadge(
                  time: _reminderClockTime,
                  label: 'Reminder Clock',
                  onTimeChanged: (t) {
                    setState(() {
                      _reminderClockTime = t;
                      if (_date != null) {
                        _date = DateTime(_date!.year, _date!.month, _date!.day, t.hour, t.minute);
                      }
                    });
                  },
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: text,
                    side: BorderSide(color: accent.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  icon: Icon(LucideIcons.clock, size: 13, color: accent),
                  label: Text('Open Clock Dial', style: GoogleFonts.dmSans(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  onPressed: () async {
                    final t = await showSanctuaryClockPicker(
                      context: context,
                      initialTime: _reminderClockTime,
                      helpText: 'SELECT REMINDER CLOCK',
                    );
                    if (t != null) {
                      setState(() {
                        _reminderClockTime = t;
                        if (_date != null) {
                          _date = DateTime(_date!.year, _date!.month, _date!.day, t.hour, t.minute);
                        }
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Alert timing offset:',
              style: GoogleFonts.dmSans(fontSize: 11, color: sub),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _reminderOffsetChip('At clock time', 'at_time', text, accent),
                _reminderOffsetChip('15m before', '15m_before', text, accent),
                _reminderOffsetChip('1h before', '1h_before', text, accent),
                _reminderOffsetChip('1 day before', '1d_before', text, accent),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: edBox(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.bell, size: 12, color: accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Alarm will ring on-device ${isTomorrow ? "tomorrow" : "today"} at ${DateLabels.time(alertTime)}',
                      style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, color: text),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: text,
                side: BorderSide(color: accent.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 9),
              ),
              onPressed: () async {
                SanctuaryHapticEngine.dialDetent();
                final title = _title.text.trim().isEmpty ? 'Untitled Task' : _title.text.trim();
                final base = _date ?? DateTime.now();
                final start = DateTime(base.year, base.month, base.day, _reminderClockTime.hour, _reminderClockTime.minute);
                final end = start.add(Duration(minutes: _duration > 0 ? _duration : 60));
                final ok = await CalendarReminderService().addToGoogleCalendar(
                  title: title,
                  startTime: start,
                  endTime: end,
                  description: _body.text.trim(),
                );
                if (mounted) {
                  AppToastEngine().showToast(
                    context,
                    title: ok ? 'Google Calendar' : 'Calendar Notice',
                    message: ok
                        ? 'Opening Google Calendar with "$title" prefilled.'
                        : 'Unable to launch Google Calendar.',
                    type: ok ? ToastType.success : ToastType.alert,
                  );
                }
              },
              icon: Icon(LucideIcons.calendarPlus, size: 14, color: accent),
              label: Text(
                'Add to Google Calendar',
                style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: text),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _to24(String label) {
    final m = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false).firstMatch(label);
    if (m == null) return '08:00';
    var h = int.parse(m.group(1)!) % 12;
    if (m.group(3)!.toUpperCase() == 'PM') h += 12;
    return '${h.toString().padLeft(2, '0')}:${m.group(2)}';
  }

  static String _durationLabel(int minutes) => switch (minutes) {
        15 => '15 min',
        30 => '30 min',
        45 => '45 min',
        60 => '1 h',
        90 => '1.5 h',
        120 => '2 h',
        180 => '3 h',
        _ => '$minutes min',
      };

  static int _durationFrom(String label) => switch (label) {
        '15 min' => 15,
        '30 min' => 30,
        '45 min' => 45,
        '1.5 h' => 90,
        '2 h' => 120,
        '3 h' => 180,
        _ => 60,
      };

  Widget _label(String s, Color sub) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(s, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: sub)),
      );

  Widget _chips(List<String> options, String selected, ValueChanged<String> onSelect, Color text) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((o) {
        final sel = o == selected;
        return ChoiceChip(
          label: Text(o, style: TextStyle(fontSize: 11, color: sel ? Colors.white : text)),
          selected: sel,
          selectedColor: AppColors.secondary,
          onSelected: (_) => onSelect(o),
        );
      }).toList(),
    );
  }

  Widget _field(TextEditingController c, String hint,
      {IconData? icon, bool required = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: icon == null ? null : Icon(icon, size: 16),
        border: const OutlineInputBorder(),
      ),
      validator: validator ?? (required ? (v) => (v ?? '').trim().isEmpty ? 'Required' : null : null),
    );
  }

  Widget _amountField(String currency, String label) {
    return TextFormField(
      controller: _amount,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(labelText: label, prefixText: '$currency ', border: const OutlineInputBorder()),
      validator: (v) {
        final amount = double.tryParse((v ?? '').replaceAll(',', '').trim());
        if (amount == null) return 'Enter an amount';
        if (amount <= 0) return 'Amount must be more than zero';
        if (amount > 100000000) return 'That amount looks too large';
        return null;
      },
    );
  }

  Future<void> _pickAndInsertImage() async {
    try {
      final List<PlatformFile> files = await FilePicker.pickFiles(type: FileType.image);
      if (files.isNotEmpty && files.first.path != null) {
        final path = files.first.path!;
        final imageMarkdown = '\n\n![Image]($path)\n';
        final text = _body.text;
        final sel = _body.selection;
        final start = sel.isValid ? sel.start.clamp(0, text.length) : text.length;
        _body.value = TextEditingValue(
          text: text.replaceRange(start, start, imageMarkdown),
          selection: TextSelection.collapsed(offset: start + imageMarkdown.length),
        );
      }
    } catch (_) {}
  }

  bool get _hasMarkdownToolbar => widget.kind == EntryKind.note || widget.kind == EntryKind.memoir;

  Widget _bodyField(String hint, bool isDark, Color text, Color sub, {int minLines = 4, bool required = false}) {
    final docked = MediaQuery.viewInsetsOf(context).bottom > 0 && _bodyFocus.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // While typing, the toolbar docks above the keyboard instead (see build).
        if (_hasMarkdownToolbar && !docked) ...[
          MarkdownAccessoryToolbar(
            controller: _body,
            onAttachImage: _pickAndInsertImage,
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: _body,
          focusNode: _bodyFocus,
          minLines: minLines,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          // Keep a few lines of breathing room between the caret and the keyboard edge.
          scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 72),
          style: GoogleFonts.dmSans(fontSize: 14, color: text, height: 1.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(fontSize: 14, color: sub.withValues(alpha: 0.6)),
            filled: true,
            fillColor: isDark ? const Color(0xFF080808) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          validator: required ? (v) => (v ?? '').trim().isEmpty ? 'Write a few words' : null : null,
        ),
      ],
    );
  }

  Widget _dateButton(DateTime? value, String placeholder, ValueChanged<DateTime> onPicked, Color text, Color accent,
      {DateTime? first}) {
    return OutlinedButton.icon(
      icon: Icon(LucideIcons.calendar, size: 14, color: accent),
      label: Text(value == null ? placeholder : DateLabels.long(value), style: GoogleFonts.dmSans(color: text)),
      onPressed: () async {
        final d = await _pickDate(value, first: first);
        if (d != null) onPicked(d);
      },
    );
  }

  /// Natural-language entry plus dedicated horological date & clock dial pickers; used for task due dates and event starts.
  Widget _whenRow(Color text, Color sub, Color accent, {bool allowClear = false}) {
    final curTime = _date != null ? TimeOfDay.fromDateTime(_date!) : _reminderClockTime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              icon: Icon(LucideIcons.calendar, size: 14, color: accent),
              label: Text(_date == null ? 'Set Date' : DateLabels.long(_date!), style: GoogleFonts.dmSans(color: text)),
              onPressed: () async {
                final d = await _pickDate(_date);
                if (mounted && d != null) {
                  setState(() {
                    _date = DateTime(d.year, d.month, d.day, curTime.hour, curTime.minute);
                  });
                }
              },
            ),
            OutlinedButton.icon(
              icon: Icon(LucideIcons.clock, size: 14, color: accent),
              label: Text(
                _date == null ? 'Clock Time (${curTime.format(context)})' : DateLabels.time(_date!),
                style: GoogleFonts.dmSans(color: text),
              ),
              onPressed: () async {
                final t = await showSanctuaryClockPicker(
                  context: context,
                  initialTime: curTime,
                  helpText: 'SELECT DUE TIME',
                );
                if (t != null) {
                  setState(() {
                    _reminderClockTime = t;
                    final base = _date ?? DateTime.now();
                    _date = DateTime(base.year, base.month, base.day, t.hour, t.minute);
                  });
                }
              },
            ),
            if (allowClear && _date != null)
              TextButton(onPressed: () => setState(() => _date = null), child: const Text('Clear')),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _when,
          style: GoogleFonts.dmSans(fontSize: 13, color: text),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'or type: "tomorrow 3pm", "fri 9:30", "in 2 hours"',
            prefixIcon: const Icon(LucideIcons.sparkles, size: 14),
            border: const OutlineInputBorder(),
            errorText: _whenHint,
          ),
          onChanged: _applyWhenText,
        ),
      ],
    );
  }
}
