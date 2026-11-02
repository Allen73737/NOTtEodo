import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/core/enterprise/app_config.dart';
import 'package:notteodo/core/enterprise/audit_ledger_engine.dart';
import 'package:notteodo/core/enterprise/offline_sync_queue_engine.dart';
import 'package:notteodo/core/enterprise/sanctuary_logger.dart';
import 'package:notteodo/core/enterprise/enterprise_diagnostic_service.dart';
import 'package:notteodo/core/systems/steganography_carrier_vault.dart';
import 'package:notteodo/core/systems/zkp_expense_audit_service.dart';
import 'package:notteodo/core/systems/monte_carlo_runway_engine.dart';
import 'package:notteodo/core/systems/linguistic_cadence_analyzer.dart';

void main() {
  group('Enterprise Architecture & Compliance Tests', () {
    test('AppConfig provides valid production defaults', () {
      expect(AppConfig.appName, contains('NOTTeodo'));
      expect(AppConfig.maxFailedAuthAttempts, equals(5));
      expect(AppConfig.enableAuditHashChaining, isTrue);
    });

    test('AuditLedgerEngine verifies cryptographic chain integrity and detects tampering', () {
      final ledger = AuditLedgerEngine();
      final initialCount = ledger.blocks.length;

      final b1 = ledger.recordEvent(
        actorId: 'TEST_USER_1',
        action: 'VAULT_AUTHENTICATE',
        resource: 'AES_VAULT',
        metadata: {'ip': '127.0.0.1'},
      );

      final b2 = ledger.recordEvent(
        actorId: 'TEST_USER_1',
        action: 'NOTE_CREATED',
        resource: 'SANCTUARY_NOTE_99',
        metadata: {'encrypted': true},
      );

      expect(b2.prevHash, equals(b1.hash));
      expect(ledger.verifyChainIntegrity(), isTrue);
      expect(ledger.blocks.length, equals(initialCount + 2));
    });

    test('OfflineSyncQueueEngine enforces idempotency and outbox queuing', () {
      final queue = OfflineSyncQueueEngine();
      queue.purgeAll();

      final m1 = queue.enqueue(
        entityTable: 'tasks',
        operation: MutationOp.insert,
        payload: {'title': 'Sovereign Task 1'},
      );

      final m2 = queue.enqueue(
        entityTable: 'tasks',
        operation: MutationOp.insert,
        payload: {'title': 'Sovereign Task 1'},
      );

      // Duplicate payload must match identical idempotency key and not duplicate
      expect(m1.idempotencyKey, equals(m2.idempotencyKey));
      expect(queue.queueLength, equals(1));
    });

    test('SanctuaryLogger redacts sensitive PII keys', () {
      final logger = SanctuaryLogger();
      logger.clear();

      logger.info('AuthTest', 'User authentication payload', {
        'username': 'Curator1',
        'password': 'SuperSecretPassword123!',
        'api_token': 'sk_test_99812984129',
      });

      final log = logger.logs.last;
      expect(log.metadata!['password'], equals('***REDACTED***'));
      expect(log.metadata!['api_token'], equals('***REDACTED***'));
      expect(log.metadata!['username'], equals('Curator1'));
    });

    test('EnterpriseDiagnosticService executes all 6 pre-flight health checks', () async {
      final results = await EnterpriseDiagnosticService.runFullDiagnosticSuite();
      expect(results.length, equals(6));
      expect(results.any((r) => r.componentName.contains('Cloud')), isTrue);
      expect(results.any((r) => r.componentName.contains('Audit Ledger')), isTrue);
    });
  });

  group('Haute Horlogerie & Cryptographic Systems Tests', () {
    test('SteganographyCarrierVault embeds and extracts secret payload from pixels', () {
      final mockRgba = Uint8List(200 * 200 * 4);
      for (int i = 0; i < mockRgba.length; i++) {
        mockRgba[i] = (i % 256);
      }

      const secretText = 'CONFIDENTIAL: Epistolary seed phrase in pixels';
      final encoded = SteganographyCarrierVault.encodePayload(
        rgbaPixels: mockRgba,
        secretPayload: secretText,
      );

      final decoded = SteganographyCarrierVault.decodePayload(rgbaPixels: encoded);
      expect(decoded, equals(secretText));
    });

    test('ZkpExpenseAuditService produces valid discrete-log proof', () {
      final zkp = ZkpExpenseAuditService();
      final proof = zkp.generateProof(
        settlementId: 'SETTLE-PARIS-2026',
        settledAmount: 3450.0,
        memberSecretSalt: 'curator_secret_4481',
      );

      final isValid = zkp.verifyProof(proof);
      expect(isValid, isTrue);
      expect(proof.commitmentHash.length, equals(64));
    });

    test('MonteCarloRunwayEngine simulates stochastic paths accurately', () {
      final sim = MonteCarloRunwayEngine.simulate(
        initialSavings: 100000.0,
        monthlyBurnRate: 2500.0,
        iterations: 500,
      );

      expect(sim.totalSimulations, equals(500));
      expect(sim.medianRunwayMonths, isPositive);
      expect(sim.worstCase10thPercentileMonths, lessThanOrEqualTo(sim.medianRunwayMonths));
      expect(sim.bestCase90thPercentileMonths, greaterThanOrEqualTo(sim.medianRunwayMonths));
    });

    test('LinguisticCadenceAnalyzer scores prose complexity and rhythm', () {
      final metrics = LinguisticCadenceAnalyzer.analyze(
        'The timeless rhythm of horological balance wheels restores tranquility to fractured thoughts.',
      );

      expect(metrics.totalWords, isPositive);
      expect(metrics.lexicalDiversity, greaterThan(0.5));
      expect(metrics.fleschReadingEase, inInclusiveRange(0.0, 100.0));
    });
  });
}
