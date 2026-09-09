/// Prose Cadence & Complexity Metrics
class LinguisticMetrics {
  final double lexicalDiversity; // Unique words / total words
  final double averageSentenceLength;
  final double fleschReadingEase;
  final int totalWords;
  final int totalSentences;
  final String cadenceAssessment;

  const LinguisticMetrics({
    required this.lexicalDiversity,
    required this.averageSentenceLength,
    required this.fleschReadingEase,
    required this.totalWords,
    required this.totalSentences,
    required this.cadenceAssessment,
  });
}

/// Linguistic Cadence & Sentiment Fluidity Analyzer
/// 100% on-device natural language analysis evaluating prose for lexical diversity,
/// rhythmic sentence cadence, and cognitive bandwidth.
class LinguisticCadenceAnalyzer {
  static LinguisticMetrics analyze(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const LinguisticMetrics(
        lexicalDiversity: 0.0,
        averageSentenceLength: 0.0,
        fleschReadingEase: 100.0,
        totalWords: 0,
        totalSentences: 0,
        cadenceAssessment: 'Serene Silence',
      );
    }

    final rawWords = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    final sentences = trimmed
        .split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    final totalWords = rawWords.length;
    final totalSentences = sentences.isEmpty ? 1 : sentences.length;

    final uniqueWords = rawWords.toSet().length;
    final diversity = totalWords > 0 ? (uniqueWords / totalWords) : 0.0;
    final avgSentenceLength = totalWords / totalSentences;

    // Estimate syllables (approximate heuristic: vowel groups)
    int syllables = 0;
    for (final w in rawWords) {
      final matches = RegExp(r'[aeiouy]+').allMatches(w).length;
      syllables += matches == 0 ? 1 : matches;
    }

    // Flesch Reading Ease Formula: 206.835 - 1.015 * (words/sentences) - 84.6 * (syllables/words)
    final wordsPerSent = totalWords / totalSentences;
    final sylPerWord = totalWords > 0 ? (syllables / totalWords) : 1.0;
    final flesch = 206.835 - (1.015 * wordsPerSent) - (84.6 * sylPerWord);

    String assessment = 'Balanced Cadence';
    if (diversity > 0.75 && avgSentenceLength > 15) {
      assessment = 'Philosophical & Erudite';
    } else if (avgSentenceLength < 8) {
      assessment = 'Laconic & Urgent';
    } else if (diversity < 0.45) {
      assessment = 'Repetitive Cognitive Load';
    }

    return LinguisticMetrics(
      lexicalDiversity: diversity,
      averageSentenceLength: avgSentenceLength,
      fleschReadingEase: flesch.clamp(0.0, 100.0),
      totalWords: totalWords,
      totalSentences: totalSentences,
      cadenceAssessment: assessment,
    );
  }
}
