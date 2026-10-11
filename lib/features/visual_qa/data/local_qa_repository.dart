import 'package:visionassist_ai/features/visual_qa/domain/entities/qa_answer.dart';
import 'package:visionassist_ai/features/visual_qa/domain/repositories/qa_repository.dart';

/// Local keyword-retrieval [QaRepository].
///
/// **Safety rule**: answers are grounded only in text actually found in
/// [ocrText].  Medicine questions without supporting text return the
/// standardised safe-fallback phrase.  This implementation never infers
/// or invents dosage information.
///
/// Mirrors the backend (`app/guards/grounding.py` and the `visual_qa` flow):
/// * the "ask the pharmacist" phrase is only for medicine questions; every
///   other unanswerable question gets a neutral phrase, and
/// * a general question ("jelaskan apa yang saya lihat") reads the recognised
///   text back instead of being refused.
class LocalQaRepository implements QaRepository {
  static const String _safetyFallback =
      'Saya tidak yakin, silakan tanyakan apoteker.';

  /// Neutral phrase for non-medicine questions the text cannot answer.
  static const String _noAnswerFallback =
      'Saya tidak menemukan jawabannya di teks yang terbaca.';

  /// Non-medicine question but nothing was recognised in the image.
  static const String _noTextFallback = 'Saya tidak menemukan teks pada gambar.';

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

  /// General "what is this / read it to me" questions that ask for the whole
  /// text rather than one fact.
  static final List<RegExp> _generalTriggers = [
    RegExp(r'\bjelaskan\b', caseSensitive: false),
    RegExp(r'\bapa ini\b', caseSensitive: false),
    RegExp(r'\bini apa\b', caseSensitive: false),
    RegExp(r'\bapa yang (saya |aku )?(lihat|terlihat)\b', caseSensitive: false),
    RegExp(r'\bbaca(kan)?\b', caseSensitive: false),
    RegExp(r'\bsemuanya\b', caseSensitive: false),
    RegExp(r'\bwhat is this\b', caseSensitive: false),
    RegExp(r'\bread (it|this|all)\b', caseSensitive: false),
    RegExp(r'\bdescribe\b', caseSensitive: false),
  ];

  @override
  Future<QaAnswer> answer({
    required String question,
    required String ocrText,
  }) async {
    final isMedicineQuestion =
        _medicineTriggers.any((rx) => rx.hasMatch(question));
    final isGeneralQuestion =
        _generalTriggers.any((rx) => rx.hasMatch(question));

    if (ocrText.trim().isEmpty) {
      return _refuse(isMedicineQuestion ? _safetyFallback : _noTextFallback);
    }

    // General question: read the recognised text back, wording unchanged.
    // A medicine-trigger question keeps the stricter sentence-matching below.
    if (isGeneralQuestion && !isMedicineQuestion) {
      final text = ocrText.trim().replaceAll(RegExp(r'\s+'), ' ');
      return QaAnswer(
        answer: text,
        isGrounded: true,
        sourceSentence: text,
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

    // No grounding found: pharmacist phrase for medicine, neutral otherwise.
    if (bestSentence == null || bestScore == 0) {
      return _refuse(isMedicineQuestion ? _safetyFallback : _noAnswerFallback);
    }

    return QaAnswer(
      answer: bestSentence,
      isGrounded: true,
      sourceSentence: bestSentence,
    );
  }

  static QaAnswer _refuse(String phrase) => QaAnswer(
        answer: phrase,
        isGrounded: false,
        sourceSentence: null,
      );
}
