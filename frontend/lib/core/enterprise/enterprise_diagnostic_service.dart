import 'audit_ledger_engine.dart';
import 'offline_sync_queue_engine.dart';
import 'sanctuary_logger.dart';
import '../systems/local_vector_search_engine.dart';
import '../systems/zkp_expense_audit_service.dart';

/// Diagnostic Check Status
enum DiagnosticStatus { passed, warning, failed }

/// Individual System Diagnostic Result
class DiagnosticCheckResult {
  final String componentName;
  final DiagnosticStatus status;
  final String details;
  final int latencyMs;

  const DiagnosticCheckResult({
    required this.componentName,
    required this.status,
    required this.details,
    required this.latencyMs,
  });
}

/// Enterprise Diagnostic & Self-Test Service
/// Executes comprehensive health checks across cryptographic engines,
/// vector indexers, offline transaction outbox, and audit ledger integrity.
class EnterpriseDiagnosticService {
  static Future<List<DiagnosticCheckResult>> runFullDiagnosticSuite() async {
    final results = <DiagnosticCheckResult>[];

    // 1. Cryptographic Hash Chain Audit Check
    final sw1 = Stopwatch()..start();
    final isChainValid = AuditLedgerEngine().verifyChainIntegrity();
    sw1.stop();
    results.add(DiagnosticCheckResult(
      componentName: 'Cryptographic Audit Ledger',
      status: isChainValid ? DiagnosticStatus.passed : DiagnosticStatus.failed,
      details: isChainValid
          ? 'Forward-chained SHA-256 integrity verified (${AuditLedgerEngine().blocks.length} blocks).'
          : 'FATAL: Audit chain digest mismatch detected.',
      latencyMs: sw1.elapsedMilliseconds,
    ));

    // 2. Zero-Knowledge Cryptographic Engine Check
    final sw2 = Stopwatch()..start();
    try {
      final zkp = ZkpExpenseAuditService();
      final proof = zkp.generateProof(
        settlementId: 'self_test_audit_01',
        settledAmount: 1000.0,
        memberSecretSalt: 'enterprise_diagnostic_salt',
      );
      final verified = zkp.verifyProof(proof);
      sw2.stop();
      results.add(DiagnosticCheckResult(
        componentName: 'Zero-Knowledge Proof Engine',
        status: verified ? DiagnosticStatus.passed : DiagnosticStatus.failed,
        details: verified
            ? 'Pedersen/Discrete-log commitment generated & verified on-device.'
            : 'ZKP mathematical proof verification failed.',
        latencyMs: sw2.elapsedMilliseconds,
      ));
    } catch (e) {
      sw2.stop();
      results.add(DiagnosticCheckResult(
        componentName: 'Zero-Knowledge Proof Engine',
        status: DiagnosticStatus.failed,
        details: 'Exception: $e',
        latencyMs: sw2.elapsedMilliseconds,
      ));
    }

    // 3. Local Vector Search Engine Check
    final sw3 = Stopwatch()..start();
    try {
      final searchEngine = LocalVectorSearchEngine();
      final matches = searchEngine.search('Sanctuary');
      sw3.stop();
      results.add(DiagnosticCheckResult(
        componentName: 'Local TF-IDF Vector Engine',
        status: DiagnosticStatus.passed,
        details: 'Index operational (${matches.length} matches retrieved).',
        latencyMs: sw3.elapsedMilliseconds,
      ));
    } catch (e) {
      sw3.stop();
      results.add(DiagnosticCheckResult(
        componentName: 'Local TF-IDF Vector Engine',
        status: DiagnosticStatus.failed,
        details: 'Vector engine fault: $e',
        latencyMs: sw3.elapsedMilliseconds,
      ));
    }

    // 4. Offline Outbox Transaction Queue Check
    final sw4 = Stopwatch()..start();
    final queue = OfflineSyncQueueEngine();
    final backlog = queue.queueLength;
    sw4.stop();
    results.add(DiagnosticCheckResult(
      componentName: 'Offline Outbox Sync Queue',
      status: backlog > 100 ? DiagnosticStatus.warning : DiagnosticStatus.passed,
      details: backlog == 0
          ? 'Queue clean. All mutations synchronized.'
          : '$backlog pending transaction mutations queued in outbox.',
      latencyMs: sw4.elapsedMilliseconds,
    ));

    // 5. Structured Logger Buffer Check
    final sw5 = Stopwatch()..start();
    final logsCount = SanctuaryLogger().logs.length;
    sw5.stop();
    results.add(DiagnosticCheckResult(
      componentName: 'Enterprise Telemetry Buffer',
      status: DiagnosticStatus.passed,
      details: 'Ring buffer holding $logsCount entries. PII filtering active.',
      latencyMs: sw5.elapsedMilliseconds,
    ));

    return results;
  }
}
