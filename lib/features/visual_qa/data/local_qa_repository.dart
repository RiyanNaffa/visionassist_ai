import 'package:visionassist_ai/features/visual_qa/domain/entities/qa_answer.dart';
import 'package:visionassist_ai/features/visual_qa/domain/repositories/qa_repository.dart';

/// Local keyword-retrieval [QaRepository].
///
/// **Safety rule**: answers are grounded only in text actually found in
/// [ocrText].  Medicine questions without supporting text return the
/// standardised safe-fallback phrase.  This implementation never infers
/// or invents dosage information.
class LocalQaRepository implements QaRepository {
  static const String _safetyFallback =
      'Saya tidak yakin, silakan tanyakan apoteker.';

  /// Medicine-related keyword triggers.
  static final List<RegExp> _medicineTriggers = [
    RegExp(r'\bdosis\b', caseSensitive: false),
    RegExp(r'\bdosage\b', caseSensitive: false),
    RegExp(r'\bdiminum\b', caseSensitive: false),
    RegExp(r'\btake\b', caseSensitive: false),
    RegExp(r'\bkali sehari\b', caseSensitive: false),
    RegExp(r'\bfrekuensi\b', caseSensitive: false),
    RegExp(r'\bfrequency\b', caseSensitive: false),
    RegExp(r'\bberapa\b', caseSensitive: false),
    RegExp(r'\bhow many\b', caseSensitive: false),
    RegExp(r'\btablet\b', caseSensitive: false),
    RegExp(r'\bkapsul\b', caseSensitive: false),
    RegExp(r'\baturan pakai\b', caseSensitive: false),
  ];

  @override
  Future<QaAnswer> answer({
    required String question,
    required String ocrText,
  }) async {
    final isMedicineQuestion =
        _medicineTriggers.any((rx) => rx.hasMatch(question));

    if (ocrText.trim().isEmpty) {
      return QaAnswer(
        answer: _safetyFallback,
        isGrounded: false,
        sourceSentence: null,
      );
    }

    // Split OCR text into sentences for retrieval.
    final sentences = ocrText
        .split(RegExp(r'(?<=[.?!\n])\s*'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Simple keyword match: find the sentence most relevant to the question.
    final questionWords = question
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((w) => w.length > 2)
        .toSet();

    String? bestSentence;
    var bestScore = 0;

    for (final sentence in sentences) {
      final sentenceLower = sentence.toLowerCase();
      final score =
          questionWords.where((w) => sentenceLower.contains(w)).length;
      if (score > bestScore) {
        bestScore = score;
        bestSentence = sentence;
      }
    }

    // If medicine question and no grounding found → safety fallback.
    if (isMedicineQuestion && (bestSentence == null || bestScore == 0)) {
      return QaAnswer(
        answer: _safetyFallback,
        isGrounded: false,
        sourceSentence: null,
      );
    }

    if (bestSentence == null || bestScore == 0) {
      return QaAnswer(
        answer: _safetyFallback,
        isGrounded: false,
        sourceSentence: null,
      );
    }

    return QaAnswer(
      answer: bestSentence,
      isGrounded: true,
      sourceSentence: bestSentence,
    );
  }
}
