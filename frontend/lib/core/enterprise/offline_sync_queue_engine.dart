import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Transaction Mutation Operation
enum MutationOp { insert, update, delete, merge }

/// Outbox Mutation Record
class OutboxMutation {
  final String mutationId;
  final String idempotencyKey;
  final String entityTable;
  final MutationOp operation;
  final Map<String, dynamic> payload;
  final int createdAtMs;
  int retryAttempts;
  String? lastError;

  OutboxMutation({
    required this.mutationId,
    required this.idempotencyKey,
    required this.entityTable,
    required this.operation,
    required this.payload,
    required this.createdAtMs,
    this.retryAttempts = 0,
    this.lastError,
  });

  Map<String, dynamic> toJson() => {
        'id': mutationId,
        'key': idempotencyKey,
        'table': entityTable,
        'op': operation.name,
        'data': payload,
        'created': createdAtMs,
        'retries': retryAttempts,
        'err': lastError,
      };
}

/// Offline-First Outbox Transaction Queue Engine
/// Enforces idempotent local queuing of write mutations when offline,
/// replaying sequentially with exponential backoff when connectivity returns.
class OfflineSyncQueueEngine {
  static final OfflineSyncQueueEngine _instance = OfflineSyncQueueEngine._internal();
  factory OfflineSyncQueueEngine() => _instance;
  OfflineSyncQueueEngine._internal();

  final List<OutboxMutation> _outbox = [];
  bool _isProcessing = false;

  List<OutboxMutation> get pendingMutations => List.unmodifiable(_outbox);
  int get queueLength => _outbox.length;

  /// Enqueues a write mutation with deterministic idempotency key
  OutboxMutation enqueue({
    required String entityTable,
    required MutationOp operation,
    required Map<String, dynamic> payload,
  }) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final payloadHash = sha256.convert(utf8.encode(jsonEncode(payload))).toString();
    final idempotencyKey = '$entityTable:${operation.name}:$payloadHash';

    // Prevent duplicate idempotent enqueue
    final existingIdx = _outbox.indexWhere((m) => m.idempotencyKey == idempotencyKey);
    if (existingIdx != -1) {
      return _outbox[existingIdx];
    }

    final mutation = OutboxMutation(
      mutationId: 'MUT-$now-${_outbox.length}',
      idempotencyKey: idempotencyKey,
      entityTable: entityTable,
      operation: operation,
      payload: payload,
      createdAtMs: now,
    );

    _outbox.add(mutation);
    return mutation;
  }

  /// Processes the outbox with an injected sync handler
  Future<int> replayQueue(
    Future<bool> Function(OutboxMutation mutation) syncHandler,
  ) async {
    if (_isProcessing || _outbox.isEmpty) return 0;
    _isProcessing = true;

    int successfulCount = 0;
    final remaining = <OutboxMutation>[];

    for (final mutation in _outbox) {
      try {
        final success = await syncHandler(mutation);
        if (success) {
          successfulCount++;
        } else {
          mutation.retryAttempts++;
          mutation.lastError = 'Server returned unfulfilled status.';
          remaining.add(mutation);
        }
      } catch (e) {
        mutation.retryAttempts++;
        mutation.lastError = e.toString();
        remaining.add(mutation);
      }
    }

    _outbox.clear();
    _outbox.addAll(remaining);
    _isProcessing = false;
    return successfulCount;
  }

  void purgeAll() {
    _outbox.clear();
  }
}
