import 'package:cat_typing/ui/features/game/game_controller.dart';
import 'package:cat_typing/ui/features/game/game_screen.dart';
import 'package:cat_typing/ui/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        selectedTextProvider.overrideWithValue('猫'),
        tickerProvider.overrideWith((ref) => const Stream<int>.empty()),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
}

void main() {
  group('HomeScreen', () {
    testWidgets('renders the app title, hero emoji, and start button',
        (tester) async {
      await _pump(tester);

      expect(find.text('Cat Typing'), findsOneWidget);
      expect(find.text('🐱'), findsOneWidget);
      expect(find.text('スタート'), findsOneWidget);
    });

    testWidgets('start button is a tappable filled button', (tester) async {
      await _pump(tester);

      expect(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.text('スタート'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping start navigates to GameScreen', (tester) async {
      await _pump(tester);

      await tester.tap(find.text('スタート'));
      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });
  });
}
