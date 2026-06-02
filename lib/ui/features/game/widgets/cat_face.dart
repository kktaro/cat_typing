import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/typing_session.dart';
import '../game_controller.dart';

class CatFace extends ConsumerStatefulWidget {
  const CatFace({super.key, this.size = 80});

  final double size;

  @override
  ConsumerState<CatFace> createState() => _CatFaceState();
}

class _CatFaceState extends ConsumerState<CatFace> {
  bool _showMistake = false;
  Timer? _mistakeTimer;

  @override
  void dispose() {
    _mistakeTimer?.cancel();
    super.dispose();
  }

  String _emojiFor(TypingSession session) {
    if (session.isCompleted) return '😹';
    final p = session.progress;
    if (p >= 0.7) return '😻';
    if (p >= 0.3) return '😺';
    return '🐱';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gameControllerProvider, (prev, next) {
      if (prev != null && next.mistakeCount > prev.mistakeCount) {
        _mistakeTimer?.cancel();
        setState(() => _showMistake = true);
        _mistakeTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _showMistake = false);
        });
      }
    });

    final session = ref.watch(gameControllerProvider);
    final emoji = _showMistake ? '😿' : _emojiFor(session);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text(
        emoji,
        key: ValueKey<String>(emoji),
        style: TextStyle(fontSize: widget.size),
      ),
    );
  }
}
