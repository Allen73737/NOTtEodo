import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const FlutterSecureStorage _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(storageNamespace: 'nt_session'),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
);

/// Keeps the Supabase refresh token in the Android Keystore / iOS Keychain instead
/// of plain SharedPreferences. (Mobile only; the web uses the browser's storage,
/// which a strict CSP protects.)
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage();

  static const String _key = 'sb-session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => await _storage.containsKey(key: _key);

  @override
  Future<String?> accessToken() => _storage.read(key: _key);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) => _storage.write(key: _key, value: persistSessionString);
}

/// PKCE code verifier storage, also kept in the secure store.
class SecurePkceStorage extends GotrueAsyncStorage {
  const SecurePkceStorage();

  @override
  Future<String?> getItem({required String key}) => _storage.read(key: 'pkce.$key');

  @override
  Future<void> removeItem({required String key}) => _storage.delete(key: 'pkce.$key');

  @override
  Future<void> setItem({required String key, required String value}) => _storage.write(key: 'pkce.$key', value: value);
}
