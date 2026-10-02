import 'package:flutter_test/flutter_test.dart';
import 'package:visionassist_ai/core/utils/allergen_checker.dart';

void main() {
  group('AllergenChecker', () {
    test('detects peanut in English', () {
      final result = AllergenChecker.check('Contains peanut oil');
      expect(result.detected, contains('Kacang'));
    });

    test('detects kacang in Indonesian', () {
      final result = AllergenChecker.check('Mengandung kacang tanah');
      expect(result.detected, contains('Kacang'));
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

    test('detects shellfish via udang', () {
      final result = AllergenChecker.check('Mengandung udang');
      expect(result.detected, contains('Kerang'));
    });

    test('detects soy via kedelai', () {
      final result = AllergenChecker.check('Kedelai organik');
      expect(result.detected, contains('Kedelai'));
    });

    test('detects sesame via wijen', () {
      final result = AllergenChecker.check('Minyak wijen');
      expect(result.detected, contains('Wijen'));
    });
  });
}
