import 'package:cat_typing/domain/typing_session.dart';
import 'package:cat_typing/domain/typing_status.dart';
import 'package:cat_typing/ui/features/game/game_controller.dart';
import 'package:cat_typing/ui/features/game/widgets/cat_face.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/seeded_game_controller.dart';

Future<void> _pump(WidgetTester tester, TypingSession session) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: seededOverrides(session),
      child: const MaterialApp(
        home: Scaffold(body: CatFace()),
      ),
    ),
  );
}

Future<ProviderContainer> _pumpWithContainer(
  WidgetTester tester,
  TypingSession session,
) async {
  final container = ProviderContainer(overrides: seededOverrides(session));
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: CatFace()),
      ),
    ),
  );
  return container;
}

void main() {
  group('CatFace progress-linked emoji', () {
    testWidgets('shows 🐱 when progress is 0%', (tester) async {
      await _pump(tester, const TypingSession(targetText: '猫が好きなのだ'));
      expect(find.text('🐱'), findsOneWidget);
    });

    testWidgets('still shows 🐱 just below 30%', (tester) async {
      // target = 10 chars, typed = 2 chars -> progress 0.2 < 0.3
      await _pump(
        tester,
        const TypingSession(targetText: 'abcdefghij', typedText: 'ab'),
      );
      expect(find.text('🐱'), findsOneWidget);
    });

    testWidgets('shows 😺 at exactly 30%', (tester) async {
      // progress = 3/10 = 0.3
      await _pump(
        tester,
        const TypingSession(targetText: 'abcdefghij', typedText: 'abc'),
      );
      expect(find.text('😺'), findsOneWidget);
    });

    testWidgets('shows 😺 in the 30%-70% band', (tester) async {
      // progress = 4/7 ≈ 0.57
      await _pump(
        tester,
        const TypingSession(targetText: '猫が好きなのだ', typedText: '猫が好き'),
      );
      expect(find.text('😺'), findsOneWidget);
    });

    testWidgets('shows 😻 at exactly 70%', (tester) async {
      // progress = 7/10 = 0.7
      await _pump(
        tester,
        const TypingSession(targetText: 'abcdefghij', typedText: 'abcdefg'),
      );
      expect(find.text('😻'), findsOneWidget);
    });

    testWidgets('shows 😻 in the 70%-100% band', (tester) async {
      // progress = 6/7 ≈ 0.857, not completed
      await _pump(
        tester,
        const TypingSession(targetText: '猫が好きなのだ', typedText: '猫が好きなの'),
      );
      expect(find.text('😻'), findsOneWidget);
    });

    testWidgets('shows 😹 once typing is completed', (tester) async {
      await _pump(
        tester,
        const TypingSession(
          targetText: '猫',
          typedText: '猫',
          status: TypingStatus.finished,
        ),
      );
      expect(find.text('😹'), findsOneWidget);
    });

    testWidgets(
        'prefers the completion emoji even when finished flag '
        'is not yet set', (tester) async {
      // The emoji is decided by isCompleted, which depends only on the
      // text comparison – so finished status is not a precondition.
      await _pump(
        tester,
        const TypingSession(targetText: '猫', typedText: '猫'),
      );
      expect(find.text('😹'), findsOneWidget);
    });
  });

  group('CatFace mistake reaction', () {
    testWidgets('flashes 😿 right after a mistake then returns to 🐱',
        (tester) async {
      final container = await _pumpWithContainer(
        tester,
        const TypingSession(targetText: '猫'),
      );

      container
          .read(gameControllerProvider.notifier)
          .onConfirmedTextChanged('X', '');
      await tester.pump();

      expect(find.text('😿'), findsOneWidget);

      // Advance past the 500ms mistake timer and the AnimatedSwitcher fade.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('😿'), findsNothing);
      expect(find.text('🐱'), findsOneWidget);
    });

    testWidgets('does not flash 😿 when typedText changes without new mistakes',
        (tester) async {
      final container = await _pumpWithContainer(
        tester,
        const TypingSession(targetText: '猫が好き'),
      );

      // Correct keystroke – mistakeCount stays at 0.
      container
          .read(gameControllerProvider.notifier)
          .onConfirmedTextChanged('猫', '');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('😿'), findsNothing);
    });
  });
}
