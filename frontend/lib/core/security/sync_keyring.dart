import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../services/local_store.dart';
import '../services/sanctuary_supabase_service.dart';
import 'crypto_box.dart';

enum E2eeState {
  /// Not checked yet this session, or the server could not be reached.
  unknown,

  /// Cloud copies are stored as plain JSON (protected by RLS and TLS only).
  off,

  /// End-to-end encryption is on and this device holds the key.
  ready,

  /// End-to-end encryption is on but this device has not been given the passphrase yet.
  needsPassphrase,
}

/// End-to-end encryption for cloud sync (zero-knowledge: the server stores only ciphertext).
///
/// * A random 256-bit **sync key** encrypts each collection snapshot with AES-256-GCM.
///   The AAD is `userId/collection`, so the server cannot swap rows between users or modules.
/// * The sync key is wrapped by PBKDF2-HMAC-SHA256(passphrase, 600k) and stored in
///   `user_keys`, so a new device needs only the passphrase. The passphrase never
///   leaves the device.
/// * Once unwrapped, the key is cached inside this device's encrypted [LocalStore].
class SyncKeyring {
  static final SyncKeyring _instance = SyncKeyring._internal();
  factory SyncKeyring() => _instance;
  SyncKeyring._internal();

  static const String _localSlot = 'sync.e2ee';
  static const String _checkPlain = 'notteodo-e2ee-v1';

  /// Lowered in tests; production always uses the OWASP default.
  @visibleForTesting
  int iterations = CryptoBox.defaultPbkdf2Iterations;

  final ValueNotifier<E2eeState> state = ValueNotifier(E2eeState.unknown);

  Uint8List? _key;
  String? _userId;

  bool get isActive => state.value == E2eeState.ready && _key != null;

  /// True when pushing would risk sending plaintext to an account that expects ciphertext.
  bool get blocksPush => state.value == E2eeState.needsPassphrase || state.value == E2eeState.unknown;

  SanctuarySupabaseService get _cloud => SanctuarySupabaseService();

  String? get _uid => _cloud.currentUser?.id;

  /// Reads the server's key record and decides whether this device can sync.
  Future<E2eeState> refresh() async {
    final uid = _uid;
    if (uid == null) return _set(E2eeState.unknown);
    final Map<String, dynamic>? row;
    try {
      row = await _cloud.fetchUserKey();
    } on PostgrestException catch (e) {
      // 42P01 / PGRST205: the server predates end-to-end encryption, so it cannot be on.
      if (e.code == '42P01' || e.code == 'PGRST205') {
        _key = null;
        return _set(E2eeState.off);
      }
      debugPrint('[SyncKeyring] Could not read key record: ${e.message}');
      return _restoreFromCache(uid);
    } catch (e) {
      debugPrint('[SyncKeyring] Could not read key record: $e');
      return _restoreFromCache(uid);
    }
    if (row == null) {
      _key = null;
      _userId = uid;
      LocalStore().writeMap(_localSlot, {'user': uid, 'off': true});
      return _set(E2eeState.off);
    }
    final cached = _cachedKey(uid);
    if (cached != null && await _matches(cached, row, uid)) {
      _key = cached;
      _userId = uid;
      return _set(E2eeState.ready);
    }
    _key = null;
    return _set(E2eeState.needsPassphrase);
  }

  /// Unwraps the account's sync key with [passphrase]. Returns false if it is wrong.
  Future<bool> unlock(String passphrase) async {
    final uid = _uid;
    if (uid == null) return false;
    final row = await _cloud.fetchUserKey();
    if (row == null) {
      await refresh();
      return false;
    }
    final kdf = Map<String, dynamic>.from(row['kdf'] as Map);
    final kek = await CryptoBox.deriveKey(passphrase, base64.decode(kdf['salt'] as String),
        iterations: (kdf['iter'] as num).toInt());
    final wrapped = base64.decode(row['wrapped_key'] as String);
    final key = await CryptoBox.open(kek, wrapped, aad: 'e2ee-key:$uid');
    if (key == null) return false;
    _remember(uid, key);
    return true;
  }

  /// Turns on end-to-end encryption with a new key (also used to start over after a
  /// forgotten passphrase: the old key and anything encrypted with it are discarded).
  Future<void> enable(String passphrase) async {
    final uid = _uid;
    if (uid == null) throw StateError('Sign in first.');
    final key = CryptoBox.newKey();
    await _cloud.upsertUserKey(await _wrapRecord(uid, key, passphrase));
    _remember(uid, key);
  }

  Future<void> changePassphrase(String passphrase) async {
    final uid = _uid;
    final key = _key;
    if (uid == null || key == null) throw StateError('Unlock sync encryption first.');
    await _cloud.upsertUserKey(await _wrapRecord(uid, key, passphrase));
  }

  /// Turns end-to-end encryption off. The caller must re-push plaintext snapshots.
  Future<void> disable() async {
    final uid = _uid;
    await _cloud.deleteUserKey();
    _key = null;
    if (uid != null) LocalStore().writeMap(_localSlot, {'user': uid, 'off': true});
    _set(E2eeState.off);
  }

  /// Called on sign-out / account switch.
  void forget() {
    _key = null;
    _userId = null;
    LocalStore().writeMap(_localSlot, {});
    _set(E2eeState.unknown);
  }

  // --- Envelopes -------------------------------------------------------------

  static bool isEnvelope(Object? data) => data is Map && data['ct'] is String;

  Future<Map<String, dynamic>> seal(String collection, Object rows) async {
    final key = _key;
    final uid = _userId;
    if (key == null || uid == null) throw StateError('Sync key is not available.');
    return {
      'v': 1,
      'alg': 'A256GCM',
      'ct': await CryptoBox.sealString(key, jsonEncode(rows), aad: '$uid/$collection'),
    };
  }

  /// Decrypts a sealed collection, or returns null if it cannot be read with this key.
  Future<List<Map<String, dynamic>>?> open(String collection, Object? data) async {
    final key = _key;
    final uid = _userId;
    if (key == null || uid == null || !isEnvelope(data)) return null;
    final plain = await CryptoBox.openString(key, (data as Map)['ct'] as String, aad: '$uid/$collection');
    if (plain == null) return null;
    try {
      return (jsonDecode(plain) as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return null;
    }
  }

  // --- Internals -------------------------------------------------------------

  Future<Map<String, dynamic>> _wrapRecord(String uid, Uint8List key, String passphrase) async {
    final salt = CryptoBox.randomBytes(16);
    final kek = await CryptoBox.deriveKey(passphrase, salt, iterations: iterations);
    return {
      'kdf': {'alg': 'pbkdf2-hmac-sha256', 'iter': iterations, 'salt': base64.encode(salt)},
      'wrapped_key': base64.encode(await CryptoBox.seal(kek, key, aad: 'e2ee-key:$uid')),
      'key_check': await CryptoBox.sealString(key, _checkPlain, aad: 'e2ee-check:$uid'),
    };
  }

  Future<bool> _matches(Uint8List key, Map<String, dynamic> row, String uid) async =>
      await CryptoBox.openString(key, row['key_check']?.toString() ?? '', aad: 'e2ee-check:$uid') == _checkPlain;

  void _remember(String uid, Uint8List key) {
    _key = key;
    _userId = uid;
    LocalStore().writeMap(_localSlot, {'user': uid, 'key': base64.encode(key)});
    _set(E2eeState.ready);
  }

  Uint8List? _cachedKey(String uid) {
    final local = LocalStore().readMap(_localSlot);
    if (local == null || local['user'] != uid || local['key'] is! String) return null;
    try {
      return base64.decode(local['key'] as String);
    } catch (_) {
      return null;
    }
  }

  /// Offline: trust what this device last saw, so it neither blocks nor leaks.
  E2eeState _restoreFromCache(String uid) {
    final local = LocalStore().readMap(_localSlot);
    if (local == null || local['user'] != uid) return _set(E2eeState.unknown);
    if (local['off'] == true) return _set(E2eeState.off);
    final key = _cachedKey(uid);
    if (key == null) return _set(E2eeState.unknown);
    _key = key;
    _userId = uid;
    return _set(E2eeState.ready);
  }

  E2eeState _set(E2eeState s) {
    state.value = s;
    return s;
  }
}
