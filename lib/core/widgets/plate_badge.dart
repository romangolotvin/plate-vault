import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';
import '../../data/models/rarity.dart';
import '../../data/series/plate_meaning.dart';

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
    final display = text.trim().isEmpty ? '· · ·' : text.trim().toUpperCase();
    final height = compact ? 44.0 : 58.0;
    final fontSize = compact ? 18.0 : 24.0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: VaultColors.plateFace,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2F3A), width: 2.2),
        boxShadow: [
          BoxShadow(
            color: VaultColors.gold.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 28 : 34,
            decoration: const BoxDecoration(
              color: VaultColors.plateBlue,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(5)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'RUS',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: compact ? 7 : 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  countryCode.length > 3
                      ? countryCode.substring(0, 3)
                      : countryCode,
                  style: GoogleFonts.manrope(
                    color: VaultColors.gold,
                    fontSize: compact ? 9 : 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                display,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.oswald(
                  color: VaultColors.plateInk,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.4,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
        return GestureDetector(
          onTap: onTapExplanation == null ? null : () => onTapExplanation!(m),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.withValues(alpha: 0.45)),
            ),
            child: Text(
              m.labelRu,
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.w700,
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
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            'Особых серий и зеркал не найдено — обычный гражданский номер.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: VaultColors.mist,
                ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Значение серии',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...meanings.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: m.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.labelRu,
                            style: TextStyle(
                              color: m.accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m.explanationRu,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: VaultColors.mist, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
