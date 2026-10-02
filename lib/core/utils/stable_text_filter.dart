import 'text_normalizer.dart';

/// Determines when live-OCR output is stable enough to speak aloud.
///
/// Text is considered stable when:
/// 1. It has been seen across [requiredFrames] consecutive frames with
///    token similarity ≥ [similarityThreshold] between each successive pair.
/// 2. It is not similar to the last text that was spoken
///    (similarity < [noveltyThreshold]).
class StableTextFilter {
  StableTextFilter({
    this.requiredFrames = 3,
    this.similarityThreshold = 0.8,
    this.noveltyThreshold = 0.8,
  });

  final int requiredFrames;
  final double similarityThreshold;
  final double noveltyThreshold;

  final List<String> _history = [];
  String _lastSpoken = '';

  /// Feeds [text] from one frame into the filter.
  ///
  /// Returns `true` if [text] is now stable **and** novel enough to speak.
  bool feed(String text) {
    if (text.trim().isEmpty) {
      _history.clear();
      return false;
    }

    if (_history.isEmpty) {
      _history.add(text);
      return false;
    }

    final prevSimilarity =
        TextNormalizer.similarity(_history.last, text);

    if (prevSimilarity < similarityThreshold) {
      // Sequence broken — restart.
      _history
        ..clear()
        ..add(text);
      return false;
    }

    _history.add(text);

    if (_history.length < requiredFrames) return false;

    // Keep buffer lean.
    if (_history.length > requiredFrames) {
      _history.removeAt(0);
    }

    // Check novelty against last spoken.
    final novelty = TextNormalizer.similarity(text, _lastSpoken);
    if (novelty >= noveltyThreshold) return false;

    return true;
  }

  /// Must be called after the text has been spoken to update the last-spoken
  /// state.
  void markSpoken(String text) {
    _lastSpoken = text;
  }

  /// Resets all internal state (e.g., when the mode is changed).
  void reset() {
    _history.clear();
    _lastSpoken = '';
  }
}
