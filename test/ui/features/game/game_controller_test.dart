import 'package:cat_typing/domain/typing_session.dart';
import 'package:cat_typing/domain/typing_status.dart';
import 'package:cat_typing/ui/features/game/game_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _makeContainer(String text) {
  final container = ProviderContainer(
    overrides: [
      selectedTextProvider.overrideWithValue(text),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('GameController.build', () {
    test('produces an initial TypingSession seeded by selectedTextProvider',
        () {
      final container = _makeContainer('猫が好き');
      final session = container.read(gameControllerProvider);

      expect(session.targetText, '猫が好き');
      expect(session.typedText, '');
      expect(session.status, TypingStatus.notStarted);
      expect(session.startedAt, isNull);
      expect(session.finishedAt, isNull);
      expect(session.mistakeCount, 0);
    });
  });

  group('GameController.onConfirmedTextChanged', () {
    test('records startedAt and transitions to playing on the first keystroke',
        () {
      final container = _makeContainer('猫が好き');
      final notifier = container.read(gameControllerProvider.notifier);

      final before = DateTime.now();
      notifier.onConfirmedTextChanged('猫', '');
      final after = DateTime.now();

      final session = container.read(gameControllerProvider);
      expect(session.status, TypingStatus.playing);
      expect(session.typedText, '猫');
      expect(session.startedAt, isNotNull);
      expect(
        session.startedAt!.isBefore(before),
        isFalse,
        reason: 'startedAt should be >= the time captured before the call',
      );
      expect(session.startedAt!.isAfter(after), isFalse);
      expect(session.mistakeCount, 0);
    });

    test('does not record a mistake when the first input matches', () {
      final container = _makeContainer('猫が好き');
      final notifier = container.read(gameControllerProvider.notifier);

      notifier.onConfirmedTextChanged('猫', '');

      expect(container.read(gameControllerProvider).mistakeCount, 0);
    });

    test('records a mistake when the first input is wrong', () {
      final container = _makeContainer('猫が好き');
      final notifier = container.read(gameControllerProvider.notifier);

      notifier.onConfirmedTextChanged('犬', '');

      final session = container.read(gameControllerProvider);
      expect(session.mistakeCount, 1);
      expect(session.status, TypingStatus.playing);
      expect(session.typedText, '犬');
    });

    test(
        'records one mistake per wrong character in the newly added '
        'substring', () {
      final container = _makeContainer('猫が好き');
      final notifier = container.read(gameControllerProvider.notifier);

      // 猫 is correct, がX is "が" (correct) and "X" (wrong) -> +1 mistake
      notifier.onConfirmedTextChanged('猫', '');
      notifier.onConfirmedTextChanged('猫がX', '猫');

      final session = container.read(gameControllerProvider);
      expect(session.mistakeCount, 1);
      expect(session.typedText, '猫がX');
    });

    test('counts every character past target.length as a mistake', () {
      final container = _makeContainer('猫');
      final notifier = container.read(gameControllerProvider.notifier);

      notifier.onConfirmedTextChanged('猫が好きすぎる', '');

      final session = container.read(gameControllerProvider);
      // 猫 is correct, がすきすぎる (6 chars) are all past target.length -> 6 mistakes
      expect(session.mistakeCount, 6);
    });

    test('BackSpace shortens typedText without changing mistakeCount', () {
      final container = _makeContainer('猫が好き');
      final notifier = container.read(gameControllerProvider.notifier);

      notifier.onConfirmedTextChanged('猫がX', '');
      final mistakeBefore =
          container.read(gameControllerProvider).mistakeCount;

      notifier.onConfirmedTextChanged('猫が', '猫がX');

      final session = container.read(gameControllerProvider);
      expect(session.typedText, '猫が');
      expect(session.mistakeCount, mistakeBefore);
    });

    test('BackSpace does not reset startedAt', () {
      final container = _makeContainer('猫が好き');
      final notifier = container.read(gameControllerProvider.notifier);

      notifier.onConfirmedTextChanged('猫', '');
      final startedAt = container.read(gameControllerProvider).startedAt;

      notifier.onConfirmedTextChanged('', '猫');

      expect(container.read(gameControllerProvider).startedAt, startedAt);
    });

    test('transitions to finished and records finishedAt when input matches',
        () {
      final container = _makeContainer('猫');
      final notifier = container.read(gameControllerProvider.notifier);

      final before = DateTime.now();
      notifier.onConfirmedTextChanged('猫', '');
      final after = DateTime.now();

      final session = container.read(gameControllerProvider);
      expect(session.status, TypingStatus.finished);
      expect(session.isCompleted, isTrue);
      expect(session.finishedAt, isNotNull);
      expect(session.finishedAt!.isBefore(before), isFalse);
      expect(session.finishedAt!.isAfter(after), isFalse);
    });

    test('ignores further input after finishing', () {
      final container = _makeContainer('猫');
      final notifier = container.read(gameControllerProvider.notifier);

      notifier.onConfirmedTextChanged('猫', '');
      final finishedSession = container.read(gameControllerProvider);

      notifier.onConfirmedTextChanged('猫が好き', '猫');

      final session = container.read(gameControllerProvider);
      expect(session.typedText, finishedSession.typedText);
      expect(session.status, TypingStatus.finished);
      expect(session.finishedAt, finishedSession.finishedAt);
      expect(session.mistakeCount, finishedSession.mistakeCount);
    });

    test('does not advance startedAt on subsequent keystrokes', () {
      final container = _makeContainer('猫が好き');
      final notifier = container.read(gameControllerProvider.notifier);

      notifier.onConfirmedTextChanged('猫', '');
      final startedAt = container.read(gameControllerProvider).startedAt;

      notifier.onConfirmedTextChanged('猫が', '猫');

      expect(container.read(gameControllerProvider).startedAt, startedAt);
    });

    test('no-op when confirmed and previous are both empty', () {
      final container = _makeContainer('猫が好き');
      final notifier = container.read(gameControllerProvider.notifier);

      notifier.onConfirmedTextChanged('', '');

      final session = container.read(gameControllerProvider);
      expect(session.status, TypingStatus.notStarted);
      expect(session.startedAt, isNull);
      expect(session.typedText, '');
      expect(session.mistakeCount, 0);
    });
  });

  group('GameController.reset', () {
    test('returns the session to its initial state', () {
      final container = _makeContainer('猫');
      final notifier = container.read(gameControllerProvider.notifier);

      notifier.onConfirmedTextChanged('犬', '');
      expect(container.read(gameControllerProvider).status,
          TypingStatus.playing);
      expect(container.read(gameControllerProvider).mistakeCount, 1);

      notifier.reset();

      final session = container.read(gameControllerProvider);
      expect(session.targetText, '猫');
      expect(session.typedText, '');
      expect(session.status, TypingStatus.notStarted);
      expect(session.startedAt, isNull);
      expect(session.finishedAt, isNull);
      expect(session.mistakeCount, 0);
    });

    test('reset after finish allows starting over', () {
      final container = _makeContainer('猫');
      final notifier = container.read(gameControllerProvider.notifier);

      notifier.onConfirmedTextChanged('猫', '');
      expect(container.read(gameControllerProvider).status,
          TypingStatus.finished);

      notifier.reset();
      notifier.onConfirmedTextChanged('犬', '');

      final session = container.read(gameControllerProvider);
      expect(session.status, TypingStatus.playing);
      expect(session.mistakeCount, 1);
    });
  });

  group('selectedTextProvider', () {
    test('falls back to the first kCatTypingTexts entry without overrides', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final text = container.read(selectedTextProvider);
      expect(text, isNotEmpty);
    });
  });

  group('integration: typing a full sentence', () {
    test('advances progress and finishes cleanly without mistakes', () {
      final container = _makeContainer('猫');
      final notifier = container.read(gameControllerProvider.notifier);

      notifier.onConfirmedTextChanged('猫', '');

      final session = container.read(gameControllerProvider);
      expect(session.progress, 1.0);
      expect(session.accuracy, 1.0);
      expect(session.status, TypingStatus.finished);
    });

    test('mistakes followed by corrections still allow finishing', () {
      final container = _makeContainer('猫が好き');
      final notifier = container.read(gameControllerProvider.notifier);

      notifier.onConfirmedTextChanged('猫', '');
      notifier.onConfirmedTextChanged('猫X', '猫');
      notifier.onConfirmedTextChanged('猫', '猫X');
      notifier.onConfirmedTextChanged('猫が', '猫');
      notifier.onConfirmedTextChanged('猫が好', '猫が');
      notifier.onConfirmedTextChanged('猫が好き', '猫が好');

      final session = container.read(gameControllerProvider);
      expect(session.status, TypingStatus.finished);
      expect(session.mistakeCount, 1);
      expect(session.isCompleted, isTrue);
      // accuracy = 4 runes / (4 + 1) = 0.8
      expect(session.accuracy, closeTo(0.8, 1e-9));
    });
  });

  group(
    'GameController in isolation - independent containers',
    () {
      test('do not share state', () {
        final containerA = _makeContainer('猫');
        final containerB = _makeContainer('犬');

        containerA
            .read(gameControllerProvider.notifier)
            .onConfirmedTextChanged('猫', '');

        expect(containerA.read(gameControllerProvider).status,
            TypingStatus.finished);
        expect(containerB.read(gameControllerProvider).status,
            TypingStatus.notStarted);
      });
    },
  );

  group('TypingSession reference identity sanity', () {
    test('emits a new TypingSession instance on each state transition', () {
      final container = _makeContainer('猫が好き');
      final notifier = container.read(gameControllerProvider.notifier);
      final TypingSession initial = container.read(gameControllerProvider);

      notifier.onConfirmedTextChanged('猫', '');
      final TypingSession next = container.read(gameControllerProvider);

      expect(identical(initial, next), isFalse);
    });
  });
}
