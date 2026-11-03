import 'dart:math';

import 'package:flutter/foundation.dart';

import 'text_intelligence.dart';

@immutable
class Suggestion {
  final String value;

  /// 0..1; the UI only shows suggestions above ~0.45.
  final double confidence;

  /// Why, in a few words ("Learned from 12 similar expenses").
  final String reason;

  const Suggestion(this.value, this.confidence, this.reason);
}

/// Multinomial naive Bayes with Laplace smoothing; learns from the user's own items.
class NaiveBayes {
  final Map<String, Map<String, int>> _wordCounts = {};
  final Map<String, int> _docCounts = {};
  final Map<String, int> _totalWords = {};
  final Set<String> _vocab = {};
  int _docs = 0;

  int get trainingSize => _docs;

  void add(String text, String label) {
    final toks = TextIntelligence.tokenize(text);
    if (toks.isEmpty) return;
    _docs++;
    _docCounts[label] = (_docCounts[label] ?? 0) + 1;
    final wc = _wordCounts.putIfAbsent(label, () => {});
    for (final t in toks) {
      wc[t] = (wc[t] ?? 0) + 1;
      _totalWords[label] = (_totalWords[label] ?? 0) + 1;
      _vocab.add(t);
    }
  }

  /// Best label and its posterior probability, or null when nothing is known.
  (String, double)? predict(String text) {
    final toks = TextIntelligence.tokenize(text);
    if (_docs == 0 || toks.isEmpty) return null;
    // Only words seen in training carry evidence; otherwise the prior would decide alone.
    final known = toks.where(_vocab.contains).toList();
    if (known.isEmpty) return null;
    final v = _vocab.length;
    final logs = <String, double>{};
    for (final label in _docCounts.keys) {
      var lp = log(_docCounts[label]! / _docs);
      final wc = _wordCounts[label]!;
      final total = _totalWords[label]!;
      for (final t in known) {
        lp += log(((wc[t] ?? 0) + 1) / (total + v));
      }
      logs[label] = lp;
    }
    final maxLog = logs.values.reduce(max);
    final exp_ = logs.map((k, l) => MapEntry(k, exp(l - maxLog)));
    final z = exp_.values.reduce((a, b) => a + b);
    final best = exp_.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return (best.key, best.value / z);
  }
}

String? _keywordMatch(String text, Map<String, List<String>> table) {
  final lower = ' ${text.toLowerCase()} ';
  String? best;
  var bestLen = 0;
  table.forEach((label, words) {
    for (final w in words) {
      if (w.length > bestLen && lower.contains(w)) {
        best = label;
        bestLen = w.length;
      }
    }
  });
  return best;
}

/// Suggests an expense category from its title.
class ExpenseCategorizer {
  ExpenseCategorizer._();

  static const Map<String, List<String>> _priors = {
    'Food & Dining': [
      'swiggy', 'zomato', 'restaurant', 'cafe', 'coffee', 'starbucks', 'lunch', 'dinner', 'breakfast', 'pizza',
      'burger', 'groceries', 'grocery', 'snack', 'tea ', 'bakery', 'dominos', 'mcdonald', 'kfc', 'food', 'meal',
      'blinkit', 'zepto', 'bigbasket', 'instamart', 'biryani', 'juice',
    ],
    'Transport': [
      'uber', 'ola ', 'rapido', 'metro', 'bus ', 'taxi', 'cab ', 'fuel', 'petrol', 'diesel', 'parking', 'toll',
      'auto ', 'train ticket', 'lyft', 'gas station',
    ],
    'Bills': [
      'rent', 'electricity', 'water bill', 'wifi', 'broadband', 'internet', 'recharge', 'phone bill', 'netflix',
      'spotify', 'prime', 'subscription', 'insurance', 'emi', 'gas bill', 'maintenance', 'dth', 'youtube premium',
    ],
    'Health': [
      'pharmacy', 'medicine', 'doctor', 'hospital', 'clinic', 'dentist', 'gym', 'apollo', 'lab test', 'vitamin',
      'physio', 'therapy', 'chemist', 'yoga',
    ],
    'Study & Books': [
      'book', 'course', 'udemy', 'coursera', 'tuition', 'exam fee', 'stationery', 'kindle', 'notebook', 'college',
      'school fee', 'workshop', 'library',
    ],
    'Travel & Stay': [
      'hotel', 'flight', 'airbnb', 'hostel', 'resort', 'makemytrip', 'booking.com', 'visa', 'luggage', 'oyo',
      'airline', 'indigo', 'trip',
    ],
    'Clothing': [
      'shirt', 'jeans', 'shoes', 'dress', 'jacket', 'zara', 'h&m', 'uniqlo', 'myntra', 'trousers', 'sneakers',
      'saree', 'kurta', 'tshirt', 't-shirt', 'socks', 'hoodie',
    ],
    'Shopping': [
      'amazon', 'flipkart', 'headphones', 'phone case', 'charger', 'gadget', 'electronics', 'gift', 'meesho',
      'decathlon', 'watch',
    ],
    'Home': [
      'furniture', 'ikea', 'plumber', 'electrician', 'cleaning', 'detergent', 'utensils', 'curtain', 'bulb',
      'repair', 'paint', 'cookware', 'mattress',
    ],
  };

  static Suggestion? suggest(String title, {List<(String, String)> history = const []}) {
    final t = title.trim();
    if (t.length < 3) return null;

    // The user's own habits win once there are enough examples.
    if (history.length >= 4) {
      final nb = NaiveBayes();
      for (final (text, label) in history) {
        nb.add(text, label);
      }
      final p = nb.predict(t);
      if (p != null && p.$2 >= 0.55 && p.$1 != 'General') {
        final similar = history.where((h) => h.$2 == p.$1).length;
        return Suggestion(p.$1, p.$2, 'Learned from $similar of your ${p.$1} expenses');
      }
    }
    final prior = _keywordMatch(t, _priors);
    if (prior != null) return Suggestion(prior, 0.7, 'Recognised from the title');
    return null;
  }
}

/// Task triage: priority, space and time of day from the title and due date.
class TaskTriage {
  TaskTriage._();

  static const _urgent = ['urgent', 'asap', 'critical', 'emergency', 'immediately', 'overdue', 'final notice'];
  static const _high = ['deadline', 'important', 'submit', 'pay ', 'payment', 'tax', 'exam', 'interview', 'renew', 'due'];
  static const _low = ['someday', 'maybe', 'eventually', 'idea', 'nice to have', 'when free', 'browse', 'look into'];

  static Suggestion? priority(String title, {DateTime? dueAt, DateTime? now}) {
    final t = ' ${title.toLowerCase()} ';
    if (t.trim().length < 3) return null;
    final today = now ?? DateTime.now();
    if (_urgent.any(t.contains)) return const Suggestion('Urgent & Critical', 0.8, 'Sounds urgent');
    if (dueAt != null) {
      final hours = dueAt.difference(today).inHours;
      if (hours < 0) return const Suggestion('Urgent & Critical', 0.75, 'Already past due');
      if (hours <= 24) return const Suggestion('High Priority', 0.7, 'Due within a day');
    }
    if (_high.any(t.contains)) return const Suggestion('High Priority', 0.65, 'Has a hard deadline word');
    if (_low.any(t.contains)) return const Suggestion('Low Priority', 0.6, 'Sounds optional');
    return null;
  }

  /// Picks the space most like this title among the user's spaces.
  static Suggestion? space(String title, {required List<(String, String)> history, required List<String> spaces}) {
    if (title.trim().length < 3) return null;
    if (history.length >= 4) {
      final nb = NaiveBayes();
      for (final (text, label) in history) {
        nb.add(text, label);
      }
      final p = nb.predict(title);
      if (p != null && p.$2 >= 0.6 && spaces.contains(p.$1)) {
        return Suggestion(p.$1, p.$2, 'Matches your other ${p.$1.replaceAll(' Space', '')} tasks');
      }
    }
    // Topic → space name fallback.
    final topic = TextIntelligence.topicsOf(title).firstOrNull;
    const map = {
      'Study & learning': 'Academic Space',
      'Ideas & creativity': 'Design Space',
      'Travel': 'Travel Space',
      'People & family': 'Personal Space',
      'Health & fitness': 'Personal Space',
      'Home': 'Personal Space',
    };
    final s = map[topic];
    if (s != null && spaces.contains(s)) return Suggestion(s, 0.55, 'About ${topic!.toLowerCase()}');
    return null;
  }

  static Suggestion? timeOfDay(String title) {
    final t = title.toLowerCase();
    if (RegExp(r'\b(morning|breakfast|wake|sunrise|am)\b').hasMatch(t)) {
      return const Suggestion('Morning', 0.7, 'Mentions the morning');
    }
    if (RegExp(r'\b(lunch|noon|afternoon)\b').hasMatch(t)) return const Suggestion('Afternoon', 0.7, 'Mentions midday');
    if (RegExp(r'\b(evening|dinner|night|tonight|pm)\b').hasMatch(t)) {
      return const Suggestion('Evening', 0.7, 'Mentions the evening');
    }
    return null;
  }
}

/// Tag suggestions for a note: its distinctive words compared with the user's other notes.
class NoteTagger {
  NoteTagger._();

  static List<String> suggestTags(String text, {List<String> corpus = const [], int count = 3}) {
    if (TextIntelligence.tokenize(text).length < 2) return const [];
    final docs = [text, ...corpus.take(300)];
    final model = TfIdfModel.fit(docs);
    final terms = model.topTerms([0], count: count + 2).where((t) => t.length >= 3).take(count);
    final topics = TextIntelligence.topicsOf(text).take(1).map((t) => t.split(' ').first);
    return {...topics, ...terms.map(TextIntelligence.titleCase)}.take(count).toList();
  }

  /// Indexes of the corpus documents most similar to [text].
  static List<int> related(String text, List<String> corpus, {int count = 3, double minSimilarity = 0.15}) {
    if (corpus.isEmpty || TextIntelligence.tokenize(text).isEmpty) return const [];
    final model = TfIdfModel.fit([text, ...corpus]);
    final scored = <(int, double)>[
      for (var i = 0; i < corpus.length; i++) (i, TextIntelligence.cosine(model.vectors[0], model.vectors[i + 1])),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final s in scored.take(count)) if (s.$2 >= minSimilarity) s.$1];
  }
}

/// Lexicon-based sentiment and mood for journal entries (negation-aware).
class MoodSense {
  MoodSense._();

  static const Map<String, int> _valence = {
    'happy': 3, 'joy': 3, 'love': 3, 'grateful': 3, 'thankful': 3, 'amazing': 3, 'wonderful': 3, 'great': 2,
    'good': 2, 'calm': 2, 'peaceful': 2, 'relaxed': 2, 'proud': 2, 'excited': 3, 'fun': 2, 'beautiful': 2,
    'energised': 2, 'energized': 2, 'productive': 2, 'hopeful': 2, 'blessed': 3, 'content': 2, 'smile': 2,
    'laugh': 2, 'enjoy': 2, 'progress': 1, 'better': 1, 'rest': 1, 'adventure': 2, 'explore': 1,
    'sad': -2, 'tired': -2, 'exhausted': -3, 'anxious': -3, 'worried': -2, 'stress': -2, 'stressed': -3,
    'angry': -3, 'upset': -2, 'lonely': -2, 'bad': -2, 'awful': -3, 'terrible': -3, 'hurt': -2, 'scared': -2,
    'afraid': -2, 'nervous': -2, 'overwhelmed': -3, 'frustrated': -2, 'cry': -2, 'sick': -2, 'drained': -2,
    'bored': -1, 'confused': -1, 'panic': -3, 'fail': -2, 'failed': -2, 'regret': -2,
  };
  static const _negators = {'not', 'no', 'never', "n't", 'hardly', 'without', 'barely'};

  /// -1 (very negative) … 1 (very positive).
  static double sentiment(String text) {
    final words = text.toLowerCase().split(RegExp(r"[^a-z']+")).where((w) => w.isNotEmpty).toList();
    var score = 0.0, hits = 0;
    for (var i = 0; i < words.length; i++) {
      final v = _valence[words[i]];
      if (v == null) continue;
      final negated = [for (var j = max(0, i - 3); j < i; j++) words[j]]
          .any((w) => _negators.contains(w) || w.endsWith("n't"));
      score += negated ? -v * 0.6 : v;
      hits++;
    }
    if (hits == 0) return 0;
    return (score / (hits * 3)).clamp(-1.0, 1.0);
  }

  static const Map<String, List<String>> _moodWords = {
    'Grateful': ['grateful', 'thankful', 'blessed', 'appreciate', 'gratitude', 'lucky'],
    'Anxious': ['anxious', 'worried', 'nervous', 'panic', 'stress', 'overwhelmed', 'scared', 'afraid'],
    'Tired': ['tired', 'exhausted', 'sleepy', 'drained', 'worn', 'fatigue'],
    'Energised': ['energised', 'energized', 'excited', 'pumped', 'motivated', 'productive', 'workout'],
    'Adventurous': ['adventure', 'explore', 'trip', 'hike', 'travel', 'new city', 'journey'],
    'Calm': ['calm', 'peaceful', 'relaxed', 'quiet', 'serene', 'meditat', 'slow'],
  };

  static Suggestion? mood(String text) {
    final t = text.toLowerCase();
    if (t.trim().length < 12) return null;
    String? best;
    var hits = 0;
    _moodWords.forEach((mood, words) {
      final c = words.where(t.contains).length;
      if (c > hits) {
        hits = c;
        best = mood;
      }
    });
    if (best != null) return Suggestion(best!, min(0.5 + hits * 0.15, 0.9), 'From the words you used');
    final s = sentiment(text);
    if (s <= -0.35) return const Suggestion('Anxious', 0.5, 'The entry reads as heavy');
    if (s >= 0.35) return const Suggestion('Grateful', 0.5, 'The entry reads as upbeat');
    return const Suggestion('Reflective', 0.45, 'A thoughtful entry');
  }
}

/// Supermarket aisle for a shopping item, so lists can be walked in store order.
class ShoppingAisles {
  ShoppingAisles._();

  static const List<String> order = [
    'Fruit & veg', 'Bakery', 'Dairy & eggs', 'Meat & fish', 'Pantry', 'Frozen', 'Drinks', 'Snacks',
    'Household', 'Personal care', 'Health', 'Electronics', 'Clothing', 'Other',
  ];

  static const Map<String, List<String>> _aisles = {
    'Fruit & veg': [
      'apple', 'banana', 'tomato', 'onion', 'potato', 'spinach', 'carrot', 'lettuce', 'fruit', 'veg', 'lemon',
      'garlic', 'ginger', 'mango', 'grape', 'orange', 'avocado', 'cucumber', 'pepper', 'coriander', 'herb',
      'berries', 'broccoli', 'mushroom',
    ],
    'Bakery': ['bread', 'bun', 'bagel', 'croissant', 'cake', 'muffin', 'pastry', 'tortilla', 'pav'],
    'Dairy & eggs': ['milk', 'egg', 'cheese', 'butter', 'yogurt', 'curd', 'paneer', 'cream', 'ghee'],
    'Meat & fish': ['chicken', 'mutton', 'fish', 'prawn', 'beef', 'pork', 'salmon', 'tuna', 'meat', 'sausage'],
    'Pantry': [
      'rice', 'flour', 'atta', 'dal', 'lentil', 'pasta', 'oil', 'salt', 'sugar', 'spice', 'masala', 'cereal',
      'oats', 'honey', 'jam', 'sauce', 'ketchup', 'beans', 'noodle', 'coffee', 'tea', 'vinegar', 'peanut',
    ],
    'Frozen': ['frozen', 'ice cream', 'peas', 'fries'],
    'Drinks': ['juice', 'soda', 'water bottle', 'cola', 'beer', 'wine', 'drink', 'coconut water'],
    'Snacks': ['chips', 'biscuit', 'cookie', 'chocolate', 'nuts', 'popcorn', 'crackers', 'namkeen'],
    'Household': [
      'detergent', 'soap', 'dish', 'cleaner', 'tissue', 'toilet paper', 'garbage bag', 'bin bag', 'sponge',
      'bulb', 'battery', 'foil', 'broom', 'mop',
    ],
    'Personal care': ['shampoo', 'toothpaste', 'toothbrush', 'deodorant', 'razor', 'lotion', 'sunscreen', 'face wash'],
    'Health': ['medicine', 'vitamin', 'bandage', 'tablet', 'syrup', 'pain relief', 'thermometer'],
    'Electronics': ['charger', 'cable', 'headphone', 'earphone', 'mouse', 'keyboard', 'adapter', 'usb'],
    'Clothing': ['shirt', 'socks', 'jeans', 'shoe', 'jacket', 'tshirt', 't-shirt', 'dress'],
  };

  static String aisleFor(String name) => _keywordMatch(name, _aisles) ?? 'Other';
}
