/// A single banknote bounding-box detection from the YOLO model.
class DetectedBanknote {
  const DetectedBanknote({
    required this.classLabel,
    required this.confidence,
    required this.cx,
    required this.cy,
    required this.width,
    required this.height,
  });

  /// Denomination string, e.g. `'20000'`. Matches an entry in
  /// `AppConstants.currencyClasses`.
  final String classLabel;

  /// Detection confidence 0.0 – 1.0.
  final double confidence;

  /// Bounding-box centre X, normalised 0.0 – 1.0.
  final double cx;

  /// Bounding-box centre Y, normalised 0.0 – 1.0.
  final double cy;

  /// Bounding-box width, normalised 0.0 – 1.0.
  final double width;

  /// Bounding-box height, normalised 0.0 – 1.0.
  final double height;
}

/// The result of running the currency detector on a single frame.
///
/// [detections] contains **all** banknotes found after NMS; empty when
/// no banknote is visible.
class CurrencyDetectionResult {
  const CurrencyDetectionResult({required this.detections});

  /// Sorted ascending by denomination value, then descending by confidence.
  final List<DetectedBanknote> detections;

  /// True when at least one banknote was detected with sufficient confidence.
  bool get hasDetections => detections.isNotEmpty;

  /// Unique set of denomination labels present in this frame, sorted
  /// ascending (e.g. `{'1000', '20000'}`).
  Set<String> get detectedLabels => detections.map((d) => d.classLabel).toSet();
}
