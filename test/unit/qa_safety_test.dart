import 'package:flutter_test/flutter_test.dart';
import 'package:visionassist_ai/features/visual_qa/data/local_qa_repository.dart';

void main() {
  late LocalQaRepository repo;

  setUp(() => repo = LocalQaRepository());

  group('LocalQaRepository - safety rules', () {
    test('empty OCR returns safety fallback', () async {
      final result = await repo.answer(
        question: 'Berapa dosis obat ini?',
        ocrText: '',
      );
      expect(result.isGrounded, isFalse);
      expect(result.answer, contains('apoteker'));
    });

    test('medicine question without matching text returns fallback', () async {
      final result = await repo.answer(
        question: 'Berapa dosis obat ini?',
        ocrText: 'Produk makanan ringan rasa keju.',
      );
      expect(result.isGrounded, isFalse);
      expect(result.answer, contains('apoteker'));
    });

    test('medicine question WITH matching text returns grounded answer', () async {
      final result = await repo.answer(
        question: 'Berapa dosis tablet ini?',
        ocrText:
            'Aturan pakai: 1 tablet diminum 3 kali sehari setelah makan.',
      );
      expect(result.isGrounded, isTrue);
      expect(result.sourceSentence, isNotNull);
    });
  });

  group('LocalQaRepository - keyword retrieval', () {
    test('returns most relevant sentence', () async {
      const text =
          'Produk ini mengandung kacang. Kadaluarsa: 01/01/2026. Harga Rp 15.000.';
      final result = await repo.answer(
        question: 'Apa tanggal kadaluarsa produk ini?',
        ocrText: text,
      );
      expect(result.answer, contains('2026'));
    });

    test('returns fallback when no relevant sentence found', () async {
      final result = await repo.answer(
        question: 'Apa warna produk ini?',
        ocrText: 'Terbuat dari bahan alami.',
      );
      expect(result.isGrounded, isFalse);
    });
  });
}
