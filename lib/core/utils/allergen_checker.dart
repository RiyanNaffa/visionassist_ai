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
      'kacang tanah',
      'peanut',
      'groundnut',
      'arachis',
      'mentega kacang',
      'peanut butter',
    ],
    'Kacang pohon': [
      'almond',
      'kacang mete',
      'kacang mede',
      'mete',
      'cashew',
      'hazelnut',
      'filbert',
      'kenari',
      'walnut',
      'pecan',
      'brazil nut',
      'pistachio',
      'pistasio',
      'macadamia',
      'queensland nut',
      'chestnut',
      'pine nut',
      'tree nut',
      'kacang pohon',
    ],
    'Gluten': [
      'gluten',
      'gandum',
      'terigu',
      'wheat',
      'rye',
      'gandum hitam',
      'barley',
      'jelai',
      'oat',
      'oats',
      'havermut',
      'spelt',
      'malt',
    ],
    'Susu': [
      'susu',
      'milk',
      'laktosa',
      'lactose',
      'dairy',
      'whey',
      'casein',
      'kasein',
      'keju',
      'cheese',
      'mentega',
      'butter',
      'krim',
      'cream',
      'yogurt',
      'yoghurt',
    ],
    'Telur': [
      'telur',
      'egg',
      'albumin',
      'ovalbumin',
      'lisozim',
      'mayones',
      'mayonnaise',
    ],
    'Krustasea': [
      'udang',
      'kepiting',
      'rajungan',
      'lobster',
      'shrimp',
      'crab',
      'prawn',
      'crustacean',
      'krustasea',
      'ebi',
      'terasi',
      'petis udang',
    ],
    'Moluska': [
      'kerang',
      'tiram',
      'cumi',
      'sotong',
      'gurita',
      'remis',
      'bekicot',
      'siput',
      'clam',
      'oyster',
      'squid',
      'octopus',
      'mussel',
      'mollusc',
      'mollusk',
      'moluska',
    ],
    'Ikan': [
      'ikan',
      'fish',
      'anchovy',
      'teri',
      'salmon',
      'tuna',
      'tongkol',
      'surimi',
      'kecap ikan',
      'fish sauce',
    ],
    'Kedelai': [
      'kedelai',
      'soy',
      'soya',
      'soybean',
      'tofu',
      'tahu',
      'tempe',
      'tempeh',
      'kecap',
      'miso',
      'edamame',
      'lesitin kedelai',
      'soy lecithin',
    ],
    'Wijen': [
      'wijen',
      'sesame',
      'tahini',
      'minyak wijen',
      'sesame oil',
      'sesame extract',
    ],
    'Sulfit': [
      'sulfit',
      'sulfite',
      'sulphite',
      'sulfur dioksida',
      'sulfur dioxide',
      'so2',
      'metabisulfit',
      'metabisulfite',
      'bisulfit',
      'ins 220',
      'ins 221',
      'ins 222',
      'ins 223',
      'ins 224',
      'ins 225',
      'ins 226',
      'ins 227',
      'ins 228',
    ],
  };

  /// Negations that come *before* the allergen ("bebas gluten", "no milk").
  static final List<RegExp> _negationPrefixes = [
    RegExp(r'\btidak\s+mengandung\b', caseSensitive: false),
    RegExp(r'\bbebas\b', caseSensitive: false),
    RegExp(r'\bfree\b', caseSensitive: false),
    RegExp(r'\bwithout\b', caseSensitive: false),
    RegExp(r'\btanpa\b', caseSensitive: false),
    RegExp(r'\bno\b', caseSensitive: false),
    RegExp(r'\bnon[\s-]', caseSensitive: false),
  ];

  /// Negation that comes *after* the allergen ("gluten free", "lactose-free").
  static final RegExp _negationSuffix = RegExp(r'^[\s-]{0,2}free\b');

  /// How far back (characters) a prefix negation can reach.
  static const int _lookback = 30;

  /// Characters that end a sentence: a negation never reaches across them.
  static const String _sentenceEnd = '.!?;\n';

  /// Returns [AllergenResult] for [text].
  ///
  /// Every mention of every keyword is examined. An allergen counts as
  /// **detected** if at least one mention is not negated, and only as
  /// **negated** when all of its mentions are - so a label that says both
  /// "bebas gluten" and "mengandung gandum" is never reported as gluten-free.
  static AllergenResult check(String text) {
    final lower = text.toLowerCase();
    final detected = <String>[];
    final negated = <String>[];

    for (final entry in _keywords.entries) {
      var mentioned = false;
      var affirmed = false;

      for (final kw in entry.value) {
        var from = 0;
        while (true) {
          final index = lower.indexOf(kw, from);
          if (index == -1) break;
          from = index + kw.length;
          mentioned = true;
          if (!_isNegated(lower, index, kw.length)) affirmed = true;
        }
      }

      if (affirmed) {
        detected.add(entry.key);
      } else if (mentioned) {
        negated.add(entry.key);
      }
    }

    return AllergenResult(detected: detected, negated: negated);
  }

  /// Whether the keyword at [start] (of [length] chars) is negated.
  static bool _isNegated(String lower, int start, int length) {
    // Prefix negation: look back, but only inside the same sentence, so
    // "Bebas pengawet. Mengandung susu." does not negate "susu".
    var before = lower.substring((start - _lookback).clamp(0, start), start);
    for (var i = before.length - 1; i >= 0; i--) {
      if (_sentenceEnd.contains(before[i])) {
        before = before.substring(i + 1);
        break;
      }
    }
    if (_negationPrefixes.any((rx) => rx.hasMatch(before))) return true;

    // Suffix negation: "gluten free", "lactose-free".
    final end = start + length;
    final after = lower.substring(end, (end + 10).clamp(end, lower.length));
    return _negationSuffix.hasMatch(after);
  }
}
