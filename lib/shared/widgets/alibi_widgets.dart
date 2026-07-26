import 'package:flutter/material.dart';

import '../../theme/alibi_theme.dart';

class AlibiHeader extends StatelessWidget {
  const AlibiHeader({required this.onMenu, super.key});

  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final palette = context.alibiPalette;
    return Row(
      children: [
        IconButton(
          onPressed: onMenu,
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          icon: const Icon(Icons.menu_rounded),
        ),
        const SizedBox(width: 10),
        Text(
          'ALIBI',
          style: TextStyle(
            color: palette.ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
          ),
        ),
        const Spacer(),
        Text(
          'STUDIO XIII',
          style: TextStyle(
            color: palette.muted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class AlibiLabel extends StatelessWidget {
  const AlibiLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.alibiPalette;
    return Text(
      text,
      style: TextStyle(
        color: palette.accent,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }
}

class AlibiInfoPage extends StatelessWidget {
  const AlibiInfoPage({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(height: 34),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 32),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class AlibiInfoBlock extends StatelessWidget {
  const AlibiInfoBlock({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.alibiPalette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.ink,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(color: palette.muted, fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}
