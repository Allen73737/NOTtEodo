import 'dart:convert';
import '../enterprise/sanctuary_logger.dart';
import 'groq_ai_service.dart';

class NoteSummaryResult {
  final String summary;
  final List<String> actionItems;
  final List<String> tags;

  const NoteSummaryResult({
    required this.summary,
    required this.actionItems,
    required this.tags,
  });
}

class AiCopilotService {
  static final AiCopilotService _instance = AiCopilotService._internal();
  factory AiCopilotService() => _instance;
  AiCopilotService._internal();

  /// Automatically breaks down a complex task into 3-5 concrete action items.
  Future<List<String>> breakdownTask(String taskTitle) async {
    final clean = taskTitle.trim();
    if (clean.isEmpty) return [];

    if (GroqAiService().isConfigured) {
      try {
        final prompt = '''Break down this task into 3 to 5 clear, concrete, sequential action subtasks:
Task: "$clean"

Return ONLY a valid JSON list of strings:
["subtask 1", "subtask 2", "subtask 3"]''';

        final res = await GroqAiService().ask(query: prompt, scope: 'Task Copilot');
        final raw = res.answer.trim();
        String jsonStr = raw;
        final match = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(raw);
        if (match != null) {
          jsonStr = match.group(1) ?? raw;
        }

        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          return decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        }
      } catch (e) {
        SanctuaryLogger().warn('AiCopilotService', 'Breakdown error: $e');
      }
    }

    // Heuristic breakdown fallback
    return [
      'Define clear objectives & deliverables for "$clean"',
      'Gather resources and remove immediate blockers',
      'Execute core execution phase',
      'Review quality & mark complete',
    ];
  }

  /// Summarizes note content and extracts actionable to-do items.
  Future<NoteSummaryResult> summarizeNoteAndExtractActions(String content) async {
    final clean = content.trim();
    if (clean.isEmpty) {
      return const NoteSummaryResult(summary: '', actionItems: [], tags: []);
    }

    if (GroqAiService().isConfigured) {
      try {
        final prompt = '''Analyze this note. Produce an executive summary (max 2 sentences), extract any implied or explicit action items, and suggest 2-3 relevant tags.

Note content:
"""
$clean
"""

Return ONLY a valid JSON object matching this schema:
{
  "summary": "concise 2-sentence executive summary",
  "actionItems": ["action 1", "action 2"],
  "tags": ["tag1", "tag2"]
}''';

        final res = await GroqAiService().ask(query: prompt, scope: 'Note Copilot');
        final raw = res.answer.trim();
        String jsonStr = raw;
        final match = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(raw);
        if (match != null) {
          jsonStr = match.group(1) ?? raw;
        }

        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final summary = decoded['summary']?.toString() ?? '';
        final actions = (decoded['actionItems'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final tags = (decoded['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

        return NoteSummaryResult(
          summary: summary,
          actionItems: actions,
          tags: tags,
        );
      } catch (e) {
        SanctuaryLogger().warn('AiCopilotService', 'Summarize note error: $e');
      }
    }

    // Heuristic fallback
    final lines = clean.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final firstSentence = lines.isNotEmpty ? lines.first : 'Personal memorandum.';
    final actions = lines
        .where((l) => l.startsWith('- [ ]') || l.startsWith('* [ ]') || l.toLowerCase().startsWith('todo:') || l.toLowerCase().startsWith('action:'))
        .map((l) => l.replaceAll(RegExp(r'^[-*]\s*\[\s*\]\s*|^todo:\s*|^action:\s*', caseSensitive: false), '').trim())
        .toList();

    return NoteSummaryResult(
      summary: firstSentence,
      actionItems: actions.isNotEmpty ? actions : ['Review note details', 'Follow up on key points'],
      tags: ['Executive', 'Memorandum'],
    );
  }
}

