import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/vault_cta.dart';
import '../../core/widgets/vault_page.dart';
import '../../data/leaderboard/leaderboard_service.dart';
import '../../data/models/rarity.dart';
import '../../data/valuation/plate_valuation_engine.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _season = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entries = _season ? state.seasonBoard : state.streetBoard;
    final season = state.currentSeason;

    return VaultPage(
      appBar: AppBar(
        title: const Text('Рейтинг'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => state.refreshLeaderboards(),
            icon: const Icon(Icons.refresh, color: VaultColors.purpleBright),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: VaultHeroPanel(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _season ? 'СЕЗОН' : 'STREET',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: VaultColors.purpleBright,
                          letterSpacing: 2.4,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _season
                        ? season.labelRu
                        : 'Весь Street-портфель',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: VaultColors.cream,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _season
                        ? 'Считаются только номера, пойманные в этом месяце'
                        : LeaderboardKind.street.subtitleRu,
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
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Всё время')),
                ButtonSegment(value: true, label: Text('Сезон')),
              ],
              selected: {_season},
              onSelectionChanged: (s) => setState(() => _season = s.first),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        _season
                            ? 'В этом сезоне пока пусто — выйди на охоту.'
                            : 'Пока нет Street-портфелей. Сними номер с двух ракурсов.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: VaultColors.mist,
                            ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final e = entries[index];
                      final value = PlateValuationEngine.instance.formatDetailed(
                        PlateValuation(
                          amountRub: e.portfolioRub,
                          rarityScore: 0,
                          rarity: Rarity.common,
                          rationale: '',
                        ),
                        state.currency,
                      );
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: e.isMe
                              ? VaultColors.purple.withValues(alpha: 0.18)
                              : VaultColors.panel.withValues(alpha: 0.9),
                          border: Border.all(
                            color: e.isMe
                                ? VaultColors.purpleBright
                                : VaultColors.purple.withValues(alpha: 0.22),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: VaultColors.purpleDim,
                            child: Text(
                              '#${e.rank}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: VaultColors.cream,
                              ),
                            ),
                          ),
                          title: Text(
                            e.isMe ? '${e.displayName} (ты)' : e.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text('${e.plateCount} номеров · $value'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
