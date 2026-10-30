import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/plate_card.dart';
import '../../core/widgets/vault_page.dart';
import '../../data/models/rarity.dart';
import '../../data/valuation/plate_valuation_engine.dart';
import 'edit_plate_screen.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.myItems;
    final dateFmt = DateFormat.yMMMd('ru');
    final totalLabel = PlateValuationEngine.instance.formatDetailed(
      PlateValuation(
        amountRub: state.collectionWorthRub,
        rarityScore: 0,
        rarity: Rarity.common,
        rationale: '',
      ),
      state.currency,
    );

    return VaultPage(
      appBar: AppBar(
        title: const Text('Моя коллекция'),
        actions: [
          IconButton(
            tooltip: 'Добавить вручную',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EditPlateScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_circle_outline, color: VaultColors.gold),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _VaultWorthHeader(
              count: state.collectionRepository.items.length,
              totalLabel: totalLabel,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, color: VaultColors.mist),
                hintText: 'Поиск по номеру или серии',
              ),
              onChanged: (v) => state.setFilters(query: v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _SortChip(
                  label: 'Новые',
                  selected: state.sort == CollectionSort.newest,
                  onTap: () =>
                      state.setFilters(sortBy: CollectionSort.newest),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'По цене',
                  selected: state.sort == CollectionSort.valueDesc,
                  onTap: () =>
                      state.setFilters(sortBy: CollectionSort.valueDesc),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'По редкости',
                  selected: state.sort == CollectionSort.rarityDesc,
                  onTap: () =>
                      state.setFilters(sortBy: CollectionSort.rarityDesc),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(
                    state.countryFilter.isEmpty
                        ? 'Страна: все'
                        : 'Страна: ${state.countryFilter}',
                  ),
                  onSelected: (_) => _pickCountry(context, state),
                ),
                const SizedBox(width: 8),
                ...Rarity.values.map((r) {
                  final selected = state.rarityFilter == r;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: selected,
                      label: Text(r.labelRu),
                      onSelected: (v) {
                        if (v) {
                          state.setFilters(rarity: r);
                        } else {
                          state.setFilters(clearRarity: true);
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? _EmptyVault(
                    onScan: () {
                      // Jump via root navigator to scan is awkward; open edit or hint.
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const EditPlateScreen(),
                        ),
                      );
                    },
                    onManual: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const EditPlateScreen(),
                        ),
                      );
                    },
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return PlateCard(
                        item: item,
                        subtitle: dateFmt.format(item.createdAt),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  EditPlateScreen(existing: item),
                            ),
                          );
                        },
                        onDelete: () => state.deletePlate(item.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCountry(BuildContext context, AppState state) async {
    final countries = {
      '',
      'RU',
      'BY',
      'KZ',
      'UA',
      'US',
      'DE',
      'FR',
      'PL',
      'GB',
      'IT',
      'ES',
      'TR',
      'CN',
      'JP',
      'XX',
    };
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            children: countries
                .map(
                  (c) => ListTile(
                    title: Text(c.isEmpty ? 'Все страны' : c),
                    onTap: () => Navigator.pop(context, c),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    if (selected != null) {
      state.setFilters(country: selected);
    }
  }
}

class _VaultWorthHeader extends StatelessWidget {
  const _VaultWorthHeader({
    required this.count,
    required this.totalLabel,
  });

  final int count;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VaultColors.panel,
            VaultColors.slate.withValues(alpha: 0.95),
            VaultColors.gold.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: VaultColors.gold.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: VaultColors.gold.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VaultColors.gold.withValues(alpha: 0.14),
              border: Border.all(color: VaultColors.gold.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.savings_outlined, color: VaultColors.gold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Стоимость сейфа',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: VaultColors.mist,
                        letterSpacing: 0.6,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  totalLabel,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: VaultColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          Text(
            '$count шт.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: VaultColors.teal,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: VaultColors.gold.withValues(alpha: 0.28),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  const _EmptyVault({
    required this.onScan,
    required this.onManual,
  });

  final VoidCallback onScan;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: VaultColors.gold.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 14),
            Text(
              'Сейф пуст',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: VaultColors.cream,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Поймай первый номер — редкие серии и столицы поднимают цену сейфа. Сканируй больше, строй коллекцию.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: VaultColors.mist,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onManual,
              icon: const Icon(Icons.add),
              label: const Text('Добавить номер'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                // Prefer navigating user toward Scan tab messaging.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Открой вкладку «Скан» и сфотографируй номер'),
                  ),
                );
                onScan();
              },
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Сканировать ещё'),
            ),
          ],
        ),
      ),
    );
  }
}
