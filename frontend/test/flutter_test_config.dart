import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Intercept system messages so asynchronous font loading does not fire
  // unsolicited transient layout callbacks after tests dispose the widget tree.
  SystemChannels.system.setMessageHandler((dynamic message) async {
    return null;
  });

  setUp(() {
    SystemChannels.system.setMessageHandler((dynamic message) async {
      return null;
    });
  });

  await testMain();
}

