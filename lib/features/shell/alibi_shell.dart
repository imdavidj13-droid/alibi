import 'package:flutter/material.dart';

import '../../models/excuse_length.dart';
import '../../models/generated_excuse.dart';
import '../../services/alibi_storage.dart';
import '../../services/excuse_generator.dart';
import '../../shared/widgets/alibi_drawer.dart';
import '../../theme/alibi_theme.dart';
import '../../theme/alibi_theme_controller.dart';
import '../generator/screens/generator_screen.dart';
import '../generator/screens/result_screen.dart';
import '../info/screens/info_screens.dart';
import '../library/screens/library_screen.dart';
import '../settings/screens/settings_screen.dart';

class AlibiShell extends StatefulWidget {
  const AlibiShell({required this.themeController, super.key});

  final AlibiThemeController themeController;

  @override
  State<AlibiShell> createState() => _AlibiShellState();
}

class _AlibiShellState extends State<AlibiShell> {
  final ExcuseGenerator _generator = ExcuseGenerator();
  final AlibiStorage _storage = AlibiStorage();
  final TextEditingController _detailController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _situations = [
    'Work',
    'Plans',
    'Family',
    'Dating',
    'School',
    'Appointments',
    'Gym',
    'Neighbours',
    'Deliveries',
  ];

  static const _tones = [
    'Believable',
    'Dramatic',
    'Brutally honest',
    'Ridiculous',
  ];

  String _situation = 'Work';
  String _tone = 'Believable';
  ExcuseLength _length = ExcuseLength.standard;
  bool _safeMode = true;
  int _tab = 0;
  bool _ready = false;
  bool _showOnboarding = false;
  List<GeneratedExcuse> _history = [];
  List<GeneratedExcuse> _favourites = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await _storage.loadHistory();
    final favourites = await _storage.loadFavourites();
    final seen = await _storage.hasSeenOnboarding();
    final preferences = await _storage.loadPreferences();
    if (!mounted) return;
    setState(() {
      _history = history;
      _favourites = favourites;
      _showOnboarding = !seen;
      _situation = _situations.contains(preferences.defaultSituation)
          ? preferences.defaultSituation
          : 'Work';
      _tone = _tones.contains(preferences.defaultTone)
          ? preferences.defaultTone
          : 'Believable';
      _length = ExcuseLength.values.firstWhere(
        (value) => value.name == preferences.defaultLength,
        orElse: () => ExcuseLength.standard,
      );
      _safeMode = preferences.safeMode;
      _ready = true;
    });
  }

  Future<void> _savePreferences() {
    return _storage.savePreferences(
      defaultSituation: _situation,
      defaultTone: _tone,
      defaultLength: _length.name,
      safeMode: _safeMode,
    );
  }

  String get _generatorSituation => switch (_situation) {
        'Appointments' => 'Work',
        'Gym' => 'Plans',
        'Neighbours' => 'Family',
        'Deliveries' => 'Work',
        _ => _situation,
      };

  String get _effectiveTone {
    if (_safeMode && (_tone == 'Dramatic' || _tone == 'Ridiculous')) {
      return 'Believable';
    }
    return _tone;
  }

  GeneratedExcuse _generate() {
    final base = _generator.generate(
      situation: _generatorSituation,
      tone: _effectiveTone,
    );
    var text = base.text;
    final detail = _cleanDetail(_detailController.text);
    if (detail.isNotEmpty) text = _weaveDetail(text, detail, _effectiveTone);

    text = switch (_length) {
      ExcuseLength.short => _shorten(text),
      ExcuseLength.standard => text,
      ExcuseLength.detailed =>
        '$text I wanted to give you enough notice rather than leave this until later.',
    };

    final result = GeneratedExcuse(
      text: text,
      situation: _situation,
      tone: _effectiveTone,
      believability: _safeMode
          ? (base.believability + 4).clamp(1, 99)
          : base.believability,
      followUpRisk: _safeMode ? FollowUpRisk.low : base.followUpRisk,
    );

    _history = [result, ..._history.where((item) => item.text != result.text)]
        .take(50)
        .toList();
    _storage.saveHistory(_history);
    return result;
  }

  String _cleanDetail(String value) => value
      .trim()
      .replaceAll(RegExp(r'[.!?,;:]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ');

  String _weaveDetail(String text, String detail, String tone) {
    final detailSentence = switch (tone) {
      'Dramatic' =>
        'To make matters worse, the situation now also involves $detail.',
      'Brutally honest' =>
        'The extra context is that this involves $detail, and I need to prioritise it today.',
      'Ridiculous' =>
        'Somehow, $detail is now involved, which raises more questions than it answers.',
      _ => 'There is also a situation involving $detail that I need to deal with.',
    };

    final firstMatch = RegExp(r'^.*?[.!?](?:\s|$)').firstMatch(text);
    if (firstMatch == null) return '$text $detailSentence';
    final first = firstMatch.group(0)!.trim();
    final rest = text.substring(firstMatch.end).trim();
    return rest.isEmpty
        ? '$first $detailSentence'
        : '$first $detailSentence $rest';
  }

  String _shorten(String text) {
    final matches = RegExp(r'[^.!?]+[.!?]').allMatches(text).toList();
    if (matches.isEmpty) return text;
    return matches.take(2).map((m) => m.group(0)!.trim()).join(' ');
  }

  Future<void> _toggleFavourite(GeneratedExcuse excuse) async {
    final exists = _favourites.any((item) => item.text == excuse.text);
    setState(() {
      _favourites = exists
          ? _favourites.where((item) => item.text != excuse.text).toList()
          : [excuse, ..._favourites];
    });
    await _storage.saveFavourites(_favourites);
  }

  bool _isFavourite(GeneratedExcuse excuse) =>
      _favourites.any((item) => item.text == excuse.text);

  void _openPage(Widget page) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _dismissOnboarding() async {
    await _storage.markOnboardingSeen();
    if (mounted) setState(() => _showOnboarding = false);
  }

  Future<void> _resetOnboarding() async {
    await _storage.resetOnboarding();
    if (!mounted) return;
    Navigator.of(context).pop();
    setState(() => _showOnboarding = true);
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          drawer: AlibiDrawer(
            selectedTab: _tab,
            onGenerate: () {
              Navigator.pop(context);
              setState(() => _tab = 0);
            },
            onLibrary: () {
              Navigator.pop(context);
              setState(() => _tab = 1);
            },
            onSettings: () => _openPage(
              SettingsScreen(
                situations: _situations,
                tones: _tones,
                situation: _situation,
                tone: _tone,
                length: _length,
                safeMode: _safeMode,
                themeChoice: widget.themeController.choice,
                onThemeChanged: widget.themeController.setChoice,
                onSituationChanged: (value) {
                  setState(() => _situation = value);
                  _savePreferences();
                },
                onToneChanged: (value) {
                  setState(() => _tone = value);
                  _savePreferences();
                },
                onLengthChanged: (value) {
                  setState(() => _length = value);
                  _savePreferences();
                },
                onSafeModeChanged: (value) {
                  setState(() => _safeMode = value);
                  _savePreferences();
                },
                onClearHistory: () async {
                  await _storage.clearHistory();
                  if (mounted) setState(() => _history = []);
                },
                onClearFavourites: () async {
                  await _storage.clearFavourites();
                  if (mounted) setState(() => _favourites = []);
                },
              ),
            ),
            onHowItWorks: () => _openPage(const HowAlibiWorksScreen()),
            onAbout: () => _openPage(const AboutScreen()),
            onPrivacy: () => _openPage(const PrivacyScreen()),
            onResetOnboarding: _resetOnboarding,
          ),
          body: SafeArea(
            child: IndexedStack(
              index: _tab,
              children: [
                GeneratorScreen(
                  situations: _situations,
                  tones: _tones,
                  selectedSituation: _situation,
                  selectedTone: _tone,
                  length: _length,
                  safeMode: _safeMode,
                  detailController: _detailController,
                  onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                  onSituationChanged: (value) {
                    setState(() => _situation = value);
                    _savePreferences();
                  },
                  onToneChanged: (value) {
                    setState(() => _tone = value);
                    _savePreferences();
                  },
                  onLengthChanged: (value) {
                    setState(() => _length = value);
                    _savePreferences();
                  },
                  onSafeModeChanged: (value) {
                    setState(() => _safeMode = value);
                    _savePreferences();
                  },
                  onGenerate: () {
                    final excuse = _generate();
                    setState(() {});
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ResultScreen(
                          initialExcuse: excuse,
                          onAnother: _generate,
                          isFavourite: _isFavourite,
                          onFavourite: _toggleFavourite,
                        ),
                      ),
                    );
                  },
                ),
                LibraryScreen(
                  history: _history,
                  favourites: _favourites,
                  isFavourite: _isFavourite,
                  onFavourite: _toggleFavourite,
                  onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (value) => setState(() => _tab = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: 'Generate',
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmarks_outlined),
                selectedIcon: Icon(Icons.bookmarks),
                label: 'Library',
              ),
            ],
          ),
        ),
        if (_showOnboarding) _OnboardingOverlay(onDone: _dismissOnboarding),
      ],
    );
  }
}

class _OnboardingOverlay extends StatelessWidget {
  const _OnboardingOverlay({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final palette = context.alibiPalette;
    return Material(
      color: palette.ink.withValues(alpha: .94),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                'A cleaner way\nto cancel.',
                style: TextStyle(
                  color: palette.background,
                  fontSize: 48,
                  height: .96,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2.4,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Choose a situation, set the tone, include a detail and generate a message.',
                style: TextStyle(
                  color: palette.background.withValues(alpha: .72),
                  fontSize: 17,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton(
                  onPressed: onDone,
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.background,
                    foregroundColor: palette.ink,
                  ),
                  child: const Text('START'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
