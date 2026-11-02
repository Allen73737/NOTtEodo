import '../state/sanctuary_state.dart';
import '../utils/date_labels.dart';

/// One of the user's own items that matched a question.
class KnowledgeMatch {
  final String kind;
  final String title;
  final String snippet;
  final double score;

  const KnowledgeMatch(this.kind, this.title, this.snippet, this.score);

  /// Compact form sent to the assistant as context.
  String get digest => '[$kind: $title]\n$snippet';
}

/// Keyword retrieval over everything stored in the app (no network, no model).
class LocalKnowledgeIndex {
  LocalKnowledgeIndex._();

  static const _stopWords = {
    'the', 'and', 'for', 'with', 'what', 'when', 'where', 'how', 'who', 'why', 'are', 'was', 'were', 'can', //
    'you', 'your', 'my', 'me', 'about', 'from', 'this', 'that', 'have', 'has', 'did', 'does', 'any', 'all', 'tell',
  };

  static List<String> terms(String text) => text
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.length > 2 && !_stopWords.contains(t))
      .toSet()
      .toList();

  static double _score(List<String> qTerms, String title, String body) {
    if (qTerms.isEmpty) return 0;
    final t = title.toLowerCase(), b = body.toLowerCase();
    var s = 0.0;
    for (final term in qTerms) {
      if (t.contains(term)) s += 2; // title hits count double
      if (b.contains(term)) s += 1;
    }
    return s / qTerms.length;
  }

  static String _clip(String s, [int max = 400]) {
    final flat = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= max ? flat : '${flat.substring(0, max - 1)}…';
  }

  static List<KnowledgeMatch> search(
    String query, {
    required List<NoteItem> notes,
    required List<TaskItem> tasks,
    required List<PlannerEvent> events,
    required List<TravelTrip> trips,
    required List<MemoirItem> journal,
    required List<ExpenseItem> expenses,
    int limit = 6,
  }) {
    final q = terms(query);
    final out = <KnowledgeMatch>[];
    void add(String kind, String title, String body) {
      final s = _score(q, title, body);
      if (s > 0) out.add(KnowledgeMatch(kind, title, _clip(body), s));
    }

    for (final n in notes) {
      add('Note', n.title, '${n.space} · ${n.tag}\n${n.body}');
    }
    for (final t in tasks) {
      add('Task', t.title,
          '${t.completed ? 'Done' : 'Open'} · ${t.priority}${t.dueAt == null ? '' : ' · due ${DateLabels.dateTime(t.dueAt!)}'}\n${t.notes}');
    }
    for (final e in events) {
      add('Event', e.title, '${DateLabels.dateTime(e.startsAt)} · ${e.durationMinutes} min\n${e.notes}');
    }
    for (final tr in trips) {
      add('Trip', tr.title, '${tr.destination} · ${tr.date} · ${tr.flight}\nPacking: ${tr.packingList.join(', ')}');
    }
    for (final m in journal.where((m) => !m.isPrivate)) {
      add('Journal', m.title, '${m.date} · ${m.mood}\n${m.excerpt}');
    }
    for (final x in expenses) {
      add('Expense', x.title, '${x.amount.toStringAsFixed(2)} · ${x.category} · ${x.dateLong}${x.note.isEmpty ? '' : '\n${x.note}'}');
    }
    out.sort((a, b) => b.score.compareTo(a.score));
    return out.take(limit).toList();
  }
}
