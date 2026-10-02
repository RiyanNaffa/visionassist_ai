/// Utility functions for normalising recognised text before comparison.
class TextNormalizer {
  TextNormalizer._();

  /// Normalises [text] for comparison:
  /// - Converts to lower case.
  /// - Collapses whitespace.
  /// - Removes punctuation except basic sentence terminators.
  /// - Trims leading/trailing whitespace.
  static String normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s.?!]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Returns the set of word tokens from [text].
  static Set<String> tokenize(String text) {
    final normalized = normalize(text);
    if (normalized.isEmpty) return {};
    return normalized.split(' ').toSet();
  }

  /// Jaccard token similarity between [a] and [b].  Range 0.0 – 1.0.
  static double similarity(String a, String b) {
    final tokensA = tokenize(a);
    final tokensB = tokenize(b);
    if (tokensA.isEmpty && tokensB.isEmpty) return 1.0;
    if (tokensA.isEmpty || tokensB.isEmpty) return 0.0;
    final intersection = tokensA.intersection(tokensB).length;
    final union = tokensA.union(tokensB).length;
    return intersection / union;
  }
}
