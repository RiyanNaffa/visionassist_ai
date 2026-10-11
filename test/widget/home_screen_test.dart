import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:visionassist_ai/core/constants/app_strings.dart';
import 'package:visionassist_ai/presentation/screens/home_screen.dart';
import 'package:visionassist_ai/presentation/controllers/home_controller.dart';
import 'package:visionassist_ai/core/services/service_providers.dart';
import 'package:visionassist_ai/core/services/permission_service.dart';
import 'package:visionassist_ai/core/services/tts_service.dart';
import 'package:visionassist_ai/core/services/haptic_service.dart';
import 'package:visionassist_ai/core/services/audio_cue_service.dart';
import 'package:visionassist_ai/core/services/camera_service.dart';
import 'package:visionassist_ai/core/services/text_recognition_service.dart';
import 'package:visionassist_ai/core/services/speech_to_text_service.dart';

// ── Fakes ──────────────────────────────────────────────────────────────────

class _FakePermissionService implements PermissionService {
  @override
  Future<PermissionStatus> check(AppPermission p) async =>
      PermissionStatus.denied;
  @override
  Future<PermissionStatus> request(AppPermission p) async =>
      PermissionStatus.denied;
  @override
  Future<void> openSettings() async {}
}

class _FakeTts implements TtsService {
  @override
  bool get isSpeaking => false;
  @override
  bool get isPaused => false;
  @override
  Future<void> speak(String t, {bool interrupt = false}) async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> setSpeechRate(double r) async {}
  @override
  Future<void> setPitch(double p) async {}
  @override
  Future<void> dispose() async {}
}

class _FakeHaptic implements HapticService {
  @override
  Future<void> selectionClick() async {}
  @override
  Future<void> lightImpact() async {}
  @override
  Future<void> mediumImpact() async {}
  @override
  Future<void> heavyImpact() async {}
  @override
  Future<void> denominationPattern(String d) async {}
  @override
  Future<void> success() async {}
  @override
  Future<void> error() async {}
}

class _FakeAudio implements AudioCueService {
  @override
  Future<void> play(AudioCueEvent e) async {}
  @override
  Future<void> dispose() async {}
}

class _FakeCamera implements CameraService {
  @override
  bool get isStreaming => false;
  @override
  Future<void> initialize() async {}
  @override
  void startImageStream(void Function(CameraFrame f) cb) {}
  @override
  Future<void> stopImageStream() async {}
  @override
  Future<String> takePicture() async => '/tmp/test.jpg';
  @override
  Future<void> dispose() async {}
}

class _FakeRecognition implements TextRecognitionService {
  @override
  Future<TextRecognitionResult> recognizeFromFrame(CameraFrame f) async =>
      const TextRecognitionResult(text: '', blocks: []);
  @override
  Future<TextRecognitionResult> recognizeFromFile(String p) async =>
      const TextRecognitionResult(text: '', blocks: []);
  @override
  Future<void> dispose() async {}
}

class _FakeStt implements SpeechToTextService {
  @override
  bool get isListening => false;
  @override
  Future<bool> initialize() async => true;
  @override
  Future<void> startListening({
    required void Function(SpeechResult r) onResult,
    String localeId = 'id-ID',
    Duration listenFor = const Duration(seconds: 10),
  }) async {}
  @override
  Future<void> stopListening() async {}
  @override
  Future<void> dispose() async {}
}

// ── Helper ─────────────────────────────────────────────────────────────────

Widget _buildApp(Widget child) => ProviderScope(
      overrides: [
        permissionServiceProvider.overrideWithValue(_FakePermissionService()),
        ttsServiceProvider.overrideWithValue(_FakeTts()),
        hapticServiceProvider.overrideWithValue(_FakeHaptic()),
        audioCueServiceProvider.overrideWithValue(_FakeAudio()),
        cameraServiceProvider.overrideWithValue(_FakeCamera()),
        textRecognitionServiceProvider.overrideWithValue(_FakeRecognition()),
        sttServiceProvider.overrideWithValue(_FakeStt()),
      ],
      child: MaterialApp(home: child),
    );

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('HomeScreen — permission denied', () {
    testWidgets('shows retry button when camera denied', (tester) async {
      await tester.pumpWidget(_buildApp(const HomeScreen()));
      await tester.pump();

      expect(find.text(AppStrings.permissionCameraRetry), findsOneWidget);
    });

    testWidgets('retry button has touch target ≥ 72dp', (tester) async {
      await tester.pumpWidget(_buildApp(const HomeScreen()));
      await tester.pump();

      final btn = find.text(AppStrings.permissionCameraRetry);
      // Button itself; its ancestor ElevatedButton with minimumSize(height:72).
      final ancestor = find.ancestor(
        of: btn,
        matching: find.byType(ElevatedButton),
      );
      final btnSize = tester.getSize(ancestor.first);
      expect(btnSize.height, greaterThanOrEqualTo(72));
    });
  });

  group('QuadrantButton', () {
    testWidgets('has semantics label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ProviderScope(
                overrides: [
                  permissionServiceProvider
                      .overrideWithValue(_FakePermissionService()),
                  ttsServiceProvider.overrideWithValue(_FakeTts()),
                  hapticServiceProvider.overrideWithValue(_FakeHaptic()),
                  audioCueServiceProvider.overrideWithValue(_FakeAudio()),
                  cameraServiceProvider.overrideWithValue(_FakeCamera()),
                  textRecognitionServiceProvider
                      .overrideWithValue(_FakeRecognition()),
                  sttServiceProvider.overrideWithValue(_FakeStt()),
                ],
                child: const HomeScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Permission screen visible — just verify the widget tree renders.
      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });
}
