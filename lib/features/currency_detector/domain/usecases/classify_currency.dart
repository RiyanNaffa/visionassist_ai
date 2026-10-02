import 'dart:typed_data';
import '../entities/currency_prediction.dart';
import '../repositories/currency_classifier.dart';

/// Use case: classify a pre-processed frame into a currency denomination.
class ClassifyCurrency {
  const ClassifyCurrency(this._classifier);

  final CurrencyClassifier _classifier;

  /// Executes classification on [rgbInput] (flat Float32List 224×224×3).
  Future<CurrencyPrediction> call(Float32List rgbInput) =>
      _classifier.classify(rgbInput);
}
