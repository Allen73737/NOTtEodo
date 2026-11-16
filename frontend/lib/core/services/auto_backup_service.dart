import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/sanctuary_state.dart';
import 'data_portability_service.dart';
import 'local_store.dart';

/// Manages automatic weekly backups of all Sanctuary notes, tasks, expenses, and data.
/// Snapshots are safely preserved on local device storage and can be restored with one tap.
class AutoBackupService {
  static final AutoBackupService _instance = AutoBackupService._internal();
  factory AutoBackupService() => _instance;
  AutoBackupService._internal();

  static const String _enabledKey = 'auto_backup_enabled';
  static const String _timestampKey = 'auto_backup_last_time';
  static const String _snapshotKey = 'auto_backup_snapshot';

  /// Whether automatic weekly backups are active. Default is true.
  bool get isEnabled {
    return LocalStore().readBool(_enabledKey) ?? true;
  }

  /// Sets automatic backup toggle.
  void setEnabled(bool enabled) {
    LocalStore().writeBool(_enabledKey, enabled);
  }

  /// Returns the timestamp of the most recent automated backup, or null if none.
  DateTime? get lastBackupDate {
    final ms = LocalStore().readInt(_timestampKey);
    if (ms != null && ms > 0) {
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return null;
  }

  /// Returns true if an automated backup snapshot is stored on this device.
  bool get hasSnapshot {
    final raw = LocalStore().readString(_snapshotKey);
    return raw != null && raw.trim().isNotEmpty;
  }

  /// Retrieves the stored snapshot JSON string, if any.
  String? get latestSnapshotJson => LocalStore().readString(_snapshotKey);

  /// Checks if 7 days have passed since the last backup (or if never run).
  /// If due and enabled, takes a fresh snapshot and saves it locally.
  Future<bool> checkAndRunAutoBackup() async {
    if (!isEnabled) return false;

    final last = lastBackupDate;
    final now = DateTime.now();

    final isDue = last == null || now.difference(last).inDays >= 7;
    if (!isDue) return false;

    return await createBackupSnapshot();
  }

  /// Creates and stores an immediate local backup snapshot.
  Future<bool> createBackupSnapshot() async {
    try {
      final json = DataPortabilityService.buildBackupJson();
      if (json.isEmpty) return false;

      LocalStore().writeString(_snapshotKey, json);
      LocalStore().writeInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('[AutoBackupService] Automated weekly backup snapshot saved successfully.');
      return true;
    } catch (e) {
      debugPrint('[AutoBackupService] Error taking auto-backup snapshot: $e');
      return false;
    }
  }

  /// Restores all data from the latest automated snapshot into the local database and Riverpod state.
  Future<int> restoreLatestAutoBackup(WidgetRef ref) async {
    final snapshot = latestSnapshotJson;
    if (snapshot == null || snapshot.trim().isEmpty) {
      throw const FormatException('No auto-backup snapshot found on this device.');
    }

    final counts = await DataPortabilityService.importBackupJson(snapshot);
    reloadAllFromStore(ref);
    return counts.values.fold<int>(0, (a, b) => a + b);
  }
}
