import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/typing_status.dart';
import '../result/result_screen.dart';
import 'game_controller.dart';
import 'widgets/cat_face.dart';
import 'widgets/progress_header.dart';
import 'widgets/target_text_view.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _lastConfirmed = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final value = _controller.value;
    if (!value.composing.isValid || value.composing.isCollapsed) {
      if (value.text != _lastConfirmed) {
        ref
            .read(gameControllerProvider.notifier)
            .onConfirmedTextChanged(value.text, _lastConfirmed);
        _lastConfirmed = value.text;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gameControllerProvider, (prev, next) {
      if (next.status == TypingStatus.finished &&
          prev?.status != TypingStatus.finished) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(builder: (_) => const ResultScreen()),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cat Typing'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Expanded(child: ProgressHeader()),
                  SizedBox(width: 16),
                  CatFace(size: 72),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDFBF7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const TargetTextView(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                maxLines: null,
                enableSuggestions: false,
                autocorrect: false,
                style: const TextStyle(fontSize: 20),
                decoration: InputDecoration(
                  hintText: 'ここに日本語で入力するのだ',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
