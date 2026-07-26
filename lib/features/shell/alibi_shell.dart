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

  static const _situations = ExcuseGenerator.situations;
  static const _tones = ExcuseGenerator.tones;

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

  GeneratedExcuse _generate() {
    final result = _generator.generate(
      situation: _situation,
      tone: _tone,
      length: _length,
      detail: _detailController.text,
      safeMode: _safeMode,
    );

    _history = [
      result,
      ..._history.where((item) => item.text != result.text),
    ].take(50).toList();
    _storage.saveHistory(_history);
    return result;
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

  bool _isFavourite(GeneratedExcuse excuse) {
    return _favourites.any((item) => item.text == excuse.text);
  }

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

  void _setSituation(String value) {
    setState(() => _situation = value);
    _savePreferences();
  }

  void _setTone(String value) {
    setState(() => _tone = value);
    _savePreferences();
  }

  void _setLength(ExcuseLength value) {
    setState(() => _length = value);
    _savePreferences();
  }

  void _setSafeMode(bool value) {
    setState(() => _safeMode = value);
    _savePreferences();
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
                onSituationChanged: _setSituation,
                onToneChanged: _setTone,
                onLengthChanged: _setLength,
                onSafeModeChanged: _setSafeMode,
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
                  onSituationChanged: _setSituation,
                  onToneChanged: _setTone,
                  onLengthChanged: _setLength,
                  onSafeModeChanged: _setSafeMode,
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
                  child: const Text(
                    'START',
                    style: TextStyle(
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
    );
  }
}
