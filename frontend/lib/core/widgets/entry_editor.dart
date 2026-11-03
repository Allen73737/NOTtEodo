import '../ai/ai_widgets.dart';
import '../ai/smart_classifier.dart';
import '../services/device_media_service.dart';
import '../services/ai_copilot_service.dart';
import 'app_toast_engine.dart';
import 'workflow_evolution_dialog.dart';
import 'pressure_test_dialog.dart';
import '../../features/notes/presentation/notes_rag_modal.dart';
import '../services/document_ingestion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../motion/motion.dart';
import '../services/nlp_date_parser.dart';
import '../state/app_settings.dart';
import '../state/sanctuary_state.dart';
import '../utils/date_labels.dart';
import 'stitch_logo_widget.dart';

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

/// Opens the editor as a full-screen sheet. Pass [editing] to change an existing item.
Future<void> openEntryEditor(BuildContext context, EntryKind kind, {Object? editing, DateTime? initialDate}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, __) => EntryEditor(
      kind: kind,
      editing: editing,
      initialDate: initialDate,
      onClose: () => Navigator.of(ctx).pop(),
    ),
    transitionBuilder: (ctx, anim, _, child) => FadeTransition(
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
  final VoidCallback onClose;
  final ValueChanged<String>? onSaved;

  const EntryEditor({
    super.key,
    required this.kind,
    required this.onClose,
    this.editing,
    this.initialDate,
    this.onSaved,
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

  String _choice = '';
  String _choice2 = '';
  DateTime? _date;
  DateTime? _endDate;
  TaskRepeat _repeat = TaskRepeat.none;
  int _duration = 60;
  bool _private = false;
  String? _whenHint;

  // --- On-device AI suggestions ---------------------------------------------
  /// Fields the user chose by hand; AI never overrides these.
  final Set<String> _touched = {};

  /// Current suggestion per field ('choice', 'choice2').
  final Map<String, Suggestion> _suggestions = {};
  List<String> _tagIdeas = const [];

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
        _tagIdeas = body.length < 20
            ? const []
            : NoteTagger.suggestTags('$title $body', corpus: [for (final n in notes) '${n.title} ${n.body}'])
                .where((t) => t.toLowerCase() != _a.text.trim().toLowerCase())
                .toList();
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

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _wireSuggestions();
    switch (widget.kind) {
      case EntryKind.note:
        final n = e as NoteItem?;
        _title.text = n?.title ?? '';
        _body.text = n?.body ?? '';
        _a.text = n?.tag ?? '';
        _choice = n?.space ?? noteSpaces.first;
      case EntryKind.task:
        final t = e as TaskItem?;
        _title.text = t?.title ?? '';
        _body.text = t?.notes ?? '';
        _choice = t?.priority ?? 'Medium Priority';
        _choice2 = t?.space ?? 'General Space';
        _date = t?.dueAt ?? widget.initialDate;
        _repeat = t?.repeat ?? TaskRepeat.none;
      case EntryKind.event:
        final ev = e as PlannerEvent?;
        _title.text = ev?.title ?? '';
        _body.text = ev?.notes ?? '';
        _date = ev?.startsAt ?? widget.initialDate ?? _nextHour();
        _duration = ev?.durationMinutes ?? 60;
      case EntryKind.outfit:
        final o = e as WardrobeOutfit?;
        _title.text = o?.title ?? '';
        _a.text = o?.items ?? '';
        _b.text = o?.weather ?? '';
        _c.text = o?.fabric ?? '';
        _body.text = o?.tag ?? '';
      case EntryKind.expense:
        final x = e as ExpenseItem?;
        _title.text = x?.title ?? '';
        _amount.text = x == null ? '' : _trimZeros(x.amount);
        _choice = x?.category ?? 'General';
        _body.text = x?.note ?? '';
        _date = x?.spentAt ?? DateTime.now();
      case EntryKind.trip:
        final t = e as TravelTrip?;
        _title.text = t?.title ?? '';
        _a.text = t?.destination ?? '';
        _b.text = t?.flight ?? '';
        _date = t?.startDate;
        _endDate = t?.endDate;
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
    for (final c in [_title, _body, _a, _b, _c, _amount, _when]) {
      c.dispose();
    }
    super.dispose();
  }

  // --- Saving ----------------------------------------------------------------

  double? get _parsedAmount => double.tryParse(_amount.text.replaceAll(',', '').trim());

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final title = _title.text.trim();
    final body = _body.text.trim();
    final e = widget.editing;

    switch (widget.kind) {
      case EntryKind.note:
        final n = ref.read(notesProvider.notifier);
        if (e is NoteItem) {
          n.updateNote(e.id, title: title, space: _choice, tag: _a.text.trim().isEmpty ? 'Note' : _a.text.trim(), content: body);
        } else {
          n.addNote(title: title, space: _choice, tag: _a.text.trim(), excerpt: '', content: body);
        }
      case EntryKind.task:
        final n = ref.read(tasksProvider.notifier);
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
      case EntryKind.event:
        final n = ref.read(eventsProvider.notifier);
        if (e is PlannerEvent) {
          n.updateEvent(e.id, title: title, startsAt: _date, durationMinutes: _duration, notes: body);
        } else {
          n.addEvent(title: title, startsAt: _date!, durationMinutes: _duration, notes: body);
        }
      case EntryKind.outfit:
        final n = ref.read(wardrobeProvider.notifier);
        final items = _a.text.trim(), weather = _b.text.trim(), fabric = _c.text.trim();
        final tag = body.isEmpty ? 'Casual' : body;
        if (e is WardrobeOutfit) {
          n.updateOutfit(e.id, title: title, items: items, weather: weather, fabric: fabric, tag: tag);
        } else {
          n.addOutfit(
            title: title,
            items: items.isEmpty ? null : items,
            weather: weather.isEmpty ? null : weather,
            fabric: fabric.isEmpty ? null : fabric,
            tag: tag,
          );
        }
      case EntryKind.expense:
        final n = ref.read(expensesProvider.notifier);
        final amount = _parsedAmount!;
        if (e is ExpenseItem) {
          n.updateExpense(e.id, title: title, amount: amount, category: _choice, note: body, spentAt: _date);
        } else {
          n.addExpense(title: title, amount: amount, category: _choice, note: body, spentAt: _date);
          _warnIfOverBudget();
        }
      case EntryKind.trip:
        final n = ref.read(travelProvider.notifier);
        if (e is TravelTrip) {
          n.updateTrip(e.id, title: title, destination: _a.text.trim(), flight: _b.text.trim(), startDate: _date, endDate: _endDate);
        } else {
          n.addTrip(title: title, destination: _a.text.trim(), flight: _b.text.trim(), startDate: _date, endDate: _endDate);
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
        if (e is MoodboardPin) {
          n.updatePin(e.id, title: title, imageUrl: _a.text.trim(), note: body);
        } else {
          n.addPin(title: title, imageUrl: _a.text.trim(), note: body);
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
        if (e is ShoppingItem) {
          n.updateItem(e.id, name: title, store: _a.text.trim(), price: price);
        } else {
          n.addItem(name: title, store: _a.text.trim(), price: price);
        }
    }

    HapticFeedback.lightImpact();
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

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final day = await _pickDate(initial);
    if (day == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? _nextHour()),
    );
    if (time == null) return DateTime(day.year, day.month, day.day, (initial ?? _nextHour()).hour);
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
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
    final accent = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    final kindLabel = widget.kind.label;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        SingleActivator(LogicalKeyboardKey.enter, control: true): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter, meta: true): ActivateIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(onInvoke: (_) => widget.onClose()),
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _save()),
        },
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                      Text(_isEdit ? 'EDIT' : 'NEW ENTRY',
                                          style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: accent)),
                                      Text(kindLabel,
                                          style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: text),
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Close',
                                  icon: Icon(LucideIcons.x, color: text, size: 22),
                                  onPressed: widget.onClose,
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5DFC9)),
                          Expanded(
                            child: SingleChildScrollView(
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
                                      hintText: widget.kind == EntryKind.shopping ? 'Item name' : '$kindLabel title',
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
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            color: isDark ? const Color(0xFF000000) : AppColors.surfaceContainerHigh,
                            child: Row(
                              children: [
                                if (_isEdit)
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
    );
  }

  List<Widget> _fieldsFor(Color text, Color sub, Color accent, bool isDark) {
    final currency = ref.watch(appSettingsProvider.select((s) => s.currencySymbol));
    switch (widget.kind) {
      case EntryKind.note:
        return [
          _label('SPACE', sub),
          _chips(noteSpaces, _choice, (v) => _pick('choice', v), text),
          _aiHint('choice', _choice),
          const SizedBox(height: 14),
          _field(_a, 'Tag (optional)', icon: LucideIcons.tag),
          if (_tagIdeas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in _tagIdeas)
                    AiSuggestionChip(
                      suggestion: Suggestion(t, 0.6, 'A distinctive word in this note'),
                      label: t,
                      onApply: () => setState(() {
                        _a.text = t;
                        _tagIdeas = _tagIdeas.where((x) => x != t).toList();
                      }),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          // Note Actions & AI Tooling Bar
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
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
                icon: const Icon(LucideIcons.brain, size: 13),
                label: Text(
                  'Note RAG AI',
                  style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: accent.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final doc = await DocumentIngestionService().pickAndParseDocument();
                  if (doc != null) {
                    setState(() {
                      if (_title.text.isEmpty) _title.text = doc.title;
                      _body.text = _body.text.isEmpty ? doc.content : '${_body.text}\n\n${doc.content}';
                      if (_a.text.isEmpty && doc.extension.isNotEmpty) _a.text = doc.extension.toUpperCase();
                    });
                    if (context.mounted) {
                      AppToastEngine().showToast(
                        context,
                        title: 'Document Ingested',
                        message: 'Ingested ${doc.fileName} (${doc.content.length} characters).',
                      );
                    }
                  }
                },
                icon: const Icon(LucideIcons.fileUp, size: 13),
                label: Text(
                  'Import Doc',
                  style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: accent.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final media = await DeviceMediaService().pickImage();
                  if (media != null) {
                    setState(() {
                      final tag = '\n\n📎 Attachment: ${media.name} (${media.path})';
                      _body.text = '${_body.text}$tag';
                    });
                    if (context.mounted) {
                      AppToastEngine().showToast(
                        context,
                        title: 'Attachment Added',
                        message: 'Attached: ${media.name}',
                      );
                    }
                  }
                },
                icon: const Icon(LucideIcons.paperclip, size: 13),
                label: Text(
                  'Attach File',
                  style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final bodyText = _body.text.trim();
                  if (bodyText.isEmpty) {
                    AppToastEngine().showToast(
                      context,
                      title: 'Empty Note',
                      message: 'Write some note content first to evolve workflows.',
                    );
                    return;
                  }
                  HapticFeedback.selectionClick();
                  showWorkflowEvolutionDialog(
                    context,
                    title: _title.text.trim().isNotEmpty ? _title.text.trim() : 'Untitled Thought',
                    content: bodyText,
                  );
                },
                icon: const Icon(LucideIcons.arrowUpRight, size: 13),
                label: Text(
                  'Evolve Workflows',
                  style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFF59E0B),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final bodyText = _body.text.trim();
                  if (bodyText.isEmpty) {
                    AppToastEngine().showToast(
                      context,
                      title: 'Empty Note',
                      message: 'Write some thoughts first to pressure-test.',
                    );
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
                icon: const Icon(LucideIcons.zap, size: 13),
                label: Text(
                  'Pressure Test',
                  style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: accent.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final bodyText = _body.text.trim();
                  if (bodyText.isEmpty) {
                    AppToastEngine().showToast(
                      context,
                      title: 'Empty Note',
                      message: 'Please write some note content first to summarize.',
                    );
                    return;
                  }
                  HapticFeedback.selectionClick();
                  final res = await AiCopilotService().summarizeNoteAndExtractActions(bodyText);
                  if (res.actionItems.isNotEmpty || res.summary.isNotEmpty) {
                    setState(() {
                      final buf = StringBuffer(bodyText);
                      if (res.summary.isNotEmpty) {
                        buf.writeln('\n\n📌 **Executive Summary**: ' + res.summary);
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
                    if (!mounted) return;
                    AppToastEngine().showToast(
                      context,
                      title: 'Note Enhanced',
                      message: 'Summary & ${res.actionItems.length} action items extracted.',
                    );
                  }
                },
                icon: const Icon(LucideIcons.sparkles, size: 13),
                label: Text(
                  'Summarize',
                  style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _bodyField('Write your note…', isDark, text, sub, minLines: 10),
        ];
      case EntryKind.task:
        return [
          _label('PRIORITY', sub),
          _chips(taskPriorities, _choice, (v) => _pick('choice', v), text),
          _aiHint('choice', _choice),
          const SizedBox(height: 14),
          _label('SPACE', sub),
          _chips(noteSpaces, _choice2, (v) => _pick('choice2', v), text),
          _aiHint('choice2', _choice2),
          const SizedBox(height: 14),
          _label('DUE', sub),
          _whenRow(text, sub, accent, allowClear: true),
          const SizedBox(height: 14),
          _label('REPEAT', sub),
          _chips(TaskRepeat.values.map((r) => r.label).toList(), _repeat.label,
              (v) => setState(() => _repeat = TaskRepeat.values.firstWhere((r) => r.label == v)), text),
          const SizedBox(height: 14),
          _bodyField('Notes (optional)', isDark, text, sub),
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
        ];
      case EntryKind.outfit:
        return [
          _field(_a, 'Pieces, e.g. Linen shirt · Chinos · Loafers', icon: LucideIcons.shirt),
          const SizedBox(height: 12),
          _field(_b, 'Weather, e.g. Sunny · 24°C', icon: LucideIcons.sun),
          const SizedBox(height: 12),
          _field(_c, 'Main fabric, e.g. Linen', icon: LucideIcons.layers),
          const SizedBox(height: 12),
          _field(_body, 'Occasion, e.g. College Casual', icon: LucideIcons.tag),
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
                if (media != null) {
                  setState(() {
                    _body.text = _body.text.isEmpty ? 'Photo: ${media.name}' : '${_body.text} · Photo: ${media.name}';
                  });
                  if (context.mounted) {
                    AppToastEngine().showToast(
                      context,
                      title: 'Garment Photo Attached',
                      message: 'Attached: ${media.name}',
                    );
                  }
                }
              },
              icon: const Icon(LucideIcons.camera, size: 13),
              label: Text('Upload Garment Photo', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
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
                if (media != null) {
                  setState(() {
                    _body.text = _body.text.isEmpty ? 'Receipt: ${media.name}' : '${_body.text} · Receipt: ${media.name}';
                  });
                  if (context.mounted) {
                    AppToastEngine().showToast(
                      context,
                      title: 'Receipt Attached',
                      message: 'Attached: ${media.name}',
                    );
                  }
                }
              },
              icon: const Icon(LucideIcons.uploadCloud, size: 13),
              label: Text('Upload Receipt from Device', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 6),
          _bodyField('Note (optional)', isDark, text, sub),
        ];
      case EntryKind.trip:
        return [
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
            ],
          ),
        ];
      case EntryKind.memoir:
        return [
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
              Text('IMAGE SOURCE', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: sub)),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  backgroundColor: accent.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final media = await DeviceMediaService().pickImage();
                  if (media != null) {
                    setState(() {
                      _a.text = media.path;
                      if (_title.text.isEmpty) _title.text = media.name;
                    });
                    if (context.mounted) {
                      AppToastEngine().showToast(
                        context,
                        title: 'Photo Selected',
                        message: 'Attached: ${media.name}',
                      );
                    }
                  }
                },
                icon: const Icon(LucideIcons.uploadCloud, size: 13),
                label: Text('Upload from Device', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold)),
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
        return [
          _label('REMIND ME AT', sub),
          OutlinedButton.icon(
            icon: Icon(LucideIcons.clock, size: 14, color: accent),
            label: Text(_choice, style: GoogleFonts.dmSans(color: text)),
            onPressed: () async {
              final parsed = DateTime.tryParse('2000-01-01 ${_to24(_choice)}');
              final t = await showTimePicker(
                context: context,
                initialTime: parsed == null ? const TimeOfDay(hour: 8, minute: 0) : TimeOfDay.fromDateTime(parsed),
              );
              if (t == null) return;
              setState(() => _choice = DateLabels.time(DateTime(2000, 1, 1, t.hour, t.minute)));
            },
          ),
        ];
      case EntryKind.shopping:
        return [
          _field(_a, 'Store (optional)', icon: LucideIcons.store),
          const SizedBox(height: 12),
          _amountField(currency, 'Estimated price'),
        ];
    }
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

  Widget _bodyField(String hint, bool isDark, Color text, Color sub, {int minLines = 4, bool required = false}) {
    return TextFormField(
      controller: _body,
      minLines: minLines,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      style: GoogleFonts.dmSans(fontSize: 14, color: text, height: 1.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(fontSize: 14, color: sub.withValues(alpha: 0.6)),
        filled: true,
        fillColor: isDark ? const Color(0xFF080808) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      validator: required ? (v) => (v ?? '').trim().isEmpty ? 'Write a few words' : null : null,
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

  /// Natural-language entry plus a picker; used for task due dates and event starts.
  Widget _whenRow(Color text, Color sub, Color accent, {bool allowClear = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              icon: Icon(LucideIcons.calendarClock, size: 14, color: accent),
              label: Text(_date == null ? 'No due date' : DateLabels.dateTime(_date!), style: GoogleFonts.dmSans(color: text)),
              onPressed: () async {
                final d = await _pickDateTime(_date);
                if (d != null) setState(() => _date = d);
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
