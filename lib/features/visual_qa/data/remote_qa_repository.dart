import '../../../core/network/proxy_client.dart';
import '../domain/entities/qa_answer.dart';
import '../domain/repositories/qa_repository.dart';

/// [QaRepository] backed by the backend proxy (`POST /v1/qa/answer`).
///
/// The proxy already runs its grounding guard, so its answer is used as-is.
/// Any failure - or an empty question / OCR text, which the proxy would
/// reject - falls back to [_fallback] (the on-device keyword matcher), so the
/// user always hears an answer and never an error.
class RemoteQaRepository implements QaRepository {
  RemoteQaRepository({
    required ProxyClient client,
    required QaRepository fallback,
  })  : _client = client,
        _fallback = fallback;

  final ProxyClient _client;
  final QaRepository _fallback;

  /// Backend request limit (see `QaAnswerRequest`).
  static const int _maxChars = 2000;

  @override
  Future<QaAnswer> answer({
    required String question,
    required String ocrText,
  }) async {
    final q = _clip(question.trim());
    final ocr = _clip(ocrText.trim());
    if (q.isEmpty || ocr.isEmpty) {
      return _fallback.answer(question: question, ocrText: ocrText);
    }

    try {
      final json = await _client.postJson('/qa/answer', {
        'question': q,
        'ocr_text': ocr,
      });
      final parsed = _parse(json);
      if (parsed != null) return parsed;
    } on ProxyException {
      // fall through to the local repository
    }
    return _fallback.answer(question: question, ocrText: ocrText);
  }

  static String _clip(String s) =>
      s.length <= _maxChars ? s : s.substring(0, _maxChars);

  static QaAnswer? _parse(Map<String, dynamic> json) {
    final answer = json['answer'];
    final grounded = json['is_grounded'];
    final source = json['source_sentence'];
    if (answer is! String || answer.trim().isEmpty) return null;
    if (grounded is! bool) return null;
    if (source != null && source is! String) return null;
    return QaAnswer(
      answer: answer.trim(),
      isGrounded: grounded,
      sourceSentence: source as String?,
    );
  }
}
