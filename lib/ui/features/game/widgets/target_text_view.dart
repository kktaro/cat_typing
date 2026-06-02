import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game_controller.dart';

class TargetTextView extends ConsumerWidget {
  const TargetTextView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider);
    final target = session.targetText;
    final correct = session.correctPrefixLength;
    final typed = target.substring(0, correct);
    final remaining = target.substring(correct);

    return RichText(
      textAlign: TextAlign.start,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 26,
          height: 1.7,
          color: Colors.black87,
        ),
        children: [
          TextSpan(
            text: typed,
            style: const TextStyle(
              color: Color(0xFF388E3C),
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: remaining,
            style: TextStyle(color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }
}
