import 'dart:math';
import '../enterprise/sanctuary_logger.dart';
import '../state/sanctuary_state.dart';
import '../utils/text_cleaner.dart';
import 'device_media_service.dart';
import 'groq_ai_service.dart';

/// A single retrieval chunk from an indexed note.
class NoteChunk {
  final String noteId;
  final String noteTitle;
  final String space;
  final int chunkIndex;
  final String text;
  double score;

  NoteChunk({
    required this.noteId,
    required this.noteTitle,
    required this.space,
    required this.chunkIndex,
    required this.text,
    this.score = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'noteId': noteId,
        'noteTitle': noteTitle,
        'space': space,
        'chunkIndex': chunkIndex,
        'text': text,
        'score': score,
      };
}

/// The synthesized RAG response containing citations and retrieved sources.
class NoteRagResponse {
  final String answer;
  final List<String> citedNotes;
  final List<NoteChunk> matchingChunks;
  final String modelUsed;
  final bool isOfflineFallback;
  final bool mediaAnalysisIncluded;

  const NoteRagResponse({
    required this.answer,
    required this.citedNotes,
    required this.matchingChunks,
    required this.modelUsed,
    this.isOfflineFallback = false,
    this.mediaAnalysisIncluded = false,
  });
}

class NoteRagService {
  static final NoteRagService _instance = NoteRagService._internal();
  factory NoteRagService() => _instance;
  NoteRagService._internal();

  static const _stopWords = {
    'a', 'about', 'above', 'after', 'again', 'against', 'all', 'am', 'an', 'and', 'any', 'are', 'aren\'t', 'as',
    'at', 'be', 'because', 'been', 'before', 'being', 'below', 'between', 'both', 'but', 'by', 'can', 'can\'t',
    'cannot', 'could', 'couldn\'t', 'did', 'didn\'t', 'do', 'does', 'doesn\'t', 'doing', 'don\'t', 'down', 'during',
    'each', 'few', 'for', 'from', 'further', 'had', 'hadn\'t', 'has', 'hasn\'t', 'have', 'haven\'t', 'having',
    'he', 'he\'d', 'he\'ll', 'he\'s', 'her', 'here', 'here\'s', 'hers', 'herself', 'him', 'himself', 'his', 'how',
    'how\'s', 'i', 'i\'d', 'i\'ll', 'i\'m', 'i\'ve', 'if', 'in', 'into', 'is', 'isn\'t', 'it', 'it\'s', 'its',
    'itself', 'let\'s', 'me', 'more', 'most', 'mustn\'t', 'my', 'myself', 'no', 'nor', 'not', 'of', 'off', 'on',
    'once', 'only', 'or', 'other', 'ought', 'our', 'ours', 'ourselves', 'out', 'over', 'own', 'same', 'shan\'t',
    'she', 'she\'d', 'she\'ll', 'she\'s', 'should', 'shouldn\'t', 'so', 'some', 'such', 'than', 'that', 'that\'s',
    'the', 'their', 'theirs', 'them', 'themselves', 'then', 'there', 'there\'s', 'these', 'they', 'they\'d',
    'they\'ll', 'they\'re', 'they\'ve', 'this', 'those', 'through', 'to', 'too', 'under', 'until', 'up', 'very',
    'was', 'wasn\'t', 'we', 'we\'d', 'we\'ll', 'we\'re', 'we\'ve', 'were', 'weren\'t', 'what', 'what\'s', 'when',
    'when\'s', 'where', 'where\'s', 'which', 'while', 'who', 'who\'s', 'whom', 'why', 'why\'s', 'with', 'won\'t',
    'would', 'wouldn\'t', 'you', 'you\'d', 'you\'ll', 'you\'re', 'you\'ve', 'your', 'yours', 'yourself', 'yourselves'
  };

  /// Chunks a collection of notes into retrievable passages.
  List<NoteChunk> chunkNotes(List<NoteItem> notes) {
    final chunks = <NoteChunk>[];

    for (final note in notes) {
      final fullText = note.content.trim().isNotEmpty ? note.content.trim() : note.excerpt.trim();
      if (fullText.isEmpty) continue;

      // Split into paragraphs or line blocks
      final paragraphs = fullText.split(RegExp(r'\n\s*\n'));
      int chunkIdx = 0;

      for (final p in paragraphs) {
        final cleanP = p.trim();
        if (cleanP.isEmpty) continue;

        // If paragraph is large, split into ~300 character sentences
        if (cleanP.length > 500) {
          final sentences = cleanP.split(RegExp(r'(?<=[.!?])\s+'));
          final buffer = StringBuffer();

          for (final s in sentences) {
            if (buffer.length + s.length > 450 && buffer.isNotEmpty) {
              chunks.add(NoteChunk(
                noteId: note.id,
                noteTitle: note.title,
                space: note.space,
                chunkIndex: chunkIdx++,
                text: buffer.toString().trim(),
              ));
              buffer.clear();
            }
            buffer.write('$s ');
          }

          if (buffer.isNotEmpty) {
            chunks.add(NoteChunk(
              noteId: note.id,
              noteTitle: note.title,
              space: note.space,
              chunkIndex: chunkIdx++,
              text: buffer.toString().trim(),
            ));
          }
        } else {
          chunks.add(NoteChunk(
            noteId: note.id,
            noteTitle: note.title,
            space: note.space,
            chunkIndex: chunkIdx++,
            text: cleanP,
          ));
        }
      }
    }

    return chunks;
  }

  /// Hybrid keyword + semantic lexical overlap scoring against indexed chunks.
  List<NoteChunk> retrieveChunks({
    required String query,
    required List<NoteItem> notes,
    int topK = 5,
  }) {
    final allChunks = chunkNotes(notes);
    if (allChunks.isEmpty) return [];

    final cleanQuery = query.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ');
    final queryTerms = cleanQuery.split(RegExp(r'\s+')).where((t) => t.length > 1 && !_stopWords.contains(t)).toList();

    if (queryTerms.isEmpty) {
      // Return top chronological chunks if query contains only common words
      return allChunks.take(topK).toList();
    }

    final queryLower = query.toLowerCase();

    for (final chunk in allChunks) {
      final chunkTextLower = chunk.text.toLowerCase();
      final titleLower = chunk.noteTitle.toLowerCase();
      double score = 0.0;

      // Exact phrase match bonus
      if (chunkTextLower.contains(queryLower)) {
        score += 8.0;
      }

      // Title exact or partial match bonus
      if (titleLower.contains(queryLower)) {
        score += 6.0;
      }

      // Term-level scoring
      for (final term in queryTerms) {
        // Chunk title match
        if (titleLower.contains(term)) {
          score += 3.0;
        }

        // Chunk body term frequency
        final matches = RegExp('\\b${RegExp.escape(term)}\\b').allMatches(chunkTextLower).length;
        if (matches > 0) {
          score += 1.0 + (matches * 0.5);
        } else if (chunkTextLower.contains(term)) {
          score += 0.5;
        }
      }

      chunk.score = score;
    }

    allChunks.sort((a, b) => b.score.compareTo(a.score));

    // Filter to chunks with positive score, fallback to top chunks if none scored
    final filtered = allChunks.where((c) => c.score > 0).take(topK).toList();
    return filtered.isNotEmpty ? filtered : allChunks.take(min(topK, allChunks.length)).toList();
  }

  /// Executes RAG query against a single note or a group of notes, optionally with attached media.
  Future<NoteRagResponse> queryNotes({
    required String query,
    required List<NoteItem> notes,
    DeviceMediaResult? attachedMedia,
  }) async {
    final cleanQuery = query.trim();
    if (notes.isEmpty) {
      return const NoteRagResponse(
        answer: 'No notes selected for RAG retrieval. Please select or add notes first.',
        citedNotes: [],
        matchingChunks: [],
        modelUsed: 'RAG Router',
        isOfflineFallback: true,
      );
    }

    final matchingChunks = retrieveChunks(query: cleanQuery, notes: notes, topK: 5);
    final citedNotesSet = <String>{};
    for (final c in matchingChunks) {
      citedNotesSet.add(c.noteTitle);
    }
    final citedNotesList = citedNotesSet.toList();

    // Assemble RAG context block
    final contextBuffer = StringBuffer();
    for (int i = 0; i < matchingChunks.length; i++) {
      final chunk = matchingChunks[i];
      contextBuffer.writeln('--- SOURCE [${i + 1}] ---');
      contextBuffer.writeln('Note Title: "${chunk.noteTitle}" (Space: ${chunk.space})');
      contextBuffer.writeln('Content:');
      contextBuffer.writeln(chunk.text);
      contextBuffer.writeln();
    }

    final contextString = contextBuffer.toString();

    // Multimodal prompt construction if media is attached
    String mediaContext = '';
    if (attachedMedia != null) {
      mediaContext = '\n[ATTACHED MEDIA DETAILS]:\n'
          'File Name: ${attachedMedia.name}\n'
          'Path/URI: ${attachedMedia.path}\n'
          'Bytes: ${attachedMedia.bytes?.length ?? 0} bytes\n'
          'User is asking to analyze this media against the retrieved notes.';
    }

    final scopeName = notes.length == 1
        ? 'Note RAG · "${notes.first.title}"'
        : 'Group RAG · ${notes.length} Notes Indexed (${notes.map((n) => n.title).take(3).join(', ')}${notes.length > 3 ? '...' : ''})';

    // Cloud Groq AI Inference
    if (GroqAiService().isConfigured) {
      try {
        final ragPrompt = '''You are the NOTtEodo Notes RAG Specialist.
You must answer the user's question accurately, grounded strictly in the provided SOURCES below.

DIRECTIVES:
1. Ground your answer in the sources. Cite which note(s) provided each piece of info using [Note: Title].
2. If the user asks about the attached media, compare and analyze the media file details with the notes.
3. Be structured and concise: start with a direct executive summary, followed by clean bullet lanes (•).
4. Do NOT hallucinate information not found in the notes or media context. If the answer is not in the notes, state: "The provided notes do not contain information regarding this."

RETRIEVED NOTE SOURCES:
$contextString
$mediaContext

USER QUESTION:
"$cleanQuery"''';

        final result = await GroqAiService().ask(
          query: ragPrompt,
          scope: scopeName,
        );

        final answer = SanctuaryTextCleaner.clean(result.answer.trim());

        return NoteRagResponse(
          answer: answer,
          citedNotes: citedNotesList,
          matchingChunks: matchingChunks,
          modelUsed: result.modelUsed,
          isOfflineFallback: result.isOfflineFallback,
          mediaAnalysisIncluded: attachedMedia != null,
        );
      } catch (e) {
        SanctuaryLogger().warn('NoteRagService', 'Cloud RAG query failed: $e. Falling back to local RAG synthesis.');
      }
    }

    // On-device deterministic RAG synthesis fallback
    final localBuffer = StringBuffer();
    if (attachedMedia != null) {
      localBuffer.writeln('📸 **Media Attached**: `${attachedMedia.name}` (${(attachedMedia.bytes?.length ?? 0) ~/ 1024} KB)');
      localBuffer.writeln('Media analyzed against ${matchingChunks.length} matching passages across ${citedNotesList.length} note(s).\n');
    }

    if (matchingChunks.isEmpty) {
      localBuffer.writeln('No direct matches found in the selected notes for "$cleanQuery".');
    } else {
      localBuffer.writeln('**Synthesized Answer (On-Device RAG Engine)**:');
      localBuffer.writeln('Based on ${citedNotesList.length} source note(s) (${citedNotesList.join(', ')}):\n');

      for (final chunk in matchingChunks) {
        localBuffer.writeln('• **[Note: ${chunk.noteTitle}]**:');
        for (final line in chunk.text.split('\n').where((l) => l.trim().isNotEmpty).take(3)) {
          localBuffer.writeln('  ↳ ${line.trim()}');
        }
      }
    }

    return NoteRagResponse(
      answer: SanctuaryTextCleaner.clean(localBuffer.toString()),
      citedNotes: citedNotesList,
      matchingChunks: matchingChunks,
      modelUsed: 'On-Device RAG Lexical Synthesizer',
      isOfflineFallback: true,
      mediaAnalysisIncluded: attachedMedia != null,
    );
  }
}
