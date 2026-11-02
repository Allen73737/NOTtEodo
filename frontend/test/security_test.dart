import 'dart:convert';

import 'package:crypto/crypto.dart' as legacy;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:notteodo/core/security/crypto_box.dart';
import 'package:notteodo/core/security/device_key_store.dart';
import 'package:notteodo/core/security/password_policy.dart';
import 'package:notteodo/core/services/data_portability_service.dart';
import 'package:notteodo/core/services/local_store.dart';
import 'package:notteodo/core/state/sanctuary_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _iter = 1000; // keeps PBKDF2 fast in tests; production uses 600,000

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

/// Simulates an app restart on the same device (same storage, same device key).
Future<void> _restart(DeviceKeyStore keys) async {
  await LocalStore().flush();
  LocalStore().resetForTest();
  await LocalStore().init(deviceKeys: keys, pbkdf2Iterations: _iter);
}

void main() {
  late MemoryDeviceKeyStore keys;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LocalStore().resetForTest();
    keys = MemoryDeviceKeyStore(biometrics: true);
    await LocalStore().init(deviceKeys: keys, pbkdf2Iterations: _iter);
  });
  tearDown(() => LocalStore().resetForTest());

  group('CryptoBox', () {
    test('seal/open round-trips and rejects a wrong key, wrong AAD or tampering', () async {
      final key = CryptoBox.newKey();
      final sealed = await CryptoBox.seal(key, utf8.encode('secret'), aad: 'a');
      expect(utf8.decode((await CryptoBox.open(key, sealed, aad: 'a'))!), 'secret');
      expect(await CryptoBox.open(CryptoBox.newKey(), sealed, aad: 'a'), isNull);
      expect(await CryptoBox.open(key, sealed, aad: 'b'), isNull);
      final tampered = [...sealed]..[14] ^= 1;
      expect(await CryptoBox.open(key, tampered, aad: 'a'), isNull);
    });

    test('every seal uses a fresh nonce', () async {
      final key = CryptoBox.newKey();
      final a = await CryptoBox.sealString(key, 'same', aad: 'x');
      final b = await CryptoBox.sealString(key, 'same', aad: 'x');
      expect(a, isNot(b));
    });

    test('PBKDF2 matches the RFC 7914 test vector', () async {
      // PBKDF2-HMAC-SHA256("passwd", "salt", c=1, dkLen=64) — first 32 bytes.
      final k = await CryptoBox.deriveKey('passwd', utf8.encode('salt'), iterations: 1);
      expect(k.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
          '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc');
    });
  });

  group('encrypted LocalStore', () {
    test('values are AES-GCM ciphertext on disk, plaintext in memory', () async {
      LocalStore().writeList('notes', [
        {'id': 'n1', 'title': 'Bank PIN is in the drawer'}
      ]);
      await LocalStore().flush();
      final raw = (await _prefs()).getString('nt.notes')!;
      expect(raw, startsWith('e1:'));
      expect(raw, isNot(contains('drawer')));
      expect(LocalStore().readList('notes', (j) => j['title'])!.single, 'Bank PIN is in the drawer');

      await _restart(keys);
      expect(LocalStore().isReady, isTrue, reason: 'no PIN: opens with the device key alone');
      expect(LocalStore().readList('notes', (j) => j['title'])!.single, 'Bank PIN is in the drawer');
    });

    test('a ciphertext moved to another slot does not decrypt (slot-bound AAD)', () async {
      LocalStore().writeList('notes', [
        {'id': 'n1'}
      ]);
      LocalStore().writeList('tasks', [
        {'id': 't1'}
      ]);
      await LocalStore().flush();
      final prefs = await _prefs();
      await prefs.setString('nt.tasks', prefs.getString('nt.notes')!);
      await _restart(keys);
      expect(LocalStore().readList('tasks', (j) => j), isNull);
      expect(LocalStore().readList('notes', (j) => j), isNotNull);
    });

    test('plaintext from older builds is migrated and encrypted in place', () async {
      SharedPreferences.setMockInitialValues({
        'nt.notes': jsonEncode([
          {'id': 'n1', 'title': 'Old note'}
        ]),
      });
      LocalStore().resetForTest();
      await LocalStore().init(deviceKeys: keys, pbkdf2Iterations: _iter);
      await LocalStore().flush();
      expect((await _prefs()).getString('nt.notes'), startsWith('e1:'));
      expect(LocalStore().readList('notes', (j) => j['title'])!.single, 'Old note');
    });

    test('a lost device key starts a fresh vault instead of crashing', () async {
      LocalStore().writeMap('settings', {'displayName': 'A'});
      await LocalStore().flush();
      await _restart(MemoryDeviceKeyStore()); // a different device secret
      expect(LocalStore().isReady, isTrue);
      expect(LocalStore().readMap('settings'), isNull);
      expect(LocalStore().startupNotice, isNotNull);
    });
  });

  group('app PIN', () {
    test('locks the vault: nothing is readable until the right PIN', () async {
      LocalStore().writeList('notes', [
        {'id': 'n1', 'title': 'Diary'}
      ]);
      await LocalStore().setPin('482913');
      await _restart(keys);

      expect(LocalStore().isLocked, isTrue);
      expect(LocalStore().hasPin, isTrue);
      expect(LocalStore().pinLength, 6);
      expect(LocalStore().readList('notes', (j) => j), isNull);

      // Writes while locked are dropped, never written over the ciphertext.
      LocalStore().writeList('notes', []);
      expect(await LocalStore().unlockWithPin('000000'), PinResult.wrong);
      expect(await LocalStore().unlockWithPin('482913'), PinResult.unlocked);
      expect(LocalStore().readList('notes', (j) => j['title'])!.single, 'Diary');
    });

    test('the PIN is never stored, in any form', () async {
      await LocalStore().setPin('482913');
      await LocalStore().flush();
      final prefs = await _prefs();
      final everything = prefs.getKeys().map((k) => '${prefs.get(k)}').join();
      expect(everything, isNot(contains('482913')));
      final sha = legacy.sha256.convert(utf8.encode('482913')).toString();
      expect(everything, isNot(contains(sha)));
    });

    test('misses back off with a pause that survives a restart', () async {
      await LocalStore().setPin('482913');
      await _restart(keys);
      for (var i = 0; i < LocalStore.freeAttempts; i++) {
        expect(await LocalStore().unlockWithPin('111111'), PinResult.wrong);
      }
      expect(LocalStore().lockedUntil, isNotNull);
      expect(await LocalStore().unlockWithPin('482913'), PinResult.coolingDown);

      await _restart(keys); // reloading the app does not reset the counter
      expect(LocalStore().failedAttempts, LocalStore.freeAttempts);
      expect(await LocalStore().unlockWithPin('482913'), PinResult.coolingDown);
    });

    test('optional auto-erase after 10 misses', () async {
      LocalStore().writeList('notes', [
        {'id': 'n1'}
      ]);
      await LocalStore().setPin('482913');
      await LocalStore().setWipeAfterFailures(true);
      await _restart(keys);

      var last = PinResult.wrong;
      for (var i = 0; i < LocalStore.wipeThreshold; i++) {
        // Skip past cool-downs so each attempt counts.
        final prefs = await _prefs();
        final header = jsonDecode(prefs.getString('nt.__vault')!) as Map<String, dynamic>..remove('until');
        await prefs.setString('nt.__vault', jsonEncode(header));
        await _restart(keys);
        last = await LocalStore().unlockWithPin('111111');
      }
      expect(last, PinResult.wiped);
      expect(LocalStore().hasPin, isFalse);
      expect(LocalStore().isReady, isTrue);
      expect(LocalStore().readList('notes', (j) => j), isNull);
    });

    test('removing the PIN returns to device-key-only unlock', () async {
      await LocalStore().setPin('482913');
      await LocalStore().removePin();
      await _restart(keys);
      expect(LocalStore().isReady, isTrue);
      expect(LocalStore().hasPin, isFalse);
    });

    test('biometric slot unlocks; a cancelled prompt does not', () async {
      LocalStore().writeMap('settings', {'displayName': 'Sam'});
      await LocalStore().setPin('482913');
      await LocalStore().enableBiometrics();
      await _restart(keys);

      keys.cancelBiometric = true;
      expect(await LocalStore().unlockWithBiometrics(), isFalse);
      expect(LocalStore().isLocked, isTrue);

      keys.cancelBiometric = false;
      expect(await LocalStore().unlockWithBiometrics(), isTrue);
      expect(LocalStore().readMap('settings')!['displayName'], 'Sam');
    });

    test('a legacy SHA-256 PIN still unlocks once and is upgraded', () async {
      const salt = 'abc';
      final hash = legacy.sha256.convert(utf8.encode('$salt:2468')).toString();
      SharedPreferences.setMockInitialValues({
        'nt.settings': jsonEncode({'displayName': 'Old', 'pinHash': hash, 'pinSalt': salt}),
      });
      LocalStore().resetForTest();
      await LocalStore().init(deviceKeys: keys, pbkdf2Iterations: _iter);

      expect(LocalStore().isLocked, isTrue);
      expect(await LocalStore().unlockWithPin('1111'), PinResult.wrong);
      expect(await LocalStore().unlockWithPin('2468'), PinResult.unlocked);
      expect(LocalStore().readMap('settings')!.containsKey('pinHash'), isFalse);

      await _restart(keys);
      expect(LocalStore().isLocked, isTrue);
      expect(await LocalStore().unlockWithPin('2468'), PinResult.unlocked);
      final header = jsonDecode((await _prefs()).getString('nt.__vault')!) as Map;
      expect(header['legacyPin'], isNull);
      expect(header['kdf']['alg'], 'pbkdf2-hmac-sha256');
    });
  });

  group('backups', () {
    setUp(() => DataPortabilityService.kdfIterations = _iter);

    test('password-encrypted backup round-trips and rejects a wrong password', () async {
      LocalStore().writeList('notes', [
        {'id': 'n1', 'title': 'Private'}
      ]);
      final file = await DataPortabilityService.buildEncryptedBackup('correct horse battery');
      expect(file, isNot(contains('Private')));
      expect(DataPortabilityService.isEncryptedBackup(file), isTrue);

      await expectLater(DataPortabilityService.decryptBackup(file, 'wrong'), throwsFormatException);
      final plain = await DataPortabilityService.decryptBackup(file, 'correct horse battery');
      expect(plain, contains('Private'));
    });

    test('CSV export neutralises spreadsheet formulas (CWE-1236)', () {
      final csv = DataPortabilityService.tasksCsv([
        TaskItem(id: 't1', title: '=HYPERLINK("http://evil","x")', priority: 'High', space: 'Work', timeOfDay: ''),
        TaskItem(id: 't2', title: '-42', priority: 'Low', space: '@home', timeOfDay: ''),
      ]);
      final rows = csv.split('\r\n');
      expect(rows[1], startsWith('"\'=HYPERLINK'));
      expect(rows[2], startsWith('-42,'), reason: 'plain numbers are left alone');
      expect(rows[2], contains(",'@home,"));
    });
  });

  group('password policy', () {
    test('rejects short, common, sequential and email-based passwords', () {
      expect(PasswordPolicy.evaluate('short').acceptable, isFalse);
      expect(PasswordPolicy.evaluate('password123').acceptable, isFalse);
      expect(PasswordPolicy.evaluate('1234567890').acceptable, isFalse);
      expect(PasswordPolicy.evaluate('aaaaaaaaaaaa').acceptable, isFalse);
      expect(PasswordPolicy.evaluate('samwise-garden-2026', email: 'samwise@shire.me').acceptable, isFalse);
    });

    test('accepts a long passphrase and rates it strong', () {
      final c = PasswordPolicy.evaluate('violet kettle drifts at noon!');
      expect(c.acceptable, isTrue);
      expect(c.score, greaterThanOrEqualTo(3));
    });

    test('breach check sends only a 5-character hash prefix', () async {
      final hash = legacy.sha1.convert(utf8.encode('hunter2hunter2')).toString().toUpperCase();
      Uri? asked;
      final client = MockClient((req) async {
        asked = req.url;
        return http.Response('${hash.substring(5)}:42\r\n0000000000000000000000000000000000A:0', 200);
      });
      expect(await PasswordPolicy.breachCount('hunter2hunter2', client: client), 42);
      expect(asked!.path, '/range/${hash.substring(0, 5)}');
      expect(asked.toString(), isNot(contains(hash.substring(5))));
    });

    test('breach check fails open when offline', () async {
      final client = MockClient((_) async => throw Exception('offline'));
      expect(await PasswordPolicy.breachCount('anything-long', client: client), isNull);
    });
  });
}
