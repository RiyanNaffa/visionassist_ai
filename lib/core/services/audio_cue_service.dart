/// Names of audio cue events.
enum AudioCueEvent { beep, success, modeSwitch, error }

/// Abstract contract for low-latency audio cue playback.
abstract class AudioCueService {
  /// Plays the audio cue for [event].
  ///
  /// The cue is played in mixing mode so it does not interrupt TTS.
  Future<void> play(AudioCueEvent event);

  /// Releases audio resources.
  Future<void> dispose();
}
