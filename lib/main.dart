import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'models/generated_excuse.dart';
import 'services/alibi_storage.dart';
import 'services/excuse_generator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlibiApp());
}

class AlibiApp extends StatelessWidget {
  const AlibiApp({super.key});

  static const background = Color(0xFFF0B8B1);
  static const ink = Color(0xFF171313);
  static const accent = Color(0xFF7C2424);
  static const muted = Color(0xFF684D4A);
  static const paper = Color(0xFFFFF8F4);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alibi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _NoPageTransitionsBuilder(),
            TargetPlatform.iOS: _NoPageTransitionsBuilder(),
            TargetPlatform.windows: _NoPageTransitionsBuilder(),
            TargetPlatform.macOS: _NoPageTransitionsBuilder(),
            TargetPlatform.linux: _NoPageTransitionsBuilder(),
          },
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
          surface: paper,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: ink,
            fontSize: 58,
            height: .92,
            fontWeight: FontWeight.w900,
            letterSpacing: -3.2,
          ),
          headlineMedium: TextStyle(
            color: ink,
            fontSize: 30,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
          bodyLarge: TextStyle(color: ink, fontSize: 16, height: 1.5),
        ),
      ),
      home: const AlibiShell(),
    );
  }
}

enum ExcuseLength { short, standard, detailed }

class AlibiShell extends StatefulWidget {
  const AlibiShell({super.key});

  @override
  State<AlibiShell> createState() => _AlibiShellState();
}

class _AlibiShellState extends State<AlibiShell> {
  final ExcuseGenerator _generator = ExcuseGenerator();
  final AlibiStorage _storage = AlibiStorage();
  final TextEditingController _contextController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _situations = const [
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

  final List<String> _tones = const [
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

  Future<void> _savePreferences() async {
    await _storage.savePreferences(
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
    final context = _contextController.text.trim();
    var text = base.text;

    if (context.isNotEmpty) {
      text = switch (_length) {
        ExcuseLength.short => '$context. ${_firstSentence(text)}',
        ExcuseLength.standard => '$context. $text',
        ExcuseLength.detailed =>
          '$context. $text I wanted to explain properly rather than leave you guessing.',
      };
    } else {
      text = switch (_length) {
        ExcuseLength.short => _firstSentence(text),
        ExcuseLength.standard => text,
        ExcuseLength.detailed =>
          '$text I wanted to give you enough notice rather than leave this until later.',
      };
    }

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

  String _firstSentence(String text) {
    final match = RegExp(r'^.*?[.!?](?:\s|$)').firstMatch(text);
    return match?.group(0)?.trim() ?? text;
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

  Future<void> _dismissOnboarding() async {
    await _storage.markOnboardingSeen();
    if (!mounted) return;
    setState(() => _showOnboarding = false);
  }

  void _openPage(Widget page) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _clearHistory() async {
    await _storage.clearHistory();
    if (!mounted) return;
    setState(() => _history = []);
  }

  Future<void> _clearFavourites() async {
    await _storage.clearFavourites();
    if (!mounted) return;
    setState(() => _favourites = []);
  }

  Future<void> _resetOnboarding() async {
    await _storage.resetOnboarding();
    if (!mounted) return;
    Navigator.of(context).pop();
    setState(() => _showOnboarding = true);
  }

  @override
  void dispose() {
    _contextController.dispose();
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
          drawer: _AlibiDrawer(
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
              _SettingsPage(
                situations: _situations,
                tones: _tones,
                situation: _situation,
                tone: _tone,
                length: _length,
                safeMode: _safeMode,
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
                onClearHistory: _clearHistory,
                onClearFavourites: _clearFavourites,
              ),
            ),
            onHowItWorks: () => _openPage(const _HowItWorksPage()),
            onAbout: () => _openPage(const _AboutPage()),
            onPrivacy: () => _openPage(const _PrivacyPage()),
            onResetOnboarding: _resetOnboarding,
          ),
          body: SafeArea(
            child: IndexedStack(
              index: _tab,
              children: [
                _GeneratorPage(
                  situations: _situations,
                  tones: _tones,
                  selectedSituation: _situation,
                  selectedTone: _tone,
                  length: _length,
                  safeMode: _safeMode,
                  contextController: _contextController,
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
                        builder: (_) => _ResultPage(
                          initialExcuse: excuse,
                          onAnother: _generate,
                          isFavourite: _isFavourite,
                          onFavourite: _toggleFavourite,
                        ),
                      ),
                    );
                  },
                ),
                _LibraryPage(
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
            backgroundColor: AlibiApp.paper,
            indicatorColor: AlibiApp.background,
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
        if (_showOnboarding)
          _OnboardingOverlay(onDone: _dismissOnboarding),
      ],
    );
  }
}

class _GeneratorPage extends StatelessWidget {
  const _GeneratorPage({
    required this.situations,
    required this.tones,
    required this.selectedSituation,
    required this.selectedTone,
    required this.length,
    required this.safeMode,
    required this.contextController,
    required this.onMenu,
    required this.onSituationChanged,
    required this.onToneChanged,
    required this.onLengthChanged,
    required this.onSafeModeChanged,
    required this.onGenerate,
  });

  final List<String> situations;
  final List<String> tones;
  final String selectedSituation;
  final String selectedTone;
  final ExcuseLength length;
  final bool safeMode;
  final TextEditingController contextController;
  final VoidCallback onMenu;
  final ValueChanged<String> onSituationChanged;
  final ValueChanged<String> onToneChanged;
  final ValueChanged<ExcuseLength> onLengthChanged;
  final ValueChanged<bool> onSafeModeChanged;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
          sliver: SliverList.list(
            children: [
              _BrandHeader(onMenu: onMenu),
              const SizedBox(height: 48),
              Text(
                'Say less.\nGet out clean.',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 18),
              const Text(
                'Build a convincing message without over-explaining.',
                style: TextStyle(
                  color: AlibiApp.muted,
                  fontSize: 17,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 42),
              const _Label('SITUATION'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: situations.map((item) {
                  return ChoiceChip(
                    label: Text(item),
                    selected: item == selectedSituation,
                    onSelected: (_) => onSituationChanged(item),
                    showCheckmark: false,
                    selectedColor: AlibiApp.ink,
                    backgroundColor: Colors.transparent,
                    labelStyle: TextStyle(
                      color: item == selectedSituation
                          ? Colors.white
                          : AlibiApp.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    side: const BorderSide(color: Color(0x44171313)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 34),
              const _Label('TONE'),
              const SizedBox(height: 12),
              ...tones.map(
                (item) => _ToneTile(
                  title: item,
                  selected: item == selectedTone,
                  onTap: () => onToneChanged(item),
                ),
              ),
              const SizedBox(height: 28),
              const _Label('LENGTH'),
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
                controller: contextController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Optional detail',
                  hintText: 'Example: mention my car without sounding dramatic',
                  filled: true,
                  fillColor: const Color(0x33FFF8F4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
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
                    backgroundColor: AlibiApp.ink,
                    foregroundColor: Colors.white,
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

class _ResultPage extends StatefulWidget {
  const _ResultPage({
    required this.initialExcuse,
    required this.onAnother,
    required this.isFavourite,
    required this.onFavourite,
  });

  final GeneratedExcuse initialExcuse;
  final GeneratedExcuse Function() onAnother;
  final bool Function(GeneratedExcuse) isFavourite;
  final Future<void> Function(GeneratedExcuse) onFavourite;

  @override
  State<_ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<_ResultPage> {
  late GeneratedExcuse _excuse = widget.initialExcuse;

  @override
  Widget build(BuildContext context) {
    final favourite = widget.isFavourite(_excuse);
    return Scaffold(
      backgroundColor: AlibiApp.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () async {
                      await widget.onFavourite(_excuse);
                      if (mounted) setState(() {});
                    },
                    icon: Icon(
                      favourite ? Icons.bookmark : Icons.bookmark_border,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${_excuse.situation} / ${_excuse.tone}'.toUpperCase(),
                style: const TextStyle(
                  color: AlibiApp.background,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _excuse.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 31,
                  height: 1.22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.8,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  _Metric(
                    label: 'BELIEVABILITY',
                    value: '${_excuse.believability.round()}%',
                  ),
                  const SizedBox(width: 40),
                  _Metric(
                    label: 'FOLLOW-UP RISK',
                    value: _excuse.followUpRiskLabel,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _excuse = widget.onAnother());
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Another'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: _excuse.text),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AlibiApp.background,
                        foregroundColor: AlibiApp.ink,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(text: _excuse.text),
                    ),
                    icon: const Icon(Icons.ios_share),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AlibiApp.ink,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryPage extends StatelessWidget {
  const _LibraryPage({
    required this.history,
    required this.favourites,
    required this.isFavourite,
    required this.onFavourite,
    required this.onMenu,
  });

  final List<GeneratedExcuse> history;
  final List<GeneratedExcuse> favourites;
  final bool Function(GeneratedExcuse) isFavourite;
  final Future<void> Function(GeneratedExcuse) onFavourite;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: _BrandHeader(onMenu: onMenu),
          ),
          const TabBar(
            tabs: [Tab(text: 'History'), Tab(text: 'Favourites')],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ExcuseList(
                  items: history,
                  isFavourite: isFavourite,
                  onFavourite: onFavourite,
                ),
                _ExcuseList(
                  items: favourites,
                  isFavourite: isFavourite,
                  onFavourite: onFavourite,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExcuseList extends StatelessWidget {
  const _ExcuseList({
    required this.items,
    required this.isFavourite,
    required this.onFavourite,
  });

  final List<GeneratedExcuse> items;
  final bool Function(GeneratedExcuse) isFavourite;
  final Future<void> Function(GeneratedExcuse) onFavourite;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Nothing saved yet.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 32),
      itemBuilder: (context, index) {
        final item = items[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.situation} · ${item.tone}'.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: AlibiApp.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.text,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => onFavourite(item),
              icon: Icon(
                isFavourite(item) ? Icons.bookmark : Icons.bookmark_border,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AlibiDrawer extends StatelessWidget {
  const _AlibiDrawer({
    required this.selectedTab,
    required this.onGenerate,
    required this.onLibrary,
    required this.onSettings,
    required this.onHowItWorks,
    required this.onAbout,
    required this.onPrivacy,
    required this.onResetOnboarding,
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
    return Drawer(
      width: MediaQuery.sizeOf(context).width * .84,
      backgroundColor: AlibiApp.background,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'ALIBI',
                    style: TextStyle(
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
              _DrawerItem(
                icon: Icons.auto_awesome_outlined,
                label: 'Generate',
                selected: selectedTab == 0,
                onTap: onGenerate,
              ),
              _DrawerItem(
                icon: Icons.bookmarks_outlined,
                label: 'Library',
                selected: selectedTab == 1,
                onTap: onLibrary,
              ),
              const _DrawerDivider(),
              _DrawerItem(
                icon: Icons.tune_rounded,
                label: 'Settings',
                onTap: onSettings,
              ),
              _DrawerItem(
                icon: Icons.lightbulb_outline_rounded,
                label: 'How Alibi works',
                onTap: onHowItWorks,
              ),
              _DrawerItem(
                icon: Icons.info_outline_rounded,
                label: 'About',
                onTap: onAbout,
              ),
              _DrawerItem(
                icon: Icons.shield_outlined,
                label: 'Privacy',
                onTap: onPrivacy,
              ),
              const _DrawerDivider(),
              _DrawerItem(
                icon: Icons.replay_rounded,
                label: 'Reset onboarding',
                onTap: onResetOnboarding,
              ),
              const Spacer(),
              const Text(
                'STUDIO XIII',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                  color: AlibiApp.muted,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Version 1.1.0',
                style: TextStyle(color: AlibiApp.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
            if (selected)
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AlibiApp.accent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(color: Color(0x33171313)),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.situations,
    required this.tones,
    required this.situation,
    required this.tone,
    required this.length,
    required this.safeMode,
    required this.onSituationChanged,
    required this.onToneChanged,
    required this.onLengthChanged,
    required this.onSafeModeChanged,
    required this.onClearHistory,
    required this.onClearFavourites,
  });

  final List<String> situations;
  final List<String> tones;
  final String situation;
  final String tone;
  final ExcuseLength length;
  final bool safeMode;
  final ValueChanged<String> onSituationChanged;
  final ValueChanged<String> onToneChanged;
  final ValueChanged<ExcuseLength> onLengthChanged;
  final ValueChanged<bool> onSafeModeChanged;
  final Future<void> Function() onClearHistory;
  final Future<void> Function() onClearFavourites;

  @override
  Widget build(BuildContext context) {
    return _InfoScaffold(
      title: 'Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('DEFAULTS'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: situation,
            decoration: const InputDecoration(labelText: 'Default situation'),
            items: situations
                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
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
                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: (value) {
              if (value != null) onToneChanged(value);
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Default length',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
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
          const _Label('DATA'),
          const SizedBox(height: 8),
          _ActionRow(
            title: 'Clear generation history',
            subtitle: 'Removes every generated excuse from this device.',
            onTap: () => _confirmAction(
              context,
              title: 'Clear history?',
              body: 'This cannot be undone.',
              action: onClearHistory,
            ),
          ),
          _ActionRow(
            title: 'Clear favourites',
            subtitle: 'Removes every saved excuse from this device.',
            onTap: () => _confirmAction(
              context,
              title: 'Clear favourites?',
              body: 'This cannot be undone.',
              action: onClearFavourites,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String body,
    required Future<void> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) await action();
  }
}

class _HowItWorksPage extends StatelessWidget {
  const _HowItWorksPage();

  @override
  Widget build(BuildContext context) {
    return const _InfoScaffold(
      title: 'How Alibi works',
      child: Column(
        children: [
          _NumberedInfo(
            number: '01',
            title: 'Choose the situation',
            body: 'Select who the message is for and what kind of commitment you need to leave.',
          ),
          _NumberedInfo(
            number: '02',
            title: 'Set the tone',
            body: 'Keep it believable, make it dramatic, be completely honest or deliberately absurd.',
          ),
          _NumberedInfo(
            number: '03',
            title: 'Add useful context',
            body: 'Include an optional detail when the message needs to mention something specific.',
          ),
          _NumberedInfo(
            number: '04',
            title: 'Copy, share or save',
            body: 'Use the result immediately or bookmark it in your private local library.',
          ),
        ],
      ),
    );
  }
}

class _AboutPage extends StatelessWidget {
  const _AboutPage();

  @override
  Widget build(BuildContext context) {
    return const _InfoScaffold(
      title: 'About',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A cleaner way\nto cancel.',
            style: TextStyle(
              fontSize: 42,
              height: .98,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Alibi is a lightweight offline excuse generator designed to create varied, useful messages without accounts, subscriptions or unnecessary setup.',
            style: TextStyle(fontSize: 17, height: 1.55),
          ),
          SizedBox(height: 34),
          _Label('MADE BY'),
          SizedBox(height: 10),
          Text(
            'STUDIO XIII',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 8),
          Text('Version 1.1.0', style: TextStyle(color: AlibiApp.muted)),
        ],
      ),
    );
  }
}

class _PrivacyPage extends StatelessWidget {
  const _PrivacyPage();

  @override
  Widget build(BuildContext context) {
    return const _InfoScaffold(
      title: 'Privacy',
      child: Column(
        children: [
          _PrivacyItem(
            title: 'No account required',
            body: 'Alibi does not ask you to create an account or provide personal profile information.',
          ),
          _PrivacyItem(
            title: 'Generated locally',
            body: 'Excuses are assembled on your device from the built-in phrase library.',
          ),
          _PrivacyItem(
            title: 'Local storage only',
            body: 'History, favourites and preferences stay in the app storage on your device.',
          ),
          _PrivacyItem(
            title: 'You control sharing',
            body: 'Nothing leaves the app unless you deliberately copy or share a generated message.',
          ),
        ],
      ),
    );
  }
}

class _InfoScaffold extends StatelessWidget {
  const _InfoScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Spacer(),
                  const Text(
                    'ALIBI',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 34),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 32),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AlibiApp.muted, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    );
  }
}

class _NumberedInfo extends StatelessWidget {
  const _NumberedInfo({
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              color: AlibiApp.accent,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: const TextStyle(
                    color: AlibiApp.muted,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyItem extends StatelessWidget {
  const _PrivacyItem({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: AlibiApp.muted,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingOverlay extends StatelessWidget {
  const _OnboardingOverlay({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AlibiApp.ink.withValues(alpha: .92),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text(
                'ALIBI / FIRST RUN',
                style: TextStyle(
                  color: AlibiApp.background,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'A cleaner way\nto cancel.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  height: .96,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2.4,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Choose a situation, set the tone, add an optional detail and generate a message. Save the good ones for later.',
                style: TextStyle(
                  color: Colors.white70,
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
                    backgroundColor: AlibiApp.background,
                    foregroundColor: AlibiApp.ink,
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

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.onMenu});

  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onMenu,
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Open menu',
        ),
        const SizedBox(width: 10),
        const Text(
          'ALIBI',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
          ),
        ),
        const Spacer(),
        const Text(
          'STUDIO XIII',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: AlibiApp.muted,
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: AlibiApp.accent,
      ),
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
                border: Border.all(color: AlibiApp.ink, width: 2),
                color: selected ? AlibiApp.ink : Colors.transparent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: AlibiApp.muted)),
                ],
              ),
            ),
          ],
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
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
