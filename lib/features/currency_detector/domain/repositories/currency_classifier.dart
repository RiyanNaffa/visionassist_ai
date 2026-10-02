import 'dart:typed_data';
import '../entities/currency_prediction.dart';

/// Abstract contract for the banknote image classifier.
///
/// **Model contract** — see `assets/models/README.md`:
/// - Input: `[1, 224, 224, 3]` float32 RGB normalised 0–1.
/// - Output: `[1, N]` softmax probabilities.
/// - Labels: file `assets/models/currency_labels.txt`, one per line.
abstract class CurrencyClassifier {
  /// Classifies a pre-processed RGB image [input].
  ///
  /// [input] must be a flat Float32List of length 224 × 224 × 3.
  Future<CurrencyPrediction> classify(Float32List input);

  /// Whether this classifier is operational (model loaded).
  bool get isAvailable;
}
