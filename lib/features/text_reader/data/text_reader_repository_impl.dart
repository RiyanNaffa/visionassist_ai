import '../../domain/entities/recognised_text.dart';
import '../../domain/repositories/text_reader_repository.dart';
import '../../../../core/services/text_recognition_service.dart';

/// Concrete [TextReaderRepository] backed by [TextRecognitionService].
class TextReaderRepositoryImpl implements TextReaderRepository {
  const TextReaderRepositoryImpl(this._recognitionService);

  final TextRecognitionService _recognitionService;

  @override
  Future<RecognisedText> recognizeFromFile(String filePath) async {
    final result = await _recognitionService.recognizeFromFile(filePath);
    return RecognisedText(text: result.text, blocks: result.blocks);
  }
}
