import 'camera_service.dart';

/// Result from a text-recognition pass.
class TextRecognitionResult {
  const TextRecognitionResult({
    required this.text,
    required this.blocks,
  });

  /// The full recognised text string (all blocks joined).
  final String text;

  /// Individual text blocks (paragraphs).
  final List<String> blocks;

  bool get isEmpty => text.trim().isEmpty;
}

/// Abstract contract for on-device OCR.
abstract class TextRecognitionService {
  /// Recognises text in the given [frame].
  Future<TextRecognitionResult> recognizeFromFrame(CameraFrame frame);

  /// Recognises text in an image at the given file [path].
  Future<TextRecognitionResult> recognizeFromFile(String path);

  /// Releases underlying ML resources.
  Future<void> dispose();
}
