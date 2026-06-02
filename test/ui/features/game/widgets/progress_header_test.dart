import 'package:cat_typing/domain/typing_session.dart';
import 'package:cat_typing/domain/typing_status.dart';
import 'package:cat_typing/ui/features/game/game_controller.dart';
import 'package:cat_typing/ui/features/game/widgets/progress_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/seeded_game_controller.dart';

Future<void> _pump(WidgetTester tester, TypingSession session) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...seededOverrides(session),
        tickerProvider.overrideWith((ref) => const Stream<int>.empty()),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ProgressHeader()),
      ),
    ),
  );
}

LinearProgressIndicator _bar(WidgetTester tester) {
  return tester.widget<LinearProgressIndicator>(
    find.byType(LinearProgressIndicator),
  );
}

void main() {
  group('ProgressHeader', () {
    testWidgets('renders 0.0 秒 and 0 % at the initial state', (tester) async {
      await _pump(tester, const TypingSession(targetText: '猫'));

      expect(find.text('0.0 秒'), findsOneWidget);
      expect(find.text('0 %'), findsOneWidget);
      expect(_bar(tester).value, 0);
    });

    testWidgets('renders fractional progress percent (50 %)', (tester) async {
      await _pump(
        tester,
        const TypingSession(targetText: '猫が好き', typedText: '猫が'),
      );

      expect(find.text('50 %'), findsOneWidget);
      expect(_bar(tester).value, 0.5);
    });

    testWidgets(
        'displays progress percent as an integer using toStringAsFixed(0)',
        (tester) async {
      // 3 / 7 ≈ 0.4286 -> 42.857… -> "43" (rounded to nearest by
      // toStringAsFixed). Not a floor — 42.857 would render as "42" if it
      // were floor-rounded.
      await _pump(
        tester,
        const TypingSession(targetText: '猫が好きなのだ', typedText: '猫が好'),
      );

      expect(find.text('43 %'), findsOneWidget);
    });

    testWidgets('renders 100 % and frozen elapsed time when finished',
        (tester) async {
      final start = DateTime(2026, 1, 1, 12, 0, 0);
      final finish = start.add(const Duration(seconds: 3, milliseconds: 400));

      await _pump(
        tester,
        TypingSession(
          targetText: '猫',
          typedText: '猫',
          status: TypingStatus.finished,
          startedAt: start,
          finishedAt: finish,
        ),
      );

      expect(find.text('100 %'), findsOneWidget);
      expect(find.text('3.4 秒'), findsOneWidget);
      expect(_bar(tester).value, 1.0);
    });

    testWidgets('shows non-zero elapsed seconds while playing', (tester) async {
      final start =
          DateTime.now().subtract(const Duration(seconds: 2, milliseconds: 500));

      await _pump(
        tester,
        TypingSession(
          targetText: '猫が好き',
          typedText: '猫',
          status: TypingStatus.playing,
          startedAt: start,
        ),
      );

      final secondsText = find
          .byWidgetPredicate(
            (w) => w is Text && (w.data?.endsWith(' 秒') ?? false),
          )
          .evaluate()
          .map((e) => (e.widget as Text).data!)
          .single;

      final secondsValue =
          double.parse(secondsText.replaceAll(' 秒', '').trim());
      expect(secondsValue, greaterThanOrEqualTo(2.5));
    });

    testWidgets('progress bar has a non-zero minHeight', (tester) async {
      await _pump(tester, const TypingSession(targetText: '猫'));
      expect(_bar(tester).minHeight, greaterThan(0));
    });
  });
}
