import 'dart:async';

import 'package:flutter/foundation.dart';

import '../enterprise/offline_sync_queue_engine.dart';
import '../security/sync_keyring.dart';
import '../state/sanctuary_state.dart';
import 'local_store.dart';
import 'sanctuary_supabase_service.dart';

enum SyncPhase { localOnly, idle, syncing, error, needsPassphrase, needsMfa }

@immutable
class SyncStatus {
  final SyncPhase phase;
  final DateTime? lastSyncAt;
  final String? message;

  const SyncStatus(this.phase, {this.lastSyncAt, this.message});

  String get label => switch (phase) {
        SyncPhase.localOnly => 'Saved on this device',
        SyncPhase.idle => 'Synced',
        SyncPhase.syncing => 'Syncing…',
        SyncPhase.error => 'Sync paused',
        SyncPhase.needsPassphrase => 'Enter your encryption passphrase to sync',
        SyncPhase.needsMfa => 'Two-step verification needed to sync',
      };
}

/// Keeps each collection mirrored to the signed-in user's `user_collections` rows.
///
/// Every local write marks its collection dirty and queues a push through the
/// [OfflineSyncQueueEngine]; a pull takes the server copy when only the server
/// changed, and merges by id (local wins) when both sides changed.
class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  static const String _metaKey = 'sync.meta';
  static const Duration _pushDelay = Duration(seconds: 2);

  final ValueNotifier<SyncStatus> status = ValueNotifier(const SyncStatus(SyncPhase.localOnly));

  VoidCallback? _onReload;
  Timer? _pushTimer;
  StreamSubscription<dynamic>? _authSub;
  bool _started = false;

  /// [onReload] re-reads every provider after a pull changed stored data.
  void start({required VoidCallback onReload}) {
    if (_started) return;
    _started = true;
    _onReload = onReload;
    LocalStore().addWriteListener(_onLocalWrite);

    // Re-queue anything edited while offline in an earlier session.
    for (final c in _dirtyCollections()) {
      _enqueue(c);
    }

    _authSub = SanctuarySupabaseService().authChanges?.listen((_) => syncNow());
    syncNow();
  }

  /// After sign-out, forget sync bookkeeping so the next account starts from its own
  /// server copy instead of merging in this device's data from the previous account.
  void resetForAccountChange() {
    _pushTimer?.cancel();
    OfflineSyncQueueEngine().purgeAll();
    LocalStore().writeMap(_metaKey, {'local': {}, 'synced': {}});
    SyncKeyring().forget();
    _setStatus(SyncPhase.localOnly);
  }

  /// Marks every collection changed and pushes it, e.g. after turning
  /// end-to-end encryption on or off so the cloud copy is rewritten.
  Future<void> pushEverything() async {
    final now = DateTime.now();
    for (final c in dataCollections) {
      _setStamp('local', c, now);
      _enqueue(c);
    }
    _pushTimer?.cancel();
    await push();
  }

  /// Sync only runs while signed in and while this device's vault is unlocked;
  /// a locked vault reads as empty and must never be pushed.
  bool get _canSync => SanctuarySupabaseService().isConnectedToCloud && LocalStore().isReady;

  @visibleForTesting
  void stop() {
    LocalStore().removeWriteListener(_onLocalWrite);
    _authSub?.cancel();
    _pushTimer?.cancel();
    _started = false;
  }

  // --- Bookkeeping -----------------------------------------------------------

  Map<String, dynamic> get _meta => LocalStore().readMap(_metaKey) ?? {'local': {}, 'synced': {}};

  DateTime? _stamp(String bucket, String c) {
    final v = (_meta[bucket] as Map?)?[c];
    return v is String ? DateTime.tryParse(v) : null;
  }

  void _setStamp(String bucket, String c, DateTime at) {
    final meta = _meta;
    final m = Map<String, dynamic>.from(meta[bucket] as Map? ?? {});
    m[c] = at.toUtc().toIso8601String();
    meta[bucket] = m;
    LocalStore().writeMap(_metaKey, meta);
  }

  bool _isDirty(String c) {
    final local = _stamp('local', c);
    if (local == null) return false;
    final synced = _stamp('synced', c);
    return synced == null || local.isAfter(synced);
  }

  Iterable<String> _dirtyCollections() => dataCollections.where(_isDirty);

  void _onLocalWrite(String key) {
    if (!dataCollections.contains(key)) return;
    _setStamp('local', key, DateTime.now());
    _enqueue(key);
  }

  void _enqueue(String collection) {
    OfflineSyncQueueEngine().enqueue(
      entityTable: 'user_collections',
      operation: MutationOp.update,
      payload: {'collection': collection},
    );
    _schedulePush();
  }

  void _schedulePush() {
    if (!_canSync) return;
    _pushTimer?.cancel();
    _pushTimer = Timer(_pushDelay, push);
  }

  // --- Push / Pull -----------------------------------------------------------

  Future<void> push() async {
    final cloud = SanctuarySupabaseService();
    if (!_canSync) return;
    final keyring = SyncKeyring();
    if (keyring.state.value == E2eeState.unknown) await keyring.refresh();
    if (keyring.blocksPush) {
      _setStatus(keyring.state.value == E2eeState.needsPassphrase ? SyncPhase.needsPassphrase : SyncPhase.error,
          message: keyring.state.value == E2eeState.needsPassphrase ? null : 'Could not reach the server.');
      return;
    }
    _setStatus(SyncPhase.syncing);
    final snapshot = LocalStore().dumpAll();
    try {
      await OfflineSyncQueueEngine().replayQueue((m) async {
        final c = m.payload['collection'] as String?;
        if (c == null) return true;
        final localAt = _stamp('local', c) ?? DateTime.now();
        final rows = snapshot[c] ?? const [];
        await cloud.pushCollection(c, keyring.isActive ? await keyring.seal(c, rows) : rows, localAt);
        _setStamp('synced', c, localAt);
        return true;
      });
      final failed = OfflineSyncQueueEngine().queueLength;
      _setStatus(failed == 0 ? SyncPhase.idle : SyncPhase.error,
          message: failed == 0 ? null : '$failed collection(s) will retry.');
    } catch (e) {
      _setStatus(SyncPhase.error, message: e.toString());
    }
  }

  Future<void> pull() async {
    final cloud = SanctuarySupabaseService();
    if (!_canSync) return;
    final keyring = SyncKeyring();
    final rows = await cloud.pullCollections();
    var changed = false;
    for (final row in rows) {
      final c = row['collection'] as String?;
      if (c == null || !dataCollections.contains(c)) continue;
      final remoteAt = DateTime.tryParse(row['updated_at']?.toString() ?? '');
      final data = row['data'];
      final List<Map<String, dynamic>>? remote = SyncKeyring.isEnvelope(data)
          // Ciphertext that this key cannot open (e.g. after a passphrase reset) is skipped
          // and later overwritten by this device's copy.
          ? await keyring.open(c, data)
          : (data as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      if (remoteAt == null || remote == null) continue;

      final synced = _stamp('synced', c);
      if (synced != null && !remoteAt.isAfter(synced)) continue; // nothing new on the server

      if (_isDirty(c)) {
        final local = (LocalStore().dumpAll()[c] as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        // Writing with notify keeps the collection dirty, so the merge is pushed back.
        LocalStore().writeList(c, mergeById(local: local, remote: remote));
      } else {
        LocalStore().writeList(c, remote, notify: false);
        _setStamp('local', c, remoteAt);
      }
      _setStamp('synced', c, remoteAt);
      changed = true;
    }
    if (changed) _onReload?.call();
  }

  /// Pull, then push whatever is still pending.
  Future<void> syncNow() async {
    final cloud = SanctuarySupabaseService();
    if (!cloud.isConnectedToCloud) {
      _setStatus(SyncPhase.localOnly);
      return;
    }
    if (!LocalStore().isReady) return; // resumes from the unlock flow
    _setStatus(SyncPhase.syncing);
    try {
      if (await cloud.needsMfaStepUp()) {
        _setStatus(SyncPhase.needsMfa);
        return;
      }
      final e2ee = await SyncKeyring().refresh();
      if (e2ee == E2eeState.needsPassphrase) {
        _setStatus(SyncPhase.needsPassphrase);
        return;
      }
      await pull();
      for (final c in _dirtyCollections()) {
        _enqueue(c);
      }
      _pushTimer?.cancel();
      await push();
      if (status.value.phase == SyncPhase.syncing) _setStatus(SyncPhase.idle);
    } catch (e) {
      _setStatus(SyncPhase.error, message: e.toString());
    }
  }

  void _setStatus(SyncPhase phase, {String? message}) {
    status.value = SyncStatus(
      phase,
      lastSyncAt: phase == SyncPhase.idle ? DateTime.now() : status.value.lastSyncAt,
      message: message,
    );
  }

  /// Union of both lists by `id`; on a clash the local row wins. Local order first.
  static List<Map<String, dynamic>> mergeById({
    required List<Map<String, dynamic>> local,
    required List<Map<String, dynamic>> remote,
  }) {
    final seen = <Object?>{};
    final out = <Map<String, dynamic>>[];
    for (final row in [...local, ...remote]) {
      final id = row['id'];
      if (id == null || seen.add(id)) out.add(row);
    }
    return out;
  }
}
