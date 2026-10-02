import 'package:flutter_test/flutter_test.dart';
import 'package:visionassist_ai/core/utils/stable_text_filter.dart';

void main() {
  group('StableTextFilter', () {
    late StableTextFilter filter;

    setUp(() => filter = StableTextFilter());

    test('single frame never triggers speak', () {
      expect(filter.feed('Hello world'), isFalse);
    });

    test('two frames never trigger speak', () {
      filter.feed('Hello world');
      expect(filter.feed('Hello world'), isFalse);
    });

    test('three identical frames trigger speak', () {
      filter.feed('Hello world');
      filter.feed('Hello world');
      expect(filter.feed('Hello world'), isTrue);
    });

    test('does not trigger again for same text after markSpoken', () {
      filter.feed('Hello world');
      filter.feed('Hello world');
      filter.feed('Hello world');
      filter.markSpoken('Hello world');

      filter.feed('Hello world');
      filter.feed('Hello world');
      expect(filter.feed('Hello world'), isFalse);
    });

    test('triggers again after novel text', () {
      filter.feed('Hello world');
      filter.feed('Hello world');
      filter.feed('Hello world');
      filter.markSpoken('Hello world');

      filter.feed('New content here');
      filter.feed('New content here');
      expect(filter.feed('New content here'), isTrue);
    });

    test('reset clears all state', () {
      filter.feed('Hello world');
      filter.feed('Hello world');
      filter.feed('Hello world');
      filter.markSpoken('Hello world');

      filter.reset();

      filter.feed('Hello world');
      filter.feed('Hello world');
      expect(filter.feed('Hello world'), isTrue);
    });

    test('dissimilar frame restarts sequence', () {
      filter.feed('Hello world');
      filter.feed('Hello world');
      filter.feed('Completely different text'); // breaks sequence
      // need 3 more stable frames now
      filter.feed('Completely different text');
      filter.feed('Completely different text');
      expect(filter.feed('Completely different text'), isTrue);
    });
  });
}
