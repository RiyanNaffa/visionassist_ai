import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'camera_service.dart';
import 'text_recognition_service.dart';
import 'tts_service.dart';
import 'haptic_service.dart';
import 'audio_cue_service.dart';
import 'speech_to_text_service.dart';
import 'permission_service.dart';
import 'impl/flutter_camera_service.dart';
import 'impl/mlkit_text_recognition_service.dart';
import 'impl/flutter_tts_service.dart';
import 'impl/flutter_haptic_service.dart';
import 'impl/audioplayers_audio_cue_service.dart';
import 'impl/stt_speech_to_text_service.dart';
import 'impl/ph_permission_service.dart';
import '../../features/currency_detector/data/tflite_currency_detector.dart';
import '../../features/currency_detector/domain/repositories/currency_detector.dart';

/// Riverpod providers for all core services.
///
/// Tests override these with fakes via [ProviderScope] overrides.

final cameraServiceProvider = Provider<CameraService>(
  (_) => FlutterCameraService(),
);

final textRecognitionServiceProvider = Provider<TextRecognitionService>(
  (_) => MlKitTextRecognitionService(),
);

final ttsServiceProvider = Provider<TtsService>((_) {
  final svc = FlutterTtsService();
  // ignore: discarded_futures — fire-and-forget init
  svc.initialize();
  return svc;
});

final hapticServiceProvider = Provider<HapticService>(
  (_) => FlutterHapticService(),
);

final audioCueServiceProvider = Provider<AudioCueService>(
  (_) => AudioplayersAudioCueService(),
);

final sttServiceProvider = Provider<SpeechToTextService>(
  (_) => SttSpeechToTextService(),
);

final permissionServiceProvider = Provider<PermissionService>(
  (_) => PhPermissionService(),
);

/// The YOLO banknote detector.
///
/// Initialisation is fire-and-forget; the detector exposes [isAvailable]
/// so callers can check readiness without blocking the UI.
final currencyDetectorProvider = Provider<CurrencyDetector>((ref) {
  final detector = TfliteCurrencyDetector();
  // ignore: discarded_futures — fire-and-forget init
  detector.initialize();
  ref.onDispose(detector.dispose);
  return detector;
});
