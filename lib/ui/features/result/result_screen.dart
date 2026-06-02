import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_controller.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider);
    final seconds = session.elapsed.inMilliseconds / 1000;
    final accuracy = session.accuracy * 100;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😹', style: TextStyle(fontSize: 120)),
              const SizedBox(height: 24),
              const Text(
                'クリア！',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              _ResultRow(label: 'タイム', value: '${seconds.toStringAsFixed(1)} 秒'),
              const SizedBox(height: 16),
              _ResultRow(
                label: '正確率',
                value: '${accuracy.toStringAsFixed(1)} %',
              ),
              const SizedBox(height: 16),
              _ResultRow(
                label: 'ミス数',
                value: '${session.mistakeCount} 回',
              ),
              const SizedBox(height: 56),
              FilledButton.icon(
                onPressed: () {
                  ref.read(gameControllerProvider.notifier).reset();
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                icon: const Icon(Icons.refresh),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  child: Text('もう一度', style: TextStyle(fontSize: 20)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 20, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
