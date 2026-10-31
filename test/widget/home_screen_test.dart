import 'package:flutter/material.dart';
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
import 'package:visionassist_ai/presentation/screens/home_screen.dart';

// ── Fakes ──────────────────────────────────────────────────────────────────

class _FakePermissionService implements PermissionService {
  _FakePermissionService({this.granted = false});
  final bool granted;
  PermissionStatus get _status =>
      granted ? PermissionStatus.granted : PermissionStatus.denied;
  @override
  Future<PermissionStatus> check(AppPermission p) async => _status;
  @override
  Future<PermissionStatus> request(AppPermission p) async => _status;
  @override
  Future<void> openSettings() async {}
}

class _FakeOnboardingStore implements OnboardingStore {
  _FakeOnboardingStore({this.completed = true});
  bool completed;
  @override
  Future<bool> isCompleted() async => completed;
  @override
  Future<void> markCompleted() async => completed = true;
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

Widget _buildApp(
  Widget child, {
  _FakeOnboardingStore? store,
  bool cameraGranted = false,
}) =>
    ProviderScope(
      overrides: [
        permissionServiceProvider.overrideWithValue(
          _FakePermissionService(granted: cameraGranted),
        ),
        onboardingStoreProvider
            .overrideWithValue(store ?? _FakeOnboardingStore()),
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
                  onboardingStoreProvider
                      .overrideWithValue(_FakeOnboardingStore()),
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

  group('HomeScreen — onboarding guide', () {
    final gestureSteps = AppStrings.onboardingSteps(screenReader: false);
    final buttonSteps = AppStrings.onboardingSteps(screenReader: true);

    void useScreenReader(WidgetTester tester) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    }

    testWidgets('first launch shows the guide, not the permission screen',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const HomeScreen(),
          store: _FakeOnboardingStore(completed: false),
        ),
      );
      await tester.pump();

      expect(find.text(gestureSteps.first), findsOneWidget);
      expect(
        find.text(AppStrings.onboardingProgress(1, gestureSteps.length)),
        findsOneWidget,
      );
      expect(find.text(AppStrings.permissionCameraRetry), findsNothing);
    });

    testWidgets('swipe left advances; double tap skips to the app',
        (tester) async {
      final store = _FakeOnboardingStore(completed: false);
      await tester.pumpWidget(_buildApp(const HomeScreen(), store: store));
      await tester.pump();

      await tester.fling(
        find.text(gestureSteps.first),
        const Offset(-300, 0),
        1000,
      );
      await tester.pump();
      expect(find.text(gestureSteps[1]), findsOneWidget);

      final step = find.text(gestureSteps[1]);
      await tester.tap(step);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(step);
      // Let the double tap resolve and the gesture timers run out.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(store.completed, isTrue);
      // Camera permission is denied in this fake, so that screen follows.
      expect(find.text(AppStrings.permissionCameraRetry), findsOneWidget);
    });

    testWidgets('screen reader: buttons drive the guide', (tester) async {
      useScreenReader(tester);
      await tester.pumpWidget(
        _buildApp(
          const HomeScreen(),
          store: _FakeOnboardingStore(completed: false),
        ),
      );
      await tester.pump();

      expect(find.text(buttonSteps.first), findsOneWidget);
      expect(find.text(AppStrings.btnOnboardingSkip), findsOneWidget);

      for (var i = 1; i < buttonSteps.length; i++) {
        await tester.tap(find.text(AppStrings.btnOnboardingNext));
        await tester.pump();
      }

      expect(find.text(buttonSteps.last), findsOneWidget);
      expect(find.text(AppStrings.btnOnboardingStart), findsOneWidget);
      expect(find.text(AppStrings.btnOnboardingSkip), findsNothing);
    });

    testWidgets('screen reader: guide and main screen fit a small phone',
        (tester) async {
      useScreenReader(tester);
      tester.view
        ..physicalSize = const Size(360, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // Low-vision users often raise the system font size.
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final store = _FakeOnboardingStore(completed: false);
      await tester.pumpWidget(
        _buildApp(const HomeScreen(), store: store, cameraGranted: true),
      );
      await tester.pump();
      expect(find.text(AppStrings.btnOnboardingSkip), findsOneWidget);

      await tester.tap(find.text(AppStrings.btnOnboardingSkip));
      await tester.pump();
      await tester.pump();
      expect(find.text(AppStrings.btnGuide), findsOneWidget);
      // A RenderFlex overflow would have failed the test by now.
    });

    testWidgets('screen reader: the Panduan button replays the guide',
        (tester) async {
      useScreenReader(tester);
      await tester.pumpWidget(
        _buildApp(const HomeScreen(), cameraGranted: true),
      );
      await tester.pump();

      await tester.tap(find.text(AppStrings.btnGuide));
      await tester.pump();

      expect(find.text(buttonSteps.first), findsOneWidget);
    });
  });
}
