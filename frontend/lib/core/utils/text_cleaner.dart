/// Sanitizes and cleans corrupted encoding artifacts (mojibake), unescapes HTML/LaTeX,
/// and normalizes quotes and typography for clean presentation.
class SanctuaryTextCleaner {
  static const Map<String, String> _mojibake = {
    'â€™': "'",
    'â€˜': "'",
    'â€œ': '"',
    'â€\x9d': '"',
    'â€': '"',
    'â‚¹': '₹',
    'Â£': '£',
    'â‚¬': '€',
    'â€”': '—',
    'â€“': '–',
    'Â·': '·',
    'â€¦': '…',
    'Â°': '°',
    'â€¢': '•',
    'âœ¨': '✨',
    'âš¡': '⚡',
    '&quot;': '"',
    '&#39;': "'",
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
  };

  /// Cleans any text string, fixing corrupted unicode symbols and normalizing quotes.
  static String clean(String input) {
    if (input.isEmpty) return input;
    String text = input;

    _mojibake.forEach((bad, good) {
      if (text.contains(bad)) {
        text = text.replaceAll(bad, good);
      }
    });

    // Fix double-encoded or trailing escape artifacts
    text = text.replaceAll(r"\'", "'").replaceAll(r'\"', '"');

    return text;
  }
}
