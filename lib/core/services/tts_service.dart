/// Abstract contract for the text-to-speech engine.
///
/// Supports sentence-level queuing, pause/resume semantics, and configurable
/// speech rate and pitch.
abstract class TtsService {
  /// Speaks [text], optionally interrupting any in-progress speech.
  ///
  /// If [interrupt] is `true`, any current speech is stopped first.
  /// If `false`, [text] is appended to the current sentence queue.
  Future<void> speak(String text, {bool interrupt = false});

  /// Pauses speech at the end of the current sentence.
  Future<void> pause();

  /// Resumes speech from where it was paused (current sentence).
  Future<void> resume();

  /// Stops speech and clears the queue.
  Future<void> stop();

  /// Sets the TTS speech rate (0.0 – 1.0).
  Future<void> setSpeechRate(double rate);

  /// Sets the TTS pitch (0.5 – 2.0, 1.0 is normal).
  Future<void> setPitch(double pitch);

  /// Whether the engine is currently speaking.
  bool get isSpeaking;

  /// Whether speech is paused.
  bool get isPaused;

  /// Releases TTS engine resources.
  Future<void> dispose();
}
