/// Non-web fallback: nothing to download to or notify through.
Future<bool> downloadTextFile(String fileName, String content, {String mimeType = 'text/plain'}) async => false;

Future<String?> pickTextFile({String accept = '.json'}) async => null;

bool get notificationsSupported => false;

Future<bool> requestNotificationPermission() async => false;

bool showSystemNotification(String title, String body) => false;

bool get speechRecognitionSupported => false;

Future<String?> listenOnce({String lang = 'en-US'}) async => null;
