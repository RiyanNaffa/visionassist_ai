/// Result from ingredient / label analysis.
class IngredientAnalysis {
  const IngredientAnalysis({
    required this.allergens,
    required this.negatedAllergens,
    this.expiryDate,
    this.prices = const [],
    required this.summary,
  });

  /// Detected allergen names (not negated).
  final List<String> allergens;

  /// Allergen names explicitly negated ("gluten free", etc.).
  final List<String> negatedAllergens;

  /// Parsed expiry date string, or `null` if not found.
  final String? expiryDate;

  /// Detected prices as formatted strings.
  final List<String> prices;

  /// Spoken summary, ≤ 15 words.
  final String summary;
}
