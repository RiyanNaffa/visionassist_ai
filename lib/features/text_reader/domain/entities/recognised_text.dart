// ── Text Reader domain entities ──────────────────────────────────────────────

/// Represents a snapshot of text recognised from the live camera stream.
class RecognisedText {
  const RecognisedText({
    required this.text,
    required this.blocks,
  });

  final String text;
  final List<String> blocks;

  bool get isEmpty => text.trim().isEmpty;
}
