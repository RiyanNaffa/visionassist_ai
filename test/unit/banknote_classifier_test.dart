import 'package:flutter_test/flutter_test.dart';
import 'package:visionassist_ai/features/currency_detector/data/tflite_currency_classifier.dart';
import 'dart:typed_data';

void main() {
  group('UnavailableCurrencyClassifier', () {
    test('isAvailable returns false', () {
      final classifier = UnavailableCurrencyClassifier();
      expect(classifier.isAvailable, isFalse);
    });

    test('classify returns UNAVAILABLE prediction', () async {
      final classifier = UnavailableCurrencyClassifier();
      final input = Float32List(224 * 224 * 3);
      final result = await classifier.classify(input);
      expect(result.label, 'UNAVAILABLE');
      expect(result.confidence, 0.0);
    });

    test('prediction isReliable is false', () async {
      final classifier = UnavailableCurrencyClassifier();
      final input = Float32List(224 * 224 * 3);
      final result = await classifier.classify(input);
      expect(result.isReliable, isFalse);
    });
  });
}
