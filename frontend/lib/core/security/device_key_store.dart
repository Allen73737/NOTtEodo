import 'dart:typed_data';

import 'crypto_box.dart';
import 'device_key_store_stub.dart'
    if (dart.library.js_interop) 'device_key_store_web.dart'
    if (dart.library.io) 'device_key_store_io.dart' as platform;

/// Holds a secret that never leaves this device and uses it to wrap the vault key.
///
/// * Android: a hardware-backed Android Keystore key (through flutter_secure_storage).
/// * iOS: a Keychain item that is only readable on this device after the first unlock.
/// * Web: a non-extractable WebCrypto AES-GCM key kept in IndexedDB. Page script can
///   use the key but cannot read its bytes.
///
/// Copying the app's storage to another machine is therefore not enough to decrypt it.
abstract class DeviceKeyStore {
  /// Where the device secret lives, shown in Settings → Security.
  String get protection;

  /// False when the platform had to fall back to a key kept next to the data.
  bool get isHardwareBacked;

  Future<Uint8List> seal(List<int> plain);
  Future<Uint8List?> open(List<int> sealed);

  /// Forgets the device secret, so everything it wrapped can no longer be read.
  Future<void> destroy();

  // --- Biometric slot (Android / iOS only) -----------------------------------

  /// True when this platform can keep a secret that the OS only releases after a
  /// biometric check (Keystore user authentication / Keychain biometryCurrentSet).
  bool get supportsBiometrics;

  /// Stores [secret] in the biometric-gated slot, or clears the slot when null.
  Future<void> writeBiometricSecret(List<int>? secret);

  /// Shows the OS biometric prompt; returns null if the user cancels or fails.
  Future<Uint8List?> readBiometricSecret({required String reason});

  /// Human label for the biometric method (e.g. "Face ID", "fingerprint").
  Future<String?> biometricLabel();
}

DeviceKeyStore createDeviceKeyStore() => platform.createPlatformDeviceKeyStore();

/// In-memory implementation for tests and platforms without secure storage.
class MemoryDeviceKeyStore implements DeviceKeyStore {
  MemoryDeviceKeyStore({this.biometrics = false});

  final bool biometrics;
  Uint8List _key = CryptoBox.newKey();
  Uint8List? _bio;

  /// When set, [readBiometricSecret] behaves as if the user cancelled the prompt.
  bool cancelBiometric = false;

  @override
  String get protection => 'memory (test)';

  @override
  bool get isHardwareBacked => false;

  @override
  Future<Uint8List> seal(List<int> plain) => CryptoBox.seal(_key, plain, aad: 'nt-device');

  @override
  Future<Uint8List?> open(List<int> sealed) => CryptoBox.open(_key, sealed, aad: 'nt-device');

  @override
  Future<void> destroy() async {
    _key = CryptoBox.newKey();
    _bio = null;
  }

  @override
  bool get supportsBiometrics => biometrics;

  @override
  Future<void> writeBiometricSecret(List<int>? secret) async =>
      _bio = secret == null ? null : Uint8List.fromList(secret);

  @override
  Future<Uint8List?> readBiometricSecret({required String reason}) async => cancelBiometric ? null : _bio;

  @override
  Future<String?> biometricLabel() async => biometrics ? 'biometrics' : null;
}
