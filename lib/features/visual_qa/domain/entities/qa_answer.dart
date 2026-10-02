/// Result of a visual Q&A session.
class QaAnswer {
  const QaAnswer({
    required this.answer,
    required this.isGrounded,
    required this.sourceSentence,
  });

  /// The spoken answer.
  final String answer;

  /// Whether the answer is grounded in text actually found in the image.
  final bool isGrounded;

  /// The matching source sentence from the OCR text, or `null` if absent.
  final String? sourceSentence;
}
