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
    }

    final activeTasks = tasks.where((t) => !t.completed).toList();
    final highPriority = activeTasks.where((t) => t.priority.toLowerCase().contains('high') || t.priority.toLowerCase().contains('urgent')).toList();
    final now = DateTime.now();
    final todaySpend = expenses.where((e) => e.spentAt.year == now.year && e.spentAt.month == now.month && e.spentAt.day == now.day).fold<double>(0.0, (s, e) => s + e.amount);

    if (GroqAiService().isConfigured) {
      try {
        final taskSummaries = activeTasks.take(5).map((t) => '- ${t.title} (${t.priority})').join('\n');
        final prompt = '''You are a helpful, clear, and friendly personal assistant in Notteodo.
Strict tone requirements: Zero robotic clichés, zero conversational assistant filler. Speak with archival luxury, horological precision, and executive restraint.
Current date: $todayKey.
Active Tasks (${activeTasks.length} pending, ${highPriority.length} high priority):
$taskSummaries

Today's Spend: ₹$todaySpend (Monthly Target: ₹$monthlyBudget).

Generate an ultra-crisp, inspiring, high-impact Daily Executive Briefing.
Return ONLY valid JSON matching this schema:
{
  "greeting": "Refined greeting e.g. Good morning, Architect.",
  "headline": "Inspiring 4-6 word daily theme",
  "primaryDirective": "The #1 core objective for today (max 15 words)",
  "topPriorities": ["priority 1", "priority 2", "priority 3"],
  "budgetGuardrail": "One sentence on today's financial burn discipline",
  "strategicMaxim": "An executive aphorism on mastery and momentum"
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

    // High quality deterministic fallback briefing
    final topTaskTitles = activeTasks.take(3).map((t) => t.title).toList();
    final fwFallback = notes.isNotEmpty
        ? 'Archived in "${notes.first.title}": "${notes.first.excerpt}"'
        : 'The mind is for having ideas, not holding them.';

    final fallback = DailyExecutiveBriefing(
      dateKey: todayKey,
      greeting: now.hour < 12 ? 'Good morning.' : now.hour < 17 ? 'Good afternoon.' : 'Good evening.',
      headline: "Today's Overview & Daily Focus",
      primaryDirective: activeTasks.isNotEmpty
          ? 'Zero in on "${activeTasks.first.title}" before opening secondary workstreams.'
          : 'Maintain momentum across open notes and active lifestyle goals.',
      topPriorities: topTaskTitles.isNotEmpty ? topTaskTitles : ['Plan new objectives', 'Review monthly budget', 'Pick today\'s outfit'],
      budgetGuardrail: todaySpend > 0 ? '₹${todaySpend.toStringAsFixed(0)} logged today. Pacing remains within parameters.' : 'Discretionary spend is calm. Stay mindful of planned disbursements.',
      strategicMaxim: 'Mastery compounds in the silence between deliberate actions.',
      forgottenWisdom: fwFallback,
      generatedAt: DateTime.now(),
    );

    _saveBriefing(fallback);
    return fallback;
  }
}
