import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/vault_cta.dart';
import '../../core/widgets/vault_page.dart';
import '../../data/leaderboard/leaderboard_service.dart';
import '../../data/models/rarity.dart';
import '../../data/valuation/plate_valuation_engine.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entries = state.streetBoard;

    return VaultPage(
      appBar: AppBar(
        title: const Text('Street-рейтинг'),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: VaultHeroPanel(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STREET',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: VaultColors.purpleBright,
                          letterSpacing: 2.4,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Один рейтинг — по стоимости Street-портфеля',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: VaultColors.cream,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LeaderboardKind.street.subtitleRu,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: VaultColors.mist,
                          height: 1.35,
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
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 56,
                            color: VaultColors.purple.withValues(alpha: 0.7),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Рейтинг пока пуст',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Сними номер двумя ракурсами на вкладке «Скан» — Street-стоимость попадёт сюда.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: VaultColors.mist,
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      final label =
                          PlateValuationEngine.instance.formatDetailed(
                        PlateValuation(
                          amountRub: e.portfolioRub,
                          rarityScore: 0,
                          rarity: Rarity.common,
                          rationale: '',
                        ),
                        state.currency,
                      );
                      final medal = switch (e.rank) {
                        1 => '1',
                        2 => '2',
                        3 => '3',
                        _ => '${e.rank}',
                      };
                      final top = e.rank <= 3;
                      return TweenAnimationBuilder<double>(
                        key: ValueKey(e.userId),
                        tween: Tween(begin: 0.94, end: 1),
                        duration:
                            Duration(milliseconds: 280 + (i % 6) * 35),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: e.isMe
                                  ? [
                                      VaultColors.purple.withValues(alpha: 0.28),
                                      VaultColors.panel,
                                    ]
                                  : [
                                      VaultColors.panel,
                                      VaultColors.slate.withValues(alpha: 0.9),
                                    ],
                            ),
                            border: Border.all(
                              color: e.isMe
                                  ? VaultColors.purpleBright
                                      .withValues(alpha: 0.65)
                                  : VaultColors.purple.withValues(alpha: 0.22),
                              width: top ? 1.4 : 1,
                            ),
                            boxShadow: top
                                ? [
                                    BoxShadow(
                                      color: VaultColors.purple
                                          .withValues(alpha: 0.25),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ]
                                : null,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: top
                                  ? VaultColors.purple.withValues(alpha: 0.35)
                                  : VaultColors.slate,
                              child: Text(
                                medal,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: top
                                      ? VaultColors.purpleBright
                                      : VaultColors.mist,
                                ),
                              ),
                            ),
                            title: Text(
                              e.isMe ? '${e.displayName} (вы)' : e.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(
                              '${e.plateCount} Street-номеров',
                              style: const TextStyle(color: VaultColors.mist),
                            ),
                            trailing: Text(
                              label,
                              style: const TextStyle(
                                color: VaultColors.purpleBright,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
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
}
