import '../entities/qa_answer.dart';

/// Abstract repository for Visual Q&A.
abstract class QaRepository {
  /// Answers [question] based on [ocrText] extracted from the captured image.
  ///
  /// Answers must be grounded solely in [ocrText].  For medicine questions
  /// without supporting text, the repository must return the safe fallback
  /// phrase.
  Future<QaAnswer> answer({
    required String question,
    required String ocrText,
  });
}
