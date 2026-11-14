import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../enterprise/sanctuary_logger.dart';
import '../services/nlp_date_parser.dart';
import '../state/sanctuary_state.dart';
import '../utils/text_cleaner.dart';
import '../widgets/app_toast_engine.dart';
import 'groq_ai_service.dart';
import '../rewards/reward_bus.dart';

class ExtractedTask {
  final String title;
  final String priority;
  final DateTime? dueAt;

  const ExtractedTask({required this.title, this.priority = 'Medium Priority', this.dueAt});
}

class ExtractedExpense {
  final String title;
  final double amount;
  final String category;

  const ExtractedExpense({required this.title, required this.amount, this.category = 'General'});
}

class ExtractedWorkflowBundle {
  final List<ExtractedTask> tasks;
  final List<ExtractedExpense> expenses;
  final String summary;

  const ExtractedWorkflowBundle({
    required this.tasks,
    required this.expenses,
    required this.summary,
  });

  bool get isEmpty => tasks.isEmpty && expenses.isEmpty;
  int get totalItems => tasks.length + expenses.length;
}

class AiWorkflowEvolutionService {
  static final AiWorkflowEvolutionService _instance = AiWorkflowEvolutionService._internal();
  factory AiWorkflowEvolutionService() => _instance;
  AiWorkflowEvolutionService._internal();

  /// Scans any note text and extracts actionable tasks, expenses, and deadlines.
  Future<ExtractedWorkflowBundle> extractWorkflowsFromNote(String noteContent) async {
    final clean = noteContent.trim();
    if (clean.isEmpty) {
      return const ExtractedWorkflowBundle(tasks: [], expenses: [], summary: 'Empty note.');
    }

    if (GroqAiService().isConfigured) {
      try {
        final prompt =
            '''You are an autonomous workflow extractor. Analyze this personal note and extract all actionable items, to-dos, and financial commitments.
Note:
"""
$clean
"""

Return ONLY valid JSON matching this schema:
{
  "summary": "1-sentence summary of workflows found",
  "tasks": [
    { "title": "string", "priority": "High Priority" | "Medium Priority" | "Low Priority", "dueText": "e.g. tomorrow, by Friday, next week or null" }
  ],
  "expenses": [
    { "title": "string", "amount": number, "category": "Food & Dining" | "Clothing" | "Travel & Stay" | "Shopping" | "Bills" | "General" }
  ]
}''';

        final res = await GroqAiService().ask(query: prompt, scope: 'Workflow Extraction');
        final raw = res.answer.trim();
        String jsonStr = raw;
        final match = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(raw);
        if (match != null) {
          jsonStr = match.group(1) ?? raw;
        }

        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final summary = decoded['summary']?.toString() ?? 'Workflows extracted from note.';

        final tasksList = <ExtractedTask>[];
        if (decoded['tasks'] is List) {
          for (final t in decoded['tasks']) {
            if (t is Map) {
              final title = SanctuaryTextCleaner.clean(t['title']?.toString() ?? '');
              final prio = t['priority']?.toString() ?? 'Medium Priority';
              final dueText = t['dueText']?.toString();
              final due = dueText != null ? NlpDateParser.tryParse(dueText) : null;
              if (title.isNotEmpty) {
                tasksList.add(ExtractedTask(title: title, priority: prio, dueAt: due));
              }
            }
          }
        }

        final expensesList = <ExtractedExpense>[];
        if (decoded['expenses'] is List) {
          for (final e in decoded['expenses']) {
            if (e is Map) {
              final title = SanctuaryTextCleaner.clean(e['title']?.toString() ?? 'Disbursement');
              final amt = double.tryParse(e['amount']?.toString() ?? '0') ?? 0.0;
              final cat = e['category']?.toString() ?? 'General';
              if (amt > 0) {
                expensesList.add(ExtractedExpense(title: title, amount: amt, category: cat));
              }
            }
          }
        }

        return ExtractedWorkflowBundle(
          tasks: tasksList,
          expenses: expensesList,
          summary: summary,
        );
      } catch (e) {
        SanctuaryLogger().warn('AiWorkflowEvolution', 'AI workflow extraction failed: $e');
      }
    }

    // Heuristic deterministic fallback
    final lines = clean.split('\n');
    final tasks = <ExtractedTask>[];
    final expenses = <ExtractedExpense>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Check expense cues
      final amtMatch = RegExp(r'(?:₹|\$|inr|rs\.?)\s*(\d+(?:[.,]\d{1,2})?)', caseSensitive: false).firstMatch(trimmed);
      if (amtMatch != null) {
        final amt = double.tryParse(amtMatch.group(1)?.replaceAll(',', '') ?? '0') ?? 0.0;
        if (amt > 0) {
          expenses.add(ExtractedExpense(
            title: trimmed.replaceAll(RegExp(r'\d+'), '').replaceAll(RegExp(r'[-*₹\$]'), '').trim(),
            amount: amt,
            category: 'General',
          ));
          continue;
        }
      }

      // Check task cues
      if (trimmed.startsWith('- [ ]') ||
          trimmed.toLowerCase().startsWith('todo:') ||
          trimmed.toLowerCase().startsWith('action:')) {
        final taskTitle =
            trimmed.replaceAll(RegExp(r'^[-*]\s*\[\s*\]\s*|^todo:\s*|^action:\s*', caseSensitive: false), '').trim();
        final due = NlpDateParser.tryParse(taskTitle);
        tasks.add(ExtractedTask(title: taskTitle, dueAt: due));
      }
    }

    return ExtractedWorkflowBundle(
      tasks: tasks,
      expenses: expenses,
      summary: 'Heuristic scan found ${tasks.length} tasks and ${expenses.length} expenses.',
    );
  }

  /// Instantiates the extracted workflows into the user's real app state.
  int instantiateAll(BuildContext context, WidgetRef ref, ExtractedWorkflowBundle bundle, String sourceNoteTitle) {
    int count = 0;

    // Bulk-created by the assistant from a note, so it earns no rewards.
    RewardBus.quietly(() {
      for (final task in bundle.tasks) {
        ref.read(tasksProvider.notifier).addTask(
              title: task.title,
              priority: task.priority,
              dueAt: task.dueAt,
              notes: 'Evolved from note: "$sourceNoteTitle"',
            );
        count++;
      }

      for (final exp in bundle.expenses) {
        ref.read(expensesProvider.notifier).addExpense(
              title: exp.title,
              amount: exp.amount,
              category: exp.category,
              note: 'Evolved from note: "$sourceNoteTitle"',
            );
        count++;
      }
    });

    if (context.mounted && count > 0) {
      AppToastEngine().showToast(
        context,
        title: 'Workflows Evolved',
        message: 'Created ${bundle.tasks.length} tasks and ${bundle.expenses.length} expenses from note.',
      );
    }

    return count;
  }
}
