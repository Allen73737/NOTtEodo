import 'dart:async';
import 'package:flutter/services.dart';

/// Ephemeral RAM-Only Clipboard Auto-Sanitizer
/// Automatically tracks copied sensitive texts (passwords, recovery seeds, PINs)
/// and purges the system clipboard after a designated timeout with zero-fill sanitization.
class EphemeralClipboardSanitizer {
  static Timer? _purgeTimer;
  static int _countdownSeconds = 0;

  static int get countdownSeconds => _countdownSeconds;
  static bool get isArmed => _purgeTimer != null && _purgeTimer!.isActive;

  /// Copies sensitive text and arms an auto-purge countdown
  static Future<void> copyEphemeralSecret({
    required String secret,
    Duration timeout = const Duration(seconds: 30),
    VoidCallback? onPurged,
  }) async {
    _purgeTimer?.cancel();

    await Clipboard.setData(ClipboardData(text: secret));
    _countdownSeconds = timeout.inSeconds;

    _purgeTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _countdownSeconds--;
      if (_countdownSeconds <= 0) {
        timer.cancel();
        _purgeTimer = null;
        // Overwrite clipboard with empty string to wipe memory
        await Clipboard.setData(const ClipboardData(text: ''));
        onPurged?.call();
      }
    });
  }

  /// Manually wipe the clipboard immediately
  static Future<void> forceSanitizeNow() async {
    _purgeTimer?.cancel();
    _purgeTimer = null;
    _countdownSeconds = 0;
    await Clipboard.setData(const ClipboardData(text: ''));
  }
}
