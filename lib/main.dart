import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/generated_excuse.dart';
import 'services/excuse_generator.dart';

void main() {
  runApp(const AlibiApp());
}

class AlibiApp extends StatelessWidget {
  const AlibiApp({super.key});

  static const background = Color(0xFFF2C2BE);
  static const ink = Color(0xFF171313);
  static const accent = Color(0xFF8F2D2D);
  static const muted = Color(0xFF674E4C);
  static const line = Color(0x33171313);
  static const paper = Color(0xFFF8DEDB);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alibi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
          surface: background,
        ),
      ),
      home: const AlibiHomeScreen(),
    );
  }
}

class AlibiHomeScreen extends StatefulWidget {
  const AlibiHomeScreen({super.key});

  @override
  State<AlibiHomeScreen> createState() => _AlibiHomeScreenState();
}

class _AlibiHomeScreenState extends State<AlibiHomeScreen> {
  static const situations = ['Work', 'Plans', 'Family', 'Dating', 'School'];

  static const tones = [
    _ToneOption('Believable', 'Low drama. High credibility.'),
    _ToneOption('Dramatic', 'A bigger story with higher risk.'),
    _ToneOption('Brutally honest', 'No cover story. Just the truth.'),
    _ToneOption('Ridiculous', 'Completely unserious by design.'),
  ];

  final ExcuseGenerator _generator = ExcuseGenerator();

  String _selectedSituation = 'Work';
  String _selectedTone = 'Believable';

  void _generate() {
    final excuse = _generator.generate(
      situation: _selectedSituation,
      tone: _selectedTone,
    );

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => AlibiResultScreen(
          initialExcuse: excuse,
          generator: _generator,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Header(),
                        const SizedBox(height: 54),
                        const Text(
                          'Need a\nway out?',
                          style: TextStyle(
                            color: AlibiApp.ink,
                            fontSize: 58,
                            height: 0.9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -3.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Build a believable exit in a few taps.',
                          style: TextStyle(
                            color: AlibiApp.muted,
                            fontSize: 17,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 52),
                        const _Eyebrow('01  SITUATION'),
                        const SizedBox(height: 16),
                        _SituationSelector(
                          values: situations,
                          selected: _selectedSituation,
                          onChanged: (value) {
                            setState(() => _selectedSituation = value);
                          },
                        ),
                        const SizedBox(height: 44),
                        const _Eyebrow('02  DELIVERY'),
                        const SizedBox(height: 10),
                        ...tones.map(
                          (tone) => _ToneTile(
                            tone: tone,
                            selected: tone.title == _selectedTone,
                            onTap: () {
                              setState(() => _selectedTone = tone.title);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _GenerateBar(
              situation: _selectedSituation,
              tone: _selectedTone,
              onPressed: _generate,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          'ALIBI',
          style: TextStyle(
            color: AlibiApp.ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        Spacer(),
        Text(
          'STUDIO XIII',
          style: TextStyle(
            color: AlibiApp.muted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.7,
          ),
        ),
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AlibiApp.accent,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.8,
      ),
    );
  }
}

class _SituationSelector extends StatelessWidget {
  const _SituationSelector({
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values.map((value) {
        final isSelected = value == selected;
        return InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? AlibiApp.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? AlibiApp.ink : AlibiApp.line,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: isSelected ? Colors.white : AlibiApp.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ToneTile extends StatelessWidget {
  const _ToneTile({
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final _ToneOption tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AlibiApp.line)),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AlibiApp.ink : Colors.transparent,
                border: Border.all(color: AlibiApp.ink, width: 1.5),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tone.title,
                    style: TextStyle(
                      color: AlibiApp.ink,
                      fontSize: 18,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tone.description,
                    style: const TextStyle(
                      color: AlibiApp.muted,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Text(
              tone.marker,
              style: TextStyle(
                color: selected ? AlibiApp.accent : AlibiApp.muted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenerateBar extends StatelessWidget {
  const _GenerateBar({
    required this.situation,
    required this.tone,
    required this.onPressed,
  });

  final String situation;
  final String tone;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      decoration: const BoxDecoration(
        color: AlibiApp.background,
        border: Border(top: BorderSide(color: AlibiApp.line)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'READY TO GENERATE',
                      style: TextStyle(
                        color: AlibiApp.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$situation · $tone',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AlibiApp.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: AlibiApp.ink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 17,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'GENERATE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_outward_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AlibiResultScreen extends StatefulWidget {
  const AlibiResultScreen({
    required this.initialExcuse,
    required this.generator,
    super.key,
  });

  final GeneratedExcuse initialExcuse;
  final ExcuseGenerator generator;

  @override
  State<AlibiResultScreen> createState() => _AlibiResultScreenState();
}

class _AlibiResultScreenState extends State<AlibiResultScreen> {
  late GeneratedExcuse _excuse;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _excuse = widget.initialExcuse;
  }

  void _another() {
    setState(() {
      _excuse = widget.generator.generate(
        situation: _excuse.situation,
        tone: _excuse.tone,
      );
      _copied = false;
    });
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _excuse.text));
    if (!mounted) return;
    setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          foregroundColor: AlibiApp.ink,
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Spacer(),
                      const Text(
                        'ALIBI',
                        style: TextStyle(
                          color: AlibiApp.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      _MetaTag(_excuse.situation),
                      const SizedBox(width: 8),
                      _MetaTag(_excuse.tone),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      decoration: BoxDecoration(
                        color: AlibiApp.paper,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AlibiApp.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'YOUR ALIBI',
                            style: TextStyle(
                              color: AlibiApp.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: SingleChildScrollView(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: Text(
                                  _excuse.text,
                                  key: ValueKey(_excuse.text),
                                  style: const TextStyle(
                                    color: AlibiApp.ink,
                                    fontSize: 30,
                                    height: 1.17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: AlibiApp.line),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _Metric(
                                  label: 'BELIEVABILITY',
                                  value: '${_excuse.believability}%',
                                ),
                              ),
                              Expanded(
                                child: _Metric(
                                  label: 'FOLLOW-UP RISK',
                                  value: _excuse.followUpRiskLabel,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _another,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('ANOTHER'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AlibiApp.ink,
                            side: const BorderSide(color: AlibiApp.ink),
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _copy,
                          icon: Icon(
                            _copied ? Icons.check_rounded : Icons.copy_rounded,
                          ),
                          label: Text(_copied ? 'COPIED' : 'COPY EXCUSE'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AlibiApp.ink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaTag extends StatelessWidget {
  const _MetaTag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AlibiApp.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AlibiApp.ink,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AlibiApp.muted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AlibiApp.ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ToneOption {
  const _ToneOption(this.title, this.description);

  final String title;
  final String description;

  String get marker => switch (title) {
        'Believable' => 'SAFE',
        'Dramatic' => 'RISKY',
        'Brutally honest' => 'DIRECT',
        'Ridiculous' => 'CHAOS',
        _ => '',
      };
}
