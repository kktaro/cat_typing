import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/typing_texts.dart';
import '../../../domain/typing_session.dart';
import '../../../domain/typing_status.dart';

final selectedTextProvider = Provider<String>((ref) => kCatTypingTexts.first);

final tickerProvider = StreamProvider.autoDispose<int>((ref) {
  return Stream<int>.periodic(const Duration(milliseconds: 100), (i) => i);
});

final gameControllerProvider =
    NotifierProvider.autoDispose<GameController, TypingSession>(
  GameController.new,
);

class GameController extends AutoDisposeNotifier<TypingSession> {
  @override
  TypingSession build() {
    final text = ref.read(selectedTextProvider);
    return TypingSession(targetText: text);
  }

  void onConfirmedTextChanged(String confirmed, String previousConfirmed) {
    final session = state;
    if (session.status == TypingStatus.finished) return;

    final now = DateTime.now();
    final target = session.targetText;

    var newStartedAt = session.startedAt;
    var newStatus = session.status;
    if (confirmed.isNotEmpty && newStartedAt == null) {
      newStartedAt = now;
      newStatus = TypingStatus.playing;
    }

    var mistakeCount = session.mistakeCount;
    if (confirmed.length > previousConfirmed.length) {
      for (var i = previousConfirmed.length; i < confirmed.length; i++) {
        if (i >= target.length ||
            confirmed.codeUnitAt(i) != target.codeUnitAt(i)) {
          mistakeCount++;
        }
      }
    }

    DateTime? newFinishedAt = session.finishedAt;
    if (confirmed == target) {
      newStatus = TypingStatus.finished;
      newFinishedAt = now;
    }

    state = session.copyWith(
      typedText: confirmed,
      status: newStatus,
      startedAt: newStartedAt,
      finishedAt: newFinishedAt,
      mistakeCount: mistakeCount,
    );
  }

  void reset() {
    state = TypingSession(targetText: ref.read(selectedTextProvider));
  }
}
