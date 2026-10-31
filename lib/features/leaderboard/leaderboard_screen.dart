import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/vault_page.dart';
import '../../data/leaderboard/leaderboard_service.dart';
import '../../data/valuation/plate_valuation_engine.dart';
import '../../data/models/rarity.dart';
import '../../data/valuation/currency.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return VaultPage(
      appBar: AppBar(
        title: const Text('Рейтинги'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: VaultColors.gold,
          labelColor: VaultColors.gold,
          unselectedLabelColor: VaultColors.mist,
          tabs: const [
            Tab(text: 'Street'),
            Tab(text: 'Неквалиф.'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => state.refreshLeaderboards(),
            icon: const Icon(Icons.refresh, color: VaultColors.gold),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _BoardList(
            kind: LeaderboardKind.street,
            entries: state.streetBoard,
            currency: state.currency,
            emptyHint:
                'Street пока пуст — снимай номера камерой в приложении.',
          ),
          _BoardList(
            kind: LeaderboardKind.unverified,
            entries: state.unverifiedBoard,
            currency: state.currency,
            emptyHint:
                'Добавь номера вручную или из галереи — они попадут сюда.',
          ),
        ],
      ),
    );
  }
}

class _BoardList extends StatelessWidget {
  const _BoardList({
    required this.kind,
    required this.entries,
    required this.currency,
    required this.emptyHint,
  });

  final LeaderboardKind kind;
  final List<LeaderboardEntry> entries;
  final AppCurrency currency;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  VaultColors.panel,
                  kind == LeaderboardKind.street
                      ? VaultColors.teal.withValues(alpha: 0.16)
                      : VaultColors.gold.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: VaultColors.gold.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kind.labelRu,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: VaultColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  kind.subtitleRu,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: VaultColors.mist,
                      ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      emptyHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: VaultColors.mist,
                          ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    final label = PlateValuationEngine.instance.formatDetailed(
                      PlateValuation(
                        amountRub: e.portfolioRub,
                        rarityScore: 0,
                        rarity: Rarity.common,
                        rationale: '',
                      ),
                      currency,
                    );
                    final medal = switch (e.rank) {
                      1 => '🥇',
                      2 => '🥈',
                      3 => '🥉',
                      _ => '#${e.rank}',
                    };
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: e.isMe
                            ? VaultColors.teal.withValues(alpha: 0.14)
                            : VaultColors.panel.withValues(alpha: 0.95),
                        border: Border.all(
                          color: e.isMe
                              ? VaultColors.teal.withValues(alpha: 0.55)
                              : VaultColors.gold.withValues(alpha: 0.18),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: VaultColors.slate,
                          child: Text(
                            medal,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        title: Text(
                          e.isMe ? '${e.displayName} (вы)' : e.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${e.plateCount} номеров · ${kind.labelRu}',
                          style: const TextStyle(color: VaultColors.mist),
                        ),
                        trailing: Text(
                          label,
                          style: const TextStyle(
                            color: VaultColors.gold,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
