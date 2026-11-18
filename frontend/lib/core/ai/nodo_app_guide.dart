import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One topic of Nodo's knowledge of the app.
class NodoGuideSection {
  final String id;
  final String title;
  final List<String> keywords;
  final String body;

  const NodoGuideSection({required this.id, required this.title, required this.keywords, required this.body});
}

/// What Nodo knows about using NOTtEodo, for answers on the device.
///
/// The same file (`assets/nodo/app_guide.json`) is mirrored on the server, where the
/// cloud Nodo reads it; a test keeps the two copies identical.
class NodoAppGuide {
  NodoAppGuide._();

  static const asset = 'assets/nodo/app_guide.json';
  static List<NodoGuideSection> _sections = const [];

  static List<NodoGuideSection> get sections => _sections;

  /// Loads the guide once. Safe to call repeatedly; failures leave it empty.
  static Future<void> load() async {
    if (_sections.isNotEmpty) return;
    try {
      _sections = parse(await rootBundle.loadString(asset));
    } catch (_) {
      _sections = const [];
    }
  }

  static List<NodoGuideSection> parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return [
      for (final s in (j['sections'] as List).whereType<Map>())
        NodoGuideSection(
          id: s['id'].toString(),
          title: s['title'].toString(),
          keywords: [for (final k in (s['keywords'] as List? ?? const [])) k.toString()],
          body: s['body'].toString(),
        ),
    ];
  }

  /// The sections that best match [query], best first (the same scoring as the server).
  static List<NodoGuideSection> search(String query, {int limit = 2, List<NodoGuideSection>? from}) {
    final q = ' ${query.toLowerCase()} ';
    final words = q.split(RegExp(r"[^a-z0-9'-]+")).where((w) => w.length > 2).toSet();
    final scored = <(NodoGuideSection, int)>[];
    for (final s in from ?? _sections) {
      var score = 0;
      for (final k in s.keywords) {
        if (k.contains(' ')) {
          if (q.contains(k)) score += 3;
        } else if (words.contains(k) || words.contains('${k}s')) {
          score += 2;
        }
      }
      for (final w in s.title.toLowerCase().split(RegExp(r'\W+'))) {
        if (w.length > 3 && words.contains(w)) score += 1;
      }
      if (score > 0) scored.add((s, score));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final x in scored.take(limit)) x.$1];
  }

  /// True when [query] reads like a question about using the app.
  static bool looksLikeHowTo(String query) => RegExp(
        r"\b(how (do|can|to|does)|where (is|are|do|can)|what is|what's|can i|find|open|change|turn (on|off)|set up|enable|disable)\b",
        caseSensitive: false,
      ).hasMatch(query);

  /// An on-device answer to a how-to question, or null when the guide has nothing.
  static String? answer(String query, {List<NodoGuideSection>? from}) {
    final hits = search(query, from: from);
    if (hits.isEmpty) return null;
    final buffer = StringBuffer('**${hits.first.title}**\n${hits.first.body}');
    if (hits.length > 1) buffer.write('\n\nRelated: ${hits[1].title}.');
    return buffer.toString();
  }
}
