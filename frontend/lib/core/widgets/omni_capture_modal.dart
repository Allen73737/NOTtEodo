import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../performance/sanctuary_motion_engine.dart';
import '../platform/browser_bridge.dart';
import '../services/nlp_date_parser.dart';
import '../state/sanctuary_state.dart';
import '../utils/date_labels.dart';
import 'app_toast_engine.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

enum ParsedIntent { task, expense, habit, note }

/// Omni-Capture Speed Hub: 1-second natural language input that splits thoughts
/// into Tasks, Expenses, Habits, or Notes simultaneously.
class OmniCaptureModal extends ConsumerStatefulWidget {
  const OmniCaptureModal({super.key});

  static Future<void> show(BuildContext context) async {
    SanctuaryHapticEngine.selection();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => const OmniCaptureModal(),
    );
  }

  @override
  ConsumerState<OmniCaptureModal> createState() => _OmniCaptureModalState();
}

class _OmniCaptureModalState extends ConsumerState<OmniCaptureModal> {
  final TextEditingController _inputCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  ParsedIntent _detectedIntent = ParsedIntent.task;
  DateTime? _detectedDate;
  double? _detectedAmount;
  String _detectedCategory = 'General';
  final List<String> _detectedTags = [];
  String _cleanTitle = '';
  bool _isDictating = false;

  Future<void> _dictate() async {
    SanctuaryHapticEngine.selection();
    setState(() => _isDictating = true);
    try {
      final heard = await listenOnce();
      if (!mounted) return;
      if (heard != null && heard.trim().isNotEmpty) {
        setState(() {
          final current = _inputCtrl.text.trim();
          _inputCtrl.text = current.isEmpty ? heard.trim() : '$current ${heard.trim()}';
        });
        _parseInput();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isDictating = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _inputCtrl.addListener(_parseInput);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _inputCtrl.removeListener(_parseInput);
    _inputCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _parseInput() {
    final text = _inputCtrl.text;
    if (text.trim().isEmpty) {
      setState(() {
        _cleanTitle = '';
        _detectedDate = null;
        _detectedAmount = null;
        _detectedTags.clear();
        _detectedIntent = ParsedIntent.task;
      });
      return;
    }

    final lower = text.toLowerCase();

    // 1. Detect tags (#tag)
    final tagRegex = RegExp(r'#(\w+)');
    final tagMatches = tagRegex.allMatches(text);
    final tags = tagMatches.map((m) => m.group(1)!).toList();

    // 2. Detect financial amounts ($45, 45$, 45 eur, etc.)
    final amountRegex = RegExp(r'(?:\$|€|£|₹|\b)(\d+(?:\.\d{1,2})?)\s*(?:\$|€|£|₹|usd|eur|inr|\b)', caseSensitive: false);
    double? amount;
    final match = amountRegex.firstMatch(text);
    if (match != null && (text.contains('\$') || text.contains('€') || text.contains('£') || text.contains('₹') || lower.contains('spent') || lower.contains('bought') || lower.contains('paid') || lower.contains('cost'))) {
      amount = double.tryParse(match.group(1) ?? '');
    }

    // 3. Detect category if expense
    String cat = 'Personal';
    if (lower.contains('coffee') || lower.contains('lunch') || lower.contains('dinner') || lower.contains('food') || lower.contains('grocer') || lower.contains('restaurant')) {
      cat = 'Food & Dining';
    } else if (lower.contains('uber') || lower.contains('cab') || lower.contains('train') || lower.contains('flight') || lower.contains('gas') || lower.contains('fuel')) {
      cat = 'Transportation';
    } else if (lower.contains('rent') || lower.contains('bill') || lower.contains('wifi') || lower.contains('electric')) {
      cat = 'Bills & Utilities';
    } else if (lower.contains('movie') || lower.contains('game') || lower.contains('concert') || lower.contains('book')) {
      cat = 'Entertainment';
    }

    // 4. Detect dates
    final parsedDate = NlpDateParser.parse(text);

    // 5. Determine primary intent
    ParsedIntent intent = ParsedIntent.task;
    if (amount != null && (lower.contains('spent') || lower.contains('bought') || lower.contains('paid') || lower.contains('cost') || text.contains('\$'))) {
      intent = ParsedIntent.expense;
    } else if (lower.contains('daily') || lower.contains('habit') || lower.contains('routine') || lower.contains('everyday')) {
      intent = ParsedIntent.habit;
    } else if (text.length > 70 || lower.startsWith('note:') || lower.startsWith('idea:')) {
      intent = ParsedIntent.note;
    }

    // Clean title by stripping #tags and amount words
    String title = text.replaceAll(tagRegex, '').trim();
    if (title.isEmpty) title = text.trim();

    setState(() {
      _cleanTitle = title;
      _detectedIntent = intent;
      _detectedDate = parsedDate;
      _detectedAmount = amount;
      _detectedCategory = cat;
      _detectedTags
        ..clear()
        ..addAll(tags);
    });
  }

  Future<void> _submit() async {
    final rawText = _inputCtrl.text.trim();
    if (rawText.isEmpty) return;

    SanctuaryHapticEngine.sealImpression();
    Navigator.of(context).pop();

    final title = _cleanTitle.isNotEmpty ? _cleanTitle : rawText;

    if (_detectedIntent == ParsedIntent.expense && _detectedAmount != null) {
      // 1. Save Expense
      ref.read(expensesProvider.notifier).addExpense(
        title: title,
        amount: _detectedAmount!,
        category: _detectedCategory,
        spentAt: _detectedDate ?? DateTime.now(),
      );
      AppToastEngine().notify(
        title: '💰 Expense Logged',
        message: '\$${_detectedAmount!.toStringAsFixed(2)} for "$title" recorded under $_detectedCategory.',
        type: ToastType.success,
      );
    } else if (_detectedIntent == ParsedIntent.habit) {
      // 2. Save Habit
      ref.read(habitsProvider.notifier).addHabit(
        title: title,
        time: 'Morning',
      );
      AppToastEngine().notify(
        title: '🌱 Habit Planted',
        message: '"$title" added to daily ritual track.',
        type: ToastType.success,
      );
    } else if (_detectedIntent == ParsedIntent.note) {
      // 3. Save Note
      ref.read(notesProvider.notifier).addNote(
        title: title.length > 35 ? '${title.substring(0, 32)}...' : title,
        excerpt: rawText,
        content: rawText,
        tag: _detectedTags.isNotEmpty ? _detectedTags.first : 'Quick Capture',
        space: 'Sanctuary Memos',
      );
      AppToastEngine().notify(
        title: '📝 Note Captured',
        message: '"$title" saved to your notes.',
        type: ToastType.success,
      );
    } else {
      // 4. Save Task
      ref.read(tasksProvider.notifier).addTask(
        title: title,
        dueAt: _detectedDate,
        priority: _detectedTags.contains('urgent') ? 'High Priority' : 'Medium Priority',
        notes: _detectedTags.isNotEmpty ? 'Tags: #${_detectedTags.join(' #')}' : '',
      );

      // If an amount was also mentioned in a task, offer dual logging
      if (_detectedAmount != null && _detectedAmount! > 0) {
        ref.read(expensesProvider.notifier).addExpense(
          title: title,
          amount: _detectedAmount!,
          category: _detectedCategory,
          spentAt: _detectedDate ?? DateTime.now(),
        );
      }

      AppToastEngine().notify(
        title: '✓ Priority Captured',
        message: _detectedDate != null
            ? '"$title" due on ${DateLabels.dateOnly(_detectedDate!)}.'
            : '"$title" added to today\'s priorities.',
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const terracotta = Color(0xFFD9725B);
    const gold = Color(0xFFD9725B);
    const sage = Color(0xFFE8927C);
    final cardBg = isDark ? const Color(0xFF141210) : const Color(0xFFFAF8F5);
    final primaryText = isDark ? const Color(0xFFFAF7F0) : const Color(0xFF1C1917);
    final subtextColor = isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            decoration: edBox(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: terracotta.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.7 : 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: terracotta.withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Pill
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: edBox(
                          color: terracotta.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.zap, size: 14, color: terracotta),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'OMNI-CAPTURE SPEED HUB',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: terracotta,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: Icon(LucideIcons.x, size: 16, color: subtextColor),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Main Text Input Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: TextField(
                    controller: _inputCtrl,
                    focusNode: _focusNode,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: primaryText,
                    ),
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Type anything: "Buy groceries \$45 tomorrow #errand" or "Meditation 10m daily"...',
                      hintStyle: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: subtextColor.withValues(alpha: 0.7),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      suffixIcon: IconButton(
                        tooltip: _isDictating ? 'Listening…' : 'Dictate voice',
                        icon: Icon(
                          _isDictating ? LucideIcons.loader : LucideIcons.mic,
                          size: 18,
                          color: _isDictating ? terracotta : terracotta.withValues(alpha: 0.8),
                        ),
                        onPressed: _isDictating ? null : _dictate,
                      ),
                    ),
                  ),
                ),

                // Live Segmented Intelligence Badges
                if (_inputCtrl.text.trim().isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        // Detected Intent Pill
                        _buildIntentPill(_detectedIntent),

                        // Detected Date
                        if (_detectedDate != null)
                          _buildDetailPill(
                            icon: LucideIcons.calendar,
                            label: DateLabels.dateOnly(_detectedDate!),
                            color: gold,
                          ),

                        // Detected Amount
                        if (_detectedAmount != null)
                          _buildDetailPill(
                            icon: LucideIcons.dollarSign,
                            label: '\$${_detectedAmount!.toStringAsFixed(2)} · $_detectedCategory',
                            color: sage,
                          ),

                        // Detected Tags
                        ..._detectedTags.map((tag) => _buildDetailPill(
                              icon: LucideIcons.hash,
                              label: tag,
                              color: terracotta,
                            )),
                      ],
                    ),
                  ),
                ],

                const Divider(height: 1),

                // Action Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 10,
                    children: [
                      // Intent Selector Override
                      SegmentedButton<ParsedIntent>(
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          textStyle: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        segments: const [
                          ButtonSegment(value: ParsedIntent.task, label: Text('Task')),
                          ButtonSegment(value: ParsedIntent.expense, label: Text('Expense')),
                          ButtonSegment(value: ParsedIntent.habit, label: Text('Habit')),
                          ButtonSegment(value: ParsedIntent.note, label: Text('Note')),
                        ],
                        selected: {_detectedIntent},
                        onSelectionChanged: (val) {
                          SanctuaryHapticEngine.selection();
                          setState(() => _detectedIntent = val.first);
                        },
                      ),

                      // Instant Save Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: terracotta,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _submit,
                        icon: const Icon(LucideIcons.cornerDownLeft, size: 14),
                        label: Text(
                          'CAPTURE',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
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
    );
  }

  Widget _buildIntentPill(ParsedIntent intent) {
    String label = 'Task';
    IconData icon = LucideIcons.checkSquare;
    Color color = const Color(0xFFD9725B);

    switch (intent) {
      case ParsedIntent.expense:
        label = 'Expense';
        icon = LucideIcons.wallet;
        color = const Color(0xFFC87A5B);
        break;
      case ParsedIntent.habit:
        label = 'Daily Habit';
        icon = LucideIcons.repeat;
        color = const Color(0xFFD9725B);
        break;
      case ParsedIntent.note:
        label = 'Note';
        icon = LucideIcons.fileText;
        color = const Color(0xFFE8927C);
        break;
      case ParsedIntent.task:
        label = 'Priority Task';
        icon = LucideIcons.checkSquare;
        color = const Color(0xFFD9725B);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: edBox(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPill({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: edBox(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.5, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
