import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../data/models/collection_item.dart';
import '../../data/models/rarity.dart';
import '../../data/models/trust_level.dart';
import '../../data/rarity/rarity_engine.dart';
import '../../data/series/plate_meaning.dart';
import '../../data/series/series_catalog.dart';
import '../../data/valuation/plate_valuation_engine.dart';
import '../../features/encyclopedia/series_encyclopedia_screen.dart';
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
    this.onFavorite,
    this.onShowcase,
    this.onShare,
    this.showMeanings = true,
  });

  final CollectionItem item;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onFavorite;
  final VoidCallback? onShowcase;
  final VoidCallback? onShare;
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
    final street = item.trust == TrustLevel.street;

    return RarityPulse(
      rarity: item.rarity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
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
                      if (onShare != null)
                        IconButton(
                          tooltip: 'Share',
                          onPressed: onShare,
                          icon: Icon(
                            Icons.ios_share,
                            color: VaultColors.mist.withValues(alpha: 0.85),
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
                      const SizedBox(width: 8),
                      _MiniTrust(street: street),
                      if (item.isFavorite)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.star, size: 16, color: VaultColors.gold),
                        ),
                      if (item.isShowcase)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.storefront,
                              size: 16, color: VaultColors.teal),
                        ),
                      const Spacer(),
                      if (item.isPublic)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            'публичный',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
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
                                    color: VaultColors.mist
                                        .withValues(alpha: 0.7),
                                  ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        street ? 'Street-оценка' : 'Оценка · Unverified',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color:
                                      VaultColors.mist.withValues(alpha: 0.8),
                                ),
                      ),
                      const Spacer(),
                      Text(
                        valueLabel,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: VaultColors.purpleBright,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ],
                  ),
                  if (item.sightingCount > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Этот номер уже находили ${item.sightingCount} ${_raz(item.sightingCount)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: VaultColors.purpleBright.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                  if (meanings.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    MeaningChips(
                      meanings: meanings,
                      max: 3,
                      onTapExplanation: (tag) {
                        final key = _seriesKeyFromTag(tag);
                        openSeriesEncyclopedia(context, seriesKey: key);
                      },
                    ),
                  ],
                  if (onFavorite != null || onShowcase != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (onFavorite != null)
                          TextButton.icon(
                            onPressed: onFavorite,
                            icon: Icon(
                              item.isFavorite
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 18,
                              color: VaultColors.gold,
                            ),
                            label: Text(
                              item.isFavorite ? 'В избранном' : 'В избранное',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        if (onShowcase != null)
                          TextButton.icon(
                            onPressed: onShowcase,
                            icon: Icon(
                              item.isShowcase
                                  ? Icons.storefront
                                  : Icons.storefront_outlined,
                              size: 18,
                              color: VaultColors.teal,
                            ),
                            label: Text(
                              item.isShowcase ? 'Витрина' : 'На витрину',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
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

  String? _seriesKeyFromTag(PlateMeaningTag tag) {
    final id = tag.id;
    if (id.startsWith('series_')) {
      return id.substring('series_'.length);
    }
    final known = RuCivilianSeriesCatalog.encyclopediaEntries();
    for (final e in known) {
      if (tag.labelRu.contains(e.seriesKey)) return e.seriesKey;
    }
    return null;
  }

  String _raz(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'раз';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return 'раза';
    }
    return 'раз';
  }
}

class _MiniTrust extends StatelessWidget {
  const _MiniTrust({required this.street});

  final bool street;

  @override
  Widget build(BuildContext context) {
    final color = street ? VaultColors.teal : VaultColors.mist;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        street ? 'Street' : 'Unverified',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
