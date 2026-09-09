/// Clean Inward Broadsheet Article
class BroadsheetArticle {
  final String title;
  final String author;
  final String publication;
  final String date;
  final String cleanText;
  final int readingTimeMinutes;

  const BroadsheetArticle({
    required this.title,
    required this.author,
    required this.publication,
    required this.date,
    required this.cleanText,
    required this.readingTimeMinutes,
  });
}

/// Sovereign Curated RSS Broadsheet Reader Service
/// Strips external tracking pixels, ad payloads, and scripts, formatting essays
/// into pure artisanal broadsheets with drop caps and classical book layouts.
class SovereignRssBroadsheetService {
  static BroadsheetArticle parseAndSanitizeRawFeed({
    required String rawHtmlOrText,
    required String title,
    required String author,
    required String publication,
  }) {
    // 1. Strip script, style, iframe, and tracking pixel tags
    var sanitized = rawHtmlOrText
        .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<iframe[\s\S]*?</iframe>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<img[^>]*pixel[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final wordCount = sanitized.split(' ').where((w) => w.isNotEmpty).length;
    final readingTime = (wordCount / 200).ceil().clamp(1, 180);

    return BroadsheetArticle(
      title: title,
      author: author,
      publication: publication,
      date: DateTime.now().toIso8601String().substring(0, 10),
      cleanText: sanitized,
      readingTimeMinutes: readingTime,
    );
  }
}
