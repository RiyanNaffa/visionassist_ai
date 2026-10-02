import '../../../../core/utils/allergen_checker.dart';
import '../../domain/entities/ingredient_analysis.dart';
import '../../domain/repositories/ingredient_repository.dart';

/// Local rule-based [IngredientRepository] implementation.
///
/// Extracts allergens, expiry date, and prices from OCR text.
class LocalIngredientRepository implements IngredientRepository {
  @override
  Future<IngredientAnalysis> analyze(String ocrText) async {
    final allergenResult = AllergenChecker.check(ocrText);
    final expiry = _parseExpiry(ocrText);
    final prices = _parsePrices(ocrText);
    final summary = _buildSummary(
      allergens: allergenResult.detected,
      expiry: expiry,
      prices: prices,
    );
    return IngredientAnalysis(
      allergens: allergenResult.detected,
      negatedAllergens: allergenResult.negated,
      expiryDate: expiry,
      prices: prices,
      summary: summary,
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static final List<RegExp> _expiryPatterns = [
    // dd/mm/yyyy or dd-mm-yyyy
    RegExp(
      r'(?:EXP|ED|BB|Baik digunakan sebelum)[:\s]*'
      r'(\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4})',
      caseSensitive: false,
    ),
    // mm/yyyy
    RegExp(
      r'(?:EXP|ED|BB|Baik digunakan sebelum)[:\s]*'
      r'(\d{1,2}[/\-]\d{4})',
      caseSensitive: false,
    ),
    // dd MMM yyyy  (e.g. 15 JAN 2026)
    RegExp(
      r'(?:EXP|ED|BB|Baik digunakan sebelum)[:\s]*'
      r'(\d{1,2}\s+[A-Za-z]{3}\s+\d{4})',
      caseSensitive: false,
    ),
    // Bare date anywhere: dd/mm/yyyy
    RegExp(r'\b(\d{1,2}[/\-]\d{1,2}[/\-]\d{4})\b'),
  ];

  static final RegExp _pricePattern = RegExp(
    r'(?:Rp\.?\s*|IDR\s*)(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)',
    caseSensitive: false,
  );

  String? _parseExpiry(String text) {
    for (final rx in _expiryPatterns) {
      final match = rx.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  List<String> _parsePrices(String text) {
    return _pricePattern
        .allMatches(text)
        .map((m) => 'Rp ${m.group(1)}')
        .toList();
  }

  String _buildSummary({
    required List<String> allergens,
    String? expiry,
    required List<String> prices,
  }) {
    final parts = <String>[];

    if (allergens.isEmpty) {
      parts.add('Tidak ada alergen');
    } else {
      parts.add('Alergen: ${allergens.join(', ')}');
    }

    if (expiry != null) parts.add('Kadaluarsa: $expiry');
    if (prices.isNotEmpty) parts.add(prices.first);

    final summary = parts.join('. ');
    // Truncate to ≤ 15 words.
    final words = summary.split(' ');
    if (words.length <= 15) return summary;
    return '${words.take(15).join(' ')}…';
  }
}
