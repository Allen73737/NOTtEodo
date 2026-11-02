import 'dart:convert';

import '../security/crypto_box.dart';
import '../state/sanctuary_state.dart';
import '../utils/date_labels.dart';
import 'local_store.dart';

/// Builds and reads the files behind Settings → Export / Import.
class DataPortabilityService {
  DataPortabilityService._();

  static const String format = 'notteodo-backup';
  static const String encryptedFormat = 'notteodo-backup-encrypted';
  static const int version = 1;

  /// Lowered in tests; production uses the OWASP default.
  static int kdfIterations = CryptoBox.defaultPbkdf2Iterations;

  /// The full backup, encrypted with AES-256-GCM under PBKDF2-HMAC-SHA256([password]).
  /// Only the format marker and KDF parameters are readable without the password.
  static Future<String> buildEncryptedBackup(String password, {DateTime? now}) async {
    final salt = CryptoBox.randomBytes(16);
    final key = await CryptoBox.deriveKey(password, salt, iterations: kdfIterations);
    final sealed = await CryptoBox.sealString(key, buildBackupJson(now: now), aad: encryptedFormat);
    return const JsonEncoder.withIndent('  ').convert({
      'format': encryptedFormat,
      'version': version,
      'kdf': {'alg': 'pbkdf2-hmac-sha256', 'iter': kdfIterations, 'salt': base64.encode(salt)},
      'cipher': 'A256GCM',
      'data': sealed,
    });
  }

  static bool isEncryptedBackup(String text) {
    try {
      final d = jsonDecode(text);
      return d is Map && d['format'] == encryptedFormat;
    } catch (_) {
      return false;
    }
  }

  /// Decrypts a [buildEncryptedBackup] file. Throws [FormatException] for a wrong password.
  static Future<String> decryptBackup(String text, String password) async {
    final d = jsonDecode(text) as Map;
    final kdf = d['kdf'] as Map;
    final iterations = (kdf['iter'] as num).toInt();
    // Cap the work factor so a crafted file cannot freeze the app.
    if (iterations < 1 || iterations > 10000000) throw const FormatException('Unsupported backup settings.');
    final key = await CryptoBox.deriveKey(password, base64.decode(kdf['salt'] as String), iterations: iterations);
    final plain = await CryptoBox.openString(key, d['data'] as String, aad: encryptedFormat);
    if (plain == null) throw const FormatException('Wrong password, or the file was modified.');
    return plain;
  }

  /// Every module as one JSON document. Settings (and the app-lock PIN) are not included.
  static String buildBackupJson({DateTime? now}) {
    final all = LocalStore().dumpAll();
    final collections = {for (final c in dataCollections) c: all[c] ?? const []};
    return const JsonEncoder.withIndent('  ').convert({
      'format': format,
      'version': version,
      'exportedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'collections': collections,
    });
  }

  /// Restores a [buildBackupJson] file. Returns how many items each collection received.
  /// Throws [FormatException] for anything that is not a backup from this app.
  static Future<Map<String, int>> importBackupJson(String text) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      throw const FormatException('This file is not valid JSON.');
    }
    if (decoded is! Map || decoded['format'] != format) {
      throw const FormatException('This is not a NOTtEodo backup file.');
    }
    if ((decoded['version'] as num? ?? 0) > version) {
      throw const FormatException('This backup was made by a newer version of the app.');
    }
    final collections = decoded['collections'];
    if (collections is! Map) throw const FormatException('The backup has no data.');

    final counts = <String, int>{};
    for (final c in dataCollections) {
      final rows = collections[c];
      if (rows is! List) continue;
      final clean =
          rows.whereType<Map>().where((r) => r['id'] is String).map((r) => Map<String, dynamic>.from(r)).toList();
      // A normal (notifying) write, so a signed-in session also pushes the restored data.
      LocalStore().writeList(c, clean);
      counts[c] = clean.length;
    }
    return counts;
  }

  static String _csvCell(Object? v) {
    var s = v?.toString() ?? '';
    // Spreadsheet formula injection (CWE-1236): neutralise cells a spreadsheet would execute.
    if (s.isNotEmpty && '=+-@\t\r'.contains(s[0]) && !RegExp(r'^-?\d+(\.\d+)?$').hasMatch(s)) s = "'$s";
    return RegExp(r'[",\n\r]').hasMatch(s) ? '"${s.replaceAll('"', '""')}"' : s;
  }

  static String _csv(List<String> header, Iterable<List<Object?>> rows) =>
      [header, ...rows].map((r) => r.map(_csvCell).join(',')).join('\r\n');

  static String expensesCsv(List<ExpenseItem> expenses) => _csv(
        ['Date', 'Title', 'Category', 'Amount', 'Note'],
        expenses.map((e) => [DateLabels.dayKey(e.spentAt), e.title, e.category, e.amount.toStringAsFixed(2), e.note]),
      );

  static String tasksCsv(List<TaskItem> tasks) => _csv(
        ['Title', 'Priority', 'Space', 'Due', 'Repeat', 'Completed', 'Notes'],
        tasks.map((t) => [
              t.title,
              t.priority,
              t.space,
              t.dueAt?.toIso8601String() ?? '',
              t.repeat.name,
              t.completed ? 'yes' : 'no',
              t.notes,
            ]),
      );

  /// All notes as one Markdown document, pinned first.
  static String notesMarkdown(List<NoteItem> notes) {
    final sorted = [...notes]..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    final b = StringBuffer('# NOTtEodo Notes\n\n');
    for (final n in sorted) {
      b
        ..writeln('## ${n.title}')
        ..writeln()
        ..writeln('*${n.space} · ${n.tag} · ${DateLabels.long(n.updatedAt)}*')
        ..writeln()
        ..writeln(n.body)
        ..writeln();
    }
    return b.toString();
  }
}
