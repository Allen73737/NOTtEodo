import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Authenticated encryption primitives shared by the on-device vault, end-to-end
/// encrypted sync and password-protected backups.
///
/// * AES-256-GCM with a fresh 96-bit random nonce per message. Each message is
///   bound to an AAD label, so a ciphertext cannot be moved to another slot.
/// * PBKDF2-HMAC-SHA256 for passwords and PINs (OWASP 2023: 600,000 iterations).
///
/// On the web, `package:cryptography` routes both to the browser's WebCrypto.
/// On Android and iOS, `cryptography_flutter` uses the platform's native crypto.
class CryptoBox {
  CryptoBox._();

  static const int keyLength = 32;
  static const int nonceLength = 12;
  static const int macLength = 16;

  /// OWASP Password Storage Cheat Sheet (2023) recommendation for PBKDF2-HMAC-SHA256.
  static const int defaultPbkdf2Iterations = 600000;

  static final AesGcm _aes = AesGcm.with256bits();
  static final Random _rng = Random.secure();

  static Uint8List randomBytes(int length) =>
      Uint8List.fromList(List<int>.generate(length, (_) => _rng.nextInt(256)));

  static Uint8List newKey() => randomBytes(keyLength);

  /// Encrypts [plain] under [key]; returns `nonce ‖ ciphertext ‖ tag`.
  static Future<Uint8List> seal(List<int> key, List<int> plain, {required String aad}) async {
    final nonce = randomBytes(nonceLength);
    final box = await _aes.encrypt(
      plain,
      secretKey: SecretKey(key),
      nonce: nonce,
      aad: utf8.encode(aad),
    );
    return Uint8List.fromList([...nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  /// Reverses [seal]. Returns null when the key, AAD or data is wrong or was tampered with.
  static Future<Uint8List?> open(List<int> key, List<int> sealed, {required String aad}) async {
    if (sealed.length < nonceLength + macLength) return null;
    try {
      final box = SecretBox(
        sealed.sublist(nonceLength, sealed.length - macLength),
        nonce: sealed.sublist(0, nonceLength),
        mac: Mac(sealed.sublist(sealed.length - macLength)),
      );
      final plain = await _aes.decrypt(box, secretKey: SecretKey(key), aad: utf8.encode(aad));
      return Uint8List.fromList(plain);
    } on SecretBoxAuthenticationError {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String> sealString(List<int> key, String plain, {required String aad}) async =>
      base64.encode(await seal(key, utf8.encode(plain), aad: aad));

  static Future<String?> openString(List<int> key, String sealedB64, {required String aad}) async {
    final Uint8List raw;
    try {
      raw = base64.decode(sealedB64);
    } catch (_) {
      return null;
    }
    final plain = await open(key, raw, aad: aad);
    if (plain == null) return null;
    try {
      return utf8.decode(plain);
    } catch (_) {
      return null;
    }
  }

  /// Stretches a password or PIN into a 256-bit key.
  static Future<Uint8List> deriveKey(String secret, List<int> salt, {int iterations = defaultPbkdf2Iterations}) async {
    final pbkdf2 = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: keyLength * 8);
    final key = await pbkdf2.deriveKeyFromPassword(password: secret, nonce: salt);
    return Uint8List.fromList(await key.extractBytes());
  }

  /// Equality that takes the same time wherever the first difference is.
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
