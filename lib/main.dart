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
    if (!mounted) return;
    setState(() {
      _history = history;
      _favourites = favourites;
      _showOnboarding = !seen;
      _ready = true;
    });
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
        ExcuseLength.detailed => '$context. $text I wanted to explain properly rather than leave you guessing.',
      };
    } else {
      text = switch (_length) {
        ExcuseLength.short => _firstSentence(text),
        ExcuseLength.standard => text,
        ExcuseLength.detailed => '$text I wanted to give you enough notice rather than leave this until later.',
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
                  onSituationChanged: (value) => setState(() => _situation = value),
                  onToneChanged: (value) => setState(() => _tone = value),
                  onLengthChanged: (value) => setState(() => _length = value),
                  onSafeModeChanged: (value) => setState(() => _safeMode = value),
                  onGenerate: () {
                    final excuse = _generate();
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
              const _BrandHeader(),
              const SizedBox(height: 48),
              Text('Say less.\nGet out clean.', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 18),
              const Text(
                'Build a convincing message without over-explaining.',
                style: TextStyle(color: AlibiApp.muted, fontSize: 17, height: 1.45),
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
                      color: item == selectedSituation ? Colors.white : AlibiApp.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    side: const BorderSide(color: Color(0x44171313)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 34),
              const _Label('TONE'),
              const SizedBox(height: 12),
              ...tones.map((item) => _ToneTile(
                    title: item,
                    selected: item == selectedTone,
                    onTap: () => onToneChanged(item),
                  )),
              const SizedBox(height: 28),
              const _Label('LENGTH'),
              const SizedBox(height: 12),
              SegmentedButton<ExcuseLength>(
                segments: const [
                  ButtonSegment(value: ExcuseLength.short, label: Text('Short')),
                  ButtonSegment(value: ExcuseLength.standard, label: Text('Standard')),
                  ButtonSegment(value: ExcuseLength.detailed, label: Text('Detailed')),
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
                title: const Text('Avoid follow-up questions', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Keeps the story restrained and lowers the risk score.'),
              ),
              const SizedBox(height: 26),
              SizedBox(
                height: 62,
                child: FilledButton(
                  onPressed: onGenerate,
                  style: FilledButton.styleFrom(
                    backgroundColor: AlibiApp.ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('CREATE ALIBI', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
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
                style: const TextStyle(color: AlibiApp.background, fontWeight: FontWeight.w900, letterSpacing: 1.4),
              ),
              const SizedBox(height: 24),
              Text(
                _excuse.text,
                style: const TextStyle(color: Colors.white, fontSize: 31, height: 1.22, fontWeight: FontWeight.w700, letterSpacing: -.8),
              ),
              const Spacer(),
              Row(
                children: [
                  _Metric(label: 'BELIEVABILITY', value: '${_excuse.believability.round()}%'),
                  const SizedBox(width: 40),
                  _Metric(label: 'FOLLOW-UP RISK', value: _excuse.followUpRiskLabel),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _excuse = widget.onAnother()),
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
                        await Clipboard.setData(ClipboardData(text: _excuse.text));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
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
                    onPressed: () => SharePlus.instance.share(ShareParams(text: _excuse.text)),
                    icon: const Icon(Icons.ios_share),
                    style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AlibiApp.ink),
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
  });

  final List<GeneratedExcuse> history;
  final List<GeneratedExcuse> favourites;
  final bool Function(GeneratedExcuse) isFavourite;
  final Future<void> Function(GeneratedExcuse) onFavourite;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: _BrandHeader(),
          ),
          const TabBar(tabs: [Tab(text: 'History'), Tab(text: 'Favourites')]),
          Expanded(
            child: TabBarView(
              children: [
                _ExcuseList(items: history, isFavourite: isFavourite, onFavourite: onFavourite),
                _ExcuseList(items: favourites, isFavourite: isFavourite, onFavourite: onFavourite),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExcuseList extends StatelessWidget {
  const _ExcuseList({required this.items, required this.isFavourite, required this.onFavourite});

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
                  Text('${item.situation} · ${item.tone}'.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: AlibiApp.accent)),
                  const SizedBox(height: 8),
                  Text(item.text, style: const TextStyle(fontSize: 16, height: 1.45, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => onFavourite(item),
              icon: Icon(isFavourite(item) ? Icons.bookmark : Icons.bookmark_border),
            ),
          ],
        );
      },
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
              const Text('ALIBI / FIRST RUN', style: TextStyle(color: AlibiApp.background, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
              const SizedBox(height: 24),
              const Text('A cleaner way\nto cancel.', style: TextStyle(color: Colors.white, fontSize: 48, height: .96, fontWeight: FontWeight.w900, letterSpacing: -2.4)),
              const SizedBox(height: 22),
              const Text('Choose a situation, set the tone, add an optional detail and generate a message. Save the good ones for later.', style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.5)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton(
                  onPressed: onDone,
                  style: FilledButton.styleFrom(backgroundColor: AlibiApp.background, foregroundColor: AlibiApp.ink),
                  child: const Text('START', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
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
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text('ALIBI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
        Spacer(),
        Text('STUDIO XIII', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: AlibiApp.muted)),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AlibiApp.accent));
  }
}

class _ToneTile extends StatelessWidget {
  const _ToneTile({required this.title, required this.selected, required this.onTap});

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
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
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
