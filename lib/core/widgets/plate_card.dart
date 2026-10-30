import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../data/models/collection_item.dart';
import '../../data/models/rarity.dart';
import '../../data/rarity/rarity_engine.dart';
import '../../data/series/plate_meaning.dart';
import '../../data/valuation/plate_valuation_engine.dart';
import '../theme.dart';
import 'plate_badge.dart';
import 'vault_motion.dart';

class PlateCard extends StatelessWidget {
  const PlateCard({
    super.key,
    required this.item,
    this.subtitle,
    this.onTap,
    this.onDelete,
    this.showMeanings = true,
  });

  final CollectionItem item;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showMeanings;

  @override
  Widget build(BuildContext context) {
    final meanings = showMeanings
        ? RarityEngine.instance.meaningsFor(
            countryCode: item.countryCode,
            rawText: item.rawText,
          )
        : const <PlateMeaningTag>[];
    final currency = context.watch<AppState>().currency;
    final value = PlateValuationEngine.instance.estimate(
      countryCode: item.countryCode,
      rawText: item.rawText,
    );
    final valueLabel =
        PlateValuationEngine.instance.formatDetailed(value, currency);

    final glow = _rarityGlow(item.rarity);
    final juicy = item.rarity.index >= Rarity.rare.index;

    return RarityPulse(
      rarity: item.rarity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  VaultColors.panel.withValues(alpha: 0.98),
                  VaultColors.slate.withValues(alpha: 0.92),
                  glow.withValues(alpha: juicy ? 0.16 : 0.08),
                ],
              ),
              border: Border.all(
                color: glow.withValues(alpha: juicy ? 0.55 : 0.35),
                width: juicy ? 1.3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: juicy ? 0.28 : 0.14),
                  blurRadius: juicy ? 26 : 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: PlateShine(
                          enabled: juicy,
                          child: PlateBadge(
                            text: item.rawText,
                            countryCode: item.countryCode,
                            compact: true,
                          ),
                        ),
                      ),
                      if (onDelete != null)
                        IconButton(
                          tooltip: 'Удалить',
                          onPressed: onDelete,
                          icon: Icon(
                            Icons.delete_outline,
                            color: VaultColors.mist.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      RarityChip(rarity: item.rarity, dense: true),
                      const Spacer(),
                      if (item.isPublic)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            'публичный',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: VaultColors.teal,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color:
                                        VaultColors.mist.withValues(alpha: 0.7),
                                  ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Оценка',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: VaultColors.mist.withValues(alpha: 0.8),
                            ),
                      ),
                      const Spacer(),
                      Text(
                        valueLabel,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: VaultColors.gold,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                  if (meanings.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    MeaningChips(meanings: meanings, max: 3),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _rarityGlow(Rarity rarity) => switch (rarity) {
        Rarity.common => VaultColors.mist,
        Rarity.uncommon => VaultColors.uncommon,
        Rarity.rare => VaultColors.rare,
        Rarity.epic => VaultColors.epic,
        Rarity.legendary => VaultColors.legendary,
      };
}
