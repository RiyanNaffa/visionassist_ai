/// Result of a speech-to-text listening session.
class SpeechResult {
  const SpeechResult({
    required this.text,
    required this.confidence,
    required this.isFinal,
  });

  final String text;

  /// Confidence score 0.0 – 1.0 (−1 if not available).
  final double confidence;
  final bool isFinal;

  bool get isEmpty => text.trim().isEmpty;
}

/// Abstract contract for speech-to-text.
abstract class SpeechToTextService {
  /// Initialises the STT engine.  Returns `true` on success.
  Future<bool> initialize();

  /// Starts listening.  Results are delivered via [onResult].
  ///
  /// [localeId] defaults to `'id-ID'`.
  Future<void> startListening({
    required void Function(SpeechResult result) onResult,
    String localeId = 'id-ID',
    Duration listenFor = const Duration(seconds: 10),
  });

  /// Stops listening.
  Future<void> stopListening();

  /// Whether the engine is currently listening.
  bool get isListening;

  /// Releases STT resources.
  Future<void> dispose();
}
