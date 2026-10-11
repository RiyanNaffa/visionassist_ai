import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'package:visionassist_ai/features/currency_detector/domain/entities/currency_detection.dart';
import 'package:visionassist_ai/features/currency_detector/domain/repositories/currency_detector.dart';

/// Hard-coded class list — must match the YOLO model's training order.
/// See `assets/models/README.md` for the full contract.
const List<String> _kClasses = [
  '1000',
  '2000',
  '5000',
  '10000',
  '20000',
  '50000',
  '100000',
];

/// YOLO end-to-end post-processing thresholds.
const double _kConfThreshold = 0.50;
const double _kNmsIouThreshold = 0.45;

/// TFLite-backed [CurrencyDetector] using a YOLO v2.6 end-to-end model.
///
/// The model asset is `assets/models/currency_detector.tflite`.
///
/// **Output tensor contract** (see `assets/models/README.md`):
/// - Shape `[1, num_detections, 6]`
/// - Each row: `[cx, cy, w, h, confidence, class_id]` (float32, normalised)
class TfliteCurrencyDetector implements CurrencyDetector {
  TfliteCurrencyDetector();

  Interpreter? _interpreter;
  bool _available = false;

  /// Initialises the interpreter from the bundled TFLite asset.
  Future<void> initialize() async {
    try {
      // fromAsset() loads the path as-is via rootBundle, so it must be the full
      // bundle key (with the `assets/` prefix declared in pubspec.yaml).
      _interpreter = await Interpreter.fromAsset(
        'assets/models/currency_detector.tflite',
      );
      _available = true;

      // Log tensor shapes so we can verify the output contract.
      final inShape = _interpreter!.getInputTensor(0).shape;
      final outShape = _interpreter!.getOutputTensor(0).shape;
      debugPrint('[CurrencyDetector] ✅ Model loaded. '
          'Input: $inShape  Output: $outShape');
    } catch (e) {
      debugPrint('[CurrencyDetector] ❌ Failed to load model: $e');
      _available = false;
    }
  }

  @override
  bool get isAvailable => _available;

  @override
  Future<CurrencyDetectionResult> detect(Float32List input) async {
    if (!_available || _interpreter == null) {
      return const CurrencyDetectionResult(detections: []);
    }

    // Input tensor: [1, 256, 256, 3]
    final inputNested = _buildInputNested(input);

    // Read output shape dynamically to support both common YOLO export layouts:
    //   A) [1, numDetections, 6]  — end-to-end (cx,cy,w,h,conf,cls)
    //   B) [1, 84, numDetections] — Ultralytics default (transposed)
    final outputShape = _interpreter!.getOutputTensor(0).shape;

    List<_RawDetection> candidates;
    try {
      if (outputShape.length == 3 && outputShape[2] == 6) {
        // Layout A: [1, N, 6]
        final numDetections = outputShape[1];
        final outputBuffer = [
          List.generate(numDetections, (_) => List<double>.filled(6, 0.0)),
        ];
        _interpreter!.runForMultipleInputs([inputNested], {0: outputBuffer});
        candidates = _filterByConfidence(outputBuffer[0]);
      } else if (outputShape.length == 3 && outputShape[1] >= 5) {
        // Layout B: [1, (4+numClasses), N] — Ultralytics transposed
        final numAttrs = outputShape[1]; // e.g. 4+7=11 for 7 classes
        final numDetections = outputShape[2];
        final outputBuffer = [
          List.generate(numAttrs, (_) => List<double>.filled(numDetections, 0.0)),
        ];
        _interpreter!.runForMultipleInputs([inputNested], {0: outputBuffer});
        candidates = _filterByConfidenceTransposed(outputBuffer[0], numDetections);
      } else {
        debugPrint('[CurrencyDetector] ⚠ Unexpected output shape: $outputShape');
        return const CurrencyDetectionResult(detections: []);
      }
    } catch (e) {
      debugPrint('[CurrencyDetector] ❌ Inference error: $e');
      return const CurrencyDetectionResult(detections: []);
    }

    final afterNms = _nonMaxSuppression(candidates);
    final sorted = _sortByDenomination(afterNms);

    return CurrencyDetectionResult(detections: sorted);
  }

  /// Releases interpreter resources.
  void dispose() => _interpreter?.close();

  // ── Private helpers ──────────────────────────────────────────────────────

  /// Reshapes flat Float32List into a nested `[1][256][256][3]` list.
  List<List<List<List<double>>>> _buildInputNested(Float32List flat) {
    const h = 256, w = 256, c = 3;
    return List.generate(
      1,
      (_) => List.generate(
        h,
        (y) => List.generate(
          w,
          (x) => List.generate(
            c,
            (ch) => flat[(y * w + x) * c + ch].toDouble(),
          ),
        ),
      ),
    );
  }

  /// Layout A: rows are `[cx, cy, w, h, confidence, class_id]`.
  List<_RawDetection> _filterByConfidence(List<List<double>> rows) {
    final result = <_RawDetection>[];
    for (final row in rows) {
      final conf = row[4];
      if (conf < _kConfThreshold) continue;
      final classIdx = row[5].round().clamp(0, _kClasses.length - 1);
      result.add(
        _RawDetection(
          cx: row[0],
          cy: row[1],
          w: row[2],
          h: row[3],
          confidence: conf,
          classIdx: classIdx,
        ),
      );
    }
    return result;
  }

  /// Layout B (Ultralytics transposed): tensor is `[1, 4+numClasses, N]`.
  ///
  /// Rows 0–3: cx, cy, w, h (normalised).
  /// Rows 4..4+numClasses-1: per-class raw scores (no sigmoid — max = conf).
  List<_RawDetection> _filterByConfidenceTransposed(
    List<List<double>> tensor, // shape: [numAttrs][numDetections]
    int numDetections,
  ) {
    final result = <_RawDetection>[];
    final numClasses = _kClasses.length;

    for (var i = 0; i < numDetections; i++) {
      final cx = tensor[0][i];
      final cy = tensor[1][i];
      final w = tensor[2][i];
      final h = tensor[3][i];

      // Find the class with the highest score.
      var maxScore = 0.0;
      var maxCls = 0;
      for (var c = 0; c < numClasses; c++) {
        final score = tensor[4 + c][i];
        if (score > maxScore) {
          maxScore = score;
          maxCls = c;
        }
      }

      if (maxScore < _kConfThreshold) continue;
      result.add(
        _RawDetection(
          cx: cx,
          cy: cy,
          w: w,
          h: h,
          confidence: maxScore,
          classIdx: maxCls,
        ),
      );
    }
    return result;
  }

  /// Greedy NMS: for each class independently, suppress overlapping boxes.
  List<_RawDetection> _nonMaxSuppression(List<_RawDetection> detections) {
    if (detections.isEmpty) return [];

    final kept = <_RawDetection>[];

    for (var cls = 0; cls < _kClasses.length; cls++) {
      final forClass =
          detections.where((d) => d.classIdx == cls).toList()
            ..sort((a, b) => b.confidence.compareTo(a.confidence));

      final suppressed = List<bool>.filled(forClass.length, false);

      for (var i = 0; i < forClass.length; i++) {
        if (suppressed[i]) continue;
        kept.add(forClass[i]);
        for (var j = i + 1; j < forClass.length; j++) {
          if (suppressed[j]) continue;
          if (_iou(forClass[i], forClass[j]) > _kNmsIouThreshold) {
            suppressed[j] = true;
          }
        }
      }
    }

    return kept;
  }

  /// Sorts detections by denomination value ascending, then by confidence
  /// descending so callers get a stable, readable list.
  List<DetectedBanknote> _sortByDenomination(List<_RawDetection> raw) {
    final list =
        raw.map((d) {
          return DetectedBanknote(
            classLabel: _kClasses[d.classIdx],
            confidence: d.confidence,
            cx: d.cx,
            cy: d.cy,
            width: d.w,
            height: d.h,
          );
        }).toList();

    list.sort((a, b) {
      final va = int.tryParse(a.classLabel) ?? 0;
      final vb = int.tryParse(b.classLabel) ?? 0;
      final cmp = va.compareTo(vb);
      if (cmp != 0) return cmp;
      return b.confidence.compareTo(a.confidence); // tie-break: higher conf first
    });

    return list;
  }

  /// Intersection-over-union of two detections (centre-format boxes).
  double _iou(_RawDetection a, _RawDetection b) {
    final ax1 = a.cx - a.w / 2, ay1 = a.cy - a.h / 2;
    final ax2 = a.cx + a.w / 2, ay2 = a.cy + a.h / 2;
    final bx1 = b.cx - b.w / 2, by1 = b.cy - b.h / 2;
    final bx2 = b.cx + b.w / 2, by2 = b.cy + b.h / 2;

    final interX1 = math.max(ax1, bx1);
    final interY1 = math.max(ay1, by1);
    final interX2 = math.min(ax2, bx2);
    final interY2 = math.min(ay2, by2);

    final interW = (interX2 - interX1).clamp(0.0, double.infinity);
    final interH = (interY2 - interY1).clamp(0.0, double.infinity);
    final intersection = interW * interH;

    if (intersection == 0.0) return 0.0;

    final areaA = a.w * a.h;
    final areaB = b.w * b.h;
    return intersection / (areaA + areaB - intersection);
  }
}

/// Fallback detector used when the TFLite model file is absent.
///
/// Announces the missing model once via the controller, then stays silent.
class UnavailableCurrencyDetector implements CurrencyDetector {
  bool _announced = false;

  @override
  bool get isAvailable => false;

  @override
  Future<CurrencyDetectionResult> detect(Float32List input) async {
    if (!_announced) {
      _announced = true;
      // The controller checks isAvailable and speaks the missing-model message.
    }
    return const CurrencyDetectionResult(detections: []);
  }
}

// ── Internal data class ─────────────────────────────────────────────────────

class _RawDetection {
  const _RawDetection({
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
    required this.confidence,
    required this.classIdx,
  });

  final double cx, cy, w, h, confidence;
  final int classIdx;
}
