import 'dart:io';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../camera_service.dart';
import '../text_recognition_service.dart';

/// ML Kit-backed [TextRecognitionService].
///
/// Performs Latin-script OCR via [TextRecognizer].
class MlKitTextRecognitionService implements TextRecognitionService {
  MlKitTextRecognitionService()
      : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  @override
  Future<TextRecognitionResult> recognizeFromFrame(CameraFrame frame) async {
    final inputImage = _frameToInputImage(frame);
    return _process(inputImage);
  }

  @override
  Future<TextRecognitionResult> recognizeFromFile(String path) async {
    final inputImage = InputImage.fromFile(File(path));
    return _process(inputImage);
  }

  @override
  Future<void> dispose() => _recognizer.close();

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<TextRecognitionResult> _process(InputImage inputImage) async {
    final recognized = await _recognizer.processImage(inputImage);
    final blocks = recognized.blocks.map((b) => b.text).toList();
    return TextRecognitionResult(
      text: recognized.text,
      blocks: blocks,
    );
  }

  InputImage _frameToInputImage(CameraFrame frame) {
    final rotation = _toMlKitRotation(frame.rotationDegrees);
    final format = frame.format == 'nv21'
        ? InputImageFormat.nv21
        : InputImageFormat.bgra8888;

    final metadata = InputImageMetadata(
      size: Size(frame.width.toDouble(), frame.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: frame.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: frame.bytes, metadata: metadata);
  }

  InputImageRotation _toMlKitRotation(int degrees) {
    switch (degrees) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }
}
