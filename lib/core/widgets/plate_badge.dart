import 'package:flutter/material.dart';

import '../../data/models/rarity.dart';
import '../../data/series/plate_meaning.dart';
import '../theme.dart';
import 'license_plate_view.dart';

/// Thin wrapper kept for call sites — visuals live in [LicensePlateView].
class PlateBadge extends StatelessWidget {
  const PlateBadge({
    super.key,
    required this.text,
    this.countryCode = 'RU',
    this.compact = false,
  });

  final String text;
  final String countryCode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LicensePlateView(
      text: text,
      countryCode: countryCode,
      compact: compact,
    );
  }
}

class RarityChip extends StatelessWidget {
  const RarityChip({super.key, required this.rarity, this.dense = false});

  final Rarity rarity;
  final bool dense;

  Color get _color => switch (rarity) {
        Rarity.common => VaultColors.mist,
        Rarity.uncommon => VaultColors.uncommon,
        Rarity.rare => VaultColors.rare,
        Rarity.epic => VaultColors.epic,
        Rarity.legendary => VaultColors.legendary,
      };

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.55)),
      ),
      child: Text(
        rarity.labelRu,
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w800,
          fontSize: dense ? 11 : 12,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class MeaningChips extends StatelessWidget {
  const MeaningChips({
    super.key,
    required this.meanings,
    this.max = 4,
    this.onTapExplanation,
  });

  final List<PlateMeaningTag> meanings;
  final int max;
  final void Function(PlateMeaningTag tag)? onTapExplanation;

  @override
  Widget build(BuildContext context) {
    if (meanings.isEmpty) return const SizedBox.shrink();
    final shown = meanings.take(max).toList();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: shown.map((m) {
        final c = m.accent;
        final isSecurity = m.kind == MeaningKind.security;
        return GestureDetector(
          onTap: onTapExplanation == null ? null : () => onTapExplanation!(m),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              gradient: isSecurity
                  ? LinearGradient(
                      colors: [
                        c.withValues(alpha: 0.28),
                        c.withValues(alpha: 0.12),
                      ],
                    )
                  : null,
              color: isSecurity ? null : c.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: c.withValues(alpha: isSecurity ? 0.7 : 0.45),
                width: isSecurity ? 1.2 : 1,
              ),
              boxShadow: isSecurity
                  ? [
                      BoxShadow(
                        color: c.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              m.labelRu,
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class MeaningDetailCard extends StatelessWidget {
  const MeaningDetailCard({super.key, required this.meanings});

  final List<PlateMeaningTag> meanings;

  @override
  Widget build(BuildContext context) {
    if (meanings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: VaultColors.panel.withValues(alpha: 0.7),
          border: Border.all(color: VaultColors.mist.withValues(alpha: 0.15)),
        ),
        child: Text(
          'Особых серий и зеркал не найдено — обычный гражданский номер.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: VaultColors.mist,
              ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            'Смысл серии',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: VaultColors.cream,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        ...meanings.map((m) => _MeaningRow(tag: m)),
      ],
    );
  }
}

class _MeaningRow extends StatelessWidget {
  const _MeaningRow({required this.tag});

  final PlateMeaningTag tag;

  @override
  Widget build(BuildContext context) {
    final c = tag.accent;
    final security = tag.kind == MeaningKind.security;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: security
              ? [
                  const Color(0xFF1A2240),
                  c.withValues(alpha: 0.22),
                  VaultColors.panel,
                ]
              : [
                  VaultColors.panel,
                  c.withValues(alpha: 0.1),
                ],
        ),
        border: Border.all(
          color: c.withValues(alpha: security ? 0.55 : 0.28),
          width: security ? 1.3 : 1,
        ),
        boxShadow: security
            ? [
                BoxShadow(
                  color: c.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: c.withValues(alpha: 0.55),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tag.labelRu,
                        style: TextStyle(
                          color: c,
                          fontWeight: FontWeight.w800,
                          fontSize: security ? 15 : 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    if (security)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: c.withValues(alpha: 0.45)),
                        ),
                        child: Text(
                          tag.kind.labelRu,
                          style: TextStyle(
                            color: c,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tag.explanationRu,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: VaultColors.mist,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
