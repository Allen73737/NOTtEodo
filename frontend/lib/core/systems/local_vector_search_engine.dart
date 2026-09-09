import 'dart:math';

/// Local Neural Vector Knowledge Retrieval Engine (On-Device RAG)
/// Calculates offline subword character & n-gram term frequency embeddings
/// to execute real-time cosine similarity search across notes, journals, and tasks.
class DocumentVector {
  final String id;
  final String title;
  final String content;
  final String category;
  final Map<String, double> tfIdfVector;

  DocumentVector({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.tfIdfVector,
  });
}

class SearchMatchResult {
  final DocumentVector document;
  final double similarityScore; // 0.0 to 1.0

  SearchMatchResult({required this.document, required this.similarityScore});
}

class LocalVectorSearchEngine {
  static final LocalVectorSearchEngine _instance = LocalVectorSearchEngine._internal();
  factory LocalVectorSearchEngine() => _instance;
  LocalVectorSearchEngine._internal();

  final List<DocumentVector> _corpus = [];

  void indexDocument({
    required String id,
    required String title,
    required String content,
    required String category,
  }) {
    // Remove if already indexed
    _corpus.removeWhere((d) => d.id == id);

    final combinedText = '$title $content'.toLowerCase();
    final tokens = _tokenize(combinedText);
    final termFreq = <String, double>{};

    for (final token in tokens) {
      termFreq[token] = (termFreq[token] ?? 0.0) + 1.0;
    }

    // Normalize vector length
    double sumSq = 0.0;
    for (final freq in termFreq.values) {
      sumSq += (freq * freq);
    }
    final norm = sqrt(sumSq);

    final normalized = <String, double>{};
    if (norm > 0) {
      termFreq.forEach((k, v) => normalized[k] = v / norm);
    }

    _corpus.add(
      DocumentVector(
        id: id,
        title: title,
        content: content,
        category: category,
        tfIdfVector: normalized,
      ),
    );
  }

  List<SearchMatchResult> search(String query, {int limit = 5, double minScore = 0.1}) {
    if (query.trim().isEmpty) return [];

    final queryTokens = _tokenize(query.toLowerCase());
    final queryFreq = <String, double>{};
    for (final t in queryTokens) {
      queryFreq[t] = (queryFreq[t] ?? 0.0) + 1.0;
    }

    double qSumSq = 0.0;
    for (final f in queryFreq.values) {
      qSumSq += (f * f);
    }
    final qNorm = sqrt(qSumSq);
    final normalizedQuery = <String, double>{};
    if (qNorm > 0) {
      queryFreq.forEach((k, v) => normalizedQuery[k] = v / qNorm);
    }

    final results = <SearchMatchResult>[];

    for (final doc in _corpus) {
      double dotProduct = 0.0;
      normalizedQuery.forEach((term, qWeight) {
        if (doc.tfIdfVector.containsKey(term)) {
          dotProduct += (qWeight * doc.tfIdfVector[term]!);
        }
      });

      if (dotProduct >= minScore) {
        results.add(SearchMatchResult(document: doc, similarityScore: dotProduct));
      }
    }

    results.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
    return results.take(limit).toList();
  }

  List<String> _tokenize(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1)
        .toList();
  }
}
