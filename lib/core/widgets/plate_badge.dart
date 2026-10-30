import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';
import '../../data/models/rarity.dart';
import '../../data/rarity/rarity_engine.dart';
import '../../data/series/plate_meaning.dart';
import '../../data/series/series_catalog.dart';

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
    final code = countryCode.toUpperCase();
    if (code == 'RU' || code == 'BY' || code == 'KZ') {
      return _RuCivilianPlate(
        text: text,
        countryCode: code,
        compact: compact,
      );
    }
    return _GenericPlateBadge(
      text: text,
      countryCode: code,
      compact: compact,
    );
  }
}

/// Realistic white RU civilian plate: L DDD LL | flag/RUS | region.
class _RuCivilianPlate extends StatelessWidget {
  const _RuCivilianPlate({
    required this.text,
    required this.countryCode,
    required this.compact,
  });

  final String text;
  final String countryCode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final normalized = RarityEngine.instance.normalize(text);
    final parts = RuCivilianSeriesCatalog.parse(normalized);
    final height = compact ? 48.0 : 72.0;
    final radius = compact ? 6.0 : 8.0;
    final mainSize = compact ? 22.0 : 34.0;
    final regionSize = compact ? 16.0 : 22.0;
    final stripWidth = compact ? 46.0 : 64.0;

    final first = parts?.firstLetter ?? (normalized.isNotEmpty ? normalized[0] : '·');
    final digits = parts?.digits ?? '···';
    final series = parts?.seriesLetters ?? '··';
    final region = parts?.region ??
        (normalized.length >= 2
            ? normalized.substring(normalized.length - 2)
            : '··');

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F0),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFF1A1A1A), width: compact ? 2.2 : 2.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: compact ? 10 : 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: VaultColors.gold.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 12,
                  vertical: compact ? 4 : 6,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _PlateGlyph(first, size: mainSize),
                    SizedBox(width: compact ? 6 : 10),
                    _PlateGlyph(digits, size: mainSize, tracking: 1.2),
                    SizedBox(width: compact ? 6 : 10),
                    _PlateGlyph(series, size: mainSize, tracking: 1.5),
                    if (parts == null && normalized.length > 1) ...[
                      const Spacer(),
                      Flexible(
                        child: Text(
                          normalized,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.oswald(
                            color: VaultColors.plateInk.withValues(alpha: 0.45),
                            fontSize: compact ? 12 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              width: 2,
              color: const Color(0xFF1A1A1A),
            ),
            SizedBox(
              width: stripWidth,
              child: ColoredBox(
                color: const Color(0xFFF8F6F0),
                child: Column(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _MiniRuFlag(width: compact ? 18 : 24),
                          SizedBox(height: compact ? 2 : 3),
                          Text(
                            countryCode == 'RU' ? 'RUS' : countryCode,
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF1A1A1A),
                              fontSize: compact ? 7.5 : 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 1.5, color: const Color(0xFF1A1A1A)),
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: Text(
                          region,
                          style: GoogleFonts.oswald(
                            color: VaultColors.plateInk,
                            fontSize: regionSize,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            height: 1,
                          ),
                        ),
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

class _PlateGlyph extends StatelessWidget {
  const _PlateGlyph(this.text, {required this.size, this.tracking = 0.8});

  final String text;
  final double size;
  final double tracking;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.oswald(
        color: VaultColors.plateInk,
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: tracking,
        height: 1,
      ),
    );
  }
}

class _MiniRuFlag extends StatelessWidget {
  const _MiniRuFlag({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final h = width * 0.62;
    return Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF333333), width: 0.6),
      ),
      child: Column(
        children: const [
          Expanded(child: ColoredBox(color: Colors.white)),
          Expanded(child: ColoredBox(color: Color(0xFF0039A6))),
          Expanded(child: ColoredBox(color: Color(0xFFD52B1E))),
        ],
      ),
    );
  }
}

class _GenericPlateBadge extends StatelessWidget {
  const _GenericPlateBadge({
    required this.text,
    required this.countryCode,
    required this.compact,
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
                  'PLT',
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
