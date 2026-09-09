/// Conflict-Free Replicated Data Type (CRDT) Delta Engine
/// Implements a State-based Last-Write-Wins Element-Set (LWW-Element-Set) CRDT
/// ensuring seamless, conflict-free multi-device synchronization across offline environments.
library;

class CrdtRecord<T> {
  final String id;
  final T value;
  final int lamportTimestamp;
  final String deviceId;
  final bool isDeleted;

  CrdtRecord({
    required this.id,
    required this.value,
    required this.lamportTimestamp,
    required this.deviceId,
    this.isDeleted = false,
  });

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) valueToJson) => {
    'id': id,
    'value': valueToJson(value),
    'lamportTimestamp': lamportTimestamp,
    'deviceId': deviceId,
    'isDeleted': isDeleted,
  };
}

class SanctuaryCrdtEngine<T> {
  final String localDeviceId;
  int _localLamportClock = 0;
  final Map<String, CrdtRecord<T>> _store = {};

  SanctuaryCrdtEngine({required this.localDeviceId});

  int _tick() {
    _localLamportClock++;
    return _localLamportClock;
  }

  /// Puts or updates a local record with automatic Lamport timestamp increment
  CrdtRecord<T> set(String id, T value) {
    final timestamp = _tick();
    final record = CrdtRecord<T>(
      id: id,
      value: value,
      lamportTimestamp: timestamp,
      deviceId: localDeviceId,
      isDeleted: false,
    );
    _store[id] = record;
    return record;
  }

  /// Marks a record as tombstones (deleted) in the CRDT set
  CrdtRecord<T>? delete(String id) {
    final existing = _store[id];
    if (existing == null) return null;

    final timestamp = _tick();
    final tombstone = CrdtRecord<T>(
      id: id,
      value: existing.value,
      lamportTimestamp: timestamp,
      deviceId: localDeviceId,
      isDeleted: true,
    );
    _store[id] = tombstone;
    return tombstone;
  }

  /// Merges a foreign peer's delta into local store using LWW rules
  bool mergeRecord(CrdtRecord<T> incoming) {
    // Advance local clock past incoming timestamp
    if (incoming.lamportTimestamp > _localLamportClock) {
      _localLamportClock = incoming.lamportTimestamp;
    }

    final local = _store[incoming.id];
    if (local == null) {
      _store[incoming.id] = incoming;
      return true;
    }

    // Compare timestamps; tie-break deterministically using deviceId hash
    if (incoming.lamportTimestamp > local.lamportTimestamp) {
      _store[incoming.id] = incoming;
      return true;
    } else if (incoming.lamportTimestamp == local.lamportTimestamp) {
      if (incoming.deviceId.compareTo(local.deviceId) > 0) {
        _store[incoming.id] = incoming;
        return true;
      }
    }
    return false; // Local record was newer
  }

  List<T> getActiveValues() {
    return _store.values
        .where((r) => !r.isDeleted)
        .map((r) => r.value)
        .toList();
  }

  List<CrdtRecord<T>> getAllRecords() => _store.values.toList();
}
