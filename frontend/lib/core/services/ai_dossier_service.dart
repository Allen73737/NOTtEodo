import 'dart:convert';
import '../enterprise/sanctuary_logger.dart';
import '../state/sanctuary_state.dart';
import '../utils/text_cleaner.dart';
import 'groq_ai_service.dart';
import 'local_store.dart';

class ExecutiveDossier {
  final String weekKey;
  final String weekTitle;
  final String velocityScore;
  final String executiveSummary;
  final List<String> highlights;
  final String capitalReport;
  final List<String> strategicNextSteps;
  final DateTime generatedAt;

  const ExecutiveDossier({
    required this.weekKey,
    required this.weekTitle,
    required this.velocityScore,
    required this.executiveSummary,
    required this.highlights,
    required this.capitalReport,
    required this.strategicNextSteps,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'weekKey': weekKey,
        'weekTitle': weekTitle,
        'velocityScore': velocityScore,
        'executiveSummary': executiveSummary,
        'highlights': highlights,
        'capitalReport': capitalReport,
        'strategicNextSteps': strategicNextSteps,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory ExecutiveDossier.fromJson(Map<String, dynamic> json) => ExecutiveDossier(
        weekKey: json['weekKey']?.toString() ?? '',
        weekTitle: json['weekTitle']?.toString() ?? 'Weekly Executive Dossier',
        velocityScore: json['velocityScore']?.toString() ?? '85% Solid Momentum',
        executiveSummary: json['executiveSummary']?.toString() ?? 'Strong execution cadence maintained across all workspaces.',
        highlights: (json['highlights'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        capitalReport: json['capitalReport']?.toString() ?? 'Discretionary outflows paced within budget guardrails.',
        strategicNextSteps: (json['strategicNextSteps'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class AiDossierService {
  static final AiDossierService _instance = AiDossierService._internal();
  factory AiDossierService() => _instance;
  AiDossierService._internal();

  static String _currentWeekKey() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final weekNum = ((now.difference(startOfYear).inDays + startOfYear.weekday) / 7).ceil();
    return '${now.year}-W$weekNum';
  }

  ExecutiveDossier? getCachedDossier() {
    final key = 'dossier_${_currentWeekKey()}';
    final map = LocalStore().readMap(key);
    if (map == null) return null;
    try {
      return ExecutiveDossier.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  void _saveDossier(ExecutiveDossier dossier) {
    final key = 'dossier_${dossier.weekKey}';
    LocalStore().writeMap(key, dossier.toJson());
  }

  /// Synthesizes the user's weekly activity into a cryptographic executive dossier.
  Future<ExecutiveDossier> generateWeeklyDossier({
    required List<TaskItem> tasks,
    required List<ExpenseItem> expenses,
    required List<NoteItem> notes,
    required List<HabitItem> habits,
    bool forceRefresh = false,
  }) async {
    final weekKey = _currentWeekKey();
    if (!forceRefresh) {
      final cached = getCachedDossier();
      if (cached != null) return cached;
    }

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final completedThisWeek = tasks.where((t) => t.isCompleted && t.createdAt.isAfter(sevenDaysAgo)).toList();
    final activeTasks = tasks.where((t) => !t.isCompleted).toList();
    final weekExpenses = expenses.where((e) => e.spentAt.isAfter(sevenDaysAgo)).toList();
    final weekTotalSpend = weekExpenses.fold<double>(0.0, (s, e) => s + e.amount);
    final recentNotes = notes.where((n) => n.createdAt.isAfter(sevenDaysAgo)).take(4).map((n) => n.title).toList();

    if (GroqAiService().isConfigured) {
      try {
        final prompt = '''You are the executive chief of staff for NOTtEodo.
Generate a Weekly Executive Sanctuary Dossier for $weekKey:
- Completed Tasks this week: ${completedThisWeek.length} (Active Pending: ${activeTasks.length})
- Sample Completed: ${completedThisWeek.take(4).map((t) => t.title).join(', ')}
- Capital Disbursed this week: ₹${weekTotalSpend.toStringAsFixed(0)} across ${weekExpenses.length} transactions
- Top Note Themes: ${recentNotes.join(', ')}

Return ONLY valid JSON:
{
  "weekTitle": "Executive Dossier · $weekKey",
  "velocityScore": "e.g. 92% Peak Velocity",
  "executiveSummary": "2-sentence macro synthesis of velocity and focus",
  "highlights": ["win 1", "win 2", "win 3"],
  "capitalReport": "1-sentence commentary on financial discipline & burn pace",
  "strategicNextSteps": ["priority 1 for next week", "priority 2 for next week"]
}''';

        final res = await GroqAiService().ask(query: prompt, scope: 'Executive Dossier');
        final raw = res.answer.trim();
        String jsonStr = raw;
        final match = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(raw);
        if (match != null) {
          jsonStr = match.group(1) ?? raw;
        }

        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final dossier = ExecutiveDossier(
          weekKey: weekKey,
          weekTitle: decoded['weekTitle']?.toString() ?? 'Executive Dossier · $weekKey',
          velocityScore: decoded['velocityScore']?.toString() ?? '88% Steady Output',
          executiveSummary: SanctuaryTextCleaner.clean(decoded['executiveSummary']?.toString() ?? 'Solid weekly performance.'),
          highlights: (decoded['highlights'] as List<dynamic>?)?.map((e) => SanctuaryTextCleaner.clean(e.toString())).toList() ?? [],
          capitalReport: SanctuaryTextCleaner.clean(decoded['capitalReport']?.toString() ?? 'Spend pace balanced.'),
          strategicNextSteps: (decoded['strategicNextSteps'] as List<dynamic>?)?.map((e) => SanctuaryTextCleaner.clean(e.toString())).toList() ?? [],
          generatedAt: DateTime.now(),
        );

        _saveDossier(dossier);
        return dossier;
      } catch (e) {
        SanctuaryLogger().warn('AiDossierService', 'Failed to generate AI dossier: $e');
      }
    }

    // High quality deterministic dossier fallback
    final fallback = ExecutiveDossier(
      weekKey: weekKey,
      weekTitle: 'Executive Dossier · $weekKey',
      velocityScore: completedThisWeek.length > 5 ? '92% Peak Momentum' : '82% Steady Rhythm',
      executiveSummary: 'Maintained disciplined focus across active workspaces with ${completedThisWeek.length} objectives closed this week.',
      highlights: completedThisWeek.isNotEmpty
          ? completedThisWeek.take(3).map((t) => 'Completed "${t.title}"').toList()
          : ['Maintained active notes archive', 'Kept financial tracking continuous'],
      capitalReport: weekTotalSpend > 0
          ? 'Allocated ₹${weekTotalSpend.toStringAsFixed(0)} across ${weekExpenses.length} disbursements with disciplined runway.'
          : 'Zero discretionary outflows logged; capital runway preserved.',
      strategicNextSteps: activeTasks.isNotEmpty
          ? activeTasks.take(2).map((t) => 'Drive completion on "${t.title}"').toList()
          : ['Establish upcoming sprint initiatives', 'Review seasonal lifestyle goals'],
      generatedAt: DateTime.now(),
    );

    _saveDossier(fallback);
    return fallback;
  }
}
