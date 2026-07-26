import 'package:flutter/material.dart';

import '../../../models/generated_excuse.dart';
import '../../../shared/widgets/alibi_widgets.dart';
import '../../../theme/alibi_theme.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({
    required this.history,
    required this.favourites,
    required this.isFavourite,
    required this.onFavourite,
    required this.onMenu,
    super.key,
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
            child: AlibiHeader(onMenu: onMenu),
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
    final palette = context.alibiPalette;
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Nothing saved yet.',
          style: TextStyle(color: palette.muted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(
        height: 32,
        color: palette.ink.withValues(alpha: .14),
      ),
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
                    style: TextStyle(
                      color: palette.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.text,
                    style: TextStyle(
                      color: palette.ink,
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
