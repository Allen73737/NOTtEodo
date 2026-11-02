import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as legacy_hash;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../security/crypto_box.dart';
import '../security/device_key_store.dart';

/// Outcome of a PIN attempt.
enum PinResult { unlocked, wrong, coolingDown, wiped }

/// Encrypted on-device persistence for every module.
///
/// ## Key hierarchy
/// * A random 256-bit **data key** encrypts each stored value with AES-256-GCM. The
///   value's storage slot is the AAD, so ciphertexts cannot be swapped between slots.
/// * Without an app PIN, the data key is wrapped by the [DeviceKeyStore] (Keystore,
///   Keychain, or a non-extractable WebCrypto key), so the app opens without a prompt.
/// * With a PIN, the data key is wrapped twice: first by
///   PBKDF2-HMAC-SHA256(PIN, 600k iterations), then by the device key. Every guess
///   then costs a full key derivation and needs this device's secret, and the
///   plaintext stays unreadable until the right PIN is entered.
///
/// Values are decrypted once at unlock and kept in memory, so reads stay
/// synchronous. Writes go to memory at once and are encrypted to disk in the background.
///
/// Until [init] has run (e.g. in widget tests) every read returns null and every
/// write is dropped, so the app simply behaves as an in-memory session.
class LocalStore {
  static final LocalStore _instance = LocalStore._internal();
  factory LocalStore() => _instance;
  LocalStore._internal();

  static const String _prefix = 'nt.';
  static const String _headerSlot = 'nt.__vault';
  static const String _publicSlot = 'nt.__public';
  static const Set<String> _internalSlots = {_headerSlot, _publicSlot};
  static const String _cipherTag = 'e1:';
  static const String _checkPlain = 'notteodo-vault-v1';

  /// Misses before each further miss adds a doubling pause.
  static const int freeAttempts = 5;

  /// Misses after which the device is erased, when the user opted in.
  static const int wipeThreshold = 10;

  SharedPreferences? _prefs;
  DeviceKeyStore? _keys;
  int _iterations = CryptoBox.defaultPbkdf2Iterations;
  Uint8List? _dek;
  Map<String, dynamic> _header = {};
  final Map<String, String> _cache = {};
  final Map<String, String?> _pending = {};
  Future<void>? _drain;

  /// A one-off message for the user produced during startup (e.g. unreadable data).
  String? startupNotice;

  /// Bumped whenever the lock configuration changes, so security UI can rebuild.
  final ValueNotifier<int> securityRevision = ValueNotifier(0);

  /// Called after every collection write, with the collection key. Used by sync.
  final List<void Function(String key)> _writeListeners = [];

  // --- State -----------------------------------------------------------------

  /// Storage is open and decrypted: reads and writes go through.
  bool get isReady => _prefs != null && _dek != null;

  /// Storage exists but is waiting for the PIN or biometrics.
  bool get isLocked => _prefs != null && _dek == null;

  bool get hasPin => _header['mode'] == 'pin' || _header['legacyPin'] is Map;
  bool get biometricEnabled => _header['bio'] == true;
  bool get wipeAfterFailures => _header['wipe'] == true;
  int get failedAttempts => (_header['failures'] as num?)?.toInt() ?? 0;

  DateTime? get lockedUntil {
    final until = DateTime.tryParse(_header['until']?.toString() ?? '');
    return until != null && until.isAfter(DateTime.now()) ? until : null;
  }

  DeviceKeyStore? get deviceKeys => _keys;
  int get kdfIterations => (_header['kdf'] as Map?)?['iter'] as int? ?? _iterations;

  /// Digits in the PIN, so the keypad can submit as soon as it is complete.
  int? get pinLength => (_header['kdf'] as Map?)?['len'] as int?;

  Future<void> init({DeviceKeyStore? deviceKeys, int? pbkdf2Iterations}) async {
    if (_prefs != null) return;
    final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[LocalStore] Storage unavailable, running in memory: $e');
      return;
    }
    _prefs = prefs;
    _keys = deviceKeys ?? createDeviceKeyStore();
    if (pbkdf2Iterations != null) _iterations = pbkdf2Iterations;

    _header = _decodeMap(prefs.getString(_headerSlot)) ?? {};
    if (_header.isEmpty) {
      await _createVault(migratePlaintext: true);
      return;
    }

    final sealed = _b64(_header['dek']);
    final wrapped = sealed == null ? null : await _keys!.open(sealed);
    if (wrapped == null) {
      await _recoverFromLostKey();
      return;
    }
    if (_header['mode'] == 'device' && !hasPin) {
      if (!await _isDataKey(wrapped)) {
        await _recoverFromLostKey();
        return;
      }
      await _loadCache(wrapped);
    }
    // PIN mode stays locked until unlockWithPin / unlockWithBiometrics.
  }

  /// Test hook: forget everything so a fresh mock can be loaded.
  @visibleForTesting
  void resetForTest() {
    _prefs = null;
    _keys = null;
    _dek = null;
    _header = {};
    _cache.clear();
    _pending.clear();
    _drain = null;
    _iterations = CryptoBox.defaultPbkdf2Iterations;
    startupNotice = null;
  }

  void addWriteListener(void Function(String key) listener) => _writeListeners.add(listener);
  void removeWriteListener(void Function(String key) listener) => _writeListeners.remove(listener);

  // --- Vault lifecycle -------------------------------------------------------

  Future<void> _createVault({required bool migratePlaintext}) async {
    final prefs = _prefs!;
    final dek = CryptoBox.newKey();
    Map<String, dynamic>? legacyPin;

    if (migratePlaintext) {
      // Builds before encryption stored a salted SHA-256 of the PIN inside settings.
      final settings = _decodeMap(prefs.getString('${_prefix}settings'));
      if (settings != null && settings['pinHash'] is String && settings['pinSalt'] is String) {
        legacyPin = {'hash': settings['pinHash'], 'salt': settings['pinSalt']};
        settings
          ..remove('pinHash')
          ..remove('pinSalt');
        await prefs.setString('${_prefix}settings', jsonEncode(settings));
      }
    } else {
      for (final k in _dataSlots(prefs)) {
        await prefs.remove(k);
      }
    }

    // Header first: any plaintext left behind by a crash is encrypted on the next load.
    _header = {
      'v': 1,
      'mode': 'device',
      'dek': base64.encode(await _keys!.seal(dek)),
      'check': await CryptoBox.sealString(dek, _checkPlain, aad: 'nt-check'),
      if (legacyPin != null) 'legacyPin': legacyPin,
    };
    await _saveHeader();
    if (legacyPin == null) {
      await _loadCache(dek);
    } else {
      // Encrypt the legacy plaintext now; the app still asks for the old PIN once.
      await _loadCache(dek);
      await flush();
      _dek = null;
      _cache.clear();
    }
  }

  /// The device secret is gone (cleared site data, restored backup on a new phone):
  /// nothing stored can be decrypted any more, so start a clean vault.
  Future<void> _recoverFromLostKey() async {
    debugPrint('[LocalStore] Device key missing or invalid; starting a fresh vault.');
    startupNotice = 'Data saved on this device could not be decrypted (its device key is missing), '
        'so the app started fresh. Sign in to restore your synced data.';
    await _keys!.destroy();
    await _createVault(migratePlaintext: false);
  }

  Future<void> _loadCache(Uint8List dek) async {
    final prefs = _prefs!;
    _cache.clear();
    final reencrypt = <String, String>{};
    for (final slot in _dataSlots(prefs)) {
      final raw = prefs.get(slot);
      if (raw is! String) continue;
      final key = slot.substring(_prefix.length);
      if (raw.startsWith(_cipherTag)) {
        final plain = await CryptoBox.openString(dek, raw.substring(_cipherTag.length), aad: slot);
        if (plain != null) {
          _cache[key] = plain;
        } else {
          debugPrint('[LocalStore] Dropped unreadable value in $key');
        }
      } else {
        // Plaintext from a build before encryption: keep it and encrypt it in place.
        _cache[key] = raw;
        reencrypt[key] = raw;
      }
    }
    _dek = dek;
    reencrypt.forEach(_queue);
    await flush();
  }

  Future<bool> _isDataKey(List<int> candidate) async =>
      await CryptoBox.openString(candidate, _header['check']?.toString() ?? '', aad: 'nt-check') == _checkPlain;

  Future<void> _saveHeader() async {
    await _prefs?.setString(_headerSlot, jsonEncode(_header));
    securityRevision.value++;
  }

  /// Forgets the decrypted data and key. Only meaningful when a PIN is set.
  Future<void> lock() async {
    if (!hasPin || _dek == null) return;
    await flush();
    _dek = null;
    _cache.clear();
  }

  // --- PIN -------------------------------------------------------------------

  Future<PinResult> unlockWithPin(String pin) async {
    if (!isLocked) return PinResult.unlocked;
    if (lockedUntil != null) return PinResult.coolingDown;
    final dek = await _dataKeyFromPin(pin);
    if (dek == null) return _registerFailure();

    await _clearFailures();
    await _loadCache(dek);
    if (_header['legacyPin'] is Map) await setPin(pin); // upgrade to PBKDF2 key wrapping
    return PinResult.unlocked;
  }

  /// Re-checks the PIN while unlocked (e.g. before opening the private journal).
  /// Misses count towards the same lockout as the lock screen.
  Future<PinResult> verifyPin(String pin) async {
    if (!hasPin) return PinResult.wrong;
    if (lockedUntil != null) return PinResult.coolingDown;
    final dek = await _dataKeyFromPin(pin);
    if (dek == null) return _registerFailure();
    await _clearFailures();
    return PinResult.unlocked;
  }

  Future<Uint8List?> _dataKeyFromPin(String pin) async {
    final keys = _keys;
    final sealed = _b64(_header['dek']);
    if (keys == null || sealed == null) return null;

    final legacy = _header['legacyPin'];
    if (legacy is Map) {
      final expected = legacy_hash.sha256.convert(utf8.encode('${legacy['salt']}:$pin')).toString();
      if (!CryptoBox.constantTimeEquals(utf8.encode(expected), utf8.encode('${legacy['hash']}'))) return null;
      return keys.open(sealed);
    }

    final inner = await keys.open(sealed);
    final kdf = _header['kdf'];
    final salt = kdf is Map ? _b64(kdf['salt']) : null;
    if (inner == null || salt == null) return null;
    final kek = await CryptoBox.deriveKey(pin, salt, iterations: (kdf['iter'] as num).toInt());
    return CryptoBox.open(kek, inner, aad: 'nt-dek-pin');
  }

  Future<PinResult> _registerFailure() async {
    final failures = failedAttempts + 1;
    _header['failures'] = failures;
    if (wipeAfterFailures && failures >= wipeThreshold) {
      await eraseAll();
      return PinResult.wiped;
    }
    if (failures >= freeAttempts) {
      // 30s, 60s, 120s ... capped at one hour.
      final seconds = (30 * (1 << (failures - freeAttempts).clamp(0, 7))).clamp(30, 3600);
      _header['until'] = DateTime.now().add(Duration(seconds: seconds)).toIso8601String();
    }
    await _saveHeader();
    return PinResult.wrong;
  }

  Future<void> _clearFailures() async {
    if (failedAttempts == 0 && _header['until'] == null) return;
    _header
      ..remove('failures')
      ..remove('until');
    await _saveHeader();
  }

  /// Sets or changes the PIN. Requires an unlocked store.
  Future<void> setPin(String pin) async {
    final dek = _dek;
    if (dek == null) throw StateError('Unlock before changing the PIN.');
    final salt = CryptoBox.randomBytes(16);
    final kek = await CryptoBox.deriveKey(pin, salt, iterations: _iterations);
    final inner = await CryptoBox.seal(kek, dek, aad: 'nt-dek-pin');
    _header
      ..['mode'] = 'pin'
      ..['kdf'] = {'alg': 'pbkdf2-hmac-sha256', 'iter': _iterations, 'salt': base64.encode(salt), 'len': pin.length}
      ..['dek'] = base64.encode(await _keys!.seal(inner))
      ..remove('legacyPin')
      ..remove('failures')
      ..remove('until');
    await _saveHeader();
  }

  /// Turns the PIN off; the data key goes back to device-only wrapping.
  Future<void> removePin() async {
    final dek = _dek;
    if (dek == null) throw StateError('Unlock before removing the PIN.');
    await disableBiometrics();
    _header
      ..['mode'] = 'device'
      ..['dek'] = base64.encode(await _keys!.seal(dek))
      ..remove('kdf')
      ..remove('legacyPin')
      ..remove('wipe')
      ..remove('failures')
      ..remove('until');
    await _saveHeader();
  }

  Future<void> setWipeAfterFailures(bool on) async {
    if (on) {
      _header['wipe'] = true;
    } else {
      _header.remove('wipe');
    }
    await _saveHeader();
  }

  // --- Biometrics ------------------------------------------------------------

  /// Puts the data key in the OS biometric-gated slot.
  Future<void> enableBiometrics() async {
    final dek = _dek;
    final keys = _keys;
    if (dek == null || keys == null || !keys.supportsBiometrics) {
      throw StateError('Biometric unlock is not available on this device.');
    }
    await keys.writeBiometricSecret(dek);
    _header['bio'] = true;
    await _saveHeader();
  }

  Future<void> disableBiometrics() async {
    if (!biometricEnabled) return;
    await _keys?.writeBiometricSecret(null);
    _header.remove('bio');
    await _saveHeader();
  }

  /// Shows the OS biometric prompt and unlocks on success.
  Future<bool> unlockWithBiometrics() async {
    if (!isLocked) return true;
    if (!biometricEnabled || _keys == null) return false;
    final dek = await _keys!.readBiometricSecret(reason: 'Unlock NOTtEodo');
    if (dek == null) return false;
    if (!await _isDataKey(dek)) {
      // Enrolled biometrics changed or the slot is stale: fall back to the PIN.
      await disableBiometrics();
      return false;
    }
    await _clearFailures();
    await _loadCache(dek);
    return true;
  }

  // --- Writes ----------------------------------------------------------------

  void _queue(String key, String? json) {
    _pending[key] = json;
    _drain ??= _runDrain();
  }

  Future<void> _runDrain() async {
    await Future<void>.value(); // always yield first, so _drain is assigned before it can clear
    try {
      while (_pending.isNotEmpty) {
        final dek = _dek;
        final prefs = _prefs;
        if (dek == null || prefs == null) {
          _pending.clear();
          break;
        }
        final batch = Map.of(_pending);
        _pending.clear();
        for (final e in batch.entries) {
          final slot = '$_prefix${e.key}';
          final value = e.value;
          if (value == null) {
            await prefs.remove(slot);
          } else {
            await prefs.setString(slot, '$_cipherTag${await CryptoBox.sealString(dek, value, aad: slot)}');
          }
        }
      }
    } catch (e) {
      debugPrint('[LocalStore] Could not persist: $e');
    } finally {
      _drain = null;
    }
  }

  /// Waits until every write so far is encrypted and on disk.
  Future<void> flush() async {
    while (_drain != null) {
      await _drain;
    }
  }

  // --- Collections -----------------------------------------------------------

  List<T>? readList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    if (!isReady) return null;
    final raw = _cache[key];
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      final out = <T>[];
      for (final row in decoded) {
        try {
          out.add(fromJson(Map<String, dynamic>.from(row as Map)));
        } catch (e) {
          // One malformed row must not take down the whole collection.
          debugPrint('[LocalStore] Skipped unreadable $key row: $e');
        }
      }
      return out;
    } catch (e) {
      debugPrint('[LocalStore] Could not read $key: $e');
      return null;
    }
  }

  void writeList(String key, List<Map<String, dynamic>> rows, {bool notify = true}) {
    if (!isReady) return;
    final json = jsonEncode(rows);
    _cache[key] = json;
    _queue(key, json);
    if (notify) {
      for (final l in List.of(_writeListeners)) {
        l(key);
      }
    }
  }

  Map<String, dynamic>? readMap(String key) => isReady ? _decodeMap(_cache[key]) : null;

  void writeMap(String key, Map<String, dynamic> value) {
    if (!isReady) return;
    final json = jsonEncode(value);
    _cache[key] = json;
    _queue(key, json);
  }

  /// Non-secret UI preferences (theme, motion) that are needed before unlock.
  /// Stored unencrypted, so never put anything personal here.
  Map<String, dynamic> readPublic() => _decodeMap(_prefs?.getString(_publicSlot)) ?? {};

  void writePublic(Map<String, dynamic> value) => _prefs?.setString(_publicSlot, jsonEncode(value));

  /// Decrypted JSON of every stored key, for backup/export and sync.
  Map<String, dynamic> dumpAll() {
    if (!isReady) return {};
    final out = <String, dynamic>{};
    _cache.forEach((k, raw) {
      try {
        out[k] = jsonDecode(raw);
      } catch (_) {}
    });
    return out;
  }

  /// Writes back a [dumpAll] snapshot. Keys not in the snapshot are left alone.
  Future<void> restoreAll(Map<String, dynamic> snapshot) async {
    if (!isReady) return;
    for (final entry in snapshot.entries) {
      final json = jsonEncode(entry.value);
      _cache[entry.key] = json;
      _queue(entry.key, json);
    }
    await flush();
  }

  /// Removes everything this app stored on the device, destroys the device key, and
  /// leaves a fresh empty vault (no PIN) so the app keeps working.
  Future<void> eraseAll() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await flush();
    _pending.clear();
    _cache.clear();
    _dek = null;
    for (final k in prefs.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
      await prefs.remove(k);
    }
    await _keys?.destroy();
    _header = {};
    await _createVault(migratePlaintext: false);
  }

  // --- Helpers ---------------------------------------------------------------

  static Iterable<String> _dataSlots(SharedPreferences prefs) =>
      prefs.getKeys().where((k) => k.startsWith(_prefix) && !_internalSlots.contains(k)).toList();

  static Map<String, dynamic>? _decodeMap(String? raw) {
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Uint8List? _b64(Object? v) {
    if (v is! String) return null;
    try {
      return base64.decode(v);
    } catch (_) {
      return null;
    }
  }
}
