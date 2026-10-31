import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/vault_cta.dart';
import '../../core/widgets/vault_page.dart';
import '../../data/models/rarity.dart';
import '../../data/valuation/plate_valuation_engine.dart';
import '../daily/daily_contract_card.dart';
import '../encyclopedia/series_encyclopedia_screen.dart';
import '../museum/museum_section.dart';
import '../sets/sets_screen.dart';
import '../social/play_hub_card.dart';

/// Home tab «Витрина»: музей лучших номеров + охотничий хаб (не вся коллекция).
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final streetLabel = PlateValuationEngine.instance.formatDetailed(
      PlateValuation(
        amountRub: state.streetWorthRub,
        rarityScore: 0,
        rarity: Rarity.common,
        rationale: '',
      ),
      state.currency,
    );
    final seasonLabel = PlateValuationEngine.instance.formatDetailed(
      PlateValuation(
        amountRub: state.seasonWorthRub,
        rarityScore: 0,
        rarity: Rarity.common,
        rationale: '',
      ),
      state.currency,
    );
    final unlocked = state.achievements.where((a) => a.unlocked).length;

    return VaultPage(
      appBar: AppBar(
        title: const Text('Витрина'),
        actions: [
          IconButton(
            tooltip: 'Энциклопедия серий',
            onPressed: () => openSeriesEncyclopedia(context),
            icon: const Icon(Icons.menu_book_rounded,
                color: VaultColors.purpleBright),
          ),
          IconButton(
            tooltip: 'Альбомы',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SetsScreen()),
              );
            },
            icon: const Icon(Icons.collections_bookmark_outlined,
                color: VaultColors.magenta),
          ),
          IconButton(
            tooltip: 'Достижения',
            onPressed: () => _showAchievements(context, state),
            icon: Badge(
              isLabelVisible: unlocked > 0,
              label: Text('$unlocked'),
              child: const Icon(Icons.military_tech_outlined,
                  color: VaultColors.purpleBright),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          _VitrinaWorthHeader(
            streetCount: state.streetCount,
            streetLabel: streetLabel,
            seasonLabel: seasonLabel,
            seasonName: state.currentSeason.labelRu,
          ),
          const SizedBox(height: 12),
          const PlayHubCard(),
          const SizedBox(height: 12),
          const DailyContractCard(),
          const SizedBox(height: 12),
          const SetsTeaserCard(),
          const SizedBox(height: 12),
          MuseumSection(
            items: state.collectionRepository.items,
            title: 'Витрина',
            subtitle:
                'До 6 лучших Street-номеров. Полная коллекция — во вкладке «Профиль».',
          ),
          if (state.collectionRepository.items.isEmpty) ...[
            const SizedBox(height: 16),
            const _EmptyVitrina(),
          ],
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
                    color: VaultColors.purpleBright,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            ...list.map(
              (a) => ListTile(
                leading: Icon(
                  a.unlocked ? Icons.emoji_events : Icons.lock_outline,
                  color:
                      a.unlocked ? VaultColors.purpleBright : VaultColors.mist,
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
}

class _VitrinaWorthHeader extends StatelessWidget {
  const _VitrinaWorthHeader({
    required this.streetCount,
    required this.streetLabel,
    required this.seasonLabel,
    required this.seasonName,
  });

  final int streetCount;
  final String streetLabel;
  final String seasonLabel;
  final String seasonName;

  @override
  Widget build(BuildContext context) {
    return VaultHeroPanel(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      VaultColors.purple.withValues(alpha: 0.35),
                      VaultColors.magenta.withValues(alpha: 0.2),
                    ],
                  ),
                  border: Border.all(
                    color: VaultColors.purpleBright.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(Icons.storefront_outlined,
                    color: VaultColors.purpleBright),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Street-витрина',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: VaultColors.mist,
                            letterSpacing: 0.6,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      streetLabel,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: VaultColors.purpleBright,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                  ],
                ),
              ),
              Text(
                '$streetCount шт.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: VaultColors.magenta,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Сезон $seasonName: $seasonLabel',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: VaultColors.purpleBright.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyVitrina extends StatelessWidget {
  const _EmptyVitrina();

  @override
  Widget build(BuildContext context) {
    return VaultHeroPanel(
      child: Column(
        children: [
          Icon(
            Icons.photo_camera_rounded,
            size: 56,
            color: VaultColors.purpleBright.withValues(alpha: 0.85),
          ),
          const SizedBox(height: 14),
          Text(
            'Витрина пока пуста',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: VaultColors.cream,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Сними номер двумя ракурсами на вкладке «Скан» — он попадёт '
            'в коллекцию профиля, а лучшие окажутся здесь.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: VaultColors.mist,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 18),
          VaultCta(
            label: 'Как снимать',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Нижняя панель → «Скан» → два ракурса'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
