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

  /// Server id of this answer, for a thumbs up or down. Null on device and for app jobs.
  final String? turnId;

  const AiQueryResult({
    required this.answer,
    required this.modelUsed,
    required this.tierIndex,
    required this.sources,
    this.isOfflineFallback = false,
    this.turnId,
  });
}

/// How a request is answered on the server.
enum NodoMode {
  /// A conversation with Nodo: personality, memory and app knowledge.
  chat('nodo'),

  /// Nodo's Architect mode for admins. The server checks the admin list itself.
  admin('admin'),

  /// A job inside the app (briefings, parsing, summaries): Nodo's rules, the task's format.
  tool('tool');

  final String wire;
  const NodoMode(this.wire);
}

/// One thing Nodo remembers about the signed-in account.
class NodoMemory {
  final String id;
  final String kind;
  final String content;

  const NodoMemory({required this.id, required this.kind, required this.content});
}

/// A question people often ask Nodo about the app, with no personal details.
class NodoInsight {
  final String topic;
  final String question;
  final String? answer;
  final int hits;
  final int score;
  final String status;

  const NodoInsight({
    required this.topic,
    required this.question,
    required this.answer,
    required this.hits,
    required this.score,
    required this.status,
  });
}

/// Gateway to Nodo in the cloud.
///
/// Every request goes through the `ai-assist` edge function, which owns Nodo's
/// personality, rules, memory and app knowledge. The provider key, model choice,
/// per-user rate limits and daily quotas all live on the server, and **no provider key
/// or model name ever reaches the app**. Without an account, or with cloud AI turned off
/// in Settings, every caller gets the on-device answer.
class GroqAiService {
  static final GroqAiService _instance = GroqAiService._internal();
  factory GroqAiService() => _instance;
  GroqAiService._internal();

  /// Shown in the UI when an answer came from the server.
  static const String cloudModelLabel = 'Nodo';

  /// The user's choice in Settings → AI (defaults to on).
  bool get cloudAllowed => LocalStore().readMap('settings')?['cloudAi'] != false;

  /// True when a cloud model can be reached: signed in and cloud AI allowed.
  bool get isConfigured => cloudAllowed && SanctuarySupabaseService().isConnectedToCloud;

  /// Answers [query], grounded in [matches] from the user's own items and [history].
  /// [profile] is a digest of the user's live app state (data, not instructions) and
  /// [persona] the personality chosen in Settings.
  Future<AiQueryResult> ask({
    required String query,
    String scope = 'Global',
    List<KnowledgeMatch> matches = const [],
    NodoMode mode = NodoMode.tool,
    String? profile,
    String? persona,
    List<Map<String, String>>? history,
  }) async {
    final sources = matches.map((m) => '${m.kind}: ${m.title}').toList();
    if (!isConfigured) {
      return _localFallback(query, scope, matches, sources,
          cloudAllowed ? 'Sign in to use Nodo in the cloud.' : 'Cloud AI is turned off in Settings.');
    }
    try {
      final data = await _invoke({
        'task': 'ask',
        'mode': mode.wire,
        'query': query,
        'scope': scope,
        'context': matches.map((m) => m.digest).join('\n\n'),
        if (profile != null) 'profile': profile,
        if (persona != null) 'persona': persona,
        if (history != null && history.isNotEmpty) 'history': history,
      });
      final answer = data['answer']?.toString() ?? '';
      if (answer.trim().isEmpty) throw StateError('empty answer');
      return AiQueryResult(
        answer: SanctuaryTextCleaner.clean(answer.trim()),
        modelUsed: cloudModelLabel,
        tierIndex: (data['tier'] as num?)?.toInt() ?? 1,
        sources: sources,
        turnId: data['turn_id']?.toString(),
      );
    } catch (e) {
      SanctuaryLogger().warn('AI', 'Cloud AI unavailable, answering on device: $e');
      return _localFallback(query, scope, matches, sources, _friendly(e));
    }
  }

  /// Tells Nodo whether an answer helped. Well-rated answers to app questions become
  /// shared knowledge (without personal details). Returns false if it wasn't recorded.
  Future<bool> rate(String turnId, {required bool helpful}) async {
    if (!isConfigured) return false;
    try {
      final data = await _invoke({'task': 'feedback', 'turn_id': turnId, 'rating': helpful ? 1 : -1});
      return data['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  /// What Nodo remembers about this account, newest first. Null when unavailable.
  Future<List<NodoMemory>?> memories() async {
    if (!SanctuarySupabaseService().isConnectedToCloud) return null;
    try {
      final data = await _invoke({'task': 'memories'});
      return [
        for (final m in (data['memories'] as List? ?? const []).whereType<Map>())
          NodoMemory(id: m['id'].toString(), kind: m['kind']?.toString() ?? 'fact', content: m['content']?.toString() ?? ''),
      ];
    } catch (_) {
      return null;
    }
  }

  /// Deletes one memory, or with no [id] everything Nodo remembers about this account.
  Future<bool> forget({String? id}) async {
    if (!SanctuarySupabaseService().isConnectedToCloud) return false;
    try {
      final data = await _invoke({'task': 'forget', if (id != null) 'id': id else 'all': true});
      return data['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Admins: what people ask Nodo about the app. Null when unavailable or not an admin.
  Future<List<NodoInsight>?> insights() async {
    if (!SanctuarySupabaseService().isConnectedToCloud) return null;
    try {
      final data = await _invoke({'task': 'insights'});
      return [
        for (final i in (data['insights'] as List? ?? const []).whereType<Map>())
          NodoInsight(
            topic: i['topic'].toString(),
            question: i['question']?.toString() ?? '',
            answer: i['answer']?.toString(),
            hits: (i['hits'] as num?)?.toInt() ?? 0,
            score: (i['score'] as num?)?.toInt() ?? 0,
            status: i['status']?.toString() ?? 'candidate',
          ),
      ];
    } catch (_) {
      return null;
    }
  }

  /// Admins: approve or reject a learned answer, optionally rewriting it.
  Future<bool> reviewInsight(String topic, {required bool approve, String? answer}) async {
    try {
      final data = await _invoke({
        'task': 'insight_review',
        'topic': topic,
        'status': approve ? 'approved' : 'rejected',
        if (answer != null) 'answer': answer,
      });
      return data['ok'] == true;
    } catch (_) {
      return false;
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
    if (t.contains('RATE_LIMITED') || t.contains('429')) return 'Nodo needs a short breather.';
    if (t.contains('QUOTA')) return 'You have used today\'s Nodo allowance.';
    if (t.contains('TimeoutException')) return 'Nodo took too long to answer.';
    return 'Nodo can\'t reach the cloud right now.';
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
        modelUsed: 'Nodo · on this device',
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
      modelUsed: 'Nodo · on this device',
      tierIndex: 0,
      sources: sources,
      isOfflineFallback: true,
    );
  }
}
