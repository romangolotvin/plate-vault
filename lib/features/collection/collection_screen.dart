import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/plate_card.dart';
import '../../core/widgets/share_plate_card.dart';
import '../../core/widgets/vault_page.dart';
import '../../data/models/rarity.dart';
import '../../data/models/trust_level.dart';
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
    final streetLabel = PlateValuationEngine.instance.formatDetailed(
      PlateValuation(
        amountRub: state.streetWorthRub,
        rarityScore: 0,
        rarity: Rarity.common,
        rationale: '',
      ),
      state.currency,
    );
    final unlocked = state.achievements.where((a) => a.unlocked).length;

    return VaultPage(
      appBar: AppBar(
        title: const Text('Моя коллекция'),
        actions: [
          IconButton(
            tooltip: 'Достижения',
            onPressed: () => _showAchievements(context, state),
            icon: Badge(
              isLabelVisible: unlocked > 0,
              label: Text('$unlocked'),
              child: const Icon(Icons.military_tech_outlined,
                  color: VaultColors.gold),
            ),
          ),
          IconButton(
            tooltip: 'Добавить вручную',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EditPlateScreen(
                    captureSource: CaptureSource.manual,
                    trust: TrustLevel.unverified,
                  ),
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
              streetCount: state.streetCount,
              totalLabel: totalLabel,
              streetLabel: streetLabel,
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
                  label: 'Street↑',
                  selected: state.sort == CollectionSort.streetFirst,
                  onTap: () =>
                      state.setFilters(sortBy: CollectionSort.streetFirst),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Редкость',
                  selected: state.sort == CollectionSort.rarityDesc,
                  onTap: () =>
                      state.setFilters(sortBy: CollectionSort.rarityDesc),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: state.trustFilter == TrustFilter.street,
                  label: const Text('Street'),
                  onSelected: (v) => state.setFilters(
                    trust: v ? TrustFilter.street : TrustFilter.all,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: state.trustFilter == TrustFilter.unverified,
                  label: const Text('Unverified'),
                  onSelected: (v) => state.setFilters(
                    trust: v ? TrustFilter.unverified : TrustFilter.all,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: state.favoritesOnly,
                  label: const Text('★'),
                  onSelected: (v) => state.setFilters(favOnly: v),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: state.showcaseOnly,
                  label: const Text('Витрина'),
                  onSelected: (v) => state.setFilters(showOnly: v),
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
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const EditPlateScreen(
                            captureSource: CaptureSource.manual,
                            trust: TrustLevel.unverified,
                          ),
                        ),
                      );
                    },
                    onManual: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const EditPlateScreen(
                            captureSource: CaptureSource.manual,
                            trust: TrustLevel.unverified,
                          ),
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
                      return TweenAnimationBuilder<double>(
                        key: ValueKey(item.id),
                        tween: Tween(begin: 0.94, end: 1),
                        duration: Duration(milliseconds: 280 + (index % 5) * 40),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: PlateCard(
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
                          onFavorite: () => state.toggleFavorite(item),
                          onShowcase: () => state.toggleShowcase(item),
                          onShare: () => showSharePlateCard(
                            context,
                            item: item,
                            currency: state.currency,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAchievements(BuildContext context, AppState state) async {
    final list = state.achievements;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: VaultColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Text(
              'Достижения охотника',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: VaultColors.gold,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            ...list.map(
              (a) => ListTile(
                leading: Icon(
                  a.unlocked ? Icons.emoji_events : Icons.lock_outline,
                  color: a.unlocked ? VaultColors.gold : VaultColors.mist,
                ),
                title: Text(a.titleRu),
                subtitle: Text(
                  '${a.detailRu}${a.goal > 1 ? ' · ${a.progress}/${a.goal}' : ''}',
                  style: const TextStyle(color: VaultColors.mist),
                ),
              ),
            ),
          ],
        );
      },
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
    required this.streetCount,
    required this.totalLabel,
    required this.streetLabel,
  });

  final int count;
  final int streetCount;
  final String totalLabel;
  final String streetLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VaultColors.gold.withValues(alpha: 0.14),
                  border: Border.all(
                    color: VaultColors.gold.withValues(alpha: 0.4),
                  ),
                ),
                child:
                    const Icon(Icons.savings_outlined, color: VaultColors.gold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Весь сейф',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: VaultColors.mist,
                            letterSpacing: 0.6,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      totalLabel,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
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
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.verified, size: 16, color: VaultColors.teal),
              const SizedBox(width: 6),
              Text(
                'Street $streetLabel · $streetCount',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: VaultColors.teal,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
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
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (context, s, child) =>
                  Transform.scale(scale: s, child: child),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 56,
                color: VaultColors.gold.withValues(alpha: 0.65),
              ),
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
              'Сними номер камерой — получишь Street. '
              'Ручной ввод тоже можно, но без Street-рейтинга. Редкие серии поднимают цену сейфа.',
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Открой вкладку «Скан» → Камера · Street',
                    ),
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
