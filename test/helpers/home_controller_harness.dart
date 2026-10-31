import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

/// Fakes and a [ProviderContainer] harness for driving [HomeController]
/// without devices or plugins.

// ── Fakes ──────────────────────────────────────────────────────────────────

class RecordingTts implements TtsService {
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

class FakeOnboardingStore implements OnboardingStore {
  FakeOnboardingStore({required this.completed});
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

class FakePermissions implements PermissionService {
  FakePermissions({required this.granted});
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

class FakeCamera implements CameraService {
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

class CountingRecognition implements TextRecognitionService {
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

class FakeHaptic implements HapticService {
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

class FakeAudio implements AudioCueService {
  @override
  Future<void> play(AudioCueEvent e) async {}
  @override
  Future<void> dispose() async {}
}

class FakeStt implements SpeechToTextService {
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

/// Currency detector whose result the test hands out with [respond].
class FakeCurrencyDetector implements CurrencyDetector {
  FakeCurrencyDetector({this.isAvailable = false});

  @override
  final bool isAvailable;

  int calls = 0;
  Completer<CurrencyDetectionResult>? _pending;

  /// Completes the detection that is in progress.
  void respond(List<DetectedBanknote> detections) {
    _pending?.complete(CurrencyDetectionResult(detections: detections));
    _pending = null;
  }

  @override
  Future<CurrencyDetectionResult> detect(Float32List input) {
    calls++;
    if (!isAvailable) {
      return Future.value(const CurrencyDetectionResult(detections: []));
    }
    _pending = Completer();
    return _pending!.future;
  }
}

// ── Harness ────────────────────────────────────────────────────────────────

class HomeControllerHarness {
  HomeControllerHarness({
    required bool completed,
    required bool granted,
    FakeCurrencyDetector? currencyDetector,
  })  : store = FakeOnboardingStore(completed: completed),
        permissions = FakePermissions(granted: granted),
        currency = currencyDetector ?? FakeCurrencyDetector() {
    container = ProviderContainer(
      overrides: [
        ttsServiceProvider.overrideWithValue(tts),
        onboardingStoreProvider.overrideWithValue(store),
        permissionServiceProvider.overrideWithValue(permissions),
        cameraServiceProvider.overrideWithValue(camera),
        textRecognitionServiceProvider.overrideWithValue(recognition),
        hapticServiceProvider.overrideWithValue(FakeHaptic()),
        audioCueServiceProvider.overrideWithValue(FakeAudio()),
        sttServiceProvider.overrideWithValue(FakeStt()),
        currencyDetectorProvider.overrideWithValue(currency),
      ],
    );
    addTearDown(container.dispose);
  }

  final tts = RecordingTts();
  final FakeOnboardingStore store;
  final FakePermissions permissions;
  final FakeCurrencyDetector currency;
  final camera = FakeCamera();
  final recognition = CountingRecognition();
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

/// Lets pending microtasks and zero-delay timers run.
Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Waits (in real time) until [condition] holds, e.g. for work on another
/// isolate.
Future<void> waitFor(bool Function() condition) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue, reason: 'condition not met within 2 s');
}

/// A small NV21 camera frame.
CameraFrame nv21Frame({int width = 4, int height = 4}) => CameraFrame(
      bytes: Uint8List(width * height * 3 ~/ 2),
      width: width,
      height: height,
      bytesPerRow: width,
      format: 'nv21',
      rotationDegrees: 0,
    );
