import 'dart:typed_data';
import '../entities/currency_detection.dart';
import '../repositories/currency_detector.dart';

/// Use case: detect banknote denominations in a pre-processed camera frame.
class DetectCurrency {
  const DetectCurrency(this._detector);

  final CurrencyDetector _detector;

  /// Runs detection on [rgbInput] (flat Float32List 256 × 256 × 3).
  Future<CurrencyDetectionResult> call(Float32List rgbInput) =>
      _detector.detect(rgbInput);
}
