/// Browser-only capabilities (file download/upload, system notifications), with
/// no-op fallbacks on other platforms and in tests.
library;

export 'browser_bridge_stub.dart' if (dart.library.js_interop) 'browser_bridge_web.dart';
