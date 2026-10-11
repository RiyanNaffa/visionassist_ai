import 'package:visionassist_ai/core/services/text_recognition_service.dart';
import 'package:visionassist_ai/features/text_reader/domain/entities/recognised_text.dart';
import 'package:visionassist_ai/features/text_reader/domain/repositories/text_reader_repository.dart';

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
