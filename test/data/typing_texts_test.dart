import 'package:cat_typing/data/typing_texts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kCatTypingTexts', () {
    test('contains between 3 and 5 entries as the design specifies', () {
      expect(kCatTypingTexts.length, inInclusiveRange(3, 5));
    });

    test('every entry is non-empty', () {
      for (final text in kCatTypingTexts) {
        expect(text, isNotEmpty);
      }
    });

    test('every entry has a reasonable length for a typing exercise', () {
      // The CLAUDE.md design suggests ~80-150 characters per entry.
      for (final text in kCatTypingTexts) {
        expect(text.runes.length, inInclusiveRange(60, 200));
      }
    });

    test('no duplicate entries', () {
      expect(kCatTypingTexts.toSet().length, kCatTypingTexts.length);
    });

    test('every entry references the cat theme', () {
      for (final text in kCatTypingTexts) {
        expect(text.contains('猫'), isTrue, reason: 'Expected 猫 in: $text');
      }
    });
  });
}
