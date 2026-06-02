import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game_controller.dart';

class ProgressHeader extends ConsumerWidget {
  const ProgressHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(tickerProvider);
    final session = ref.watch(gameControllerProvider);
    final seconds = session.elapsed.inMilliseconds / 1000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${seconds.toStringAsFixed(1)} 秒',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${(session.progress * 100).toStringAsFixed(0)} %',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: session.progress,
            minHeight: 10,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF66BB6A)),
          ),
        ),
      ],
    );
  }
}
