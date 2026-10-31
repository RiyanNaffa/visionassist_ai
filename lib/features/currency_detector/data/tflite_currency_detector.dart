import 'dart:math' as math;

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
///
/// Inference runs on a background isolate ([IsolateInterpreter]). On the UI
/// isolate a frame took long enough that a finger's down event waited past
/// the 500 ms long-press timeout, so swipes in this mode were swallowed and
/// the user could not switch modes.
class TfliteCurrencyDetector implements CurrencyDetector {
  TfliteCurrencyDetector();

  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  bool _available = false;

  /// Initialises the interpreter from the bundled TFLite asset.
  Future<void> initialize() async {
    try {
      // fromAsset() loads the path as-is via rootBundle, so it must be the full
      // bundle key (with the `assets/` prefix declared in pubspec.yaml).
      _interpreter = await Interpreter.fromAsset(
        'assets/models/currency_detector.tflite',
      );
      _isolateInterpreter = await IsolateInterpreter.create(
        address: _interpreter!.address,
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
    final isolateInterpreter = _isolateInterpreter;
    if (!_available || _interpreter == null || isolateInterpreter == null) {
      return const CurrencyDetectionResult(detections: []);
    }

    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final output = Float32List(outputShape.fold(1, (a, b) => a * b));
    try {
      // Raw bytes are copied into the [1, 256, 256, 3] tensor as they are; a
      // nested List is converted number by number (~50 ms per frame on a PC,
      // several times that on a phone).
      await isolateInterpreter.run(
        input.buffer.asUint8List(input.offsetInBytes, input.lengthInBytes),
        output.buffer,
      );
    } catch (e) {
      debugPrint('[CurrencyDetector] ❌ Inference error: $e');
      return const CurrencyDetectionResult(detections: []);
    }
    return decodeOutput(output, outputShape);
  }

  /// Releases interpreter resources.
  void dispose() {
    _isolateInterpreter?.close();
    _interpreter?.close();
  }

  /// Turns the model's flat output tensor into detections: confidence
  /// filter, per-class NMS, then sorted by denomination.
  ///
  /// Two YOLO export layouts are supported:
  /// - A) `[1, N, 6]`: rows of `[cx, cy, w, h, confidence, class_id]`
  ///   (end-to-end export, the bundled model).
  /// - B) `[1, 4 + numClasses, N]`: Ultralytics' transposed layout, rows
  ///   0–3 are `cx, cy, w, h` and the rest are per-class scores.
  @visibleForTesting
  static CurrencyDetectionResult decodeOutput(
    Float32List output,
    List<int> shape,
  ) {
    final List<_RawDetection> candidates;
    if (shape.length == 3 && shape[2] == 6) {
      candidates = _filterRows(output, shape[1]);
    } else if (shape.length == 3 && shape[1] >= 5) {
      candidates = _filterTransposed(output, shape[1], shape[2]);
    } else {
      debugPrint('[CurrencyDetector] ⚠ Unexpected output shape: $shape');
      return const CurrencyDetectionResult(detections: []);
    }
    return CurrencyDetectionResult(
      detections: _sortByDenomination(_nonMaxSuppression(candidates)),
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  /// Layout A: [numDetections] rows of `[cx, cy, w, h, confidence, class_id]`.
  static List<_RawDetection> _filterRows(Float32List out, int numDetections) {
    final result = <_RawDetection>[];
    for (var i = 0; i < numDetections; i++) {
      final row = i * 6;
      final conf = out[row + 4];
      if (conf < _kConfThreshold) continue;
      result.add(
        _RawDetection(
          cx: out[row],
          cy: out[row + 1],
          w: out[row + 2],
          h: out[row + 3],
          confidence: conf,
          classIdx: out[row + 5].round().clamp(0, _kClasses.length - 1),
        ),
      );
    }
    return result;
  }

  /// Layout B (Ultralytics transposed): `numAttrs` rows of `numDetections`.
  ///
  /// Rows 0–3: cx, cy, w, h (normalised).
  /// Rows 4..4+numClasses-1: per-class raw scores (no sigmoid — max = conf).
  static List<_RawDetection> _filterTransposed(
    Float32List out,
    int numAttrs,
    int numDetections,
  ) {
    double at(int attr, int i) => out[attr * numDetections + i];
    final result = <_RawDetection>[];
    final numClasses = math.min(_kClasses.length, numAttrs - 4);

    for (var i = 0; i < numDetections; i++) {
      // Find the class with the highest score.
      var maxScore = 0.0;
      var maxCls = 0;
      for (var c = 0; c < numClasses; c++) {
        final score = at(4 + c, i);
        if (score > maxScore) {
          maxScore = score;
          maxCls = c;
        }
      }

      if (maxScore < _kConfThreshold) continue;
      result.add(
        _RawDetection(
          cx: at(0, i),
          cy: at(1, i),
          w: at(2, i),
          h: at(3, i),
          confidence: maxScore,
          classIdx: maxCls,
        ),
      );
    }
    return result;
  }

  /// Greedy NMS: for each class independently, suppress overlapping boxes.
  static List<_RawDetection> _nonMaxSuppression(
    List<_RawDetection> detections,
  ) {
    if (detections.isEmpty) return [];

    final kept = <_RawDetection>[];

    for (var cls = 0; cls < _kClasses.length; cls++) {
      final forClass = detections.where((d) => d.classIdx == cls).toList()
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
  static List<DetectedBanknote> _sortByDenomination(List<_RawDetection> raw) {
    final list = raw.map((d) {
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
      return b.confidence
          .compareTo(a.confidence); // tie-break: higher conf first
    });

    return list;
  }

  /// Intersection-over-union of two detections (centre-format boxes).
  static double _iou(_RawDetection a, _RawDetection b) {
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
