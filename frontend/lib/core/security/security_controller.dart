import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_store.dart';

/// What the app-lock and encryption settings look like right now.
@immutable
class SecurityState {
  final bool hasPin;
  final bool biometricEnabled;

  /// e.g. "Face ID"; null when this device cannot do biometric unlock.
  final String? biometricLabel;
  final bool wipeAfterFailures;

  /// Where the device key lives, e.g. "Android Keystore".
  final String keyProtection;
  final bool hardwareBacked;

  const SecurityState({
    this.hasPin = false,
    this.biometricEnabled = false,
    this.biometricLabel,
    this.wipeAfterFailures = false,
    this.keyProtection = 'memory',
    this.hardwareBacked = false,
  });

  bool get biometricAvailable => biometricLabel != null;
}

class SecurityNotifier extends StateNotifier<SecurityState> {
  SecurityNotifier() : super(_read(null)) {
    LocalStore().securityRevision.addListener(_refresh);
    _loadBiometricLabel();
  }

  String? _label;

  static SecurityState _read(String? label) {
    final store = LocalStore();
    return SecurityState(
      hasPin: store.hasPin,
      biometricEnabled: store.biometricEnabled,
      biometricLabel: label,
      wipeAfterFailures: store.wipeAfterFailures,
      keyProtection: store.deviceKeys?.protection ?? 'memory (storage unavailable)',
      hardwareBacked: store.deviceKeys?.isHardwareBacked ?? false,
    );
  }

  void _refresh() {
    if (mounted) state = _read(_label);
  }

  Future<void> _loadBiometricLabel() async {
    final keys = LocalStore().deviceKeys;
    if (keys == null || !keys.supportsBiometrics) return;
    _label = await keys.biometricLabel();
    _refresh();
  }

  Future<void> setPin(String pin) => LocalStore().setPin(pin);
  Future<void> removePin() => LocalStore().removePin();
  Future<void> enableBiometrics() => LocalStore().enableBiometrics();
  Future<void> disableBiometrics() => LocalStore().disableBiometrics();
  Future<void> setWipeAfterFailures(bool on) => LocalStore().setWipeAfterFailures(on);

  @override
  void dispose() {
    LocalStore().securityRevision.removeListener(_refresh);
    super.dispose();
  }
}

final securityProvider = StateNotifierProvider<SecurityNotifier, SecurityState>((ref) => SecurityNotifier());

/// Android FLAG_SECURE: hides the app from screenshots, screen recording and the
/// recent-apps thumbnail. No-op on other platforms.
class ScreenPrivacy {
  ScreenPrivacy._();

  static const MethodChannel _channel = MethodChannel('notteodo/privacy');

  static Future<void> setSecure(bool on) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('setSecure', on);
    } catch (_) {}
  }
}
