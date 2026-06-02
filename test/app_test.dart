import 'package:cat_typing/app.dart';
import 'package:cat_typing/ui/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CatTypingApp', () {
    testWidgets('boots into HomeScreen', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: CatTypingApp()));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Cat Typing'), findsOneWidget);
    });

    testWidgets('does not render the debug banner', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: CatTypingApp()));

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('uses the configured app title', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: CatTypingApp()));

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, 'Cat Typing');
    });
  });
}
