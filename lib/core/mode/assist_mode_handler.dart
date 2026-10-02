/// Output produced by an [AssistModeHandler] after processing.
class ModeOutput {
  const ModeOutput({
    required this.spokenText,
    this.displayText,
    this.isError = false,
    this.isEmpty = false,
  });

  /// Text to be spoken aloud.
  final String spokenText;

  /// Optional text for on-screen display (falls back to [spokenText]).
  final String? displayText;

  final bool isError;
  final bool isEmpty;

  String get screenText => displayText ?? spokenText;

  static const ModeOutput empty = ModeOutput(
    spokenText: '',
    isEmpty: true,
  );
}

/// Contract that every assist mode must implement.
abstract class AssistModeHandler {
  /// Human-readable mode name (Indonesian).
  String get name;

  /// Process [input] and return a [ModeOutput].
  ///
  /// [input] is either a [CameraFrame] (live) or a file path (captured).
  Future<ModeOutput> process(Object input);

  /// Called when the mode is activated (e.g., plays an audio cue).
  Future<void> onActivate();

  /// Called when the mode is deactivated.
  Future<void> onDeactivate();
}
