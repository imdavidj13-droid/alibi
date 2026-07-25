import 'package:flutter/material.dart';

void main() {
  runApp(const AlibiApp());
}

class AlibiApp extends StatelessWidget {
  const AlibiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alibi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F0E8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5A36),
          brightness: Brightness.light,
        ),
        fontFamily: 'Arial',
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFFFF5A36),
          selectionColor: Color(0x33FF5A36),
          selectionHandleColor: Color(0xFFFF5A36),
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
  static const List<String> _situations = [
    'Work',
    'Plans',
    'Family',
    'Dating',
    'School',
  ];

  static const List<_ToneOption> _tones = [
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

  String _selectedSituation = 'Work';
  String _selectedTone = 'Believable';

  void _generateExcuse() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) {
          return AlibiResultScreen(
            situation: _selectedSituation,
            tone: _selectedTone,
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
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _TopBar(),
                          const SizedBox(height: 56),
                          const Text(
                            'Need a\nway out?',
                            style: TextStyle(
                              color: Color(0xFF171717),
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
                              color: Color(0xFF69665F),
                              fontSize: 17,
                              height: 1.45,
                              fontWeight: FontWeight.w400,
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
                            children: _situations.map((situation) {
                              final isSelected =
                                  situation == _selectedSituation;

                              return _TextChoice(
                                label: situation,
                                isSelected: isSelected,
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
                          ..._tones.map((tone) {
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
    return Row(
      children: [
        const Text(
          'ALIBI',
          style: TextStyle(
            color: Color(0xFF171717),
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.4,
          ),
        ),
        const Spacer(),
        Semantics(
          button: true,
          label: 'Open saved excuses',
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(40),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.bookmark_border_rounded,
                color: Color(0xFF171717),
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.number,
    required this.label,
  });

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          number,
          style: const TextStyle(
            color: Color(0xFFFF5A36),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8A867D),
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
                  ? const Color(0xFF171717)
                  : const Color(0xFF9A968D),
              fontSize: 21,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              decoration:
                  isSelected ? TextDecoration.underline : TextDecoration.none,
              decorationColor: const Color(0xFFFF5A36),
              decorationThickness: 3,
              decorationStyle: TextDecorationStyle.solid,
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
              bottom: BorderSide(
                color: Color(0x1F171717),
                width: 1,
              ),
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
                      ? const Color(0xFFFF5A36)
                      : const Color(0xFF8A867D),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(
                        color: const Color(0xFF171717),
                        fontSize: 18,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                      child: Text(tone.title),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      tone.description,
                      style: const TextStyle(
                        color: Color(0xFF77736B),
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        key: ValueKey('selected'),
                        color: Color(0xFFFF5A36),
                        size: 24,
                      )
                    : const Icon(
                        Icons.arrow_forward_rounded,
                        key: ValueKey('not-selected'),
                        color: Color(0xFFAAA69D),
                        size: 21,
                      ),
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
        color: Color(0xFFF4F0E8),
        border: Border(
          top: BorderSide(
            color: Color(0x1A171717),
          ),
        ),
      ),
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
                  color: Color(0xFF747067),
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
                backgroundColor: const Color(0xFF171717),
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
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 19,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlibiResultScreen extends StatelessWidget {
  const AlibiResultScreen({
    required this.situation,
    required this.tone,
    super.key,
  });

  final String situation;
  final String tone;

  String get _excuse {
    switch (tone) {
      case 'Dramatic':
        return 'Something unexpected has happened at home and I need to deal '
            'with it immediately. I will explain properly once everything is '
            'under control.';

      case 'Brutally honest':
        return 'I have had a long day and I do not have the energy to pretend '
            'I will be good company tonight. Can we rearrange?';

      case 'Ridiculous':
        return 'A neighbour has accidentally locked themselves out while '
            'holding a birthday cake, and somehow I am now responsible for '
            'solving the entire situation.';

      case 'Believable':
      default:
        return 'I am really sorry, but something has come up at home and I '
            'need to stay back to deal with it. I should have more clarity '
            'later today.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    const Spacer(),
                    const Text(
                      'ALIBI',
                      style: TextStyle(
                        color: Color(0xFF171717),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '$situation · $tone'.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFFF5A36),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '“$_excuse”',
                  style: const TextStyle(
                    color: Color(0xFF171717),
                    fontSize: 34,
                    height: 1.18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                  ),
                ),
                const Spacer(),
                const Row(
                  children: [
                    Expanded(
                      child: _ResultStat(
                        label: 'BELIEVABILITY',
                        value: '84%',
                      ),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      child: _ResultStat(
                        label: 'FOLLOW-UP RISK',
                        value: 'LOW',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('COPY EXCUSE'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF171717),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.label,
    required this.value,
  });

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
            color: Color(0xFF8A867D),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF171717),
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