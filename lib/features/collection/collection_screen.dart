import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/plate_card.dart';
import '../../core/widgets/vault_page.dart';
import '../../data/models/rarity.dart';
import 'edit_plate_screen.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.myItems;
    final dateFmt = DateFormat.yMMMd('ru');

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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
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
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: VaultColors.gold.withValues(alpha: 0.55),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Сейф пуст',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Добавьте номер вручную или отсканируйте камерой.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: VaultColors.mist),
                          ),
                        ],
                      ),
                    ),
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
                              builder: (_) => EditPlateScreen(existing: item),
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
