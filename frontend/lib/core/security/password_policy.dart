import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

@immutable
class PasswordCheck {
  /// 0 (very weak) … 4 (strong).
  final int score;
  final String label;

  /// Why the password is not accepted; null when it is.
  final String? problem;

  const PasswordCheck(this.score, this.label, this.problem);

  bool get acceptable => problem == null;
}

/// Account and passphrase rules, following NIST SP 800-63B: favour length, block
/// known-bad passwords, and skip arbitrary composition rules.
class PasswordPolicy {
  PasswordPolicy._();

  static const int minLength = 10;

  // A short blocklist of the most common passwords and keyboard walks; the breach
  // check below catches the long tail.
  static const Set<String> _common = {
    'password', 'password1', 'password123', '123456789', '1234567890', 'qwertyuiop', 'qwerty123',
    'iloveyou', 'sunshine', 'princess', 'football', 'baseball', 'welcome1', 'letmein123', 'admin123',
    'abc123456', 'passw0rd', 'p@ssw0rd', 'trustno1', 'dragon123', 'monkey123', 'master123',
    'superman', 'starwars', 'whatever', 'asdfghjkl', 'zxcvbnm123', '1q2w3e4r5t', 'qazwsxedc',
    'notteodo', 'notteodo123', 'changeme', 'secret123', 'computer', 'internet', '11111111111',
  };

  static PasswordCheck evaluate(String password, {String? email}) {
    final pw = password.trim();
    final lower = pw.toLowerCase();
    final local = email?.split('@').first.toLowerCase() ?? '';

    String? problem;
    if (pw.length < minLength) {
      problem = 'Use at least $minLength characters. A short phrase works well.';
    } else if (_common.contains(lower) || RegExp(r'^(.)\1+$').hasMatch(pw) || _isSequence(lower)) {
      problem = 'This password is too common or predictable.';
    } else if (local.length >= 3 && lower.contains(local)) {
      problem = "Don't include your email name in the password.";
    }

    final bits = _entropyBits(pw);
    final score = problem != null
        ? (pw.length >= 6 ? 1 : 0)
        : bits >= 80
            ? 4
            : bits >= 60
                ? 3
                : bits >= 45
                    ? 2
                    : 1;
    const labels = ['Very weak', 'Weak', 'Fair', 'Good', 'Strong'];
    if (problem == null && score < 2) problem = 'Make it longer or mix in words, numbers or symbols.';
    return PasswordCheck(score, labels[score], problem);
  }

  static bool _isSequence(String s) {
    const runs = ['0123456789', 'abcdefghijklmnopqrstuvwxyz', 'qwertyuiopasdfghjklzxcvbnm'];
    return runs.any((r) => r.contains(s) || r.split('').reversed.join().contains(s));
  }

  /// Rough character-pool entropy, discounted for repeated characters.
  static double _entropyBits(String pw) {
    if (pw.isEmpty) return 0;
    var pool = 0;
    if (RegExp(r'[a-z]').hasMatch(pw)) pool += 26;
    if (RegExp(r'[A-Z]').hasMatch(pw)) pool += 26;
    if (RegExp(r'[0-9]').hasMatch(pw)) pool += 10;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(pw)) pool += 33;
    final unique = pw.split('').toSet().length;
    final effectiveLength = (pw.length + unique) / 2;
    return effectiveLength * (pool == 0 ? 0 : log(pool) / ln2);
  }

  /// How many times [password] appears in known breaches, via the Have I Been Pwned
  /// k-anonymity range API: only the first 5 hex characters of its SHA-1 leave the
  /// device, and responses are padded. Returns null if the service is unreachable.
  static Future<int?> breachCount(String password, {http.Client? client}) async {
    final hash = sha1.convert(utf8.encode(password)).toString().toUpperCase();
    final prefix = hash.substring(0, 5), suffix = hash.substring(5);
    final c = client ?? http.Client();
    try {
      final res = await c
          .get(Uri.parse('https://api.pwnedpasswords.com/range/$prefix'), headers: {'Add-Padding': 'true'})
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;
      for (final line in const LineSplitter().convert(res.body)) {
        final parts = line.split(':');
        if (parts.length == 2 && parts[0].trim() == suffix) return int.tryParse(parts[1].trim()) ?? 0;
      }
      return 0;
    } catch (_) {
      return null;
    } finally {
      if (client == null) c.close();
    }
  }
}
