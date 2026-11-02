import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'crypto_box.dart';
import 'device_key_store.dart';

DeviceKeyStore createPlatformDeviceKeyStore() => WebDeviceKeyStore();

/// Keeps a **non-extractable** AES-GCM CryptoKey in IndexedDB.
///
/// The key's bytes are never exposed to JavaScript, so even injected script
/// cannot copy it out of the browser. If IndexedDB is unavailable (some
/// private-browsing modes) the store falls back to a raw key in localStorage and
/// reports itself as not hardware backed.
class WebDeviceKeyStore implements DeviceKeyStore {
  static const String _dbName = 'notteodo-keys';
  static const String _storeName = 'keys';
  static const String _keyId = 'device-v1';
  static const String _fallbackSlot = 'nt.__dk';

  web.CryptoKey? _key;
  Uint8List? _fallbackKey;

  @override
  String get protection => _fallbackKey != null
      ? 'browser storage (IndexedDB unavailable)'
      : 'browser WebCrypto key (non-extractable)';

  @override
  bool get isHardwareBacked => _fallbackKey == null;

  Future<JSAny?> _await(web.IDBRequest req) {
    final done = Completer<JSAny?>();
    req.onsuccess = ((web.Event _) => done.complete(req.result)).toJS;
    req.onerror = ((web.Event _) => done.completeError(StateError('IndexedDB request failed'))).toJS;
    return done.future;
  }

  Future<web.IDBDatabase> _openDb() {
    final done = Completer<web.IDBDatabase>();
    final req = web.window.indexedDB.open(_dbName, 1);
    req.onupgradeneeded = ((web.Event _) {
      final db = req.result as web.IDBDatabase;
      if (!db.objectStoreNames.contains(_storeName)) db.createObjectStore(_storeName);
    }).toJS;
    req.onsuccess = ((web.Event _) => done.complete(req.result as web.IDBDatabase)).toJS;
    req.onerror = ((web.Event _) => done.completeError(StateError('IndexedDB is unavailable'))).toJS;
    req.onblocked = ((web.Event _) => done.completeError(StateError('IndexedDB is blocked'))).toJS;
    return done.future;
  }

  Future<void> _ensureKey() async {
    if (_key != null || _fallbackKey != null) return;
    try {
      final db = await _openDb();
      try {
        final read = db.transaction(_storeName.toJS, 'readonly').objectStore(_storeName);
        final existing = await _await(read.get(_keyId.toJS));
        if (existing != null) {
          _key = existing as web.CryptoKey;
          return;
        }
        final generated = await web.window.crypto.subtle
            .generateKey(
              {'name': 'AES-GCM', 'length': 256}.jsify()!,
              false, // non-extractable
              ['encrypt'.toJS, 'decrypt'.toJS].toJS,
            )
            .toDart;
        final key = generated as web.CryptoKey;
        final write = db.transaction(_storeName.toJS, 'readwrite').objectStore(_storeName);
        await _await(write.put(key, _keyId.toJS));
        _key = key;
      } finally {
        db.close();
      }
    } catch (e) {
      debugPrint('[DeviceKeyStore] Falling back to localStorage key: $e');
      final storage = web.window.localStorage;
      final stored = storage.getItem(_fallbackSlot);
      if (stored != null) {
        _fallbackKey = base64.decode(stored);
      } else {
        final fresh = CryptoBox.newKey();
        storage.setItem(_fallbackSlot, base64.encode(fresh));
        _fallbackKey = fresh;
      }
    }
  }

  /// `{name: 'AES-GCM', iv, additionalData}` for SubtleCrypto.encrypt / decrypt.
  static JSObject _gcmParams(Uint8List iv) {
    final p = JSObject();
    p.setProperty('name'.toJS, 'AES-GCM'.toJS);
    p.setProperty('iv'.toJS, iv.toJS);
    p.setProperty('additionalData'.toJS, Uint8List.fromList(utf8.encode('nt-device')).toJS);
    return p;
  }

  @override
  Future<Uint8List> seal(List<int> plain) async {
    await _ensureKey();
    final fb = _fallbackKey;
    if (fb != null) return CryptoBox.seal(fb, plain, aad: 'nt-device');
    final nonce = CryptoBox.randomBytes(CryptoBox.nonceLength);
    final out = await web.window.crypto.subtle
        .encrypt(
          _gcmParams(nonce),
          _key!,
          Uint8List.fromList(plain).toJS,
        )
        .toDart;
    final ct = (out as JSArrayBuffer).toDart.asUint8List();
    return Uint8List.fromList([...nonce, ...ct]);
  }

  @override
  Future<Uint8List?> open(List<int> sealed) async {
    await _ensureKey();
    final fb = _fallbackKey;
    if (fb != null) return CryptoBox.open(fb, sealed, aad: 'nt-device');
    if (sealed.length < CryptoBox.nonceLength + CryptoBox.macLength) return null;
    try {
      final bytes = Uint8List.fromList(sealed);
      final out = await web.window.crypto.subtle
          .decrypt(
            _gcmParams(bytes.sublist(0, CryptoBox.nonceLength)),
            _key!,
            bytes.sublist(CryptoBox.nonceLength).toJS,
          )
          .toDart;
      return (out as JSArrayBuffer).toDart.asUint8List();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> destroy() async {
    _key = null;
    _fallbackKey = null;
    web.window.localStorage.removeItem(_fallbackSlot);
    try {
      final db = await _openDb();
      try {
        await _await(db.transaction(_storeName.toJS, 'readwrite').objectStore(_storeName).delete(_keyId.toJS));
      } finally {
        db.close();
      }
    } catch (_) {}
  }

  @override
  bool get supportsBiometrics => false;

  @override
  Future<void> writeBiometricSecret(List<int>? secret) async {}

  @override
  Future<Uint8List?> readBiometricSecret({required String reason}) async => null;

  @override
  Future<String?> biometricLabel() async => null;
}
