import '../entities/recognised_text.dart';

/// Abstract repository for Text Reader.
abstract class TextReaderRepository {
  /// Recognises text from an image at [filePath].
  Future<RecognisedText> recognizeFromFile(String filePath);
}
