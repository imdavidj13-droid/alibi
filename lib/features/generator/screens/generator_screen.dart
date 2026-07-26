import 'package:flutter/material.dart';

import '../../../models/excuse_length.dart';
import '../../../shared/widgets/alibi_widgets.dart';
import '../../../theme/alibi_theme.dart';

class GeneratorScreen extends StatelessWidget {
  const GeneratorScreen({
    required this.situations,
    required this.tones,
    required this.selectedSituation,
    required this.selectedTone,
    required this.length,
    required this.safeMode,
    required this.detailController,
    required this.onMenu,
    required this.onSituationChanged,
    required this.onToneChanged,
    required this.onLengthChanged,
    required this.onSafeModeChanged,
    required this.onGenerate,
    super.key,
  });

  final List<String> situations;
  final List<String> tones;
  final String selectedSituation;
  final String selectedTone;
  final ExcuseLength length;
  final bool safeMode;
  final TextEditingController detailController;
  final VoidCallback onMenu;
  final ValueChanged<String> onSituationChanged;
  final ValueChanged<String> onToneChanged;
  final ValueChanged<ExcuseLength> onLengthChanged;
  final ValueChanged<bool> onSafeModeChanged;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final palette = context.alibiPalette;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
          sliver: SliverList.list(
            children: [
              AlibiHeader(onMenu: onMenu),
              const SizedBox(height: 48),
              Text(
                'Say less.\nGet out clean.',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 18),
              Text(
                'Build a convincing message without over-explaining.',
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 17,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 42),
              const AlibiLabel('SITUATION'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: situations.map((item) {
                  final selected = item == selectedSituation;
                  return ChoiceChip(
                    label: Text(item),
                    selected: selected,
                    onSelected: (_) => onSituationChanged(item),
                    showCheckmark: false,
                    selectedColor: palette.ink,
                    backgroundColor: Colors.transparent,
                    labelStyle: TextStyle(
                      color: selected ? palette.background : palette.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(color: palette.ink.withValues(alpha: .28)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 34),
              const AlibiLabel('TONE'),
              const SizedBox(height: 12),
              ...tones.map(
                (item) => _ToneTile(
                  title: item,
                  selected: item == selectedTone,
                  onTap: () => onToneChanged(item),
                ),
              ),
              const SizedBox(height: 28),
              const AlibiLabel('LENGTH'),
              const SizedBox(height: 12),
              SegmentedButton<ExcuseLength>(
                segments: const [
                  ButtonSegment(
                    value: ExcuseLength.short,
                    label: Text('Short'),
                  ),
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
                onSelectionChanged: (value) => onLengthChanged(value.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: detailController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Include a detail',
                  hintText:
                      'Enter a person, place or subject to weave into the message.\nExample: my car, a delivery, Arsenal Women',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 18),
              SwitchListTile(
                value: safeMode,
                onChanged: onSafeModeChanged,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Avoid follow-up questions',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text(
                  'Keeps the story restrained and lowers the risk score.',
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                height: 62,
                child: FilledButton(
                  onPressed: onGenerate,
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.ink,
                    foregroundColor: palette.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'CREATE ALIBI',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToneTile extends StatelessWidget {
  const _ToneTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  String get subtitle => switch (title) {
    'Believable' => 'Restrained and difficult to question',
    'Dramatic' => 'High stakes and emotionally charged',
    'Brutally honest' => 'Direct, clear and technically not an excuse',
    _ => 'Absurd enough to become the joke',
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.alibiPalette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: palette.ink, width: 2),
                color: selected ? palette.ink : Colors.transparent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(color: palette.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
