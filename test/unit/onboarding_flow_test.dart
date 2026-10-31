import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visionassist_ai/core/constants/app_strings.dart';
import 'package:visionassist_ai/core/services/audio_cue_service.dart';
import 'package:visionassist_ai/core/services/camera_service.dart';
import 'package:visionassist_ai/core/services/haptic_service.dart';
import 'package:visionassist_ai/core/services/onboarding_store.dart';
import 'package:visionassist_ai/core/services/permission_service.dart';
import 'package:visionassist_ai/core/services/service_providers.dart';
import 'package:visionassist_ai/core/services/speech_to_text_service.dart';
import 'package:visionassist_ai/core/services/text_recognition_service.dart';
import 'package:visionassist_ai/core/services/tts_service.dart';
import 'package:visionassist_ai/features/currency_detector/domain/entities/currency_detection.dart';
import 'package:visionassist_ai/features/currency_detector/domain/repositories/currency_detector.dart';
import 'package:visionassist_ai/presentation/controllers/home_controller.dart';

// ── Fakes ──────────────────────────────────────────────────────────────────

class _RecordingTts implements TtsService {
  final List<String> spoken = [];

  /// speak() returns only once this completes, like a TTS engine that is
  /// still binding on a cold start.
  Future<void> engineReady = Future.value();

  @override
  bool get isSpeaking => false;
  @override
  bool get isPaused => false;
  @override
  Future<void> speak(String t, {bool interrupt = false}) async {
    spoken.add(t);
    await engineReady;
  }

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

class _FakeStore implements OnboardingStore {
  _FakeStore({required this.completed});
  bool completed;
  int marks = 0;
  @override
  Future<bool> isCompleted() async => completed;
  @override
  Future<void> markCompleted() async {
    marks++;
    completed = true;
  }
}

class _FakePermissions implements PermissionService {
  _FakePermissions({required this.granted});
  final bool granted;
  int checks = 0;
  int requests = 0;
  PermissionStatus get _status =>
      granted ? PermissionStatus.granted : PermissionStatus.denied;
  @override
  Future<PermissionStatus> check(AppPermission p) async {
    checks++;
    return _status;
  }

  @override
  Future<PermissionStatus> request(AppPermission p) async {
    requests++;
    return _status;
  }

  @override
  Future<void> openSettings() async {}
}

class _FakeCamera implements CameraService {
  bool initialized = false;
  void Function(CameraFrame f)? onFrame;
  @override
  bool get isStreaming => onFrame != null;
  @override
  Future<void> initialize() async => initialized = true;
  @override
  void startImageStream(void Function(CameraFrame f) cb) => onFrame = cb;
  @override
  Future<void> stopImageStream() async => onFrame = null;
  @override
  Future<String> takePicture() async => '/tmp/test.jpg';
  @override
  Future<void> dispose() async {}
}

class _CountingRecognition implements TextRecognitionService {
  int frames = 0;
  @override
  Future<TextRecognitionResult> recognizeFromFrame(CameraFrame f) async {
    frames++;
    return const TextRecognitionResult(text: '', blocks: []);
  }

  @override
  Future<TextRecognitionResult> recognizeFromFile(String p) async =>
      const TextRecognitionResult(text: '', blocks: []);
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

class _FakeCurrencyDetector implements CurrencyDetector {
  @override
  bool get isAvailable => false;
  @override
  Future<CurrencyDetectionResult> detect(Float32List input) async =>
      const CurrencyDetectionResult(detections: []);
}

// ── Harness ────────────────────────────────────────────────────────────────

class _Harness {
  _Harness({required bool completed, required bool granted})
      : store = _FakeStore(completed: completed),
        permissions = _FakePermissions(granted: granted) {
    container = ProviderContainer(
      overrides: [
        ttsServiceProvider.overrideWithValue(tts),
        onboardingStoreProvider.overrideWithValue(store),
        permissionServiceProvider.overrideWithValue(permissions),
        cameraServiceProvider.overrideWithValue(camera),
        textRecognitionServiceProvider.overrideWithValue(recognition),
        hapticServiceProvider.overrideWithValue(_FakeHaptic()),
        audioCueServiceProvider.overrideWithValue(_FakeAudio()),
        sttServiceProvider.overrideWithValue(_FakeStt()),
        currencyDetectorProvider.overrideWithValue(_FakeCurrencyDetector()),
      ],
    );
    addTearDown(container.dispose);
  }

  final tts = _RecordingTts();
  final _FakeStore store;
  final _FakePermissions permissions;
  final camera = _FakeCamera();
  final recognition = _CountingRecognition();
  late final ProviderContainer container;

  HomeController get controller =>
      container.read(homeControllerProvider.notifier);
  HomeState get state => container.read(homeControllerProvider);

  /// Builds the controller and lets its async start-up run.
  Future<void> start() async {
    container.read(homeControllerProvider);
    await settle();
  }
}

Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

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
      final h = _Harness(completed: false, granted: false);
      await h.start();

      expect(h.state.isOnboarding, isTrue);
      expect(h.state.onboardingStep, 0);
      expect(h.tts.spoken, [_steps.first]);
      expect(h.permissions.checks, 0);
      expect(h.permissions.requests, 0);
    });

    test('next, previous and repeat speak the matching step', () async {
      final h = _Harness(completed: false, granted: false);
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
      final h = _Harness(completed: false, granted: false);
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
      final h = _Harness(completed: false, granted: true);
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
      final h = _Harness(completed: true, granted: true);
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
      final h = _Harness(completed: true, granted: true);
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
      final h = _Harness(completed: true, granted: false);
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
      final h = _Harness(completed: true, granted: true);
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
      final h = _Harness(completed: true, granted: true);
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
