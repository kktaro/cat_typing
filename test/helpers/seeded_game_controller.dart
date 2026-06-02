import 'package:cat_typing/domain/typing_session.dart';
import 'package:cat_typing/ui/features/game/game_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SeedingGameController extends GameController {
  SeedingGameController(this._initial);

  final TypingSession _initial;

  @override
  TypingSession build() => _initial;
}

List<Override> seededOverrides(TypingSession session) {
  return [
    selectedTextProvider.overrideWithValue(session.targetText),
    gameControllerProvider.overrideWith(() => SeedingGameController(session)),
  ];
}
