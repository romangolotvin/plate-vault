import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets/vault_cta.dart';
import '../../core/widgets/vault_page.dart';
import '../../data/series/plate_meaning.dart';
import '../../data/series/series_catalog.dart';

class SeriesEncyclopediaScreen extends StatefulWidget {
  const SeriesEncyclopediaScreen({super.key, this.initialSeriesKey});

  final String? initialSeriesKey;

  @override
  State<SeriesEncyclopediaScreen> createState() =>
      _SeriesEncyclopediaScreenState();
}

class _SeriesEncyclopediaScreenState extends State<SeriesEncyclopediaScreen> {
  late final TextEditingController _queryCtrl;
  MeaningKind? _kind;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController(text: widget.initialSeriesKey ?? '');
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _query => _queryCtrl.text.trim();

  @override
  Widget build(BuildContext context) {
    final all = RuCivilianSeriesCatalog.encyclopediaEntries();
    final filtered = all.where((e) {
      if (_kind != null && e.kind != _kind) return false;
      if (_query.isEmpty) return true;
      final q = _query.toUpperCase();
      return e.seriesKey.contains(q) ||
          e.label.toUpperCase().contains(q) ||
          e.text.toUpperCase().contains(q);
    }).toList();

    return VaultPage(
      appBar: AppBar(title: const Text('Энциклопедия серий')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: VaultHeroPanel(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RU · фольклор охотников',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: VaultColors.purpleBright,
                          letterSpacing: 1.4,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'МЕР, ЕКХ, АМР, ВОР и другие читаемые серии — '
                    'не официальный реестр, а уличный смысл для сейфа.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: VaultColors.mist,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, color: VaultColors.mist),
                hintText: 'Поиск: МЕР, АМР, ФСБ…',
              ),
              controller: _queryCtrl,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Все'),
                  selected: _kind == null,
                  onSelected: (_) => setState(() => _kind = null),
                ),
                const SizedBox(width: 8),
                ...[
                  MeaningKind.security,
                  MeaningKind.administration,
                  MeaningKind.blatnye,
                  MeaningKind.coolSeries,
                  MeaningKind.government,
                ].map(
                  (k) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: _kind == k,
                      label: Text(k.labelRu),
                      onSelected: (v) =>
                          setState(() => _kind = v ? k : null),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'Ничего не найдено',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: VaultColors.mist),
                    ),
                  )
                : ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _SeriesTile(entry: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SeriesTile extends StatelessWidget {
  const _SeriesTile({required this.entry});

  final KnownSeriesEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = entry.kind.accent;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            VaultColors.panel,
            c.withValues(alpha: 0.14),
          ],
        ),
        border: Border.all(color: c.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: c.withValues(alpha: 0.18),
                  border: Border.all(color: c.withValues(alpha: 0.55)),
                ),
                child: Text(
                  entry.seriesKey,
                  style: TextStyle(
                    color: c,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Text(
                '+${entry.boost}',
                style: TextStyle(
                  color: c,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entry.kind.labelRu,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: c.withValues(alpha: 0.9),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: VaultColors.mist,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

void openSeriesEncyclopedia(
  BuildContext context, {
  String? seriesKey,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SeriesEncyclopediaScreen(initialSeriesKey: seriesKey),
    ),
  );
}
