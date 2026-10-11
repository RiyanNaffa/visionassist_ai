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

    test('medicine question WITH matching text returns grounded answer',
        () async {
      final result = await repo.answer(
        question: 'Berapa dosis tablet ini?',
        ocrText: 'Aturan pakai: 1 tablet diminum 3 kali sehari setelah makan.',
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

  group('LocalQaRepository - refusal phrase', () {
    test('non-medicine question without an answer does not mention apoteker',
        () async {
      final result = await repo.answer(
        question: 'Apa warna produk ini?',
        ocrText: 'Terbuat dari bahan alami.',
      );
      expect(result.isGrounded, isFalse);
      expect(result.answer, isNot(contains('apoteker')));
      expect(result.answer, contains('tidak menemukan'));
    });

    test('non-medicine question with no recognised text says so', () async {
      final result = await repo.answer(
        question: 'Apa warna produk ini?',
        ocrText: '   ',
      );
      expect(result.isGrounded, isFalse);
      expect(result.answer, contains('tidak menemukan teks'));
    });

    test('medicine question keeps the apoteker phrase', () async {
      final result = await repo.answer(
        question: 'Berapa kali sehari diminum?',
        ocrText: 'Terbuat dari bahan alami.',
      );
      expect(result.isGrounded, isFalse);
      expect(result.answer, contains('apoteker'));
    });
  });

  group('LocalQaRepository - general questions', () {
    const ocr = 'daftar allergen di source code';

    test('"jelaskan apa yang saya lihat" reads the text back', () async {
      final result = await repo.answer(
        question: 'Jelaskan apa yang saya lihat',
        ocrText: ocr,
      );
      expect(result.isGrounded, isTrue);
      expect(result.answer, ocr);
      expect(result.sourceSentence, ocr);
    });

    test('collapses line breaks but keeps every word', () async {
      final result = await repo.answer(
        question: 'Baca semuanya',
        ocrText: 'Mengandung susu.\nEXP 10/2027\n  Rp 15.000 ',
      );
      expect(result.answer, 'Mengandung susu. EXP 10/2027 Rp 15.000');
    });

    test('works in English too', () async {
      final result = await repo.answer(question: 'What is this?', ocrText: ocr);
      expect(result.isGrounded, isTrue);
      expect(result.answer, ocr);
    });

    test('a medicine-trigger question is not read back', () async {
      final result = await repo.answer(
        question: 'Jelaskan berapa dosis obat ini',
        ocrText: ocr,
      );
      expect(result.isGrounded, isFalse);
      expect(result.answer, contains('apoteker'));
    });
  });

  group('LocalQaRepository - retrieval accuracy', () {
    const label =
        'Mengandung susu dan telur. Diproduksi oleh PT Contoh Makmur, '
        'Jakarta. Netto 250g. EXP 10/2027. Harga Rp 15.000. '
        'Simpan di tempat sejuk.';

    test('a price is returned whole, not cut at the thousands dot', () async {
      final result =
          await repo.answer(question: 'Berapa harganya?', ocrText: label);
      expect(result.isGrounded, isTrue);
      expect(result.answer, contains('15.000'));
    });

    test('an expiry question picks the sentence with the date', () async {
      final result =
          await repo.answer(question: 'Kapan expired?', ocrText: label);
      expect(result.answer, contains('10/2027'));
    });

    test('question filler words such as "ini" do not decide the answer',
        () async {
      final result = await repo.answer(
        question: 'Apa tanggal kadaluarsa produk ini?',
        ocrText: 'Produk ini mengandung kacang. Kadaluarsa: 01/01/2026.',
      );
      expect(result.answer, contains('2026'));
    });

    test('a content word still selects the matching sentence', () async {
      final result = await repo.answer(
        question: 'Di mana diproduksi?',
        ocrText: label,
      );
      expect(result.answer, contains('PT Contoh Makmur'));
    });

    test('words are matched whole, not as substrings', () async {
      // "apa" must not match inside "mengapa"/"dapat"; nothing relevant here.
      final result = await repo.answer(
        question: 'Apa warnanya?',
        ocrText: 'Produk dapat disimpan lama.',
      );
      expect(result.isGrounded, isFalse);
    });
  });
}
