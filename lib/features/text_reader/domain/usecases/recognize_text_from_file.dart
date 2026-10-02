import '../entities/recognised_text.dart';
import '../repositories/text_reader_repository.dart';

/// Use case: recognise text from a captured still image.
class RecognizeTextFromFile {
  const RecognizeTextFromFile(this._repository);

  final TextReaderRepository _repository;

  /// Executes the use case with [filePath].
  Future<RecognisedText> call(String filePath) =>
      _repository.recognizeFromFile(filePath);
}
