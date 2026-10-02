import '../entities/ingredient_analysis.dart';
import '../repositories/ingredient_repository.dart';

/// Use case: analyse a product label image for allergens, expiry, and prices.
class AnalyzeIngredients {
  const AnalyzeIngredients(this._repository);

  final IngredientRepository _repository;

  /// Executes analysis on [ocrText] extracted from the product image.
  Future<IngredientAnalysis> call(String ocrText) =>
      _repository.analyze(ocrText);
}
