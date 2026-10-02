import '../entities/ingredient_analysis.dart';

/// Abstract repository for Ingredient Analyzer.
abstract class IngredientRepository {
  /// Analyses OCR text from a product label.
  Future<IngredientAnalysis> analyze(String ocrText);
}
