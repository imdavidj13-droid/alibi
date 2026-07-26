import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/generated_excuse.dart';
import '../../../theme/alibi_theme.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    required this.initialExcuse,
    required this.onAnother,
    required this.isFavourite,
    required this.onFavourite,
    super.key,
  });

  final GeneratedExcuse initialExcuse;
  final GeneratedExcuse Function() onAnother;
  final bool Function(GeneratedExcuse) isFavourite;
  final Future<void> Function(GeneratedExcuse) onFavourite;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late GeneratedExcuse _excuse = widget.initialExcuse;

  @override
  Widget build(BuildContext context) {
    final palette = context.alibiPalette;
    final favourite = widget.isFavourite(_excuse);

    return Scaffold(
      backgroundColor: palette.ink,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: palette.background),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () async {
                            await widget.onFavourite(_excuse);
                            if (mounted) setState(() {});
                          },
                          icon: Icon(
                            favourite ? Icons.bookmark : Icons.bookmark_border,
                            color: palette.background,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 54),
                    Text(
                      '${_excuse.situation} / ${_excuse.tone}'.toUpperCase(),
                      style: TextStyle(
                        color: palette.accent,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _excuse.text,
                      style: TextStyle(
                        color: palette.background,
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
                              foregroundColor: palette.background,
                              side: BorderSide(
                                color: palette.background.withValues(
                                  alpha: .35,
                                ),
                              ),
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
                              backgroundColor: palette.background,
                              foregroundColor: palette.ink,
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
                            backgroundColor: palette.surface,
                            foregroundColor: palette.ink,
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

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.alibiPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: palette.background.withValues(alpha: .58),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: TextStyle(
            color: palette.background,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
