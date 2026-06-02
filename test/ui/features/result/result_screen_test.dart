import 'package:cat_typing/domain/typing_session.dart';
import 'package:cat_typing/domain/typing_status.dart';
import 'package:cat_typing/ui/features/game/game_controller.dart';
import 'package:cat_typing/ui/features/game/game_screen.dart';
import 'package:cat_typing/ui/features/home/home_screen.dart';
import 'package:cat_typing/ui/features/result/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/seeded_game_controller.dart';

Future<void> _pumpResult(WidgetTester tester, TypingSession session) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...seededOverrides(session),
        tickerProvider.overrideWith((ref) => const Stream<int>.empty()),
      ],
      child: const MaterialApp(home: ResultScreen()),
    ),
  );
}

void main() {
  group('ResultScreen rendering', () {
    testWidgets('renders headline, time, accuracy, and mistake count',
        (tester) async {
      final start = DateTime(2026, 1, 1, 12, 0, 0);
      final finish = start.add(const Duration(seconds: 5, milliseconds: 200));

      await _pumpResult(
        tester,
        TypingSession(
          targetText: '猫が好き',
          typedText: '猫が好き',
          status: TypingStatus.finished,
          startedAt: start,
          finishedAt: finish,
          mistakeCount: 1,
        ),
      );

      expect(find.text('クリア！'), findsOneWidget);
      expect(find.text('😹'), findsOneWidget);
      expect(find.text('5.2 秒'), findsOneWidget);
      // 4 runes / (4 + 1) = 0.8 -> "80.0 %"
      expect(find.text('80.0 %'), findsOneWidget);
      expect(find.text('1 回'), findsOneWidget);
      expect(find.text('もう一度'), findsOneWidget);
    });

    testWidgets('shows 100.0 % when there were no mistakes', (tester) async {
      final start = DateTime(2026, 1, 1, 12, 0, 0);
      final finish = start.add(const Duration(seconds: 1));

      await _pumpResult(
        tester,
        TypingSession(
          targetText: '猫',
          typedText: '猫',
          status: TypingStatus.finished,
          startedAt: start,
          finishedAt: finish,
        ),
      );

      expect(find.text('100.0 %'), findsOneWidget);
      expect(find.text('0 回'), findsOneWidget);
    });

    testWidgets('formats time with a single decimal place', (tester) async {
      final start = DateTime(2026, 1, 1, 12, 0, 0);
      final finish = start.add(const Duration(milliseconds: 100));

      await _pumpResult(
        tester,
        TypingSession(
          targetText: '猫',
          typedText: '猫',
          status: TypingStatus.finished,
          startedAt: start,
          finishedAt: finish,
        ),
      );

      expect(find.text('0.1 秒'), findsOneWidget);
    });
  });

  group('Full play loop integration', () {
    testWidgets(
        'home → game → result → home: もう一度 returns to HomeScreen with '
        'a clean session', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedTextProvider.overrideWithValue('猫'),
            tickerProvider.overrideWith((ref) => const Stream<int>.empty()),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Home → Game
      await tester.tap(find.text('スタート'));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsOneWidget);

      // Game → Result by typing the full sentence.
      await tester.enterText(find.byType(TextField), '猫');
      await tester.pumpAndSettle();
      expect(find.byType(ResultScreen), findsOneWidget);
      expect(find.text('クリア！'), findsOneWidget);

      // Result → Home via もう一度
      await tester.tap(find.text('もう一度'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(ResultScreen), findsNothing);
    });

    testWidgets(
        'starting a second round after もう一度 begins with a fresh session',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedTextProvider.overrideWithValue('猫'),
            tickerProvider.overrideWith((ref) => const Stream<int>.empty()),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.tap(find.text('スタート'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '猫');
      await tester.pumpAndSettle();
      await tester.tap(find.text('もう一度'));
      await tester.pumpAndSettle();

      // Second run
      await tester.tap(find.text('スタート'));
      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);
    });
  });
}
