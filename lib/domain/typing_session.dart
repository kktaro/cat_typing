import 'package:flutter/foundation.dart';

import 'typing_status.dart';

@immutable
class TypingSession {
  const TypingSession({
    required this.targetText,
    this.typedText = '',
    this.status = TypingStatus.notStarted,
    this.startedAt,
    this.finishedAt,
    this.mistakeCount = 0,
  });

  final String targetText;
  final String typedText;
  final TypingStatus status;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int mistakeCount;

  int get correctPrefixLength {
    final limit = typedText.length < targetText.length
        ? typedText.length
        : targetText.length;
    var i = 0;
    while (i < limit && typedText.codeUnitAt(i) == targetText.codeUnitAt(i)) {
      i++;
    }
    return i;
  }

  bool get isCompleted => typedText == targetText;

  double get progress {
    if (targetText.isEmpty) return 0;
    return correctPrefixLength / targetText.length;
  }

  Duration get elapsed {
    final start = startedAt;
    if (start == null) return Duration.zero;
    final end = finishedAt ?? DateTime.now();
    return end.difference(start);
  }

  double get accuracy {
    final totalRunes = targetText.runes.length;
    if (totalRunes == 0) return 1;
    return totalRunes / (totalRunes + mistakeCount);
  }

  TypingSession copyWith({
    String? targetText,
    String? typedText,
    TypingStatus? status,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? mistakeCount,
  }) {
    return TypingSession(
      targetText: targetText ?? this.targetText,
      typedText: typedText ?? this.typedText,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      mistakeCount: mistakeCount ?? this.mistakeCount,
    );
  }
}
