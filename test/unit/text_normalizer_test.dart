import 'package:flutter_test/flutter_test.dart';
import 'package:visionassist_ai/core/utils/text_normalizer.dart';

void main() {
  group('TextNormalizer.normalize', () {
    test('lower-cases text', () {
      expect(TextNormalizer.normalize('HELLO World'), 'hello world');
    });

    test('collapses whitespace', () {
      expect(TextNormalizer.normalize('hello   world'), 'hello world');
    });

    test('removes punctuation except sentence terminators', () {
      expect(TextNormalizer.normalize('hello, world!'), 'hello world!');
    });

    test('trims leading and trailing whitespace', () {
      expect(TextNormalizer.normalize('  hi  '), 'hi');
    });
  });

  group('TextNormalizer.similarity', () {
    test('identical strings return 1.0', () {
      expect(TextNormalizer.similarity('hello world', 'hello world'), 1.0);
    });

    test('completely different strings return 0.0', () {
      expect(TextNormalizer.similarity('hello', 'world'), 0.0);
    });

    test('partial overlap returns fractional value', () {
      final sim = TextNormalizer.similarity('hello world', 'hello dart');
      expect(sim, greaterThan(0.0));
      expect(sim, lessThan(1.0));
    });

    test('two empty strings return 1.0', () {
      expect(TextNormalizer.similarity('', ''), 1.0);
    });

    test('one empty string returns 0.0', () {
      expect(TextNormalizer.similarity('hello', ''), 0.0);
    });
  });

  group('TextNormalizer.tokenize', () {
    test('returns word set', () {
      expect(TextNormalizer.tokenize('hello world'), {'hello', 'world'});
    });

    test('empty string returns empty set', () {
      expect(TextNormalizer.tokenize(''), isEmpty);
    });
  });
}
