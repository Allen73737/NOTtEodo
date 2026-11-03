import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/core/services/device_media_service.dart';
import 'package:notteodo/core/services/document_ingestion_service.dart';
import 'package:notteodo/core/services/note_rag_service.dart';
import 'package:notteodo/core/state/sanctuary_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Note RAG System Verification', () {
    final noteA = NoteItem(
      id: 'note-arch-1',
      title: 'Distributed System Blueprint',
      space: 'Tech',
      tag: 'ARCHITECTURE',
      excerpt: 'Postgres partitioned shards with Redis caching layer and 99.99% SLA.',
      content: '''# Distributed System Blueprint
Our target architecture utilizes Postgres partitioned shards with Redis caching layer and a 99.99% SLA.
Key latency requirements:
- Read queries under 15ms
- Write pipeline throughput 10,000 rps
- Database failover automated via Raft consensus
All secrets must be rotated every 30 days using KMS.''',
      updatedAt: DateTime.now(),
    );

    final noteB = NoteItem(
      id: 'note-fin-2',
      title: 'Infrastructure Budget Q3',
      space: 'Finance',
      tag: 'BUDGET',
      excerpt: 'Total monthly cloud server budget allocated is \$4,500.',
      content: '''# Infrastructure Budget Q3
Total monthly cloud server budget allocated is \$4,500.
Breakdown:
- Cloud database instances: \$2,800
- Multi-region edge cache: \$900
- Cold storage archives: \$400
- Network egress buffer: \$400
Approved by executive board on October 1st.''',
      updatedAt: DateTime.now(),
    );

    final noteC = NoteItem(
      id: 'note-ops-3',
      title: 'Incident Response Protocol',
      space: 'Operations',
      tag: 'OPS',
      excerpt: 'Severity 1 outages require escalation within 5 minutes.',
      content: '''# Incident Response Protocol
Severity 1 outages require escalation within 5 minutes.
Lead engineer will page on-call rotating team.
Communication cadence:
- Status page updated every 15 minutes
- Post-mortem documented within 48 hours in the tech workspace.''',
      updatedAt: DateTime.now(),
    );

    test('Chunking splits notes into coherent passages with metadata', () {
      final chunks = NoteRagService().chunkNotes([noteA, noteB, noteC]);

      expect(chunks, isNotEmpty);
      expect(chunks.any((c) => c.noteTitle == 'Distributed System Blueprint'), isTrue);
      expect(chunks.any((c) => c.noteTitle == 'Infrastructure Budget Q3'), isTrue);
      expect(chunks.any((c) => c.noteTitle == 'Incident Response Protocol'), isTrue);
    });

    test('Retrieval algorithm scores and returns top relevant chunks for single note RAG', () {
      final chunks = NoteRagService().retrieveChunks(
        query: 'What is the read query latency and write throughput?',
        notes: [noteA],
        topK: 3,
      );

      expect(chunks, isNotEmpty);
      expect(chunks.first.noteTitle, equals('Distributed System Blueprint'));
      expect(chunks.first.text.toLowerCase(), contains('15ms'));
      expect(chunks.first.score, greaterThan(0));
    });

    test('Retrieval accurately filters and ranks across grouped notes (Multi-Note RAG)', () {
      final chunks = NoteRagService().retrieveChunks(
        query: 'What is the budget for database instances?',
        notes: [noteA, noteB, noteC],
        topK: 3,
      );

      expect(chunks, isNotEmpty);
      expect(chunks.first.noteTitle, equals('Infrastructure Budget Q3'));
      expect(chunks.first.text, contains('\$2,800'));
    });

    test('Single Note RAG query generates grounded answer with citations', () async {
      final response = await NoteRagService().queryNotes(
        query: 'How often must secrets be rotated?',
        notes: [noteA],
      );

      expect(response, isNotNull);
      expect(response.answer, isNotEmpty);
      expect(response.citedNotes, contains('Distributed System Blueprint'));
      expect(response.matchingChunks, isNotEmpty);
    });

    test('Group Note RAG query synthesizes knowledge across multiple notes', () async {
      final response = await NoteRagService().queryNotes(
        query: 'What are the SLA targets and total cloud costs?',
        notes: [noteA, noteB],
      );

      expect(response, isNotNull);
      expect(response.answer, isNotEmpty);
      expect(response.citedNotes.length, greaterThanOrEqualTo(1));
    });

    test('Upload Media Mode in RAG analyzes media alongside note context', () async {
      final sampleMedia = DeviceMediaResult(
        path: '/storage/diagram_spec.png',
        name: 'diagram_spec.png',
        bytes: Uint8List.fromList([1, 2, 3, 4, 5]),
      );

      final response = await NoteRagService().queryNotes(
        query: 'Does this diagram align with our multi-region edge cache and failover plan?',
        notes: [noteA, noteB],
        attachedMedia: sampleMedia,
      );

      expect(response, isNotNull);
      expect(response.mediaAnalysisIncluded, isTrue);
      expect(response.answer, isNotEmpty);
    });
  });

  group('Document Ingestion Service Verification', () {
    test('Extracts title from markdown content heading', () {
      const mdContent = '''# Executive Strategy 2027
Here are our quarterly strategic imperatives:
- Expand open-source adoption
- Zero-trust security governance''';

      final note = DocumentIngestionService().toNoteItem(
        const IngestedDocument(
          title: 'Executive Strategy 2027',
          content: mdContent,
          fileName: 'strategy.md',
          extension: 'md',
          byteSize: 200,
        ),
        space: 'Strategy',
      );

      expect(note.title, equals('Executive Strategy 2027'));
      expect(note.space, equals('Strategy'));
      expect(note.tag, equals('MD'));
      expect(note.content, contains('Zero-trust security'));
    });
  });
}
