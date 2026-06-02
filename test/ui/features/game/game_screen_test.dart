import 'package:cat_typing/domain/typing_status.dart';
import 'package:cat_typing/ui/features/game/game_controller.dart';
import 'package:cat_typing/ui/features/game/game_screen.dart';
import 'package:cat_typing/ui/features/game/widgets/cat_face.dart';
import 'package:cat_typing/ui/features/game/widgets/progress_header.dart';
import 'package:cat_typing/ui/features/game/widgets/target_text_view.dart';
import 'package:cat_typing/ui/features/result/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  String target = '猫',
}) async {
  final container = ProviderContainer(
    overrides: [
      selectedTextProvider.overrideWithValue(target),
      tickerProvider.overrideWith((ref) => const Stream<int>.empty()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameScreen()),
    ),
  );
  return container;
}

TextEditingController _controllerOf(WidgetTester tester) {
  return tester.widget<TextField>(find.byType(TextField)).controller!;
}

void main() {
  group('GameScreen layout', () {
    testWidgets('shows all the core widgets at start', (tester) async {
      await _pump(tester);

      expect(find.byType(ProgressHeader), findsOneWidget);
      expect(find.byType(CatFace), findsOneWidget);
      expect(find.byType(TargetTextView), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('TextField is configured for IME-friendly input',
        (tester) async {
      await _pump(tester);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.autofocus, isTrue);
      expect(textField.maxLines, isNull);
      expect(textField.enableSuggestions, isFalse);
      expect(textField.autocorrect, isFalse);
    });
  });

  group('GameScreen IME handling', () {
    testWidgets('does not advance state while text is in composing state',
        (tester) async {
      final container = await _pump(tester, target: '猫');
      final controller = _controllerOf(tester);

      // Simulate IME mid-conversion: hiragana typed but not confirmed yet.
      controller.value = const TextEditingValue(
        text: 'ねこ',
        composing: TextRange(start: 0, end: 2),
      );
      await tester.pump();

      final session = container.read(gameControllerProvider);
      expect(session.status, TypingStatus.notStarted);
      expect(session.typedText, '');
    });

    testWidgets('advances state once composing collapses (IME confirmation)',
        (tester) async {
      final container = await _pump(tester, target: '猫');
      final controller = _controllerOf(tester);

      // Hiragana being composed: no state change yet.
      controller.value = const TextEditingValue(
        text: 'ねこ',
        composing: TextRange(start: 0, end: 2),
      );
      await tester.pump();
      expect(container.read(gameControllerProvider).typedText, '');

      // Conversion confirmed: composing becomes empty/collapsed.
      controller.value = const TextEditingValue(
        text: '猫',
        composing: TextRange.empty,
      );
      await tester.pump();

      final session = container.read(gameControllerProvider);
      expect(session.typedText, '猫');
      expect(session.status, TypingStatus.finished);
    });

    testWidgets('ignores duplicate confirmations of the same text',
        (tester) async {
      final container = await _pump(tester, target: '猫が好き');
      final controller = _controllerOf(tester);

      controller.value = const TextEditingValue(text: '猫');
      await tester.pump();
      final session1 = container.read(gameControllerProvider);

      // Same text re-applied with empty composing should be a no-op.
      controller.value = const TextEditingValue(text: '猫');
      await tester.pump();
      final session2 = container.read(gameControllerProvider);

      expect(session2.typedText, session1.typedText);
      expect(session2.mistakeCount, session1.mistakeCount);
      expect(session2.startedAt, session1.startedAt);
    });
  });

  group('GameScreen integration with the controller', () {
    testWidgets(
        'entering the full target text transitions to ResultScreen via '
        'pushReplacement', (tester) async {
      await _pump(tester, target: '猫');

      await tester.enterText(find.byType(TextField), '猫');
      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsNothing);
      expect(find.byType(ResultScreen), findsOneWidget);
    });

    testWidgets('partial input keeps GameScreen visible', (tester) async {
      final container = await _pump(tester, target: '猫が好き');

      await tester.enterText(find.byType(TextField), '猫');
      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.byType(ResultScreen), findsNothing);
      expect(
        container.read(gameControllerProvider).status,
        TypingStatus.playing,
      );
    });

    testWidgets(
        'enterText with the wrong character keeps GameScreen and counts '
        'a mistake', (tester) async {
      final container = await _pump(tester, target: '猫');

      await tester.enterText(find.byType(TextField), '犬');
      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsOneWidget);
      final session = container.read(gameControllerProvider);
      expect(session.mistakeCount, 1);
      expect(session.status, TypingStatus.playing);
    });

    testWidgets('hardware BackSpace shortens the controller text',
        (tester) async {
      final container = await _pump(tester, target: '猫が好き');

      await tester.enterText(find.byType(TextField), '猫が');
      await tester.pumpAndSettle();
      expect(container.read(gameControllerProvider).typedText, '猫が');

      final controller = _controllerOf(tester);
      controller.value = const TextEditingValue(text: '猫');
      await tester.pump();

      expect(container.read(gameControllerProvider).typedText, '猫');
    });
  });

  // Ensure we restore the platform keyboard hooks the test framework attaches.
  tearDown(() {
    TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.textInput, null);
  });
}
