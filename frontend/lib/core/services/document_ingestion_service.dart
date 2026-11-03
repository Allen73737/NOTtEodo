import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../enterprise/sanctuary_logger.dart';
import '../state/sanctuary_state.dart';
import '../utils/text_cleaner.dart';

class IngestedDocument {
  final String title;
  final String content;
  final String fileName;
  final String extension;
  final int byteSize;
  final Uint8List? rawBytes;

  const IngestedDocument({
    required this.title,
    required this.content,
    required this.fileName,
    required this.extension,
    required this.byteSize,
    this.rawBytes,
  });
}

class DocumentIngestionService {
  static final DocumentIngestionService _instance = DocumentIngestionService._internal();
  factory DocumentIngestionService() => _instance;
  DocumentIngestionService._internal();

  /// Picks a document from system/device and parses its text content.
  Future<IngestedDocument?> pickAndParseDocument() async {
    try {
      final List<PlatformFile> files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'markdown', 'csv', 'json', 'pdf', 'doc', 'docx'],
      );

      if (files.isEmpty) return null;

      final PlatformFile file = files.first;
      final fileName = file.name;
      final extension = (file.extension ?? '').toLowerCase();

      Uint8List? bytes;
      try {
        bytes = await file.xFile.readAsBytes();
      } catch (_) {
        if (file.path != null && !kIsWeb) {
          bytes = await File(file.path!).readAsBytes();
        }
      }

      final size = bytes?.length ?? 0;
      String content = '';
      if (bytes != null) {
        content = _extractText(bytes, extension, fileName);
      }

      // Compute a clean title from first heading or filename
      String title = _extractTitle(content, fileName);

      return IngestedDocument(
        title: title,
        content: content,
        fileName: fileName,
        extension: extension,
        byteSize: size,
        rawBytes: bytes,
      );
    } catch (e) {
      SanctuaryLogger().warn('DocumentIngestion', 'Failed to pick and ingest document: $e');
      return null;
    }
  }

  /// Extracts readable text from bytes based on extension.
  String _extractText(Uint8List bytes, String extension, String fileName) {
    if (['txt', 'md', 'markdown', 'csv', 'json'].contains(extension)) {
      try {
        final decoded = utf8.decode(bytes, allowMalformed: true);
        return SanctuaryTextCleaner.clean(decoded);
      } catch (_) {
        return SanctuaryTextCleaner.clean(String.fromCharCodes(bytes));
      }
    }

    if (extension == 'pdf') {
      return _extractFromPdf(bytes, fileName);
    }

    // Fallback for doc/docx/binary: extract visible ASCII/UTF8 character streaks
    return _extractTextHeuristic(bytes, fileName);
  }

  /// Heuristic PDF plain-text extractor for standard uncompressed / stream text.
  String _extractFromPdf(Uint8List bytes, String fileName) {
    try {
      final raw = utf8.decode(bytes, allowMalformed: true);
      final textBlocks = <String>[];

      // Extract text within PDF ( ... ) Tj operators
      final tjRegex = RegExp(r"\(([^)]+)\)");
      final matches = tjRegex.allMatches(raw);

      for (final m in matches) {
        final text = m.group(1)?.replaceAll(r'\(', '(').replaceAll(r'\)', ')').trim();
        if (text != null && text.length > 2 && !text.startsWith('/')) {
          textBlocks.add(text);
        }
      }

      if (textBlocks.isNotEmpty) {
        final joined = textBlocks.join(' ');
        if (joined.trim().length > 40) {
          return SanctuaryTextCleaner.clean(joined);
        }
      }
    } catch (_) {}

    return 'Ingested PDF Document: $fileName\nSize: ${(bytes.length / 1024).toStringAsFixed(1)} KB\nThis document has been ingested into your knowledge index.';
  }

  /// Extracts printable text strings from unknown or doc binary files.
  String _extractTextHeuristic(Uint8List bytes, String fileName) {
    final buffer = StringBuffer();
    int currentRun = 0;
    final runChars = <int>[];

    for (int i = 0; i < bytes.length; i++) {
      final b = bytes[i];
      // Printable ASCII (space to ~) or newline/tab
      if ((b >= 32 && b <= 126) || b == 10 || b == 13 || b == 9) {
        runChars.add(b);
        currentRun++;
      } else {
        if (currentRun >= 5) {
          buffer.write(String.fromCharCodes(runChars));
          buffer.write(' ');
        }
        currentRun = 0;
        runChars.clear();
      }
    }

    final extracted = buffer.toString().trim();
    if (extracted.length > 50) {
      return SanctuaryTextCleaner.clean(extracted);
    }

    return 'Ingested Document: $fileName (${(bytes.length / 1024).toStringAsFixed(1)} KB)';
  }

  /// Extracts title from markdown heading `# Title` or cleans file basename.
  String _extractTitle(String content, String fileName) {
    final lines = content.split('\n');
    for (final l in lines.take(5)) {
      final trimmed = l.trim();
      if (trimmed.startsWith('# ')) {
        return trimmed.substring(2).trim();
      }
    }

    // Fallback: strip extension
    final dotIdx = fileName.lastIndexOf('.');
    final base = dotIdx > 0 ? fileName.substring(0, dotIdx) : fileName;
    // Replace underscores and hyphens with spaces
    final clean = base.replaceAll(RegExp(r'[-_]'), ' ').trim();
    return clean.isNotEmpty ? clean : 'Ingested Document';
  }

  /// Converts an IngestedDocument into a NoteItem ready to be added to notesProvider.
  NoteItem toNoteItem(IngestedDocument doc, {String space = 'General Space'}) {
    final excerpt = doc.content.length > 180 ? '${doc.content.substring(0, 180).trim()}...' : doc.content;
    return NoteItem(
      id: newId(),
      title: doc.title,
      space: space,
      tag: doc.extension.toUpperCase().isNotEmpty ? doc.extension.toUpperCase() : 'DOC',
      excerpt: excerpt.isNotEmpty ? excerpt : 'Uploaded ${doc.fileName}',
      content: doc.content,
      updatedAt: DateTime.now(),
    );
  }
}
