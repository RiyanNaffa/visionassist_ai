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
  /// Synced with Python ingredient_guard._ALLERGEN_KEYWORDS.
  static const Map<String, List<String>> _keywords = {
    'Kacang tanah': [
      'kacang tanah', 'peanut', 'groundnut', 'arachis',
      'mentega kacang', 'peanut butter',
    ],
    'Kacang pohon': [
      'almond', 'kacang mete', 'kacang mede', 'mete', 'cashew',
      'hazelnut', 'filbert', 'kenari', 'walnut', 'pecan',
      'brazil nut', 'pistachio', 'pistasio', 'macadamia',
      'queensland nut', 'chestnut', 'pine nut', 'tree nut', 'kacang pohon',
    ],
    'Gluten': [
      'gluten', 'gandum', 'terigu', 'wheat', 'rye', 'gandum hitam',
      'barley', 'jelai', 'oat', 'oats', 'havermut', 'spelt', 'malt',
    ],
    'Susu': [
      'susu', 'milk', 'laktosa', 'lactose', 'dairy', 'whey', 'casein',
      'kasein', 'keju', 'cheese', 'mentega', 'butter', 'krim', 'cream',
      'yogurt', 'yoghurt',
    ],
    'Telur': [
      'telur', 'egg', 'albumin', 'ovalbumin', 'lisozim',
      'mayones', 'mayonnaise',
    ],
    'Krustasea': [
      'udang', 'kepiting', 'rajungan', 'lobster', 'shrimp', 'crab',
      'prawn', 'crustacean', 'krustasea', 'ebi', 'terasi', 'petis udang',
    ],
    'Moluska': [
      'kerang', 'tiram', 'cumi', 'sotong', 'gurita', 'remis', 'bekicot',
      'siput', 'clam', 'oyster', 'squid', 'octopus', 'mussel',
      'mollusc', 'mollusk', 'moluska',
    ],
    'Ikan': [
      'ikan', 'fish', 'anchovy', 'teri', 'salmon', 'tuna', 'tongkol',
      'surimi', 'kecap ikan', 'fish sauce',
    ],
    'Kedelai': [
      'kedelai', 'soy', 'soya', 'soybean', 'tofu', 'tahu', 'tempe',
      'tempeh', 'kecap', 'miso', 'edamame', 'lesitin kedelai', 'soy lecithin',
    ],
    'Wijen': [
      'wijen', 'sesame', 'tahini', 'minyak wijen',
      'sesame oil', 'sesame extract',
    ],
    'Sulfit': [
      'sulfit', 'sulfite', 'sulphite', 'sulfur dioksida', 'sulfur dioxide',
      'so2', 'metabisulfit', 'metabisulfite', 'bisulfit',
      'ins 220', 'ins 221', 'ins 222', 'ins 223', 'ins 224',
      'ins 225', 'ins 226', 'ins 227', 'ins 228',
    ],
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
