import 'dart:typed_data';
import 'dart:math' as math;

/// Converts a raw YUV (NV21) or BGRA camera buffer to a flat Float32List
/// representing a 256 × 256 RGB image normalised to 0–1.
///
/// Written in pure Dart so it is unit-testable without a device.
class RgbConverter {
  RgbConverter._();

  static const int _targetWidth = 256;
  static const int _targetHeight = 256;

  /// Converts NV21 [bytes] (width × height × 1.5 bytes) to a normalised
  /// RGB Float32List.
  static Float32List fromNv21(
    Uint8List bytes,
    int width,
    int height,
  ) {
    final rgb = _extractRgbNv21(bytes, width, height);
    return _resizeAndNormalize(rgb, width, height);
  }

  /// Converts BGRA [bytes] (width × height × 4 bytes) to a normalised
  /// RGB Float32List.
  static Float32List fromBgra(
    Uint8List bytes,
    int width,
    int height,
  ) {
    final rgb = _extractRgbBgra(bytes, width, height);
    return _resizeAndNormalize(rgb, width, height);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Decodes NV21 bytes to an interleaved RGB [Uint8List].
  static Uint8List _extractRgbNv21(Uint8List bytes, int width, int height) {
    final rgb = Uint8List(width * height * 3);
    final uvOffset = width * height;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final yValue = bytes[y * width + x] & 0xFF;
        final uvIndex = uvOffset + (y >> 1) * width + (x & ~1);
        final v = (bytes[uvIndex] & 0xFF) - 128;
        final u = (bytes[uvIndex + 1] & 0xFF) - 128;

        final r = (yValue + 1.402 * v).round().clamp(0, 255);
        final g = (yValue - 0.344136 * u - 0.714136 * v).round().clamp(0, 255);
        final b = (yValue + 1.772 * u).round().clamp(0, 255);

        final idx = (y * width + x) * 3;
        rgb[idx] = r;
        rgb[idx + 1] = g;
        rgb[idx + 2] = b;
      }
    }
    return rgb;
  }

  /// Decodes BGRA bytes to an interleaved RGB [Uint8List].
  static Uint8List _extractRgbBgra(Uint8List bytes, int width, int height) {
    final rgb = Uint8List(width * height * 3);
    for (var i = 0; i < width * height; i++) {
      rgb[i * 3] = bytes[i * 4 + 2]; // R
      rgb[i * 3 + 1] = bytes[i * 4 + 1]; // G
      rgb[i * 3 + 2] = bytes[i * 4]; // B
    }
    return rgb;
  }

  /// Bilinear resize of [srcRgb] from (srcW × srcH) to 224 × 224 and
  /// normalise pixel values to [0.0, 1.0].
  static Float32List _resizeAndNormalize(
    Uint8List srcRgb,
    int srcW,
    int srcH,
  ) {
    final output = Float32List(_targetWidth * _targetHeight * 3);
    final xRatio = srcW / _targetWidth;
    final yRatio = srcH / _targetHeight;

    for (var ty = 0; ty < _targetHeight; ty++) {
      for (var tx = 0; tx < _targetWidth; tx++) {
        final srcX = tx * xRatio;
        final srcY = ty * yRatio;
        final x0 = srcX.floor().clamp(0, srcW - 1);
        final x1 = math.min(x0 + 1, srcW - 1);
        final y0 = srcY.floor().clamp(0, srcH - 1);
        final y1 = math.min(y0 + 1, srcH - 1);
        final dx = srcX - x0;
        final dy = srcY - y0;

        for (var c = 0; c < 3; c++) {
          final p00 = srcRgb[(y0 * srcW + x0) * 3 + c];
          final p10 = srcRgb[(y0 * srcW + x1) * 3 + c];
          final p01 = srcRgb[(y1 * srcW + x0) * 3 + c];
          final p11 = srcRgb[(y1 * srcW + x1) * 3 + c];
          final value =
              p00 * (1 - dx) * (1 - dy) +
              p10 * dx * (1 - dy) +
              p01 * (1 - dx) * dy +
              p11 * dx * dy;
          output[(ty * _targetWidth + tx) * 3 + c] = value / 255.0;
        }
      }
    }
    return output;
  }
}
