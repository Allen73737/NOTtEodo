import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'crypto_box.dart';
import 'device_key_store.dart';

DeviceKeyStore createPlatformDeviceKeyStore() => SecureStorageDeviceKeyStore();

/// Android Keystore / Apple Keychain backed device secret.
class SecureStorageDeviceKeyStore implements DeviceKeyStore {
  static const String _deviceKeyName = 'nt.device.key.v1';
  static const String _bioKeyName = 'nt.bio.dek.v1';

  // The device key must never be silently reset: that would make every stored byte unreadable.
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false, storageNamespace: 'nt_device'),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  // Released by the OS only after a strong biometric check; invalidated when biometrics change.
  static const FlutterSecureStorage _bioStorage = FlutterSecureStorage(
    aOptions: AndroidOptions.biometric(
      enforceBiometrics: true,
      requireBiometricsPerOperation: true,
      biometricType: AndroidBiometricType.strongBiometricOnly,
      storageNamespace: 'nt_bio',
      biometricPromptTitle: 'Unlock NOTtEodo',
      biometricPromptNegativeButton: 'Use PIN',
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.passcode,
      accessControlFlags: [AccessControlFlag.biometryCurrentSet],
    ),
  );

  Uint8List? _key;
  bool _fallback = false;

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  @override
  String get protection => _fallback
      ? 'app memory only (secure storage unavailable)'
      : Platform.isAndroid
          ? 'Android Keystore'
          : Platform.isIOS || Platform.isMacOS
              ? 'Apple Keychain (this device only)'
              : 'OS credential store';

  @override
  bool get isHardwareBacked => !_fallback;

  Future<Uint8List> _deviceKey() async {
    final cached = _key;
    if (cached != null) return cached;
    try {
      final stored = await _storage.read(key: _deviceKeyName);
      if (stored != null) return _key = base64.decode(stored);
      final fresh = CryptoBox.newKey();
      await _storage.write(key: _deviceKeyName, value: base64.encode(fresh));
      return _key = fresh;
    } catch (e) {
      // e.g. desktop builds without a keyring. Data stays readable for this run only.
      debugPrint('[DeviceKeyStore] Secure storage unavailable: $e');
      _fallback = true;
      return _key = CryptoBox.newKey();
    }
  }

  @override
  Future<Uint8List> seal(List<int> plain) async => CryptoBox.seal(await _deviceKey(), plain, aad: 'nt-device');

  @override
  Future<Uint8List?> open(List<int> sealed) async => CryptoBox.open(await _deviceKey(), sealed, aad: 'nt-device');

  @override
  Future<void> destroy() async {
    _key = null;
    try {
      await _storage.delete(key: _deviceKeyName);
    } catch (_) {}
    await writeBiometricSecret(null);
  }

  @override
  bool get supportsBiometrics => _isMobile;

  @override
  Future<void> writeBiometricSecret(List<int>? secret) async {
    if (!_isMobile) return;
    try {
      if (secret == null) {
        await _bioStorage.delete(key: _bioKeyName);
      } else {
        await _bioStorage.write(key: _bioKeyName, value: base64.encode(secret));
      }
    } catch (e) {
      if (secret != null) rethrow;
    }
  }

  @override
  Future<Uint8List?> readBiometricSecret({required String reason}) async {
    if (!_isMobile) return null;
    try {
      final v = await _bioStorage.read(key: _bioKeyName);
      return v == null ? null : base64.decode(v);
    } catch (e) {
      debugPrint('[DeviceKeyStore] Biometric unlock failed: $e');
      return null;
    }
  }

  @override
  Future<String?> biometricLabel() async {
    if (!_isMobile) return null;
    try {
      final auth = LocalAuthentication();
      if (!await auth.isDeviceSupported() || !await auth.canCheckBiometrics) return null;
      final kinds = await auth.getAvailableBiometrics();
      if (kinds.isEmpty) return null;
      if (Platform.isIOS) return kinds.contains(BiometricType.face) ? 'Face ID' : 'Touch ID';
      if (kinds.contains(BiometricType.fingerprint)) return 'fingerprint';
      return kinds.contains(BiometricType.face) ? 'face unlock' : 'biometrics';
    } catch (_) {
      return null;
    }
  }
}
