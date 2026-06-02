import 'package:cat_typing/domain/typing_session.dart';
import 'package:cat_typing/ui/features/game/widgets/target_text_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/seeded_game_controller.dart';

Future<void> _pump(WidgetTester tester, TypingSession session) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: seededOverrides(session),
      child: const MaterialApp(
        home: Scaffold(body: TargetTextView()),
      ),
    ),
  );
}

TextSpan _rootSpan(WidgetTester tester) {
  final richText = tester.widget<RichText>(
    find.descendant(
      of: find.byType(TargetTextView),
      matching: find.byType(RichText),
    ),
  );
  return richText.text as TextSpan;
}

void main() {
  group('TargetTextView', () {
    testWidgets('shows only the remaining segment when nothing typed',
        (tester) async {
      await _pump(tester, const TypingSession(targetText: '猫が好き'));

      final children =
          _rootSpan(tester).children!.whereType<TextSpan>().toList();
      expect(children, hasLength(2));
      expect(children[0].text, '');
      expect(children[1].text, '猫が好き');
    });

    testWidgets('splits the text at correctPrefixLength on partial match',
        (tester) async {
      await _pump(
        tester,
        const TypingSession(targetText: '猫が好き', typedText: '猫が'),
      );

      final children =
          _rootSpan(tester).children!.whereType<TextSpan>().toList();
      expect(children[0].text, '猫が');
      expect(children[1].text, '好き');
    });

    testWidgets('renders the entire text as typed once completed',
        (tester) async {
      await _pump(
        tester,
        const TypingSession(targetText: '猫', typedText: '猫'),
      );

      final children =
          _rootSpan(tester).children!.whereType<TextSpan>().toList();
      expect(children[0].text, '猫');
      expect(children[1].text, '');
    });

    testWidgets('typed span uses a distinct color from remaining span',
        (tester) async {
      await _pump(
        tester,
        const TypingSession(targetText: '猫が好き', typedText: '猫'),
      );

      final children =
          _rootSpan(tester).children!.whereType<TextSpan>().toList();
      expect(children[0].style?.color, isNot(equals(children[1].style?.color)));
    });

    testWidgets('typed span carries an emphasised weight', (tester) async {
      await _pump(
        tester,
        const TypingSession(targetText: '猫が好き', typedText: '猫'),
      );

      final children =
          _rootSpan(tester).children!.whereType<TextSpan>().toList();
      expect(children[0].style?.fontWeight, FontWeight.w600);
    });

    testWidgets('treats divergent typing as zero prefix', (tester) async {
      // '犬' shares no prefix with '猫が好き', so the typed segment is empty.
      await _pump(
        tester,
        const TypingSession(targetText: '猫が好き', typedText: '犬'),
      );

      final children =
          _rootSpan(tester).children!.whereType<TextSpan>().toList();
      expect(children[0].text, '');
      expect(children[1].text, '猫が好き');
    });
  });
}
