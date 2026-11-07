import '../utils/text_cleaner.dart';
import 'dart:convert';
import '../enterprise/sanctuary_logger.dart';
import '../state/sanctuary_state.dart';
import 'groq_ai_service.dart';
import 'local_store.dart';

class DailyExecutiveBriefing {
  final String dateKey;
  final String greeting;
  final String headline;
  final String primaryDirective;
  final List<String> topPriorities;
  final String budgetGuardrail;
  final String strategicMaxim;
  final String forgottenWisdom;
  final DateTime generatedAt;

  const DailyExecutiveBriefing({
    required this.dateKey,
    required this.greeting,
    required this.headline,
    required this.primaryDirective,
    required this.topPriorities,
    required this.budgetGuardrail,
    required this.strategicMaxim,
    this.forgottenWisdom = '',
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'greeting': greeting,
        'headline': headline,
        'primaryDirective': primaryDirective,
        'topPriorities': topPriorities,
        'budgetGuardrail': budgetGuardrail,
        'strategicMaxim': strategicMaxim,
        'forgottenWisdom': forgottenWisdom,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory DailyExecutiveBriefing.fromJson(Map<String, dynamic> json) => DailyExecutiveBriefing(
        dateKey: json['dateKey']?.toString() ?? '',
        greeting: json['greeting']?.toString() ?? 'Good day, Executive.',
        headline: json['headline']?.toString() ?? 'Your Daily Strategic Compass',
        primaryDirective: json['primaryDirective']?.toString() ?? 'Execute highest-leverage tasks with deliberate focus.',
        topPriorities: (json['topPriorities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        budgetGuardrail: json['budgetGuardrail']?.toString() ?? 'Maintain balanced burn across categories.',
        strategicMaxim: json['strategicMaxim']?.toString() ?? 'Excellence is not an act, but a habit.',
        forgottenWisdom: json['forgottenWisdom']?.toString() ?? '',
        generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class AiBriefingService {
  static final AiBriefingService _instance = AiBriefingService._internal();
  factory AiBriefingService() => _instance;
  AiBriefingService._internal();

  Future<DailyExecutiveBriefing>? _inFlightBriefing;

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  DailyExecutiveBriefing? getCachedBriefing() {
    final key = 'briefing_${_todayKey()}';
    final map = LocalStore().readMap(key);
    if (map == null) return null;
    try {
      return DailyExecutiveBriefing.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  void _saveBriefing(DailyExecutiveBriefing briefing) {
    final key = 'briefing_${briefing.dateKey}';
    LocalStore().writeMap(key, briefing.toJson());
  }

  /// Synthesizes or retrieves today's executive briefing.
  Future<DailyExecutiveBriefing> getOrGenerateBriefing({
    required List<TaskItem> tasks,
    required List<HabitItem> habits,
    required List<ExpenseItem> expenses,
    List<NoteItem> notes = const [],
    required double monthlyBudget,
    bool forceRefresh = false,
  }) async {
    final todayKey = _todayKey();
    if (!forceRefresh) {
      final cached = getCachedBriefing();
      if (cached != null) return cached;
      if (_inFlightBriefing != null) return _inFlightBriefing!;
    }

    final future = _computeBriefing(
      tasks: tasks,
      habits: habits,
      expenses: expenses,
      notes: notes,
      monthlyBudget: monthlyBudget,
      todayKey: todayKey,
    );
    _inFlightBriefing = future;
    try {
      return await future;
    } finally {
      _inFlightBriefing = null;
    }
  }

  Future<DailyExecutiveBriefing> _computeBriefing({
    required List<TaskItem> tasks,
    required List<HabitItem> habits,
    required List<ExpenseItem> expenses,
    required List<NoteItem> notes,
    required double monthlyBudget,
    required String todayKey,
  }) async {

    final activeTasks = tasks.where((t) => !t.completed).toList();
    final highPriority = activeTasks.where((t) => t.priority.toLowerCase().contains('high') || t.priority.toLowerCase().contains('urgent')).toList();
    final now = DateTime.now();
    final todaySpend = expenses.where((e) => e.spentAt.year == now.year && e.spentAt.month == now.month && e.spentAt.day == now.day).fold<double>(0.0, (s, e) => s + e.amount);

    if (GroqAiService().isConfigured) {
      try {
        final taskSummaries = activeTasks.take(5).map((t) => '- ${t.title} (${t.priority})').join('\n');
        final prompt = '''You are a helpful, clear, and friendly personal assistant in NOTtEodo.
Write in simple, natural, encouraging everyday language. Keep sentences clear, practical, and grounded in the user's actual tasks.
Current date: $todayKey.
Active Tasks (${activeTasks.length} pending, ${highPriority.length} high priority):
$taskSummaries

Today's Spend: ₹$todaySpend (Monthly Target: ₹$monthlyBudget).

Generate a clear, motivating, practical Daily Briefing for today.
Return ONLY valid JSON matching this schema:
{
  "greeting": "Friendly greeting e.g. Good morning!",
  "headline": "Clear 4-6 word focus for today",
  "primaryDirective": "The single most important task or step to take first (max 15 words)",
  "topPriorities": ["priority 1", "priority 2", "priority 3"],
  "budgetGuardrail": "Clear one-sentence update on today's spending and monthly budget",
  "strategicMaxim": "A short, practical reminder on steady focus and daily progress"
}''';

        // Select past note for forgotten wisdom resurfacing
        String pastWisdomCandidate = '';
        if (notes.isNotEmpty) {
          final candidate = notes[DateTime.now().day % notes.length];
          pastWisdomCandidate = 'Past Archived Note: "${candidate.title}" — "${candidate.excerpt}"';
        }

        final promptWithWisdom = prompt + (pastWisdomCandidate.isNotEmpty ? '\n\nResurface this past note as a 1-sentence thought-provoking "forgottenWisdom" question connecting to today: $pastWisdomCandidate\nAdd "forgottenWisdom": "..." to JSON schema.' : '');

        final res = await GroqAiService().ask(query: promptWithWisdom, scope: 'Executive Briefing');
        final raw = res.answer.trim();
        String jsonStr = raw;
        final match = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(raw);
        if (match != null) {
          jsonStr = match.group(1) ?? raw;
        }

        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final fw = decoded['forgottenWisdom']?.toString() ?? (notes.isNotEmpty ? 'From archives ("${notes.first.title}"): "${notes.first.excerpt}"' : 'Past discipline compounds into present mastery.');

        final briefing = DailyExecutiveBriefing(
          dateKey: todayKey,
          greeting: SanctuaryTextCleaner.clean(decoded['greeting']?.toString() ?? 'Good day.'),
          headline: SanctuaryTextCleaner.clean(decoded['headline']?.toString() ?? 'Strategic Execution Mode'),
          primaryDirective: SanctuaryTextCleaner.clean(decoded['primaryDirective']?.toString() ?? (activeTasks.isNotEmpty ? 'Focus on completing "${activeTasks.first.title}".' : 'Plan and prioritize your upcoming initiatives.')),
          topPriorities: (decoded['topPriorities'] as List<dynamic>?)?.map((e) => SanctuaryTextCleaner.clean(e.toString())).toList() ?? (activeTasks.take(3).map((t) => t.title).toList()),
          budgetGuardrail: SanctuaryTextCleaner.clean(decoded['budgetGuardrail']?.toString() ?? 'Keep discretionary outflows paced evenly.'),
          strategicMaxim: SanctuaryTextCleaner.clean(decoded['strategicMaxim']?.toString() ?? 'Velocity and clarity compound into dominance.'),
          forgottenWisdom: SanctuaryTextCleaner.clean(fw),
          generatedAt: DateTime.now(),
        );

        _saveBriefing(briefing);
        return briefing;
      } catch (e) {
        SanctuaryLogger().warn('AiBriefingService', 'AI briefing generation failed: $e');
      }
    }

    // Genuinely dynamic, human fallback briefing based on real user items
    final topTaskTitles = activeTasks.take(3).map((t) => t.title).toList();
    final pendingHabits = habits.where((h) => !h.completedToday).toList();
    final fwFallback = notes.isNotEmpty
        ? 'From note "${notes.first.title}": "${notes.first.excerpt}"'
        : 'The mind is for having ideas, not holding them.';

    final directive = activeTasks.isNotEmpty
        ? 'Start by finishing "${activeTasks.first.title}" to build today\'s momentum.'
        : (pendingHabits.isNotEmpty
            ? 'Complete your habit "${pendingHabits.first.title}" to keep your streak alive.'
            : 'Your list is clear! Capture a new goal or take a mindful pause.');

    final spendStatus = todaySpend > 0
        ? '₹${todaySpend.toStringAsFixed(0)} spent today against your ₹${monthlyBudget.toStringAsFixed(0)} monthly target.'
        : '₹0 spent today. You\'re pacing well against your ₹${monthlyBudget.toStringAsFixed(0)} target.';

    final fallback = DailyExecutiveBriefing(
      dateKey: todayKey,
      greeting: now.hour < 12 ? 'Good morning.' : now.hour < 17 ? 'Good afternoon.' : 'Good evening.',
      headline: activeTasks.isNotEmpty ? '${activeTasks.length} Tasks Scheduled Today' : 'Daily Focus & Overview',
      primaryDirective: directive,
      topPriorities: topTaskTitles.isNotEmpty ? topTaskTitles : ['Add your main goal', 'Review budget target', 'Check daily habits'],
      budgetGuardrail: spendStatus,
      strategicMaxim: 'One focused hour on your main priority accomplishes more than an entire day of multitasking.',
      forgottenWisdom: fwFallback,
      generatedAt: DateTime.now(),
    );

    _saveBriefing(fallback);
    return fallback;
  }
}
