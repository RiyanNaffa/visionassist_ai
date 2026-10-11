import 'dart:typed_data';
import '../entities/currency_detection.dart';

/// Abstract contract for the real-time banknote detector.
///
/// **Model contract** — see `assets/models/README.md`:
/// - Input:  `[1, 256, 256, 3]` float32 RGB normalised 0–1.
/// - Output: `[1, num_detections, 6]` float32 — `[cx, cy, w, h, conf, class_id]`.
/// - Classes: `AppConstants.currencyClasses` (7 IDR denominations, 0-indexed).
abstract class CurrencyDetector {
  /// Runs detection on [input], a flat Float32List of length 256 × 256 × 3.
  ///
  /// Returns a [CurrencyDetectionResult] with all post-NMS bounding boxes.
  Future<CurrencyDetectionResult> detect(Float32List input);

  /// Whether this detector is operational (model loaded).
  bool get isAvailable;
}
