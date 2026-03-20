import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/utils/name_matcher.dart';

void main() {
  group('NameMatcher.softMatch', () {
    test('matches identical names', () {
      expect(NameMatcher.softMatch('John Doe', 'John Doe'), isTrue);
    });

    test('matches case-insensitively', () {
      expect(NameMatcher.softMatch('john doe', 'JOHN DOE'), isTrue);
    });

    test('matches first two words when both have multi-word names', () {
      expect(
        NameMatcher.softMatch('John Doe Smith', 'John Doe'),
        isTrue,
      );
    });

    test('matches first word for single-word names', () {
      expect(NameMatcher.softMatch('John', 'John'), isTrue);
    });

    test('matches first word when one is single-word', () {
      expect(NameMatcher.softMatch('John', 'John Doe'), isTrue);
    });

    test('does not match different names', () {
      expect(NameMatcher.softMatch('John Doe', 'Jane Doe'), isFalse);
    });

    test('does not match completely different names', () {
      expect(NameMatcher.softMatch('Alice', 'Bob'), isFalse);
    });

    test('returns false for empty first name', () {
      expect(NameMatcher.softMatch('', 'John'), isFalse);
    });

    test('returns false for empty second name', () {
      expect(NameMatcher.softMatch('John', ''), isFalse);
    });

    test('returns false for both empty', () {
      expect(NameMatcher.softMatch('', ''), isFalse);
    });

    test('strips special characters (hyphen merges words)', () {
      // 'John-Doe' → 'johndoe' (single token), 'John Doe' → 'john doe' (two tokens)
      expect(NameMatcher.softMatch('John-Doe', 'John Doe'), isFalse);
      // Same hyphenated name matches itself
      expect(NameMatcher.softMatch('John-Doe', 'John-Doe'), isTrue);
    });

    test('trims whitespace', () {
      expect(NameMatcher.softMatch('  John Doe  ', 'John Doe'), isTrue);
    });
  });
}
