import 'dart:async';
import 'dart:convert';

import '../enterprise/sanctuary_logger.dart';
import '../utils/text_cleaner.dart';
import 'local_knowledge_index.dart';
import 'local_store.dart';
import 'sanctuary_supabase_service.dart';

/// Result of an AI query, with where the answer came from.
class AiQueryResult {
  final String answer;
  final String modelUsed;
  final int tierIndex;
  final List<String> sources;
  final bool isOfflineFallback;

  const AiQueryResult({
    required this.answer,
    required this.modelUsed,
    required this.tierIndex,
    required this.sources,
    this.isOfflineFallback = false,
  });
}

/// Gateway to the cloud AI model.
///
/// Every request goes through the `ai-assist` edge function. The Groq API key, the
/// model fallback cascade, per-user rate limits and daily quotas all live on the
/// server, and **no provider key ships in the app**. Without an account, or with
/// cloud AI turned off in Settings, every caller gets the on-device answer.
class GroqAiService {
  static final GroqAiService _instance = GroqAiService._internal();
  factory GroqAiService() => _instance;
  GroqAiService._internal();

  /// Shown in the UI when an answer came from the server.
  static const String cloudModelLabel = 'NOTtEodo AI (cloud)';

  /// The user's choice in Settings → AI (defaults to on).
  bool get cloudAllowed => LocalStore().readMap('settings')?['cloudAi'] != false;

  /// True when a cloud model can be reached: signed in and cloud AI allowed.
  bool get isConfigured => cloudAllowed && SanctuarySupabaseService().isConnectedToCloud;

  /// Answers [query], grounded in [matches] from the user's own items.
  Future<AiQueryResult> ask({
    required String query,
    String scope = 'Global',
    List<KnowledgeMatch> matches = const [],
    String? systemPrompt,
  }) async {
    final sources = matches.map((m) => '${m.kind}: ${m.title}').toList();
    if (!isConfigured) {
      return _localFallback(query, scope, matches, sources,
          cloudAllowed ? 'Sign in to use the cloud AI assistant.' : 'Cloud AI is turned off in Settings.');
    }
    try {
      final data = await _invoke({
        'task': 'ask',
        'query': query,
        'scope': scope,
        'context': matches.map((m) => m.digest).join('\n\n'),
        if (systemPrompt != null) 'systemPrompt': systemPrompt,
      });
      final answer = data['answer']?.toString() ?? '';
      if (answer.trim().isEmpty) throw StateError('empty answer');
      return AiQueryResult(
        answer: SanctuaryTextCleaner.clean(answer.trim()),
        modelUsed: data['model']?.toString() ?? cloudModelLabel,
        tierIndex: (data['tier'] as num?)?.toInt() ?? 1,
        sources: sources,
      );
    } catch (e) {
      SanctuaryLogger().warn('AI', 'Cloud AI unavailable, answering on device: $e');
      return _localFallback(query, scope, matches, sources, _friendly(e));
    }
  }

  /// Short names for groups of item titles (one name per group), or null when offline.
  Future<List<String>?> nameGroups(List<List<String>> groups, {String kind = 'items'}) async {
    if (!isConfigured || groups.isEmpty) return null;
    try {
      final data = await _invoke({
        'task': 'group_names',
        'kind': kind,
        'groups': [
          for (final g in groups.take(10)) [for (final t in g.take(8)) t.length > 80 ? t.substring(0, 80) : t],
        ],
      });
      final names = (data['names'] as List?)?.map((e) => e.toString()).toList();
      return names != null && names.length == groups.take(10).length ? names : null;
    } catch (_) {
      return null;
    }
  }

  /// Speech to text (Whisper on the server). Returns null when unavailable.
  Future<String?> transcribeAudio(List<int> audioBytes, {String filename = 'audio.wav'}) async {
    if (!isConfigured || audioBytes.length > 3 * 1024 * 1024) return null;
    try {
      final data = await _invoke({'task': 'transcribe', 'filename': filename, 'audio_b64': base64.encode(audioBytes)});
      return data['text']?.toString();
    } catch (e) {
      SanctuaryLogger().warn('AIVoice', 'Transcription unavailable: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) =>
      SanctuarySupabaseService().invokeFunction('ai-assist', body).timeout(const Duration(seconds: 30));

  static String _friendly(Object e) {
    final t = e.toString();
    if (t.contains('RATE_LIMITED') || t.contains('429')) return 'You have reached the AI limit for now.';
    if (t.contains('QUOTA')) return 'You have used today\'s AI allowance.';
    if (t.contains('TimeoutException')) return 'The AI took too long to answer.';
    return 'The cloud AI is unavailable right now.';
  }

  /// On-device answer: the most relevant matching items, quoted.
  AiQueryResult _localFallback(
    String query,
    String scope,
    List<KnowledgeMatch> matches,
    List<String> sources,
    String? reason,
  ) {
    if (matches.isEmpty) {
      final message = reason != null
          ? '$reason\n\nNo stored notes, tasks, or events match your question.'
          : 'Nothing in "$scope" matches that yet. Add notes or tasks and ask again.';
      return AiQueryResult(
        answer: message,
        modelUsed: 'On-device search',
        tierIndex: 0,
        sources: sources,
        isOfflineFallback: true,
      );
    }

    final buffer = StringBuffer();
    if (reason != null) {
      buffer
        ..writeln('_${reason}_ Here is what matches on this device:')
        ..writeln();
    }
    buffer
      ..writeln('**${matches.length} matching item(s):**')
      ..writeln();
    for (final m in matches.take(5)) {
      buffer.writeln('• **[${m.kind}] ${m.title}**');
      for (final line in m.snippet.split('\n').where((l) => l.trim().isNotEmpty).take(2)) {
        buffer.writeln('  ↳ $line');
      }
      buffer.writeln();
    }
    return AiQueryResult(
      answer: buffer.toString().trim(),
      modelUsed: 'On-device search',
      tierIndex: 0,
      sources: sources,
      isOfflineFallback: true,
    );
  }
}
