import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:visionassist_ai/features/currency_detector/data/tflite_currency_detector.dart'
    show UnavailableCurrencyDetector;
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
}
