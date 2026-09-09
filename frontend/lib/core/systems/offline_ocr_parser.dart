/// Offline Optical Character Recognition (OCR) Parser
/// Cleans, parses, and structures raw scanned text tokens into
/// elegant markdown with headings, blockquotes, bullet points, and extracted tags.
library;

class StructuredOcrDocument {
  final String title;
  final String formattedMarkdown;
  final List<String> extractedTags;
  final List<String> actionItems;

  StructuredOcrDocument({
    required this.title,
    required this.formattedMarkdown,
    required this.extractedTags,
    required this.actionItems,
  });
}

class OfflineOcrParser {
  static final OfflineOcrParser _instance = OfflineOcrParser._internal();
  factory OfflineOcrParser() => _instance;
  OfflineOcrParser._internal();

  /// Parses raw OCR scanned text buffer into a structured sanctuary note
  StructuredOcrDocument parseRawScan(String rawText) {
    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    if (lines.isEmpty) {
      return StructuredOcrDocument(
        title: 'Untitled Curated Scan',
        formattedMarkdown: '',
        extractedTags: [],
        actionItems: [],
      );
    }

    final title = lines.first.replaceAll(RegExp(r'^[#*\-•\s]+'), '');
    final bodyLines = lines.skip(1).toList();

    final buffer = StringBuffer();
    final tags = <String>[];
    final actionItems = <String>[];

    buffer.writeln('# $title\n');

    for (final line in bodyLines) {
      // Check for tags (#tag)
      final tagMatches = RegExp(r'#(\w+)').allMatches(line);
      for (final match in tagMatches) {
        final tag = match.group(1);
        if (tag != null && !tags.contains(tag)) {
          tags.add(tag);
        }
      }

      // Check for action items ([ ] or TODO)
      if (line.toLowerCase().startsWith('todo:') ||
          line.toLowerCase().startsWith('- [ ]') ||
          line.startsWith('[]')) {
        final item = line.replaceAll(RegExp(r'^(todo:|- \[ \]|\[\])\s*', caseSensitive: false), '');
        actionItems.add(item);
        buffer.writeln('- [ ] $item');
      } else if (line.startsWith('"') || line.startsWith('“')) {
        // Blockquote
        buffer.writeln('> $line');
      } else {
        buffer.writeln(line);
      }
    }

    return StructuredOcrDocument(
      title: title,
      formattedMarkdown: buffer.toString(),
      extractedTags: tags.isEmpty ? ['scanned', 'archive'] : tags,
      actionItems: actionItems,
    );
  }
}
