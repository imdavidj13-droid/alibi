import 'package:flutter/material.dart';

import '../features/shell/alibi_shell.dart';
import '../theme/alibi_theme.dart';
import '../theme/alibi_theme_controller.dart';

class AlibiApp extends StatefulWidget {
  const AlibiApp({super.key});

  @override
  State<AlibiApp> createState() => _AlibiAppState();
}

class _AlibiAppState extends State<AlibiApp> {
  final AlibiThemeController _themeController = AlibiThemeController();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    await _themeController.load();
    _themeController.addListener(_onThemeChanged);
    if (mounted) setState(() => _ready = true);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final choice = _themeController.choice;
    return MaterialApp(
      title: 'Alibi',
      debugShowCheckedModeBanner: false,
      theme: AlibiTheme.build(choice),
      home: _ready
          ? AlibiShell(themeController: _themeController)
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
