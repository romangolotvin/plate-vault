import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../data/models/rarity.dart';
import '../../data/valuation/currency.dart';
import '../../data/valuation/plate_valuation_engine.dart';

class DailyContractCard extends StatelessWidget {
  const DailyContractCard({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final daily = state.dailyState;
    if (daily == null) return const SizedBox.shrink();

    final contract = daily.contract;
    final done = daily.isCompleteToday;
    final bonusText = _formatBonus(contract.bonusRub, state.currency);

    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        compact ? 12 : 16,
        14,
        compact ? 12 : 16,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: done
              ? [
                  VaultColors.panel,
                  VaultColors.uncommon.withValues(alpha: 0.18),
                ]
              : [
                  VaultColors.panel,
                  VaultColors.purple.withValues(alpha: 0.2),
                  VaultColors.magenta.withValues(alpha: 0.1),
                ],
        ),
        border: Border.all(
          color: done
              ? VaultColors.uncommon.withValues(alpha: 0.55)
              : VaultColors.purpleBright.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: (done ? VaultColors.uncommon : VaultColors.purple)
                .withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.verified_rounded : Icons.bolt_rounded,
                color: done ? VaultColors.uncommon : VaultColors.purpleBright,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  done ? 'Контракт дня выполнен' : 'Контракт дня',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: VaultColors.cream,
                      ),
                ),
              ),
              Text(
                contract.dayKey,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: VaultColors.mist,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            contract.titleRu,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: done ? VaultColors.uncommon : VaultColors.purpleBright,
                  fontSize: compact ? 20 : 24,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            contract.bodyRu,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: VaultColors.mist,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: VaultColors.purple.withValues(alpha: 0.2),
                  border: Border.all(
                    color: VaultColors.purpleBright.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  contract.badgeRu,
                  style: const TextStyle(
                    color: VaultColors.purpleBright,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '+$bonusText',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: VaultColors.magenta,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 8),
            Text(
              done
                  ? 'Бонус уже в Street-рейтинге. Завтра — новый контракт.'
                  : 'Выполни, добавив подходящий Street-номер через Скан.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: VaultColors.mist.withValues(alpha: 0.9),
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatBonus(double rub, AppCurrency currency) {
    return PlateValuationEngine.instance.formatDetailed(
      PlateValuation(
        amountRub: rub,
        rarityScore: 0,
        rarity: Rarity.common,
        rationale: '',
      ),
      currency,
    );
  }
}
