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
  final TextEditingController _detailController = TextEditingController();
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

    var text = base.text;
    final detail = _cleanDetail(_detailController.text);
    if (detail.isNotEmpty) {
      text = _weaveDetail(text, detail, _effectiveTone);
    }

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

  String _cleanDetail(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[.!?,;:]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

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
    return matches.take(2).map((match) => match.group(0)!.trim()).join(' ');
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
    required this.detailController,
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
  final TextEditingController detailController;
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
                controller: detailController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Include a detail',
                  hintText:
                      'Enter a person, place or subject to weave into the message.\nExample: my car, a delivery, Arsenal Women',
                  alignLabelWithHint: true,
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
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
                            favourite
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 54),
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
                        fontSize: 30,
                        height: 1.22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.8,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Wrap(
                      spacing: 40,
                      runSpacing: 24,
                      children: [
                        _Metric(
                          label: 'BELIEVABILITY',
                          value: '${_excuse.believability.round()}%',
                        ),
                        _Metric(
                          label: 'FOLLOW-UP RISK',
                          value: _excuse.followUpRiskLabel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
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
            );
          },
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
              const Divider(height: 28),
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
              const Divider(height: 28),
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
    return _InfoPage(
      title: 'Settings',
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

class _HowItWorksPage extends StatelessWidget {
  const _HowItWorksPage();

  @override
  Widget build(BuildContext context) {
    return const _InfoPage(
      title: 'How Alibi works',
      children: [
        _InfoBlock(
          title: 'Choose the situation',
          body: 'Select who the message is for and what kind of commitment you need to leave.',
        ),
        _InfoBlock(
          title: 'Set the tone',
          body: 'Keep it believable, make it dramatic, be direct or make the excuse deliberately absurd.',
        ),
        _InfoBlock(
          title: 'Include a detail',
          body: 'Enter a person, place or subject. Alibi will weave it into a complete sentence instead of copying it word for word.',
        ),
        _InfoBlock(
          title: 'Copy, share or save',
          body: 'Use the result immediately or bookmark it in your private local library.',
        ),
      ],
    );
  }
}

class _AboutPage extends StatelessWidget {
  const _AboutPage();

  @override
  Widget build(BuildContext context) {
    return const _InfoPage(
      title: 'About',
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
          'Alibi is a lightweight offline excuse generator built by Studio XIII.',
          style: TextStyle(fontSize: 17, height: 1.55),
        ),
      ],
    );
  }
}

class _PrivacyPage extends StatelessWidget {
  const _PrivacyPage();

  @override
  Widget build(BuildContext context) {
    return const _InfoPage(
      title: 'Privacy',
      children: [
        _InfoBlock(
          title: 'No account required',
          body: 'Alibi does not ask you to create an account or provide personal profile information.',
        ),
        _InfoBlock(
          title: 'Generated locally',
          body: 'Excuses are assembled on your device from the built-in phrase library.',
        ),
        _InfoBlock(
          title: 'Local storage only',
          body: 'History, favourites and preferences stay in the app storage on your device.',
        ),
      ],
    );
  }
}

class _InfoPage extends StatelessWidget {
  const _InfoPage({required this.title, required this.children});

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

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.body});

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
                'Choose a situation, set the tone, include an optional detail and generate a message.',
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
