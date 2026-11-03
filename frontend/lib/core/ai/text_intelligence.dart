import 'dart:math';

/// On-device text understanding: tokenising, light stemming, topic detection,
/// TF-IDF vectors and similarity. Runs offline, with no model download and no data leaving the device.
class TextIntelligence {
  TextIntelligence._();

  static const Set<String> stopwords = {
    'a', 'about', 'above', 'after', 'again', 'all', 'also', 'am', 'an', 'and', 'any', 'are', 'as', 'at', 'be',
    'because', 'been', 'before', 'being', 'below', 'between', 'both', 'but', 'by', 'can', 'could', 'did', 'do',
    'does', 'doing', 'done', 'down', 'during', 'each', 'few', 'for', 'from', 'further', 'get', 'got', 'had', 'has',
    'have', 'having', 'he', 'her', 'here', 'hers', 'him', 'his', 'how', 'i', 'if', 'in', 'into', 'is', 'it', 'its',
    'just', 'like', 'me', 'more', 'most', 'my', 'need', 'no', 'nor', 'not', 'now', 'of', 'off', 'on', 'once', 'only',
    'or', 'other', 'our', 'ours', 'out', 'over', 'own', 'same', 'she', 'should', 'so', 'some', 'such', 'than',
    'that', 'the', 'their', 'them', 'then', 'there', 'these', 'they', 'this', 'those', 'through', 'to', 'too',
    'under', 'until', 'up', 'very', 'was', 'we', 'were', 'what', 'when', 'where', 'which', 'while', 'who', 'whom',
    'why', 'will', 'with', 'would', 'you', 'your', 'yours', 'make', 'new', 'one', 'two', 'thing', 'things', 'today',
    'tomorrow', 'next', 'week', 'day', 'via', 'etc', 'let', 'lets', 'want', 'going', 'use', 'using', 'note', 'notes',
  };

  /// Topic lexicon: lets very short texts (task titles, shopping items) group by
  /// meaning rather than exact words. Keys are display names.
  static const Map<String, Set<String>> topics = {
    'Work & projects': {
      'meeting', 'client', 'project', 'deadline', 'report', 'presentation', 'deck', 'email', 'manager', 'review',
      'standup', 'sprint', 'launch', 'roadmap', 'proposal', 'invoice', 'team', 'office', 'call', 'sync', 'spec',
      'deploy', 'release', 'bug', 'feature', 'interview', 'hire', 'okr', 'kpi', 'quarter', 'stakeholder',
    },
    'Study & learning': {
      'exam', 'study', 'lecture', 'assignment', 'homework', 'course', 'class', 'thesis', 'research', 'paper',
      'chapter', 'revise', 'revision', 'quiz', 'tutorial', 'learn', 'book', 'reading', 'semester', 'professor',
      'notes', 'syllabus', 'lab', 'essay', 'library', 'flashcard',
    },
    'Travel': {
      'flight', 'hotel', 'trip', 'visa', 'passport', 'airport', 'booking', 'itinerary', 'travel', 'vacation',
      'holiday', 'train', 'luggage', 'pack', 'packing', 'beach', 'tour', 'airbnb', 'hostel', 'check-in', 'museum',
    },
    'Health & fitness': {
      'gym', 'run', 'running', 'workout', 'doctor', 'dentist', 'medicine', 'pill', 'yoga', 'meditate', 'sleep',
      'diet', 'protein', 'walk', 'steps', 'therapy', 'checkup', 'vitamin', 'hospital', 'appointment', 'stretch',
      'cardio', 'swim', 'health', 'water',
    },
    'Money & bills': {
      'rent', 'bill', 'bank', 'tax', 'salary', 'budget', 'pay', 'payment', 'loan', 'emi', 'insurance', 'invest',
      'savings', 'credit', 'card', 'refund', 'expense', 'subscription', 'electricity', 'recharge', 'wifi', 'fee',
    },
    'Errands & shopping': {
      'buy', 'groceries', 'grocery', 'milk', 'store', 'order', 'pickup', 'return', 'amazon', 'market', 'shop',
      'shopping', 'deliver', 'delivery', 'courier', 'post', 'parcel', 'refill',
    },
    'Home': {
      'clean', 'cleaning', 'laundry', 'repair', 'fix', 'plumber', 'furniture', 'kitchen', 'garden', 'plant',
      'dishes', 'vacuum', 'decor', 'move', 'moving', 'paint', 'room', 'house', 'apartment',
    },
    'People & family': {
      'mom', 'dad', 'mother', 'father', 'sister', 'brother', 'family', 'friend', 'friends', 'birthday',
      'anniversary', 'wedding', 'gift', 'party', 'dinner', 'kids', 'son', 'daughter', 'grandma', 'wife', 'husband',
    },
    'Ideas & creativity': {
      'idea', 'ideas', 'design', 'sketch', 'draw', 'write', 'writing', 'blog', 'story', 'poem', 'music', 'song',
      'photo', 'photography', 'video', 'brainstorm', 'concept', 'inspiration', 'moodboard', 'art', 'palette',
    },
  };

  static final RegExp _split = RegExp(r"[^a-z0-9À-ɏ'-]+");

  /// Lowercased, stopword-free, lightly stemmed tokens.
  static List<String> tokenize(String text) {
    final out = <String>[];
    for (var raw in text.toLowerCase().split(_split)) {
      raw = raw.replaceAll(RegExp(r"^[-']+|[-']+$"), '');
      if (raw.length < 2 || stopwords.contains(raw) || RegExp(r'^\d+$').hasMatch(raw)) continue;
      out.add(stem(raw));
    }
    return out;
  }

  /// A deliberately light English stemmer (plural / -ing / -ed), stable enough for grouping.
  static String stem(String w) {
    if (w.length > 5 && w.endsWith('ies')) return '${w.substring(0, w.length - 3)}y';
    if (w.length > 5 && w.endsWith('ing')) return w.substring(0, w.length - 3);
    if (w.length > 4 && w.endsWith('ed') && !w.endsWith('eed')) return w.substring(0, w.length - 2);
    if (w.length > 3 && w.endsWith('s') && !w.endsWith('ss') && !w.endsWith('us')) return w.substring(0, w.length - 1);
    return w;
  }

  static final Map<String, String> _topicByStem = {
    for (final e in topics.entries)
      for (final w in e.value) stem(w): e.key,
  };

  /// Topics mentioned in [text], strongest first.
  static List<String> topicsOf(String text) {
    final counts = <String, int>{};
    for (final t in tokenize(text)) {
      final topic = _topicByStem[t];
      if (topic != null) counts[topic] = (counts[topic] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in sorted) e.key];
  }

  static double cosine(Map<String, double> a, Map<String, double> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final (small, big) = a.length <= b.length ? (a, b) : (b, a);
    var dot = 0.0;
    small.forEach((k, v) {
      final w = big[k];
      if (w != null) dot += v * w;
    });
    return dot; // vectors are L2-normalised
  }

  static Map<String, double> normalise(Map<String, double> v) {
    final norm = sqrt(v.values.fold<double>(0, (s, x) => s + x * x));
    if (norm == 0) return v;
    return v.map((k, x) => MapEntry(k, x / norm));
  }

  static String titleCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// TF-IDF over a small corpus, with topic tokens mixed in so short texts that
/// share a meaning (e.g. "flight" and "passport") end up close together.
class TfIdfModel {
  final List<Map<String, double>> vectors;
  final Map<String, double> idf;

  TfIdfModel._(this.vectors, this.idf);

  static const double topicWeight = 1.6;

  factory TfIdfModel.fit(List<String> docs) {
    final tokenised = [for (final d in docs) _features(d)];
    final df = <String, int>{};
    for (final toks in tokenised) {
      for (final t in toks.toSet()) {
        df[t] = (df[t] ?? 0) + 1;
      }
    }
    final n = docs.length;
    final idf = df.map((t, c) => MapEntry(t, log((1 + n) / (1 + c)) + 1));
    final vectors = <Map<String, double>>[];
    for (final toks in tokenised) {
      final tf = <String, double>{};
      for (final t in toks) {
        tf[t] = (tf[t] ?? 0) + (t.startsWith('#') ? topicWeight : 1);
      }
      vectors.add(TextIntelligence.normalise(tf.map((t, f) => MapEntry(t, (1 + log(f)) * (idf[t] ?? 1)))));
    }
    return TfIdfModel._(vectors, idf);
  }

  static List<String> _features(String doc) {
    final toks = TextIntelligence.tokenize(doc);
    return [...toks, for (final topic in TextIntelligence.topicsOf(doc)) '#$topic'];
  }

  /// Highest-weighted plain words (not topics) in [indexes]' combined vectors.
  List<String> topTerms(Iterable<int> indexes, {int count = 3}) {
    final sum = <String, double>{};
    for (final i in indexes) {
      vectors[i].forEach((k, v) {
        if (!k.startsWith('#')) sum[k] = (sum[k] ?? 0) + v;
      });
    }
    final sorted = sum.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in sorted.take(count)) e.key];
  }
}
