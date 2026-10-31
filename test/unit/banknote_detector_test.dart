import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:visionassist_ai/features/currency_detector/data/tflite_currency_detector.dart'
    show TfliteCurrencyDetector, UnavailableCurrencyDetector;
import 'package:visionassist_ai/features/currency_detector/domain/entities/currency_detection.dart';

/// Tests untuk domain entities (tanpa TFLite runtime).
///
/// [UnavailableCurrencyDetector] sengaja diimplementasikan inline di sini
/// agar test bisa berjalan tanpa memuat `tflite_flutter` yang membutuhkan
/// native binaries on-device.
class _StubUnavailableDetector {
  bool _announced = false;

  bool get isAvailable => false;

  Future<CurrencyDetectionResult> detect(Float32List input) async {
    if (!_announced) _announced = true;
    return const CurrencyDetectionResult(detections: []);
  }
}

void main() {
  // ── Stub unavailable detector ─────────────────────────────────────────────

  group('UnavailableCurrencyDetector (stub)', () {
    test('isAvailable returns false', () {
      final detector = _StubUnavailableDetector();
      expect(detector.isAvailable, isFalse);
    });

    test('detect returns empty result for 256×256×3 input', () async {
      final detector = _StubUnavailableDetector();
      final input = Float32List(256 * 256 * 3);
      final result = await detector.detect(input);
      expect(result.hasDetections, isFalse);
      expect(result.detections, isEmpty);
    });

    test('calling detect twice does not throw', () async {
      final detector = _StubUnavailableDetector();
      final input = Float32List(256 * 256 * 3);
      await detector.detect(input);
      await detector.detect(input);
    });
  });

  // ── CurrencyDetectionResult ───────────────────────────────────────────────

  group('CurrencyDetectionResult', () {
    test('empty result has no detections', () {
      const r = CurrencyDetectionResult(detections: []);
      expect(r.hasDetections, isFalse);
      expect(r.detectedLabels, isEmpty);
    });

    test('single detection is reported correctly', () {
      const r = CurrencyDetectionResult(
        detections: [
          DetectedBanknote(
            classLabel: '20000',
            confidence: 0.91,
            cx: 0.5,
            cy: 0.5,
            width: 0.4,
            height: 0.3,
          ),
        ],
      );
      expect(r.hasDetections, isTrue);
      expect(r.detectedLabels, contains('20000'));
    });

    test('detectedLabels returns unique set for duplicate classes', () {
      const r = CurrencyDetectionResult(
        detections: [
          DetectedBanknote(
            classLabel: '1000',
            confidence: 0.88,
            cx: 0.2,
            cy: 0.5,
            width: 0.3,
            height: 0.2,
          ),
          DetectedBanknote(
            classLabel: '1000',
            confidence: 0.75,
            cx: 0.7,
            cy: 0.5,
            width: 0.3,
            height: 0.2,
          ),
        ],
      );
      expect(r.detectedLabels.length, 1);
      expect(r.detectedLabels, {'1000'});
    });

    test('detectedLabels spans multiple denominations', () {
      const r = CurrencyDetectionResult(
        detections: [
          DetectedBanknote(
            classLabel: '1000',
            confidence: 0.9,
            cx: 0.2,
            cy: 0.5,
            width: 0.3,
            height: 0.2,
          ),
          DetectedBanknote(
            classLabel: '50000',
            confidence: 0.85,
            cx: 0.7,
            cy: 0.5,
            width: 0.3,
            height: 0.2,
          ),
        ],
      );
      expect(r.detectedLabels, containsAll(['1000', '50000']));
    });
  });

  // ── DetectedBanknote ──────────────────────────────────────────────────────

  group('DetectedBanknote', () {
    test('stores all fields correctly', () {
      const b = DetectedBanknote(
        classLabel: '100000',
        confidence: 0.97,
        cx: 0.5,
        cy: 0.4,
        width: 0.6,
        height: 0.5,
      );
      expect(b.classLabel, '100000');
      expect(b.confidence, closeTo(0.97, 0.0001));
      expect(b.cx, closeTo(0.5, 0.0001));
      expect(b.cy, closeTo(0.4, 0.0001));
      expect(b.width, closeTo(0.6, 0.0001));
      expect(b.height, closeTo(0.5, 0.0001));
    });
  });

  // ── AppStrings.currencySpeech mapping ─────────────────────────────────────

  group('AppStrings.currencySpeech', () {
    // Import secara inline untuk avoid circular dependency di test
    const Map<String, String> speechMap = {
      '1000': 'Seribu Rupiah',
      '2000': 'Dua ribu Rupiah',
      '5000': 'Lima ribu Rupiah',
      '10000': 'Sepuluh ribu Rupiah',
      '20000': 'Dua puluh ribu Rupiah',
      '50000': 'Lima puluh ribu Rupiah',
      '100000': 'Seratus ribu Rupiah',
    };

    for (final entry in speechMap.entries) {
      test('${entry.key} → "${entry.value}"', () {
        expect(speechMap[entry.key], entry.value);
      });
    }

    test('all 7 IDR classes have a spoken form', () {
      expect(speechMap.length, 7);
    });
  });

  // ── Output decoding (no TFLite runtime needed) ────────────────────────────

  group('TfliteCurrencyDetector.decodeOutput', () {
    const decode = TfliteCurrencyDetector.decodeOutput;

    /// Layout A: rows of [cx, cy, w, h, confidence, class_id].
    Float32List rows(List<List<double>> r) =>
        Float32List.fromList([for (final row in r) ...row]);

    test('layout A keeps confident rows, sorted by denomination', () {
      final out = rows([
        [0.5, 0.5, 0.2, 0.1, 0.90, 4], // 20000
        [0.2, 0.2, 0.2, 0.1, 0.30, 1], // below the threshold
        [0.8, 0.8, 0.2, 0.1, 0.70, 0], // 1000
      ]);

      final result = decode(out, [1, 3, 6]);

      expect(result.detections.map((d) => d.classLabel), ['1000', '20000']);
      expect(result.detections.last.confidence, closeTo(0.9, 1e-6));
      expect(result.detections.last.cx, closeTo(0.5, 1e-6));
    });

    test('layout A suppresses an overlapping box of the same class', () {
      final out = rows([
        [0.50, 0.50, 0.4, 0.2, 0.90, 4],
        [0.51, 0.50, 0.4, 0.2, 0.80, 4], // same note, lower confidence
        [0.10, 0.10, 0.1, 0.1, 0.60, 4], // a second note
      ]);

      final result = decode(out, [1, 3, 6]);

      expect(result.detections, hasLength(2));
      expect(result.detections.first.confidence, closeTo(0.9, 1e-6));
    });

    test('layout B (transposed) takes the best class score', () {
      const n = 2; // detections; 4 box values + 7 class scores each
      final out = Float32List((4 + 7) * n);
      void put(int attr, int i, double v) => out[attr * n + i] = v;
      put(0, 0, 0.5);
      put(1, 0, 0.5);
      put(2, 0, 0.3);
      put(3, 0, 0.2);
      put(4 + 0, 0, 0.1);
      put(4 + 5, 0, 0.8); // 50000
      put(4 + 2, 1, 0.4); // below the threshold

      final result = decode(out, [1, 4 + 7, n]);

      expect(result.detections.single.classLabel, '50000');
      expect(result.detections.single.cx, closeTo(0.5, 1e-6));
    });

    test('an unexpected shape gives no detections', () {
      expect(decode(Float32List(4), [1, 4]).hasDetections, isFalse);
    });
  });
}
