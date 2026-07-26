import 'package:flutter/material.dart';

import '../../../models/excuse_length.dart';
import '../../../shared/widgets/alibi_widgets.dart';
import '../../../theme/alibi_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.situations,
    required this.tones,
    required this.situation,
    required this.tone,
    required this.length,
    required this.safeMode,
    required this.themeChoice,
    required this.onSituationChanged,
    required this.onToneChanged,
    required this.onLengthChanged,
    required this.onSafeModeChanged,
    required this.onThemeChanged,
    required this.onClearHistory,
    required this.onClearFavourites,
    super.key,
  });

  final List<String> situations;
  final List<String> tones;
  final String situation;
  final String tone;
  final ExcuseLength length;
  final bool safeMode;
  final AlibiThemeChoice themeChoice;
  final ValueChanged<String> onSituationChanged;
  final ValueChanged<String> onToneChanged;
  final ValueChanged<ExcuseLength> onLengthChanged;
  final ValueChanged<bool> onSafeModeChanged;
  final ValueChanged<AlibiThemeChoice> onThemeChanged;
  final Future<void> Function() onClearHistory;
  final Future<void> Function() onClearFavourites;

  @override
  Widget build(BuildContext context) {
    return AlibiInfoPage(
      title: 'Settings',
      children: [
        const AlibiLabel('APPEARANCE'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AlibiThemeChoice.values.map((choice) {
            final palette = AlibiTheme.palette(choice);
            final selected = choice == themeChoice;
            return InkWell(
              onTap: () => onThemeChanged(choice),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 92,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: .18),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: palette.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: palette.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      choice.label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 38),
        const AlibiLabel('DEFAULTS'),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: situation,
          decoration: const InputDecoration(labelText: 'Default situation'),
          items: situations
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onSituationChanged(value);
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: tone,
          decoration: const InputDecoration(labelText: 'Default tone'),
          items: tones
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onToneChanged(value);
          },
        ),
        const SizedBox(height: 24),
        SegmentedButton<ExcuseLength>(
          segments: const [
            ButtonSegment(value: ExcuseLength.short, label: Text('Short')),
            ButtonSegment(
              value: ExcuseLength.standard,
              label: Text('Standard'),
            ),
            ButtonSegment(
              value: ExcuseLength.detailed,
              label: Text('Detailed'),
            ),
          ],
          selected: {length},
          onSelectionChanged: (values) => onLengthChanged(values.first),
          showSelectedIcon: false,
        ),
        const SizedBox(height: 20),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: safeMode,
          onChanged: onSafeModeChanged,
          title: const Text(
            'Avoid follow-up questions by default',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 36),
        const AlibiLabel('DATA'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Clear generation history'),
          trailing: const Icon(Icons.delete_outline),
          onTap: onClearHistory,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Clear favourites'),
          trailing: const Icon(Icons.delete_outline),
          onTap: onClearFavourites,
        ),
      ],
    );
  }
}
