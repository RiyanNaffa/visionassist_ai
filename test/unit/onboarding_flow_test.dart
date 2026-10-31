import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:visionassist_ai/core/constants/app_strings.dart';
import 'package:visionassist_ai/core/services/camera_service.dart';

import '../helpers/home_controller_harness.dart';

final _steps = AppStrings.onboardingSteps(screenReader: false);

final _frame = CameraFrame(
  bytes: Uint8List(0),
  width: 1,
  height: 1,
  bytesPerRow: 1,
  format: 'nv21',
  rotationDegrees: 0,
);

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('both guide variants have the same number of steps', () {
    expect(
      AppStrings.onboardingSteps(screenReader: true),
      hasLength(_steps.length),
    );
  });

  group('first launch', () {
    test('starts the guide and holds back the camera request', () async {
      final h = HomeControllerHarness(completed: false, granted: false);
      await h.start();

      expect(h.state.isOnboarding, isTrue);
      expect(h.state.onboardingStep, 0);
      expect(h.tts.spoken, [_steps.first]);
      expect(h.permissions.checks, 0);
      expect(h.permissions.requests, 0);
    });

    test('next, previous and repeat speak the matching step', () async {
      final h = HomeControllerHarness(completed: false, granted: false);
      await h.start();

      await h.controller.onboardingNext();
      expect(h.state.onboardingStep, 1);
      expect(h.tts.spoken.last, _steps[1]);

      await h.controller.onboardingRepeat();
      expect(h.state.onboardingStep, 1);
      expect(h.tts.spoken.last, _steps[1]);

      await h.controller.onboardingPrevious();
      await h.controller.onboardingPrevious(); // stays on the first step
      expect(h.state.onboardingStep, 0);
      expect(h.tts.spoken.last, _steps[0]);
    });

    test('finishing the last step saves it and then asks for the camera',
        () async {
      final h = HomeControllerHarness(completed: false, granted: false);
      await h.start();

      for (var i = 0; i < _steps.length; i++) {
        await h.controller.onboardingNext();
      }
      await settle();

      expect(h.state.isOnboarding, isFalse);
      expect(h.store.marks, 1);
      expect(
        h.tts.spoken,
        containsAllInOrder([
          _steps.last,
          '${AppStrings.ttsOnboardingDone} '
              '${AppStrings.ttsActiveMode(AppStrings.modeTextReader)}',
          AppStrings.ttsCameraPermissionPrompt,
        ]),
      );
      expect(h.permissions.requests, 1);
    });

    test('skipping says so and is remembered too', () async {
      final h = HomeControllerHarness(completed: false, granted: true);
      await h.start();

      await h.controller.onboardingNext();
      await h.controller.finishOnboarding();
      await settle();

      expect(h.state.isOnboarding, isFalse);
      expect(h.store.marks, 1);
      expect(
        h.tts.spoken,
        contains(
          '${AppStrings.ttsOnboardingSkipped} '
          '${AppStrings.ttsActiveMode(AppStrings.modeTextReader)}',
        ),
      );
      // Permission already granted: no prompt, straight to the camera.
      expect(
          h.tts.spoken, isNot(contains(AppStrings.ttsCameraPermissionPrompt)));
      expect(h.permissions.requests, 0);
      expect(h.camera.initialized, isTrue);
    });
  });

  group('later launches', () {
    test('greet briefly and open the camera without the guide', () async {
      final h = HomeControllerHarness(completed: true, granted: true);
      await h.start();

      expect(h.state.isOnboarding, isFalse);
      expect(h.tts.spoken, [
        '${AppStrings.ttsWelcomeBack} '
            '${AppStrings.ttsActiveMode(AppStrings.modeTextReader)} '
            '${AppStrings.ttsGuideHintGesture}',
      ]);
      expect(h.camera.initialized, isTrue);
      expect(h.store.marks, 0);
    });

    test('open the camera while the TTS engine is still starting', () async {
      final h = HomeControllerHarness(completed: true, granted: true);
      final engine = Completer<void>();
      h.tts.engineReady = engine.future;
      await h.start();

      // Regression: the greeting used to be awaited first, which kept the
      // permission screen up for seconds on a cold start.
      expect(h.camera.initialized, isTrue);
      expect(h.state.cameraPermissionGranted, isTrue);
      engine.complete();
    });

    test('queue the greeting ahead of the camera prompt', () async {
      final h = HomeControllerHarness(completed: true, granted: false);
      final engine = Completer<void>();
      h.tts.engineReady = engine.future;
      await h.start();

      expect(h.tts.spoken, hasLength(2));
      expect(h.tts.spoken.first, startsWith(AppStrings.ttsWelcomeBack));
      expect(h.tts.spoken.last, AppStrings.ttsCameraPermissionPrompt);

      engine.complete();
      await settle();
      expect(h.permissions.requests, 1);
    });

    test('replaying the guide does not ask for the camera again', () async {
      final h = HomeControllerHarness(completed: true, granted: true);
      await h.start();

      await h.controller.startOnboarding();
      expect(h.state.isOnboarding, isTrue);
      expect(h.tts.spoken.last, _steps.first);

      await h.controller.finishOnboarding();
      await settle();

      expect(h.state.isOnboarding, isFalse);
      expect(h.permissions.checks, 1); // only the one at start-up
      expect(h.permissions.requests, 0);
    });

    test('live frames are ignored while the guide runs', () async {
      final h = HomeControllerHarness(completed: true, granted: true);
      await h.start();
      final onFrame = h.camera.onFrame!;

      await h.controller.startOnboarding();
      onFrame(_frame);
      await settle();
      expect(h.recognition.frames, 0);

      await h.controller.finishOnboarding();
      onFrame(_frame);
      await settle();
      expect(h.recognition.frames, 1);
    });
  });
}
