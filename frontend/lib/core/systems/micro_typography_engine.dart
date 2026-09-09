/// Micro-Typographic Optical Margin & Ligature Engine
/// Enforces classical Gutenberg publishing standards: historical ligatures,
/// true curly quotes, and hanging punctuation offsets for heirloom text blocks.
class MicroTypographyEngine {
  /// Converts plain ASCII typography into classical bookbinding typographic glyphs
  static String applyClassicalLigaturesAndQuotes(String input) {
    var text = input;

    // 1. Classical smart quotes
    text = text.replaceAllMapped(
      RegExp(r'(^|[\s(\[{])"([^\s"])'),
      (m) => '${m[1]}“${m[2]}',
    );
    text = text.replaceAllMapped(
      RegExp(r'([^\s])"'),
      (m) => '${m[1]}”',
    );
    text = text.replaceAllMapped(
      RegExp(r"(^|[\s(\[{])'([^\s'])"),
      (m) => '${m[1]}‘${m[2]}',
    );
    text = text.replaceAllMapped(
      RegExp(r"([^\s])'"),
      (m) => '${m[1]}’',
    );

    // 2. Em-dash and En-dash
    text = text.replaceAll('---', '—'); // Em dash
    text = text.replaceAll('--', '–'); // En dash

    // 3. Ellipsis character
    text = text.replaceAll('...', '…');

    // 4. Unicode ligatures (fi, fl, ffi, ffl)
    text = text.replaceAll('ffi', 'ﬃ');
    text = text.replaceAll('ffl', 'ﬄ');
    text = text.replaceAll('fi', 'ﬁ');
    text = text.replaceAll('fl', 'ﬂ');
    text = text.replaceAll('ff', 'ﬀ');

    return text;
  }

  /// Calculates hanging punctuation offset for quotation marks and hyphens
  static double computeHangingPunctuationOffset(String lineStart) {
    if (lineStart.startsWith('“') || lineStart.startsWith('‘') || lineStart.startsWith('"')) {
      return -4.5; // Hang quote mark outside the margin
    }
    return 0.0;
  }
}
