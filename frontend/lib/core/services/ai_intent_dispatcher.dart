import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../enterprise/sanctuary_logger.dart';
import '../services/nlp_date_parser.dart';
import '../state/sanctuary_state.dart';
import '../widgets/app_toast_engine.dart';
import '../widgets/floating_voice_ai_widget.dart';
import 'ai_financial_service.dart';
import 'groq_ai_service.dart';

enum DispatchIntent { expense, task, note, query }

class DispatchResult {
  final DispatchIntent intent;
  final String title;
  final String details;
  final bool success;

  const DispatchResult({
    required this.intent,
    required this.title,
    required this.details,
    required this.success,
  });
}

class AiIntentDispatcher {
  static final AiIntentDispatcher _instance = AiIntentDispatcher._internal();
  factory AiIntentDispatcher() => _instance;
  AiIntentDispatcher._internal();

  /// Analyzes spoken or typed natural language and automatically dispatches to the correct module.
  Future<DispatchResult> dispatch(BuildContext context, WidgetRef ref, String input, {Function(String)? onOpenAiQuery}) async {
    final clean = input.trim();
    if (clean.isEmpty) {
      return const DispatchResult(
        intent: DispatchIntent.query,
        title: '',
        details: 'Empty input',
        success: false,
      );
    }

    // Classify intent using Groq AI cascade if configured
    DispatchIntent classified = _classifyLocally(clean);
    Map<String, dynamic>? aiEntities;

    if (GroqAiService().isConfigured) {
      try {
        final prompt = '''You are an intent router for a personal sanctuary app. Classify the user input into ONE intent: "expense", "task", "note", or "query".
Also extract entities:
- For "expense": amount (number), title (string), category (string)
- For "task": title (string), dueText (string or null), priority (string)
- For "note": title (string), content (string), space (string)
- For "query": query (string)

Return ONLY valid JSON:
{
  "intent": "expense" | "task" | "note" | "query",
  "entities": { ... }
}

User input: "$clean"''';

        final res = await GroqAiService().ask(query: prompt, scope: 'Intent Router');
        final raw = res.answer.trim();
        String jsonStr = raw;
        final match = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(raw);
        if (match != null) {
          jsonStr = match.group(1) ?? raw;
        }

        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final intentStr = decoded['intent']?.toString().toLowerCase() ?? '';
        if (intentStr == 'expense') {
          classified = DispatchIntent.expense;
        } else if (intentStr == 'task') {
          classified = DispatchIntent.task;
        } else if (intentStr == 'note') {
          classified = DispatchIntent.note;
        } else if (intentStr == 'query') {
          classified = DispatchIntent.query;
        }

        aiEntities = decoded['entities'] as Map<String, dynamic>?;
      } catch (e) {
        SanctuaryLogger().warn('AiIntentDispatcher', 'AI classification failed: $e. Using local heuristics.');
      }
    }

    // Execute corresponding action
    switch (classified) {
      case DispatchIntent.expense:
        final parsed = await AiFinancialService().parseNaturalLanguageExpense(clean);
        ref.read(expensesProvider.notifier).addExpense(
          title: parsed.title,
          amount: parsed.amount,
          category: parsed.category,
          note: parsed.note,
        );

        if (context.mounted) {
          AppToastEngine().showToast(
            context,
            title: 'Expense Recorded',
            message: '₹${parsed.amount.toStringAsFixed(0)} logged under ${parsed.category} (${parsed.title})',
          );
        }

        return DispatchResult(
          intent: DispatchIntent.expense,
          title: parsed.title,
          details: '₹${parsed.amount.toStringAsFixed(0)} · ${parsed.category}',
          success: true,
        );

      case DispatchIntent.task:
        final due = NlpDateParser.tryParse(clean);
        String taskTitle = clean;
        if (aiEntities != null && aiEntities['title'] != null) {
          taskTitle = aiEntities['title'].toString();
        } else {
          taskTitle = quickCaptureTitle(clean);
        }

        ref.read(tasksProvider.notifier).addTask(
          title: taskTitle,
          dueAt: due,
          priority: aiEntities?['priority']?.toString() ?? 'Medium Priority',
        );

        if (context.mounted) {
          AppToastEngine().showToast(
            context,
            title: 'Task Created',
            message: due != null ? '"$taskTitle" (Due ${_formatDue(due)})' : '"$taskTitle" added to Daily Rhythm',
          );
        }

        return DispatchResult(
          intent: DispatchIntent.task,
          title: taskTitle,
          details: due != null ? 'Due ${_formatDue(due)}' : 'Added to Tasks',
          success: true,
        );

      case DispatchIntent.note:
        String noteTitle = 'Memorandum';
        String noteContent = clean;
        if (aiEntities != null) {
          noteTitle = aiEntities['title']?.toString() ?? 'Memorandum';
          noteContent = aiEntities['content']?.toString() ?? clean;
        } else {
          final stripped = clean.replaceAll(RegExp(r'^(?:note:|memo:|jot\s+down:?)\s*', caseSensitive: false), '').trim();
          noteTitle = stripped.length > 30 ? '${stripped.substring(0, 27)}...' : stripped;
          noteContent = stripped;
        }

        ref.read(notesProvider.notifier).addNote(
          title: noteTitle,
          space: 'General Space',
          tag: 'Voice Memo',
          excerpt: noteContent,
          content: noteContent,
        );

        if (context.mounted) {
          AppToastEngine().showToast(
            context,
            title: 'Note Archived',
            message: '"$noteTitle" saved to Knowledge Space.',
          );
        }

        return DispatchResult(
          intent: DispatchIntent.note,
          title: noteTitle,
          details: 'Saved to Notes',
          success: true,
        );

      case DispatchIntent.query:
        if (onOpenAiQuery != null) {
          onOpenAiQuery(clean);
        }
        return DispatchResult(
          intent: DispatchIntent.query,
          title: clean,
          details: 'Routed to AI Assistant',
          success: true,
        );
    }
  }

  static DispatchIntent _classifyLocally(String text) {
    final lower = text.toLowerCase();
    
    // Check expense cues
    if (RegExp(r'(?:spent|paid|bought|cost|expense|rs\.?|inr|₹|\$)\s*\d+', caseSensitive: false).hasMatch(text) ||
        lower.startsWith('spent ') || lower.startsWith('paid ') || lower.startsWith('bought ')) {
      return DispatchIntent.expense;
    }

    // Check note cues
    if (lower.startsWith('note:') || lower.startsWith('memo:') || lower.startsWith('note ') || lower.startsWith('jot down')) {
      return DispatchIntent.note;
    }

    // Check query cues
    if (lower.startsWith('what ') || lower.startsWith('why ') || lower.startsWith('how ') || lower.startsWith('where ') || lower.startsWith('who ') || lower.startsWith('suggest ') || lower.startsWith('explain ') || lower.endsWith('?')) {
      return DispatchIntent.query;
    }

    // Default to task
    return DispatchIntent.task;
  }

  static String _formatDue(DateTime dt) {
    return '${dt.day}/${dt.month} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
