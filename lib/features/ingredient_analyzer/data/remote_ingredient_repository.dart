import '../../../core/network/proxy_client.dart';
import '../../../core/utils/allergen_checker.dart';
import '../domain/entities/ingredient_analysis.dart';
import '../domain/repositories/ingredient_repository.dart';

/// [IngredientRepository] that lets the proxy *rephrase* the summary only.
///
/// Safety model: the on-device [_local] repository always produces the
/// allergens, negated allergens, expiry date and prices - the remote side can
/// never change them. The remote summary replaces the local one only if it
///   * is non-empty and at most 15 words, and
///   * mentions no allergen category that the local analysis did not find
///     (a client-side copy of the backend's allergen-leak guard).
/// Otherwise - or on any network error - the local summary is kept.
class RemoteIngredientRepository implements IngredientRepository {
  RemoteIngredientRepository({
    required ProxyClient client,
    required IngredientRepository local,
  })  : _client = client,
        _local = local;

  final ProxyClient _client;
  final IngredientRepository _local;

  static const int _maxChars = 2000;
  static const int _maxSummaryWords = 15;

  @override
  Future<IngredientAnalysis> analyze(String ocrText) async {
    final base = await _local.analyze(ocrText);
    final ocr = ocrText.trim();
    if (ocr.isEmpty) return base;

    try {
      final json = await _client.postJson('/ingredients/summarize', {
        'ocr_text': ocr.length <= _maxChars ? ocr : ocr.substring(0, _maxChars),
        'allergens': base.allergens,
        'negated_allergens': base.negatedAllergens,
        'expiry_date': base.expiryDate,
        'prices': base.prices,
      });
      final summary = json['summary'];
      if (summary is String && _isSafe(summary, base)) {
        return IngredientAnalysis(
          allergens: base.allergens,
          negatedAllergens: base.negatedAllergens,
          expiryDate: base.expiryDate,
          prices: base.prices,
          summary: summary.trim(),
        );
      }
    } on ProxyException {
      // keep the local summary
    }
    return base;
  }

  static bool _isSafe(String summary, IngredientAnalysis base) {
    final trimmed = summary.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.split(RegExp(r'\s+')).length > _maxSummaryWords) return false;

    final known = {...base.allergens, ...base.negatedAllergens};
    final mentioned = AllergenChecker.check(trimmed);
    return [...mentioned.detected, ...mentioned.negated].every(known.contains);
  }
}
