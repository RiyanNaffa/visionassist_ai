import '../entities/qa_answer.dart';
import '../repositories/qa_repository.dart';

/// Use case: answer a spoken question grounded in the captured image text.
class AnswerVisualQuestion {
  const AnswerVisualQuestion(this._repository);

  final QaRepository _repository;

  /// Executes the Q&A use case.
  Future<QaAnswer> call({
    required String question,
    required String ocrText,
  }) =>
      _repository.answer(question: question, ocrText: ocrText);
}
