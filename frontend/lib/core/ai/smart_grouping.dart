import 'package:flutter/foundation.dart';

import 'text_intelligence.dart';

@immutable
class SmartGroup {
  final String label;

  /// Indexes into the input list.
  final List<int> members;

  /// True for the catch-all group of items that matched nothing else.
  final bool isOther;

  const SmartGroup(this.label, this.members, {this.isOther = false});

  SmartGroup copyWith({String? label}) => SmartGroup(label ?? this.label, members, isOther: isOther);
}

/// Unsupervised grouping of short texts: TF-IDF + topic vectors, leader clustering
/// refined with k-means style reassignment, then merging of near-duplicate groups.
/// O(n·k) per pass, so a few hundred items group in milliseconds on any device.
class SmartGrouper {
  SmartGrouper._();

  static List<SmartGroup> group(
    List<String> docs, {
    double threshold = 0.2,
    int maxGroups = 8,
    String otherLabel = 'Everything else',
  }) {
    final n = docs.length;
    if (n == 0) return const [];
    if (n < 3) return [SmartGroup(otherLabel, List.generate(n, (i) => i), isOther: true)];

    final model = TfIdfModel.fit(docs);
    final vecs = model.vectors;

    // 1. Leader clustering, richest documents first so they become the seeds.
    final order = List.generate(n, (i) => i)..sort((a, b) => vecs[b].length.compareTo(vecs[a].length));
    var clusters = <List<int>>[];
    var centroids = <Map<String, double>>[];
    for (final i in order) {
      final (best, sim) = _nearest(vecs[i], centroids);
      if (best >= 0 && sim >= threshold) {
        clusters[best].add(i);
        centroids[best] = _centroid(clusters[best], vecs);
      } else {
        clusters.add([i]);
        centroids.add(vecs[i]);
      }
    }

    // 2. Reassignment passes (k-means style) to undo order effects.
    for (var pass = 0; pass < 3; pass++) {
      final next = List.generate(clusters.length, (_) => <int>[]);
      for (var i = 0; i < n; i++) {
        final (best, sim) = _nearest(vecs[i], centroids);
        final own = clusters.indexWhere((c) => c.contains(i));
        next[(best >= 0 && sim >= threshold * 0.85) ? best : own].add(i);
      }
      clusters = [for (final c in next) if (c.isNotEmpty) c];
      centroids = [for (final c in clusters) _centroid(c, vecs)];
    }

    // 3. Merge groups whose centres are very close.
    var merged = true;
    while (merged) {
      merged = false;
      outer:
      for (var a = 0; a < clusters.length; a++) {
        for (var b = a + 1; b < clusters.length; b++) {
          if (TextIntelligence.cosine(centroids[a], centroids[b]) >= threshold + 0.15) {
            clusters[a].addAll(clusters.removeAt(b));
            centroids.removeAt(b);
            centroids[a] = _centroid(clusters[a], vecs);
            merged = true;
            break outer;
          }
        }
      }
    }

    // 4. Singletons and overflow join a group sharing their topic, else "Everything else".
    clusters.sort((a, b) => b.length.compareTo(a.length));
    final keep = <List<int>>[];
    final leftovers = <int>[];
    for (final c in clusters) {
      if (c.length >= 2 && keep.length < maxGroups - 1) {
        keep.add(c);
      } else {
        leftovers.addAll(c);
      }
    }
    final keepTopics = [for (final c in keep) _dominantTopic(c, docs)];
    final other = <int>[];
    for (final i in leftovers) {
      final topics = TextIntelligence.topicsOf(docs[i]);
      final target = topics.isEmpty ? -1 : keepTopics.indexOf(topics.first);
      if (target >= 0) {
        keep[target].add(i);
      } else {
        other.add(i);
      }
    }

    // 5. Name every group: its shared topic, or its two strongest words.
    final used = <String>{};
    final groups = <SmartGroup>[];
    for (var g = 0; g < keep.length; g++) {
      final members = keep[g]..sort();
      var label = keepTopics[g] ??
          model.topTerms(members, count: 2).map(TextIntelligence.titleCase).join(' & ');
      if (label.isEmpty) label = 'Group ${g + 1}';
      if (!used.add(label)) {
        final extra = model.topTerms(members, count: 1);
        label = '$label · ${extra.isEmpty ? g + 1 : TextIntelligence.titleCase(extra.first)}';
        used.add(label);
      }
      groups.add(SmartGroup(label, members));
    }
    if (other.isNotEmpty) groups.add(SmartGroup(otherLabel, other..sort(), isOther: true));
    return groups;
  }

  static (int, double) _nearest(Map<String, double> v, List<Map<String, double>> centroids) {
    var best = -1;
    var bestSim = -1.0;
    for (var c = 0; c < centroids.length; c++) {
      final s = TextIntelligence.cosine(v, centroids[c]);
      if (s > bestSim) {
        bestSim = s;
        best = c;
      }
    }
    return (best, bestSim);
  }

  static Map<String, double> _centroid(List<int> members, List<Map<String, double>> vecs) {
    final sum = <String, double>{};
    for (final i in members) {
      vecs[i].forEach((k, v) => sum[k] = (sum[k] ?? 0) + v);
    }
    return TextIntelligence.normalise(sum);
  }

  /// The topic shared by at least half of the group, if any.
  static String? _dominantTopic(List<int> members, List<String> docs) {
    final counts = <String, int>{};
    for (final i in members) {
      for (final t in TextIntelligence.topicsOf(docs[i]).take(1)) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;
    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return top.value * 2 >= members.length ? top.key : null;
  }
}
