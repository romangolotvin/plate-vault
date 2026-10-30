import 'package:flutter/material.dart';

import '../../data/models/collection_item.dart';
import '../../data/models/rarity.dart';
import '../../data/rarity/rarity_engine.dart';
import '../../data/series/plate_meaning.dart';
import '../theme.dart';
import 'plate_badge.dart';

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

    final glow = _rarityGlow(item.rarity);
    return Material(
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
                VaultColors.slate.withValues(alpha: 0.9),
                glow.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(
              color: glow.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: 0.16),
                blurRadius: 20,
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
                      child: PlateBadge(
                        text: item.rawText,
                        countryCode: item.countryCode,
                        compact: true,
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    RarityChip(rarity: item.rarity, dense: true),
                    const SizedBox(width: 8),
                    if (item.isPublic)
                      Text(
                        'публичный',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: VaultColors.teal,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    const Spacer(),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: VaultColors.mist.withValues(alpha: 0.75),
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
