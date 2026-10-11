import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../speech_to_text_service.dart';

/// `speech_to_text` plugin-backed [SpeechToTextService].
class SttSpeechToTextService implements SpeechToTextService {
  SttSpeechToTextService() : _stt = stt.SpeechToText();

  final stt.SpeechToText _stt;
  bool _initialized = false;

  @override
  bool get isListening => _stt.isListening;

  @override
  Future<bool> initialize() async {
    _initialized = await _stt.initialize();
    return _initialized;
  }

  @override
  Future<void> startListening({
    required void Function(SpeechResult result) onResult,
    String localeId = 'id-ID',
    Duration listenFor = const Duration(seconds: 10),
  }) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    await _stt.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: localeId,
        listenFor: listenFor,
      ),
      onResult: (result) => onResult(
        SpeechResult(
          text: result.recognizedWords,
          confidence: result.hasConfidenceRating ? result.confidence : -1.0,
          isFinal: result.finalResult,
        ),
      ),
    );
  }

  @override
  Future<void> stopListening() => _stt.stop();

  @override
  Future<void> dispose() async {
    await _stt.cancel();
  }
}
