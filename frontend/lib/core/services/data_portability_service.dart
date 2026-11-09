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

  /// Splits CSV text into rows of cells, handling quoted cells with commas, quotes and newlines.
  /// The delimiter (comma, semicolon or tab) is the one used most in the first line.
  static List<List<String>> parseCsv(String text) {
    final firstLine = text.split(RegExp(r'[\r\n]')).first;
    final delimiter = [',', ';', '\t'].reduce((a, b) => b.allMatches(firstLine).length > a.allMatches(firstLine).length ? b : a);
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var quoted = false;
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (quoted) {
        if (c == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          cell.write(c);
        }
      } else if (c == '"') {
        quoted = true;
      } else if (c == delimiter) {
        row.add(cell.toString().trim());
        cell.clear();
      } else if (c == '\n' || c == '\r') {
        if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
        row.add(cell.toString().trim());
        cell.clear();
        if (row.any((v) => v.isNotEmpty)) rows.add(row);
        row = <String>[];
      } else {
        cell.write(c);
      }
    }
    row.add(cell.toString().trim());
    if (row.any((v) => v.isNotEmpty)) rows.add(row);
    return rows;
  }

  /// Reads expenses from a bank or spreadsheet CSV. The header row decides which
  /// columns hold the date, description, amount (or separate debit/credit) and category;
  /// credits and zero rows are skipped and debits are stored as positive spend.
  // Compiled once: building a RegExp per row made a 10,000-row import take ~7 s.
  static final _notNumber = RegExp(r'[^0-9.,\-()]');
  static final _signMarks = RegExp(r'[()\-]');
  static final _decimalComma = RegExp(r',\d{2}$');
  static final _numericDate = RegExp(r'^(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{2,4})');

  static List<ExpenseItem> expensesFromCsv(String text) {
    final rows = parseCsv(text);
    if (rows.length < 2) return const [];
    final header = rows.first.map((h) => h.toLowerCase()).toList();
    int col(List<String> names) => header.indexWhere((h) => names.any(h.contains));
    final date = col(['date', 'posted', 'time']);
    final title = col(['description', 'title', 'narration', 'details', 'merchant', 'payee', 'name', 'particulars']);
    final amount = col(['amount', 'value', 'spent']);
    final debit = col(['debit', 'withdrawal', 'paid out', 'money out']);
    final category = col(['category', 'type']);
    final note = col(['note', 'memo', 'reference']);
    if (title < 0 || (amount < 0 && debit < 0)) return const [];

    double? number(String raw) {
      final cleaned = raw.replaceAll(_notNumber, '');
      if (cleaned.isEmpty) return null;
      final negative = cleaned.startsWith('-') || cleaned.startsWith('(');
      // "1.234,56" → 1234.56 ; "1,234.56" → 1234.56
      var digits = cleaned.replaceAll(_signMarks, '');
      if (digits.contains(',') && digits.contains('.')) {
        digits = digits.lastIndexOf(',') > digits.lastIndexOf('.')
            ? digits.replaceAll('.', '').replaceAll(',', '.')
            : digits.replaceAll(',', '');
      } else if (_decimalComma.hasMatch(digits)) {
        digits = digits.replaceAll(',', '.');
      } else {
        digits = digits.replaceAll(',', '');
      }
      final v = double.tryParse(digits);
      return v == null ? null : (negative ? -v : v);
    }

    DateTime? day(String raw) {
      final iso = DateTime.tryParse(raw);
      if (iso != null) return iso;
      final m = _numericDate.firstMatch(raw.trim());
      if (m == null) return null;
      var y = int.parse(m.group(3)!);
      if (y < 100) y += 2000;
      // Day first (most bank exports outside the US).
      final a = int.parse(m.group(1)!), b = int.parse(m.group(2)!);
      final (d, mo) = a > 12 || b <= 12 ? (a, b) : (b, a);
      return DateTime(y, mo, d);
    }

    String at(List<String> r, int i) => i >= 0 && i < r.length ? r[i] : '';
    final signed = amount >= 0 && rows.skip(1).any((x) => (number(at(x, amount)) ?? 0) < 0);
    final out = <ExpenseItem>[];
    for (final r in rows.skip(1)) {
      final name = at(r, title);
      if (name.isEmpty) continue;
      double? spend;
      if (debit >= 0) {
        spend = number(at(r, debit))?.abs();
      } else {
        // A signed amount column: negative is money out. All-positive files are all spend.
        final v = number(at(r, amount));
        spend = v == null || (v > 0 && signed) ? null : v.abs();
      }
      if (spend == null || spend == 0) continue;
      out.add(ExpenseItem(
        id: newId(),
        title: name,
        amount: spend,
        category: at(r, category).isEmpty ? 'General' : at(r, category),
        note: at(r, note),
        spentAt: day(at(r, date)) ?? DateTime.now(),
      ));
    }
    return out;
  }

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
