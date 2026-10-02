import 'package:flutter_test/flutter_test.dart';
import 'package:visionassist_ai/features/ingredient_analyzer/data/local_ingredient_repository.dart';

void main() {
  late LocalIngredientRepository repo;

  setUp(() => repo = LocalIngredientRepository());

  group('LocalIngredientRepository - allergens', () {
    test('detects peanut', () async {
      final result = await repo.analyze('Contains peanut oil, sugar');
      expect(result.allergens, contains('Kacang'));
    });

    test('negates gluten free', () async {
      final result = await repo.analyze('gluten free snack');
      expect(result.negatedAllergens, contains('Gluten'));
      expect(result.allergens, isNot(contains('Gluten')));
    });
  });

  group('LocalIngredientRepository - expiry', () {
    test('parses EXP dd/mm/yyyy', () async {
      final result = await repo.analyze('EXP: 31/12/2025 info');
      expect(result.expiryDate, '31/12/2025');
    });

    test('parses BB mm/yyyy', () async {
      final result = await repo.analyze('BB 06/2026');
      expect(result.expiryDate, '06/2026');
    });

    test('parses Baik digunakan sebelum dd MMM yyyy', () async {
      final result =
          await repo.analyze('Baik digunakan sebelum 15 JAN 2026');
      expect(result.expiryDate, '15 JAN 2026');
    });

    test('returns null when no expiry', () async {
      final result = await repo.analyze('Produk makanan ringan');
      expect(result.expiryDate, isNull);
    });
  });

  group('LocalIngredientRepository - summary ≤ 15 words', () {
    test('summary is at most 15 words', () async {
      final longText =
          'Contains peanut wheat milk egg shellfish fish soy sesame EXP: 01/01/2026 Rp 25.000';
      final result = await repo.analyze(longText);
      final wordCount = result.summary.split(' ').length;
      expect(wordCount, lessThanOrEqualTo(16)); // +1 for ellipsis token
    });
  });

  group('LocalIngredientRepository - prices', () {
    test('parses Rp price', () async {
      final result = await repo.analyze('Harga Rp 25.000 per item');
      expect(result.prices, isNotEmpty);
      expect(result.prices.first, contains('25.000'));
    });
  });
}
