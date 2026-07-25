import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/generated_excuse.dart';
import 'services/excuse_generator.dart';

void main() {
  runApp(const AlibiApp());
}

class AlibiApp extends StatelessWidget {
  const AlibiApp({super.key});

  static const backgroundColor = Color(0xFFF2C2BE);
  static const textColor = Color(0xFF171313);
  static const accentColor = Color(0xFF8F2D2D);
  static const mutedTextColor = Color(0xFF604A49);
  static const softTextColor = Color(0xFF745B59);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alibi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.light,
          surface: backgroundColor,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: accentColor,
          selectionColor: Color(0x338F2D2D),
          selectionHandleColor: accentColor,
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
    _ToneOption(
      title: 'Believable',
      description: 'Safe, ordinary and difficult to question.',
      icon: Icons.verified_outlined,
    ),
    _ToneOption(
      title: 'Dramatic',
      description: 'A little chaos makes everything convincing.',
      icon: Icons.bolt_outlined,
    ),
    _ToneOption(
      title: 'Brutally honest',
      description: 'Technically not an excuse at all.',
      icon: Icons.record_voice_over_outlined,
    ),
    _ToneOption(
      title: 'Ridiculous',
      description: 'No one will believe it. That is the point.',
      icon: Icons.auto_awesome_outlined,
    ),
  ];

  final ExcuseGenerator _generator = ExcuseGenerator();

  String _selectedSituation = 'Work';
  String _selectedTone = 'Believable';

  void _generateExcuse() {
    final excuse = _generator.generate(
      situation: _selectedSituation,
      tone: _selectedTone,
    );

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) {
          return AlibiResultScreen(
            initialExcuse: excuse,
            generator: _generator,
          );
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 20.0 : 28.0;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      24,
                      horizontalPadding,
                      32,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _TopBar(),
                            const SizedBox(height: 54),
                            const Text(
                              'Need a\nway out?',
                              style: TextStyle(
                                color: AlibiApp.textColor,
                                fontSize: 54,
                                height: 0.95,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -2.8,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Choose the situation. We will handle the explanation.',
                              style: TextStyle(
                                color: AlibiApp.mutedTextColor,
                                fontSize: 17,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 52),
                            const _SectionLabel(
                              number: '01',
                              label: 'WHO IS IT FOR?',
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 24,
                              runSpacing: 18,
                              children: situations.map((situation) {
                                return _TextChoice(
                                  label: situation,
                                  isSelected: situation == _selectedSituation,
                                  onTap: () {
                                    setState(() {
                                      _selectedSituation = situation;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 52),
                            const _SectionLabel(
                              number: '02',
                              label: 'HOW BOLD?',
                            ),
                            const SizedBox(height: 12),
                            ...tones.map((tone) {
                              return _ToneRow(
                                tone: tone,
                                isSelected: tone.title == _selectedTone,
                                onTap: () {
                                  setState(() {
                                    _selectedTone = tone.title;
                                  });
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _BottomAction(
                  situation: _selectedSituation,
                  tone: _selectedTone,
                  onPressed: _generateExcuse,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          'ALIBI',
          style: TextStyle(
            color: AlibiApp.textColor,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.4,
          ),
        ),
        Spacer(),
        Icon(
          Icons.bookmark_border_rounded,
          color: AlibiApp.textColor,
          size: 24,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          number,
          style: const TextStyle(
            color: AlibiApp.accentColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: AlibiApp.softTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _TextChoice extends StatelessWidget {
  const _TextChoice({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              color: isSelected
                  ? AlibiApp.textColor
                  : const Color(0xFF806865),
              fontSize: 21,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              decoration:
                  isSelected ? TextDecoration.underline : TextDecoration.none,
              decorationColor: AlibiApp.accentColor,
              decorationThickness: 3,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _ToneRow extends StatelessWidget {
  const _ToneRow({
    required this.tone,
    required this.isSelected,
    required this.onTap,
  });

  final _ToneOption tone;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0x24171313)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  tone.icon,
                  color: isSelected
                      ? AlibiApp.accentColor
                      : AlibiApp.softTextColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tone.title,
                      style: TextStyle(
                        color: AlibiApp.textColor,
                        fontSize: 18,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      tone.description,
                      style: const TextStyle(
                        color: AlibiApp.mutedTextColor,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                isSelected
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
                color: isSelected
                    ? AlibiApp.accentColor
                    : const Color(0xFF806865),
                size: isSelected ? 24 : 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
      decoration: const BoxDecoration(
        color: AlibiApp.backgroundColor,
        border: Border(top: BorderSide(color: Color(0x24171313))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$situation  ·  $tone',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AlibiApp.mutedTextColor,
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: AlibiApp.textColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  shape: const StadiumBorder(),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'GENERATE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.arrow_forward_rounded, size: 19),
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

  @override
  void initState() {
    super.initState();
    _excuse = widget.initialExcuse;
  }

  void _generateAnother() {
    setState(() {
      _excuse = widget.generator.generate(
        situation: _excuse.situation,
        tone: _excuse.tone,
      );
    });
  }

  Future<void> _copyExcuse() async {
    await Clipboard.setData(ClipboardData(text: _excuse.text));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Excuse copied'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 20.0 : 28.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                24,
                horizontalPadding,
                28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 620,
                    minHeight: constraints.maxHeight - 52,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back_rounded),
                              color: AlibiApp.textColor,
                              padding: EdgeInsets.zero,
                            ),
                            const Spacer(),
                            const Text(
                              'ALIBI',
                              style: TextStyle(
                                color: AlibiApp.textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.2,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '${_excuse.situation} · ${_excuse.tone}'.toUpperCase(),
                          style: const TextStyle(
                            color: AlibiApp.accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Text(
                            '“${_excuse.text}”',
                            key: ValueKey(_excuse.text),
                            style: const TextStyle(
                              color: AlibiApp.textColor,
                              fontSize: 32,
                              height: 1.18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.1,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: _ResultStat(
                                label: 'BELIEVABILITY',
                                value: '${_excuse.believability}%',
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _ResultStat(
                                label: 'FOLLOW-UP RISK',
                                value: _excuse.followUpRiskLabel,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _generateAnother,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('ANOTHER'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AlibiApp.textColor,
                                  side: const BorderSide(
                                    color: AlibiApp.textColor,
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 19),
                                  shape: const StadiumBorder(),
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
                                onPressed: _copyExcuse,
                                icon: const Icon(Icons.copy_rounded),
                                label: const Text('COPY'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AlibiApp.textColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: const StadiumBorder(),
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
            );
          },
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({required this.label, required this.value});

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
            color: AlibiApp.softTextColor,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AlibiApp.textColor,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ToneOption {
  const _ToneOption({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}