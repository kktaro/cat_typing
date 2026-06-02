import 'package:cat_typing/domain/typing_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TypingStatus', () {
    test('declares exactly three values in expected order', () {
      expect(TypingStatus.values, <TypingStatus>[
        TypingStatus.notStarted,
        TypingStatus.playing,
        TypingStatus.finished,
      ]);
    });

    test('each value has a stable name', () {
      expect(TypingStatus.notStarted.name, 'notStarted');
      expect(TypingStatus.playing.name, 'playing');
      expect(TypingStatus.finished.name, 'finished');
    });
  });
}
