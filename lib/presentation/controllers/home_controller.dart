import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/services/audio_cue_service.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/service_providers.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/text_recognition_service.dart';
import '../../core/services/speech_to_text_service.dart';
import '../../core/utils/rgb_converter.dart';
import '../../core/utils/stable_text_filter.dart';
import '../../features/currency_detector/domain/usecases/detect_currency.dart';
import '../../features/text_reader/data/text_reader_repository_impl.dart';
import '../../features/text_reader/domain/usecases/recognize_text_from_file.dart';
import '../../features/ingredient_analyzer/domain/usecases/analyze_ingredients.dart';
import '../../features/visual_qa/domain/usecases/answer_visual_question.dart';
import '../providers/repository_providers.dart';

// ── State ──────────────────────────────────────────────────────────────────

/// The top-level application state.
class HomeState {
  const HomeState({
    this.modeIndex = 0,
    this.statusText = '',
    this.isProcessing = false,
    this.cameraPermissionGranted = false,
    this.cameraPermissionPermanentlyDenied = false,
    this.isListeningForQuery = false,
    this.cameraReady = false,
  });

  final int modeIndex;
  final String statusText;
  final bool isProcessing;
  final bool cameraPermissionGranted;
  final bool cameraPermissionPermanentlyDenied;
  final bool isListeningForQuery;

  /// True once the [CameraController] is initialised and ready to preview.
  final bool cameraReady;

  String get modeName => AppStrings.modeNames[modeIndex];

  HomeState copyWith({
    int? modeIndex,
    String? statusText,
    bool? isProcessing,
    bool? cameraPermissionGranted,
    bool? cameraPermissionPermanentlyDenied,
    bool? isListeningForQuery,
    bool? cameraReady,
  }) =>
      HomeState(
        modeIndex: modeIndex ?? this.modeIndex,
        statusText: statusText ?? this.statusText,
        isProcessing: isProcessing ?? this.isProcessing,
        cameraPermissionGranted:
            cameraPermissionGranted ?? this.cameraPermissionGranted,
        cameraPermissionPermanentlyDenied: cameraPermissionPermanentlyDenied ??
            this.cameraPermissionPermanentlyDenied,
        isListeningForQuery: isListeningForQuery ?? this.isListeningForQuery,
        cameraReady: cameraReady ?? this.cameraReady,
      );
}

// ── Controller ─────────────────────────────────────────────────────────────

/// Manages the top-level application state.
///
/// All mode switching, capture, live-stream processing, and Q&A routing
/// is coordinated here.
class HomeController extends Notifier<HomeState> {
  // Services (resolved from providers at first use via ref).
  late final TtsService _tts;
  late final HapticService _haptic;
  late final AudioCueService _audio;
  late final CameraService _camera;
  late final TextRecognitionService _recognition;
  late final SpeechToTextService _stt;
  late final PermissionService _permissions;

  // Utilities
  final StableTextFilter _stableFilter = StableTextFilter();
  bool _liveProcessingBusy = false;

  // Use cases (initialised lazily in [build])
  late final AnalyzeIngredients _analyzeIngredients;
  late final AnswerVisualQuestion _answerQuestion;
  late final RecognizeTextFromFile _recognizeFromFile;
  late final DetectCurrency _detectCurrency;

  // ── Currency detection state ──────────────────────────────────────────────

  /// The last set of denomination labels that was announced, used to avoid
  /// re-announcing the same denominations on every frame.
  Set<String> _lastSpokenLabels = {};

  /// Timestamp of the last "model missing" TTS so we don't spam it every frame.
  DateTime? _lastMissingAnnouncedAt;

  @override
  HomeState build() {
    _tts = ref.read(ttsServiceProvider);
    _haptic = ref.read(hapticServiceProvider);
    _audio = ref.read(audioCueServiceProvider);
    _camera = ref.read(cameraServiceProvider);
    _recognition = ref.read(textRecognitionServiceProvider);
    _stt = ref.read(sttServiceProvider);
    _permissions = ref.read(permissionServiceProvider);

    _analyzeIngredients = AnalyzeIngredients(
      ref.read(ingredientRepositoryProvider),
    );
    _answerQuestion = AnswerVisualQuestion(ref.read(qaRepositoryProvider));
    _recognizeFromFile = RecognizeTextFromFile(
      TextReaderRepositoryImpl(_recognition),
    );
    _detectCurrency = DetectCurrency(ref.read(currencyDetectorProvider));

    // Check camera permission on init.
    _initCameraPermission();

    return const HomeState();
  }

  // ── Permission ────────────────────────────────────────────────────────────

  Future<void> _initCameraPermission() async {
    final status = await _permissions.check(AppPermission.camera);
    if (status == PermissionStatus.granted) {
      state = state.copyWith(cameraPermissionGranted: true);
      await _initCamera();
    } else {
      await requestCameraPermission();
    }
  }

  /// Requests camera permission (called by the retry button).
  Future<void> requestCameraPermission() async {
    final status = await _permissions.request(AppPermission.camera);
    switch (status) {
      case PermissionStatus.granted:
        state = state.copyWith(
          cameraPermissionGranted: true,
          cameraPermissionPermanentlyDenied: false,
        );
        await _initCamera();
      case PermissionStatus.permanentlyDenied:
        state = state.copyWith(cameraPermissionPermanentlyDenied: true);
        await _tts.speak(
          AppStrings.ttsCameraPermissionDenied,
          interrupt: true,
        );
      default:
        await _tts.speak(
          AppStrings.ttsCameraPermissionDenied,
          interrupt: true,
        );
    }
  }

  Future<void> openSettings() => _permissions.openSettings();

  Future<void> _initCamera() async {
    try {
      await _camera.initialize();
      // Signal the UI to rebuild so CameraPreview can attach to the controller.
      state = state.copyWith(cameraReady: true);
      _startLiveStream();
    } catch (e) {
      debugPrint('[HomeController] Camera init failed: $e');
    }
  }

  // ── Live stream ───────────────────────────────────────────────────────────

  void _startLiveStream() {
    _camera.startImageStream((frame) async {
      // Only Text Reader (0) and Currency Detector (1) use live stream.
      if (state.modeIndex > 1) return;
      if (_liveProcessingBusy) return;
      _liveProcessingBusy = true;
      try {
        await _processLiveFrame(frame);
      } finally {
        _liveProcessingBusy = false;
      }
    });
  }

  Future<void> _processLiveFrame(CameraFrame frame) async {
    if (state.modeIndex == 0) {
      // ── Text Reader ───────────────────────────────────────────────────────
      final result = await _recognition.recognizeFromFrame(frame);
      if (result.isEmpty) return;
      final shouldSpeak = _stableFilter.feed(result.text);
      if (shouldSpeak) {
        _stableFilter.markSpoken(result.text);
        state = state.copyWith(statusText: result.text);
        await _audio.play(AudioCueEvent.beep);
        await _tts.speak(result.text, interrupt: false);
      }
    } else if (state.modeIndex == 1) {
      // ── Currency Detector ─────────────────────────────────────────────────
      await _processCurrencyFrame(frame);
    }
  }

  /// Runs YOLO detection on [frame] and announces denominations when the
  /// detected set changes compared to the last spoken frame.
  Future<void> _processCurrencyFrame(CameraFrame frame) async {
    // Model still initialising (race condition guard) — wait silently.
    // initialize() is async; isAvailable becomes true once it completes.
    if (!ref.read(currencyDetectorProvider).isAvailable) {
      final now = DateTime.now();
      final lastAnnounced = _lastMissingAnnouncedAt;
      // Show banner immediately; repeat TTS at most once every 10 s.
      if (state.statusText != AppStrings.bannerCurrencyModelMissing) {
        state = state.copyWith(
          statusText: AppStrings.bannerCurrencyModelMissing,
        );
      }
      if (lastAnnounced == null ||
          now.difference(lastAnnounced).inSeconds >= 10) {
        _lastMissingAnnouncedAt = now;
        await _tts.speak(AppStrings.ttsCurrencyModelMissing, interrupt: true);
      }
      return;
    }

    // Model became available — clear the missing banner if it was showing.
    if (state.statusText == AppStrings.bannerCurrencyModelMissing) {
      _lastMissingAnnouncedAt = null;
    }

    // Model loaded — show scanning hint while no banknote is visible.
    if (state.statusText.isEmpty ||
        state.statusText == AppStrings.bannerCurrencyModelMissing) {
      state = state.copyWith(statusText: AppStrings.bannerCurrencyScanning);
    }

    // Convert raw camera frame to 256 × 256 normalised RGB.
    final Float32List rgbInput;
    if (frame.format == 'nv21' || frame.format == 'yuv420') {
      rgbInput = RgbConverter.fromNv21(frame.bytes, frame.width, frame.height);
    } else {
      rgbInput = RgbConverter.fromBgra(frame.bytes, frame.width, frame.height);
    }

    final result = await _detectCurrency(rgbInput);

    if (!result.hasDetections) {
      // Reset spoken-labels so next detection is always announced,
      // and restore the scanning prompt.
      if (_lastSpokenLabels.isNotEmpty) {
        _lastSpokenLabels = {};
        state = state.copyWith(statusText: AppStrings.bannerCurrencyScanning);
      }
      return;
    }

    final currentLabels = result.detectedLabels;

    // Only announce when the set of denominations actually changes.
    if (_setsEqual(currentLabels, _lastSpokenLabels)) return;
    _lastSpokenLabels = Set.unmodifiable(currentLabels);

    // Build spoken text: unique denominations, ascending order, joined by comma.
    final sortedLabels =
        currentLabels.toList()
          ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));

    final speechParts =
        sortedLabels
            .map(AppStrings.currencySpeech)
            .whereType<String>()
            .toList();

    if (speechParts.isEmpty) return;

    final announcement = speechParts.join(', ');
    state = state.copyWith(statusText: announcement);
    await _audio.play(AudioCueEvent.beep);
    await _tts.speak(announcement, interrupt: true);
  }

  // ── Mode switching ────────────────────────────────────────────────────────

  Future<void> nextMode() async {
    final next = (state.modeIndex + 1) % AppStrings.modeNames.length;
    await _switchMode(next);
  }

  Future<void> previousMode() async {
    final prev =
        (state.modeIndex - 1 + AppStrings.modeNames.length) %
            AppStrings.modeNames.length;
    await _switchMode(prev);
  }

  Future<void> _switchMode(int index) async {
    _stableFilter.reset();
    _lastSpokenLabels = {};
    state = state.copyWith(modeIndex: index, statusText: '');
    await _haptic.lightImpact();
    await _audio.play(AudioCueEvent.modeSwitch);
    final name = AppStrings.modeNames[index];
    await _tts.speak(
      '${AppStrings.ttsModeSwitch}$name',
      interrupt: true,
    );
  }

  // ── Single tap: pause / resume ────────────────────────────────────────────

  Future<void> onSingleTap() async {
    await _haptic.selectionClick();
    if (_tts.isSpeaking) {
      await _tts.pause();
    } else if (_tts.isPaused) {
      await _tts.resume();
    }
  }

  // ── Double tap: capture ───────────────────────────────────────────────────

  Future<void> onDoubleTap() async {
    if (state.isProcessing) return;
    await _haptic.mediumImpact();
    await _audio.play(AudioCueEvent.beep);
    await _tts.speak(AppStrings.ttsCapturing, interrupt: true);
    state = state.copyWith(isProcessing: true);

    try {
      final path = await _camera.takePicture();
      await _processCapture(path);
    } catch (e) {
      debugPrint('[HomeController] Capture error: $e');
      await _audio.play(AudioCueEvent.error);
      await _haptic.error();
    } finally {
      state = state.copyWith(isProcessing: false);
      // Restart stream for live modes.
      if (state.modeIndex <= 1 && !_camera.isStreaming) {
        _startLiveStream();
      }
    }
  }

  Future<void> _processCapture(String path) async {
    switch (state.modeIndex) {
      case 0: // Text Reader
        final result = await _recognizeFromFile(path);
        if (result.isEmpty) {
          await _tts.speak(AppStrings.ttsNoTextFound, interrupt: true);
        } else {
          state = state.copyWith(statusText: result.text);
          await _tts.speak(result.text, interrupt: true);
          await _audio.play(AudioCueEvent.success);
        }

      case 2: // Ingredient Analyzer
        final ocr = await _recognizeFromFile(path);
        final analysis = await _analyzeIngredients(ocr.text);
        state = state.copyWith(statusText: analysis.summary);
        await _audio.play(AudioCueEvent.success);
        await _tts.speak(analysis.summary, interrupt: true);

      default:
        break;
    }
  }

  // ── Long press: voice Q&A ─────────────────────────────────────────────────

  Future<void> onLongPress() async {
    if (state.modeIndex != 3) return; // Only Visual Q&A
    if (state.isListeningForQuery) return;

    await _haptic.mediumImpact();
    state = state.copyWith(isListeningForQuery: true);
    await _tts.speak(AppStrings.ttsListening, interrupt: true);

    final micStatus = await _permissions.check(AppPermission.microphone);
    if (micStatus != PermissionStatus.granted) {
      await _permissions.request(AppPermission.microphone);
    }

    String query = '';
    await _stt.startListening(
      localeId: 'id-ID',
      onResult: (result) {
        if (result.isFinal) query = result.text;
      },
    );

    // Wait for STT to finish.
    await Future<void>.delayed(const Duration(seconds: 10));
    await _stt.stopListening();
    state = state.copyWith(isListeningForQuery: false);

    if (query.trim().isEmpty) return;

    state = state.copyWith(isProcessing: true);
    try {
      final path = await _camera.takePicture();
      final ocr = await _recognizeFromFile(path);
      final answer = await _answerQuestion(
        question: query,
        ocrText: ocr.text,
      );
      state = state.copyWith(statusText: answer.answer);
      await _audio.play(
        answer.isGrounded ? AudioCueEvent.success : AudioCueEvent.error,
      );
      await _tts.speak(answer.answer, interrupt: true);
    } finally {
      state = state.copyWith(isProcessing: false);
      if (!_camera.isStreaming) _startLiveStream();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _setsEqual(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}

// ── Provider ───────────────────────────────────────────────────────────────

/// The main [HomeController] provider.
final homeControllerProvider =
    NotifierProvider<HomeController, HomeState>(HomeController.new);
