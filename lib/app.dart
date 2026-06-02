import 'package:flutter/material.dart';

import 'ui/core/theme/app_theme.dart';
import 'ui/features/home/home_screen.dart';

class CatTypingApp extends StatelessWidget {
  const CatTypingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cat Typing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
