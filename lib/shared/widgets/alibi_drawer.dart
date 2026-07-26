import 'package:flutter/material.dart';

import '../../theme/alibi_theme.dart';

class AlibiDrawer extends StatelessWidget {
  const AlibiDrawer({
    required this.selectedTab,
    required this.onGenerate,
    required this.onLibrary,
    required this.onSettings,
    required this.onHowItWorks,
    required this.onAbout,
    required this.onPrivacy,
    required this.onResetOnboarding,
    super.key,
  });

  final int selectedTab;
  final VoidCallback onGenerate;
  final VoidCallback onLibrary;
  final VoidCallback onSettings;
  final VoidCallback onHowItWorks;
  final VoidCallback onAbout;
  final VoidCallback onPrivacy;
  final VoidCallback onResetOnboarding;

  @override
  Widget build(BuildContext context) {
    final palette = context.alibiPalette;
    return Drawer(
      width: MediaQuery.sizeOf(context).width * .84,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'ALIBI',
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.8,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              _Item(
                icon: Icons.auto_awesome_outlined,
                label: 'Generate',
                selected: selectedTab == 0,
                onTap: onGenerate,
              ),
              _Item(
                icon: Icons.bookmarks_outlined,
                label: 'Library',
                selected: selectedTab == 1,
                onTap: onLibrary,
              ),
              const Divider(height: 28),
              _Item(icon: Icons.tune_rounded, label: 'Settings', onTap: onSettings),
              _Item(
                icon: Icons.lightbulb_outline_rounded,
                label: 'How Alibi works',
                onTap: onHowItWorks,
              ),
              _Item(icon: Icons.info_outline_rounded, label: 'About', onTap: onAbout),
              _Item(icon: Icons.shield_outlined, label: 'Privacy', onTap: onPrivacy),
              const Divider(height: 28),
              _Item(
                icon: Icons.replay_rounded,
                label: 'Reset onboarding',
                onTap: onResetOnboarding,
              ),
              const Spacer(),
              Text(
                'STUDIO XIII',
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 6),
              Text('Version 1.1.0', style: TextStyle(color: palette.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = context.alibiPalette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: palette.ink, size: 22),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 17,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
            if (selected)
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.accent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
