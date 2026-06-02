import 'package:cat_typing/data/typing_texts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kCatTypingTexts', () {
    test('contains 50 entries as the design specifies', () {
      expect(kCatTypingTexts.length, 50);
    });

    test('every entry is non-empty', () {
      for (final text in kCatTypingTexts) {
        expect(text, isNotEmpty);
      }
    });

    test('every entry has a reasonable length for a typing exercise', () {
      for (final text in kCatTypingTexts) {
        expect(text.runes.length, inInclusiveRange(200, 300));
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
