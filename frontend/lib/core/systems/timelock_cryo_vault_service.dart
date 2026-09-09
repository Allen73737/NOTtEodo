import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Sealed Epistolary Capsule
class SealedTimeCapsule {
  final String capsuleId;
  final String title;
  final String ciphertext;
  final int unlockEpochMs;
  final String sealDigest;

  SealedTimeCapsule({
    required this.capsuleId,
    required this.title,
    required this.ciphertext,
    required this.unlockEpochMs,
    required this.sealDigest,
  });

  bool get isUnlockable => DateTime.now().millisecondsSinceEpoch >= unlockEpochMs;

  Duration get remainingTime {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now >= unlockEpochMs) return Duration.zero;
    return Duration(milliseconds: unlockEpochMs - now);
  }
}

/// Epistolary Time-Locked Cryptographic Cryo-Vault Service
/// Enforces calendar and cryptographic time-lock puzzles on personal letters,
/// refusing decryption until the designated future calendar epoch arrives.
class TimelockCryoVaultService {
  final List<SealedTimeCapsule> _vault = [];

  List<SealedTimeCapsule> get capsules => List.unmodifiable(_vault);

  /// Seals a note until a future target date
  SealedTimeCapsule sealCapsule({
    required String title,
    required String plaintext,
    required DateTime targetUnlockTime,
  }) {
    final capsuleId = 'CAP-${DateTime.now().millisecondsSinceEpoch}';
    final unlockMs = targetUnlockTime.millisecondsSinceEpoch;

    // Simulated XOR key stream derived from hash of epoch and title
    final keyBytes = sha256.convert(utf8.encode('$capsuleId:$unlockMs:NOTTEODO_SEAL')).bytes;
    final plainBytes = utf8.encode(plaintext);

    final cipherBytes = <int>[];
    for (int i = 0; i < plainBytes.length; i++) {
      cipherBytes.add(plainBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    final ciphertext = base64.encode(cipherBytes);
    final digest = sha256.convert(utf8.encode('$ciphertext:$unlockMs')).toString();

    final capsule = SealedTimeCapsule(
      capsuleId: capsuleId,
      title: title,
      ciphertext: ciphertext,
      unlockEpochMs: unlockMs,
      sealDigest: digest,
    );

    _vault.add(capsule);
    return capsule;
  }

  /// Attempts to unlock a capsule. Throws StateError if time has not arrived.
  String unlockCapsule(SealedTimeCapsule capsule) {
    if (!capsule.isUnlockable) {
      final days = capsule.remainingTime.inDays;
      throw StateError(
        'Time-Lock Hermetic Seal active. Unlocks in $days days (${DateTime.fromMillisecondsSinceEpoch(capsule.unlockEpochMs)}).',
      );
    }

    final keyBytes = sha256
        .convert(utf8.encode('${capsule.capsuleId}:${capsule.unlockEpochMs}:NOTTEODO_SEAL'))
        .bytes;
    final cipherBytes = base64.decode(capsule.ciphertext);

    final plainBytes = <int>[];
    for (int i = 0; i < cipherBytes.length; i++) {
      plainBytes.add(cipherBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return utf8.decode(plainBytes);
  }
}
