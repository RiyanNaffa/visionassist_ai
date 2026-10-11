import 'package:flutter_test/flutter_test.dart';
import 'package:visionassist_ai/core/utils/allergen_checker.dart';

void main() {
  group('AllergenChecker', () {
    // ── existing cases (updated to new canonical names) ──────────────────

    test('detects peanut in English', () {
      final result = AllergenChecker.check('Contains peanut oil');
      expect(result.detected, contains('Kacang tanah'));
    });

    test('detects kacang tanah in Indonesian', () {
      final result = AllergenChecker.check('Mengandung kacang tanah');
      expect(result.detected, contains('Kacang tanah'));
    });

    test('detects gluten via gandum', () {
      final result = AllergenChecker.check('Dibuat dari tepung gandum');
      expect(result.detected, contains('Gluten'));
    });

    test('negates gluten free', () {
      final result = AllergenChecker.check('gluten free product');
      expect(result.negated, contains('Gluten'));
      expect(result.detected, isNot(contains('Gluten')));
    });

    test('negates bebas gluten', () {
      final result = AllergenChecker.check('bebas gluten');
      expect(result.negated, contains('Gluten'));
    });

    test('negates tidak mengandung susu', () {
      final result = AllergenChecker.check('tidak mengandung susu');
      expect(result.negated, contains('Susu'));
    });

    test('detects multiple allergens', () {
      final result = AllergenChecker.check(
        'Contains wheat, milk and egg',
      );
      expect(result.detected, containsAll(['Gluten', 'Susu', 'Telur']));
    });

    test('no allergens in plain text', () {
      final result = AllergenChecker.check('Air mineral, garam');
      expect(result.detected, isEmpty);
    });

    test('detects crustacean via udang', () {
      final result = AllergenChecker.check('Mengandung udang');
      expect(result.detected, contains('Krustasea'));
    });

    test('detects soy via kedelai', () {
      final result = AllergenChecker.check('Kedelai organik');
      expect(result.detected, contains('Kedelai'));
    });

    test('detects sesame via wijen', () {
      final result = AllergenChecker.check('Minyak wijen');
      expect(result.detected, contains('Wijen'));
    });

    // ── new cases ─────────────────────────────────────────────────────────

    test('donuts is not kacang', () {
      // "donuts" must not be matched as a nut keyword
      final result = AllergenChecker.check('Donat cokelat donuts');
      expect(result.detected, isNot(contains('Kacang tanah')));
      expect(result.detected, isNot(contains('Kacang pohon')));
    });

    test('santan is not susu', () {
      // "santan" (coconut cream) must not trigger Susu
      final result = AllergenChecker.check('Mengandung santan kelapa');
      expect(result.detected, isNot(contains('Susu')));
    });

    test('terong is not telur', () {
      // "terong" (eggplant) must not trigger Telur
      final result = AllergenChecker.check('Sayuran terong ungu');
      expect(result.detected, isNot(contains('Telur')));
    });

    test('kenari is kacang pohon', () {
      final result = AllergenChecker.check('Mengandung kenari');
      expect(result.detected, contains('Kacang pohon'));
    });

    // ── additional synonym coverage ───────────────────────────────────────

    test('detects sesame oil (sesame oil)', () {
      final result = AllergenChecker.check('Contains sesame oil');
      expect(result.detected, contains('Wijen'));
    });

    test('detects sesame extract', () {
      final result = AllergenChecker.check('sesame extract added');
      expect(result.detected, contains('Wijen'));
    });

    test('detects sulfite via ins 220', () {
      final result = AllergenChecker.check('Pengawet INS 220');
      expect(result.detected, contains('Sulfit'));
    });

    test('detects mollusc via cumi', () {
      final result = AllergenChecker.check('Cumi-cumi segar');
      expect(result.detected, contains('Moluska'));
    });

    test('detects tree nut via almond', () {
      final result = AllergenChecker.check('Mengandung almond');
      expect(result.detected, contains('Kacang pohon'));
    });

    test('detects mayonnaise as telur', () {
      final result = AllergenChecker.check('Saus mayones');
      expect(result.detected, contains('Telur'));
    });
  });

  group('AllergenChecker - negation', () {
    test('"X free" after the allergen is a negation', () {
      for (final text in [
        'gluten free product',
        'Gluten-free snack',
        'lactose-free milk',
        'dairy free',
      ]) {
        final result = AllergenChecker.check(text);
        expect(result.detected, isEmpty, reason: text);
        expect(result.negated, isNotEmpty, reason: text);
      }
    });

    test('"non-dairy" is a negation', () {
      final result = AllergenChecker.check('non-dairy creamer');
      expect(result.negated, contains('Susu'));
      expect(result.detected, isNot(contains('Susu')));
    });

    test('a negation does not reach into the next sentence', () {
      final result = AllergenChecker.check('Bebas pengawet. Mengandung susu.');
      expect(result.detected, contains('Susu'));
      expect(result.negated, isNot(contains('Susu')));
    });

    test('a negation does not reach across a line break', () {
      final result = AllergenChecker.check('Tanpa pewarna\nMengandung telur');
      expect(result.detected, contains('Telur'));
    });

    test('negation still applies within one sentence', () {
      final result = AllergenChecker.check('Tanpa pewarna, bebas gluten');
      expect(result.negated, contains('Gluten'));
    });

    test('an allergen stated both ways is reported as detected', () {
      final result = AllergenChecker.check(
        'Bebas gluten. Dibuat dari tepung gandum.',
      );
      expect(result.detected, contains('Gluten'));
      expect(result.negated, isNot(contains('Gluten')));
    });

    test('a later positive mention beats an earlier negated one', () {
      final result = AllergenChecker.check('no milk added. contains milk.');
      expect(result.detected, contains('Susu'));
    });
  });
}
