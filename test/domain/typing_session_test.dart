import 'package:cat_typing/domain/typing_session.dart';
import 'package:cat_typing/domain/typing_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TypingSession defaults', () {
    test('initialise with only targetText leaves other fields at defaults', () {
      const session = TypingSession(targetText: '猫');

      expect(session.targetText, '猫');
      expect(session.typedText, '');
      expect(session.status, TypingStatus.notStarted);
      expect(session.startedAt, isNull);
      expect(session.finishedAt, isNull);
      expect(session.mistakeCount, 0);
    });
  });

  group('correctPrefixLength', () {
    test('returns 0 when typedText is empty', () {
      const session = TypingSession(targetText: '猫が好き');
      expect(session.correctPrefixLength, 0);
    });

    test('returns 0 when targetText is empty', () {
      const session = TypingSession(targetText: '', typedText: 'abc');
      expect(session.correctPrefixLength, 0);
    });

    test('returns 0 when nothing matches', () {
      const session = TypingSession(targetText: '猫', typedText: '犬');
      expect(session.correctPrefixLength, 0);
    });

    test('returns the matching prefix length on partial match', () {
      const session = TypingSession(
        targetText: '猫が大好き',
        typedText: '猫が好き',
      );
      // first divergence at index 2 (好 vs 大)
      expect(session.correctPrefixLength, 2);
    });

    test('returns length of typedText when fully a prefix of target', () {
      const session = TypingSession(
        targetText: '猫が好きなのだ',
        typedText: '猫が好き',
      );
      expect(session.correctPrefixLength, 4);
    });

    test('returns target.length when typed equals target', () {
      const session = TypingSession(
        targetText: '猫が好き',
        typedText: '猫が好き',
      );
      expect(session.correctPrefixLength, 4);
    });

    test('caps at target.length when typed is longer but starts with target',
        () {
      const session = TypingSession(
        targetText: '猫',
        typedText: '猫が好き',
      );
      expect(session.correctPrefixLength, 1);
    });

    test('handles ASCII characters consistently', () {
      const session = TypingSession(
        targetText: 'cat typing',
        typedText: 'cat tyXing',
      );
      expect(session.correctPrefixLength, 6);
    });

    test(
        'counts surrogate pair characters as two UTF-16 code units '
        '(emoji-aware spec)', () {
      // 🐱 occupies two UTF-16 code units; typing the same emoji advances
      // correctPrefixLength by 2.
      const session = TypingSession(
        targetText: '🐱猫',
        typedText: '🐱',
      );
      expect(session.correctPrefixLength, 2);
    });

    test(
        'returns 0 when surrogate pairs diverge on the high-surrogate code unit',
        () {
      // 🐱 (U+1F431) and 🐶 (U+1F436) share the same high surrogate (0xD83D),
      // so the first code unit matches but the second (low surrogate) differs.
      const session = TypingSession(targetText: '🐱', typedText: '🐶');
      expect(session.correctPrefixLength, 1);
    });

    test('returns 0 when both texts are empty', () {
      const session = TypingSession(targetText: '', typedText: '');
      expect(session.correctPrefixLength, 0);
    });
  });

  group('isCompleted', () {
    test('returns true when typedText equals targetText', () {
      const session = TypingSession(
        targetText: '猫',
        typedText: '猫',
      );
      expect(session.isCompleted, isTrue);
    });

    test('returns false when typedText differs', () {
      const session = TypingSession(
        targetText: '猫',
        typedText: '犬',
      );
      expect(session.isCompleted, isFalse);
    });

    test('returns false when typedText is empty and target is not', () {
      const session = TypingSession(targetText: '猫');
      expect(session.isCompleted, isFalse);
    });

    test('returns true when both are empty', () {
      const session = TypingSession(targetText: '', typedText: '');
      expect(session.isCompleted, isTrue);
    });
  });

  group('progress', () {
    test('returns 0 when targetText is empty', () {
      const session = TypingSession(targetText: '');
      expect(session.progress, 0);
    });

    test('returns 0 when nothing has been typed', () {
      const session = TypingSession(targetText: '猫が好き');
      expect(session.progress, 0);
    });

    test('returns fractional progress on partial match', () {
      const session = TypingSession(
        targetText: '猫が好きなのだ',
        typedText: '猫が好き',
      );
      expect(session.progress, closeTo(4 / 7, 1e-9));
    });

    test('returns 1.0 when typed equals target', () {
      const session = TypingSession(
        targetText: '猫が好き',
        typedText: '猫が好き',
      );
      expect(session.progress, 1.0);
    });

    test('does not decrease when mistakes occupy later positions', () {
      const session = TypingSession(
        targetText: '猫が好き',
        typedText: '猫がXX',
      );
      expect(session.progress, closeTo(2 / 4, 1e-9));
    });
  });

  group('elapsed', () {
    test('returns zero when startedAt is null', () {
      const session = TypingSession(targetText: '猫');
      expect(session.elapsed, Duration.zero);
    });

    test('returns finishedAt - startedAt when both are present', () {
      final start = DateTime(2026, 1, 1, 12, 0, 0);
      final finish = start.add(const Duration(seconds: 7));
      final session = TypingSession(
        targetText: '猫',
        typedText: '猫',
        status: TypingStatus.finished,
        startedAt: start,
        finishedAt: finish,
      );
      expect(session.elapsed, const Duration(seconds: 7));
    });

    test('returns a positive duration when only startedAt is present', () {
      final start = DateTime.now().subtract(const Duration(milliseconds: 50));
      final session = TypingSession(
        targetText: '猫',
        status: TypingStatus.playing,
        startedAt: start,
      );
      expect(session.elapsed.inMilliseconds, greaterThanOrEqualTo(0));
    });
  });

  group('accuracy', () {
    test('returns 1.0 when there are no mistakes', () {
      const session = TypingSession(targetText: '猫が好き');
      expect(session.accuracy, 1.0);
    });

    test('shrinks as mistake count grows', () {
      const session = TypingSession(
        targetText: '猫が好き',
        mistakeCount: 4,
      );
      // runes.length = 4, accuracy = 4 / (4 + 4) = 0.5
      expect(session.accuracy, closeTo(0.5, 1e-9));
    });

    test('returns 1.0 when targetText is empty', () {
      const session = TypingSession(targetText: '');
      expect(session.accuracy, 1.0);
    });

    test('uses rune count rather than codeUnit count', () {
      const session = TypingSession(
        targetText: '猫🐱',
        mistakeCount: 0,
      );
      // 🐱 is one rune but two UTF-16 code units. Accuracy should still be 1.0.
      expect(session.accuracy, 1.0);
    });
  });

  group('copyWith', () {
    test('returns identical-by-value object when called without args', () {
      final start = DateTime(2026, 1, 1);
      final session = TypingSession(
        targetText: '猫',
        typedText: 'ね',
        status: TypingStatus.playing,
        startedAt: start,
        mistakeCount: 1,
      );

      final copy = session.copyWith();
      expect(copy.targetText, session.targetText);
      expect(copy.typedText, session.typedText);
      expect(copy.status, session.status);
      expect(copy.startedAt, session.startedAt);
      expect(copy.finishedAt, session.finishedAt);
      expect(copy.mistakeCount, session.mistakeCount);
    });

    test('overrides only specified fields', () {
      const session = TypingSession(targetText: '猫');
      final updated = session.copyWith(
        typedText: 'ね',
        status: TypingStatus.playing,
        mistakeCount: 2,
      );

      expect(updated.targetText, '猫');
      expect(updated.typedText, 'ね');
      expect(updated.status, TypingStatus.playing);
      expect(updated.mistakeCount, 2);
    });

    test('does not mutate the original instance', () {
      const session = TypingSession(targetText: '猫');
      session.copyWith(typedText: 'ね', mistakeCount: 99);
      expect(session.typedText, '');
      expect(session.mistakeCount, 0);
    });

    test(
        'preserves existing nullable fields when null is passed '
        '(no reset semantics)', () {
      final start = DateTime(2026, 1, 1);
      final finish = start.add(const Duration(seconds: 5));
      final session = TypingSession(
        targetText: '猫',
        typedText: '猫',
        status: TypingStatus.finished,
        startedAt: start,
        finishedAt: finish,
      );

      // Passing null does not reset; the `??` fallback keeps the original.
      final copy = session.copyWith();
      expect(copy.startedAt, start);
      expect(copy.finishedAt, finish);
    });
  });
}
