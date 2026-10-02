import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:visionassist_ai/core/utils/rgb_converter.dart';

void main() {
  group('RgbConverter.fromBgra', () {
    test('output length is 224*224*3', () {
      final width = 4;
      final height = 4;
      // BGRA: B=255, G=0, R=0, A=255 (pure blue in BGRA)
      final bytes = Uint8List(width * height * 4);
      for (var i = 0; i < width * height; i++) {
        bytes[i * 4] = 255; // B
        bytes[i * 4 + 1] = 0; // G
        bytes[i * 4 + 2] = 0; // R
        bytes[i * 4 + 3] = 255; // A
      }
      final result = RgbConverter.fromBgra(bytes, width, height);
      expect(result.length, equals(224 * 224 * 3));
    });

    test('values are normalised between 0 and 1', () {
      final width = 4;
      final height = 4;
      final bytes = Uint8List(width * height * 4)..fillRange(0, width * height * 4, 128);
      final result = RgbConverter.fromBgra(bytes, width, height);
      for (final v in result) {
        expect(v, greaterThanOrEqualTo(0.0));
        expect(v, lessThanOrEqualTo(1.0));
      }
    });

    test('white BGRA maps to ~1.0 RGB', () {
      final width = 2;
      final height = 2;
      final bytes = Uint8List(width * height * 4)..fillRange(0, width * height * 4, 255);
      final result = RgbConverter.fromBgra(bytes, width, height);
      for (final v in result) {
        expect(v, closeTo(1.0, 0.01));
      }
    });

    test('black BGRA maps to ~0.0 RGB', () {
      final width = 2;
      final height = 2;
      final bytes = Uint8List(width * height * 4);
      final result = RgbConverter.fromBgra(bytes, width, height);
      for (final v in result) {
        expect(v, closeTo(0.0, 0.01));
      }
    });
  });

  group('RgbConverter.fromNv21', () {
    test('output length is 224*224*3', () {
      final width = 4;
      final height = 4;
      // NV21: Y plane + UV interleaved
      final bytes = Uint8List((width * height * 1.5).toInt())..fillRange(0, width * height, 200);
      final result = RgbConverter.fromNv21(bytes, width, height);
      expect(result.length, equals(224 * 224 * 3));
    });

    test('values are normalised between 0 and 1', () {
      final width = 4;
      final height = 4;
      final bytes = Uint8List((width * height * 1.5).toInt());
      for (var i = 0; i < width * height; i++) bytes[i] = 180;
      final result = RgbConverter.fromNv21(bytes, width, height);
      for (final v in result) {
        expect(v, greaterThanOrEqualTo(0.0));
        expect(v, lessThanOrEqualTo(1.0));
      }
    });
  });
}
