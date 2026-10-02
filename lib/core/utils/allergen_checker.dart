/// Result of allergen detection.
class AllergenResult {
  const AllergenResult({
    required this.detected,
    required this.negated,
  });

  /// Allergen names detected (not negated).
  final List<String> detected;

  /// Allergen names mentioned but explicitly negated (e.g. "gluten free").
  final List<String> negated;

  bool get hasAllergens => detected.isNotEmpty;
}

/// Detects allergen mentions in Indonesian and English product text.
///
/// Handles negations such as "bebas gluten" / "gluten free" /
/// "tidak mengandung kacang".
class AllergenChecker {
  AllergenChecker._();

  /// Map from canonical allergen name → list of keyword patterns.
  static const Map<String, List<String>> _keywords = {
    'Kacang': ['kacang', 'peanut', 'nuts', 'almond', 'cashew'],
    'Gluten': ['gandum', 'terigu', 'gluten', 'wheat'],
    'Susu': ['susu', 'milk', 'laktosa', 'lactose', 'dairy', 'whey', 'casein'],
    'Telur': ['telur', 'egg'],
    'Kerang': ['udang', 'kepiting', 'shellfish', 'shrimp', 'crab', 'lobster'],
    'Ikan': ['ikan', 'fish', 'anchovy', 'salmon', 'tuna'],
    'Kedelai': ['kedelai', 'soy', 'soya', 'tofu'],
    'Wijen': ['wijen', 'sesame', 'tahini'],
  };

  /// Negation patterns in Indonesian and English.
  static final List<RegExp> _negationPrefixes = [
    RegExp(r'\btidak\s+mengandung\b', caseSensitive: false),
    RegExp(r'\bbebas\b', caseSensitive: false),
    RegExp(r'\bfree\b', caseSensitive: false),
    RegExp(r'\bwithout\b', caseSensitive: false),
    RegExp(r'\btanpa\b', caseSensitive: false),
    RegExp(r'\bno\b', caseSensitive: false),
  ];

  /// Returns [AllergenResult] for [text].
  static AllergenResult check(String text) {
    final lower = text.toLowerCase();
    final detected = <String>[];
    final negated = <String>[];

    for (final entry in _keywords.entries) {
      final name = entry.key;
      final keywords = entry.value;

      for (final kw in keywords) {
        // Find keyword position.
        final kwIndex = lower.indexOf(kw);
        if (kwIndex == -1) continue;

        // Look back up to 30 chars for a negation prefix.
        final lookback = lower.substring(
          (kwIndex - 30).clamp(0, lower.length),
          kwIndex,
        );
        final isNegated =
            _negationPrefixes.any((rx) => rx.hasMatch(lookback));

        if (isNegated) {
          if (!negated.contains(name)) negated.add(name);
        } else {
          if (!detected.contains(name) && !negated.contains(name)) {
            detected.add(name);
          }
        }
        break; // matched one keyword for this allergen — stop checking others
      }
    }

    return AllergenResult(detected: detected, negated: negated);
  }
}
