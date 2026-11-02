import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Saves [content] through the browser's download flow.
Future<bool> downloadTextFile(String fileName, String content, {String mimeType = 'text/plain'}) async {
  try {
    final blob = web.Blob([content.toJS].toJS, web.BlobPropertyBag(type: '$mimeType;charset=utf-8'));
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = fileName
      ..style.display = 'none';
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    Timer(const Duration(seconds: 2), () => web.URL.revokeObjectURL(url));
    return true;
  } catch (_) {
    return false;
  }
}

/// Opens the browser file chooser and returns the chosen file's text, or null if cancelled.
Future<String?> pickTextFile({String accept = '.json'}) {
  final completer = Completer<String?>();
  final input = web.document.createElement('input') as web.HTMLInputElement
    ..type = 'file'
    ..accept = accept;

  input.onchange = (web.Event _) {
    final file = input.files?.item(0);
    if (file == null) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    file.text().toDart.then(
          (text) => completer.complete(text.toDart),
          onError: (_) => completer.complete(null),
        );
  }.toJS;
  input.oncancel = (web.Event _) {
    if (!completer.isCompleted) completer.complete(null);
  }.toJS;
  input.click();
  return completer.future;
}

bool get notificationsSupported {
  try {
    return web.Notification.permission.isNotEmpty;
  } catch (_) {
    return false;
  }
}

Future<bool> requestNotificationPermission() async {
  if (!notificationsSupported) return false;
  if (web.Notification.permission == 'granted') return true;
  try {
    final result = await web.Notification.requestPermission().toDart;
    return result.toDart == 'granted';
  } catch (_) {
    return false;
  }
}

JSFunction? get _speechCtor {
  final ctor = globalContext['SpeechRecognition'] ?? globalContext['webkitSpeechRecognition'];
  return ctor.isA<JSFunction>() ? ctor as JSFunction : null;
}

bool get speechRecognitionSupported => _speechCtor != null;

/// Listens for one phrase with the browser's speech recognition; null if unsupported or nothing heard.
Future<String?> listenOnce({String lang = 'en-US'}) {
  final ctor = _speechCtor;
  if (ctor == null) return Future.value(null);
  final completer = Completer<String?>();
  final rec = ctor.callAsConstructor<JSObject>();
  rec['lang'] = lang.toJS;
  rec['interimResults'] = false.toJS;
  rec['maxAlternatives'] = 1.toJS;
  rec['onresult'] = (JSObject event) {
    try {
      final results = event['results'] as JSObject;
      final first = (results.callMethod<JSObject>('item'.toJS, 0.toJS)).callMethod<JSObject>('item'.toJS, 0.toJS);
      final text = (first['transcript'] as JSString).toDart;
      if (!completer.isCompleted) completer.complete(text);
    } catch (_) {
      if (!completer.isCompleted) completer.complete(null);
    }
  }.toJS;
  rec['onerror'] = (JSObject _) {
    if (!completer.isCompleted) completer.complete(null);
  }.toJS;
  rec['onend'] = (JSObject _) {
    if (!completer.isCompleted) completer.complete(null);
  }.toJS;
  rec.callMethod<JSAny?>('start'.toJS);
  return completer.future;
}

bool showSystemNotification(String title, String body) {
  if (!notificationsSupported || web.Notification.permission != 'granted') return false;
  try {
    web.Notification(title, web.NotificationOptions(body: body, icon: 'icons/Icon-192.png'));
    return true;
  } catch (_) {
    return false;
  }
}
