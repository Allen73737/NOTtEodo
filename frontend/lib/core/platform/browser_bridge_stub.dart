import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Non-web fallback: nothing to download to or notify through.
Future<bool> downloadTextFile(String fileName, String content, {String mimeType = 'text/plain'}) async => false;

Future<String?> pickTextFile({String accept = '.json'}) async => null;

bool get notificationsSupported => false;

Future<bool> requestNotificationPermission() async => false;

bool showSystemNotification(String title, String body) => false;

const MethodChannel _speechChannel = MethodChannel('notteodo/speech');

bool get speechRecognitionSupported {
  if (kIsWeb) return false;
  try {
    return Platform.isAndroid || Platform.isIOS;
  } catch (_) {
    return false;
  }
}

Future<String?> listenOnce({String lang = 'en-US'}) async {
  if (kIsWeb) return null;
  try {
    if (Platform.isAndroid) {
      final res = await _speechChannel.invokeMethod<String>('listen');
      return res;
    }
  } catch (_) {
    return null;
  }
  return null;
}
