import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notteodo/core/widgets/omni_capture_modal.dart';
import 'package:notteodo/core/widgets/voice_studio_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithScope(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(body: child),
      ),
    );
  }

  group('Voice Studio & Speech-to-Text Transcription Suite', () {
    testWidgets('1. VoiceStudioModal renders live transcription studio with dictate action', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Setup mock method channel for voice recorder
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('notteodo/voice_recorder'), (MethodCall call) async {
        if (call.method == 'startRecording') {
          return '/tmp/mock_recording.m4a';
        }
        if (call.method == 'stopRecording') {
          return {'path': '/tmp/mock_recording.m4a', 'transcript': 'Buy espresso beans tomorrow'};
        }
        return null;
      });

      await tester.pumpWidget(
        wrapWithScope(
          const VoiceStudioModal(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Voice Studio Header
      expect(find.text('VOICE STUDIO'), findsOneWidget);

      // Soundwave and Timer status
      expect(find.textContaining('RECORDING ·'), findsOneWidget);

      // Header row above transcript has Live Dictate button
      expect(find.text('Live Dictate'), findsOneWidget);

      // Stop & Transcribe button
      expect(find.text('Stop & Transcribe'), findsOneWidget);

      // Destination chips
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Journal'), findsOneWidget);
      expect(find.text('Habits'), findsOneWidget);
      expect(find.text('AI Plan'), findsOneWidget);

      // Audio attach toggle
      expect(find.textContaining('Attach Voice Audio'), findsOneWidget);

      // Tap Stop & Transcribe
      await tester.tap(find.text('Stop & Transcribe'));
      await tester.pump(const Duration(milliseconds: 400));

      // Check transcript populated
      expect(find.text('Buy espresso beans tomorrow'), findsOneWidget);
    });

    testWidgets('2. OmniCaptureModal includes voice dictation button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithScope(
          const OmniCaptureModal(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Omni-Capture Speed Hub
      expect(find.text('OMNI-CAPTURE SPEED HUB'), findsOneWidget);

      // Voice Dictate button exists in TextField suffix
      expect(find.byTooltip('Dictate voice'), findsOneWidget);
    });
  });
}

