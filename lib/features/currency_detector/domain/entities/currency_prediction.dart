/// Result from the currency classifier.
class CurrencyPrediction {
  const CurrencyPrediction({
    required this.label,
    required this.confidence,
  });

  /// Label from `currency_labels.txt`, e.g. `IDR_20000`.
  final String label;

  /// Softmax confidence 0.0 – 1.0.
  final double confidence;

  bool get isReliable => confidence >= 0.85;
}
