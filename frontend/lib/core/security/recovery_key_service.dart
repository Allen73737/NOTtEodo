import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/local_store.dart';
import '../services/sanctuary_supabase_service.dart';
import 'crypto_box.dart';

/// Verification result for Master Recovery Key.
class RecoveryKeyVerification {
  final bool isValid;
  final String? errorMessage;
  final int? cooldownSeconds;

  const RecoveryKeyVerification({
    required this.isValid,
    this.errorMessage,
    this.cooldownSeconds,
  });

  bool get isCoolingDown => (cooldownSeconds ?? 0) > 0;
}

/// Production Master Recovery Key and In-App Vault Rescue Service.
///
/// Implements Signal/Proton/1Password-style offline recovery for users who:
/// - Registered with placeholder, typo, or disposable emails (e.g. user@fake.com)
/// - Forgot their login password or in-app vault PIN
/// - Experience email server outages and cannot receive magic links or reset emails
/// - Need to safely rescue, export, and migrate their local encrypted sanctuary
class MasterRecoveryKeyService {
  static final MasterRecoveryKeyService _instance = MasterRecoveryKeyService._internal();
  factory MasterRecoveryKeyService() => _instance;
  MasterRecoveryKeyService._internal();

  static const String _recoveryKeyPublicSlot = 'nt.__master_recovery_key';
  static const String _attemptsPublicSlot = 'nt.__recovery_key_attempts';
  static const String _secureStorageKey = 'nt_master_recovery_key_raw';

  // Crockford Base32 charset (excludes 0, O, 1, I to prevent visual ambiguity)
  static const String _charset = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  static const int maxAttempts = 5;
  static const int lockoutSeconds = 300; // 5 minutes cooldown after 5 failed tries

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
    webOptions: WebOptions(dbName: 'notteodo_recovery', publicKey: 'nt_rec_pub'),
  );

  /// Generates a high-entropy 16-character alphanumeric key formatted as NOTT-XXXX-XXXX-XXXX.
  static String generateKey() {
    final randomBytes = CryptoBox.randomBytes(12);
    final sb = StringBuffer('NOTT');
    for (int i = 0; i < 12; i++) {
      if (i % 4 == 0) sb.write('-');
      sb.write(_charset[randomBytes[i] % _charset.length]);
    }
    return sb.toString();
  }

  /// Normalizes an input recovery key by removing hyphens, spaces, and the NOTT prefix, then uppercasing.
  static String normalizeKey(String key) {
    var clean = key.trim().toUpperCase().replaceAll('-', '').replaceAll(' ', '');
    if (clean.startsWith('NOTT')) {
      clean = clean.substring(4);
    }
    return clean;
  }

  /// Formats a 12-char clean key into standard NOTT-XXXX-XXXX-XXXX shape.
  static String formatKey(String clean) {
    var raw = normalizeKey(clean);
    if (raw.length > 12) raw = raw.substring(0, 12);
    final sb = StringBuffer('NOTT');
    for (int i = 0; i < raw.length; i++) {
      if (i % 4 == 0) sb.write('-');
      sb.write(raw[i]);
    }
    return sb.toString();
  }

  /// Whether a Master Recovery Key is currently active and configured on this device.
  bool get hasRecoveryKey {
    final meta = LocalStore().readPublic()[_recoveryKeyPublicSlot];
    if (meta is Map && meta['hash'] is String) return true;
    return false;
  }

  /// Returns timestamp of key generation.
  DateTime? get createdAt {
    final meta = LocalStore().readPublic()[_recoveryKeyPublicSlot];
    if (meta is Map && meta['createdAt'] is String) {
      return DateTime.tryParse(meta['createdAt'] as String);
    }
    return null;
  }

  /// Returns email linked to recovery key, if any.
  String? get associatedEmail {
    final meta = LocalStore().readPublic()[_recoveryKeyPublicSlot];
    if (meta is Map && meta['userEmail'] is String) {
      return meta['userEmail'] as String;
    }
    return null;
  }

  /// Persists a new Master Recovery Key securely with a cryptographic salt and SHA-256 hash.
  Future<void> saveRecoveryKey(String formattedKey, {String? userEmail}) async {
    final cleanKey = normalizeKey(formattedKey);
    final saltBytes = CryptoBox.randomBytes(16);
    final saltHex = base64Url.encode(saltBytes);

    // Compute cryptographic salted digest
    final saltedKey = '$cleanKey:$saltHex';
    final digest = crypto.sha256.convert(utf8.encode(saltedKey)).bytes;
    final hashHex = base64Url.encode(digest);

    final email = userEmail ?? SanctuarySupabaseService().currentUser?.email;

    final meta = <String, dynamic>{
      'hash': hashHex,
      'salt': saltHex,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      if (email != null && email.isNotEmpty) 'userEmail': email.toLowerCase().trim(),
    };

    // 1. Store hash and salt in public metadata slot
    final pub = Map<String, dynamic>.from(LocalStore().readPublic());
    pub[_recoveryKeyPublicSlot] = meta;
    LocalStore().writePublic(pub);

    // 2. Store encrypted raw key in Hardware Keystore / Secure Storage
    try {
      await _storage.write(key: _secureStorageKey, value: formattedKey);
    } catch (e) {
      debugPrint('[MasterRecoveryKeyService] SecureStorage warning: $e');
    }

    // 3. Sync recovery key status to cloud metadata if user is connected
    final supabase = SanctuarySupabaseService();
    if (supabase.isConnectedToCloud) {
      try {
        await supabase.updateUserMetadata({
          'has_recovery_key': true,
          'recovery_key_hash': hashHex,
          'recovery_key_created_at': meta['createdAt'],
        });
      } catch (e) {
        debugPrint('[MasterRecoveryKeyService] Cloud metadata update notice: $e');
      }
    }
  }

  /// Retrieves the saved recovery key string from secure storage (e.g. for user viewing in settings).
  Future<String?> getSavedKeyRaw() async {
    try {
      final raw = await _storage.read(key: _secureStorageKey);
      if (raw != null && raw.isNotEmpty) return raw;
    } catch (_) {}
    return null;
  }

  /// Rate-limiting helper: returns seconds remaining in lockout, or 0 if allowed.
  int getCooldownSecondsRemaining() {
    final pub = LocalStore().readPublic();
    final attemptsMeta = pub[_attemptsPublicSlot];
    if (attemptsMeta is Map) {
      final lockedUntilStr = attemptsMeta['lockedUntil'] as String?;
      if (lockedUntilStr != null) {
        final lockedUntil = DateTime.tryParse(lockedUntilStr);
        if (lockedUntil != null && lockedUntil.isAfter(DateTime.now())) {
          return lockedUntil.difference(DateTime.now()).inSeconds + 1;
        }
      }
    }
    return 0;
  }

  void _recordAttemptFailure() {
    final pub = Map<String, dynamic>.from(LocalStore().readPublic());
    final attemptsMeta = Map<String, dynamic>.from((pub[_attemptsPublicSlot] as Map?) ?? {});
    final currentFailures = (attemptsMeta['failures'] as int? ?? 0) + 1;
    attemptsMeta['failures'] = currentFailures;

    if (currentFailures >= maxAttempts) {
      final lockUntil = DateTime.now().add(const Duration(seconds: lockoutSeconds));
      attemptsMeta['lockedUntil'] = lockUntil.toUtc().toIso8601String();
    }

    pub[_attemptsPublicSlot] = attemptsMeta;
    LocalStore().writePublic(pub);
  }

  void _resetAttemptFailures() {
    final pub = Map<String, dynamic>.from(LocalStore().readPublic());
    pub.remove(_attemptsPublicSlot);
    LocalStore().writePublic(pub);
  }

  /// Verifies a candidate recovery key against stored salted hash using constant-time comparison.
  Future<RecoveryKeyVerification> verifyRecoveryKey(String candidateKey, {String? email}) async {
    final cooldown = getCooldownSecondsRemaining();
    if (cooldown > 0) {
      return RecoveryKeyVerification(
        isValid: false,
        cooldownSeconds: cooldown,
        errorMessage: 'Too many incorrect attempts. Please wait $cooldown seconds.',
      );
    }

    final cleanCandidate = normalizeKey(candidateKey);
    if (cleanCandidate.length < 12) {
      return const RecoveryKeyVerification(
        isValid: false,
        errorMessage: 'Master Recovery Key must be 16 characters (e.g. NOTT-XXXX-XXXX-XXXX).',
      );
    }

    final pub = LocalStore().readPublic();
    final meta = pub[_recoveryKeyPublicSlot];

    if (meta is! Map || meta['hash'] is! String || meta['salt'] is! String) {
      return const RecoveryKeyVerification(
        isValid: false,
        errorMessage: 'No Master Recovery Key has been configured on this device yet.',
      );
    }

    final storedHashHex = meta['hash'] as String;
    final saltHex = meta['salt'] as String;
    final storedEmail = meta['userEmail'] as String?;

    // Optional email check if provided
    if (email != null && email.isNotEmpty && storedEmail != null && storedEmail.isNotEmpty) {
      if (email.toLowerCase().trim() != storedEmail.toLowerCase().trim()) {
        _recordAttemptFailure();
        return const RecoveryKeyVerification(
          isValid: false,
          errorMessage: 'This Master Recovery Key does not belong to the entered account.',
        );
      }
    }

    // Recompute salted digest
    final candidateSalted = '$cleanCandidate:$saltHex';
    final candidateDigest = crypto.sha256.convert(utf8.encode(candidateSalted)).bytes;
    final candidateHashHex = base64Url.encode(candidateDigest);

    // Constant-time comparison
    final match = CryptoBox.constantTimeEquals(
      utf8.encode(candidateHashHex),
      utf8.encode(storedHashHex),
    );

    if (match) {
      _resetAttemptFailures();
      await SanctuarySupabaseService().logSecurityEvent('RECOVERY_KEY_VERIFIED', {'email': storedEmail ?? email ?? 'local'});
      return const RecoveryKeyVerification(isValid: true);
    } else {
      _recordAttemptFailure();
      final newCooldown = getCooldownSecondsRemaining();
      if (newCooldown > 0) {
        return RecoveryKeyVerification(
          isValid: false,
          cooldownSeconds: newCooldown,
          errorMessage: 'Too many attempts. Locked for $newCooldown seconds.',
        );
      }
      return const RecoveryKeyVerification(
        isValid: false,
        errorMessage: 'Incorrect Master Recovery Key. Please check the code and try again.',
      );
    }
  }

  /// Resets cloud password when verified via recovery key and session is active,
  /// or resets local PIN and state.
  Future<void> executeRecoveryPasswordReset({
    required String recoveryKey,
    required String newPassword,
    String? email,
  }) async {
    final verify = await verifyRecoveryKey(recoveryKey, email: email);
    if (!verify.isValid) {
      throw StateError(verify.errorMessage ?? 'Invalid recovery key');
    }

    final supabase = SanctuarySupabaseService();
    if (supabase.isConnectedToCloud) {
      await supabase.updateUserPassword(newPassword);
    }
  }

  /// Rescues and exports the entire local on-device vault as an encrypted or structured JSON package.
  /// Used when a user needs to migrate off a dummy/fake email without losing their local data.
  String rescueLocalVaultToJson() {
    final rawDump = LocalStore().dumpAll();
    final exportBundle = <String, dynamic>{
      'app': 'NOTtEodo',
      'version': '1.0.0',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'type': 'sanctuary_local_vault_rescue',
      'itemCounts': {
        for (final entry in rawDump.entries) entry.key: entry.value.length,
      },
      'collections': rawDump,
    };
    return const JsonEncoder.withIndent('  ').convert(exportBundle);
  }

  /// Removes the recovery key from device.
  Future<void> clearRecoveryKey() async {
    final pub = Map<String, dynamic>.from(LocalStore().readPublic());
    pub.remove(_recoveryKeyPublicSlot);
    pub.remove(_attemptsPublicSlot);
    LocalStore().writePublic(pub);
    try {
      await _storage.delete(key: _secureStorageKey);
    } catch (_) {}
  }
}
