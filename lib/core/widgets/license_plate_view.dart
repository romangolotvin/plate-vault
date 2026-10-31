import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/plates/plate_fields.dart';
import '../../data/plates/plate_registry.dart';
import '../../data/plates/plate_visual_spec.dart';
import '../../data/rarity/rarity_engine.dart';

/// Country-driven metal plate widget. Pass [countryCode] + plate text;
/// layout/fonts come from [PlateRegistry].
class LicensePlateView extends StatelessWidget {
  const LicensePlateView({
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
    final registry = PlateRegistry.instance;
    final spec = registry.resolve(countryCode);
    final normalized = RarityEngine.instance.normalize(text);
    final fields = registry.parse(spec.code, normalized);
    final visual = spec.visual;
    final height = compact ? 52.0 : 78.0;

    final child = switch (visual.layout) {
      PlateLayoutKind.ruGostStripRight => _RuGostPlate(
          visual: visual,
          fields: fields,
          normalized: normalized,
          compact: compact,
          height: height,
        ),
      PlateLayoutKind.euBlueLeft => _EuBlueLeftPlate(
          visual: visual,
          fields: fields,
          compact: compact,
          height: height,
        ),
      PlateLayoutKind.ukPlain => _UkPlate(
          visual: visual,
          fields: fields,
          compact: compact,
          height: height,
        ),
      PlateLayoutKind.usPlain => _UsPlate(
          visual: visual,
          fields: fields,
          compact: compact,
          height: height,
        ),
      PlateLayoutKind.generic => _GenericPlate(
          visual: visual,
          fields: fields,
          countryCode: spec.code,
          compact: compact,
          height: height,
        ),
    };

    return SizedBox(height: height, width: double.infinity, child: child);
  }
}

TextStyle _plateTypeface(
  PlateFontKey key, {
  required Color color,
  required double size,
  FontWeight weight = FontWeight.w700,
  double letterSpacing = 0.5,
}) {
  final base = TextStyle(
    color: color,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: 1.0,
  );
  // Extra-black / condensed stacks read closer to thick ГОСТ metal glyphs.
  return switch (key) {
    PlateFontKey.ruGostApprox => GoogleFonts.robotoCondensed(
        textStyle: base.copyWith(fontWeight: FontWeight.w900),
      ),
    PlateFontKey.deFeApprox => GoogleFonts.robotoCondensed(
        textStyle: base.copyWith(fontWeight: FontWeight.w800),
      ),
    PlateFontKey.ukCharlesApprox => GoogleFonts.oswald(
        textStyle: base.copyWith(fontWeight: FontWeight.w700),
      ),
    PlateFontKey.dinApprox => GoogleFonts.robotoCondensed(
        textStyle: base.copyWith(fontWeight: FontWeight.w800),
      ),
    PlateFontKey.usBlock => GoogleFonts.oswald(
        textStyle: base.copyWith(fontWeight: FontWeight.w700),
      ),
  };
}

/// Authentic-ish ГОСТ white: large L · DDD · LL | flag/RUS | region.
class _RuGostPlate extends StatelessWidget {
  const _RuGostPlate({
    required this.visual,
    required this.fields,
    required this.normalized,
    required this.compact,
    required this.height,
  });

  final PlateVisualSpec visual;
  final ParsedPlateFields fields;
  final String normalized;
  final bool compact;
  final double height;

  @override
  Widget build(BuildContext context) {
    final matched = fields.matched;
    final letter = fields.getOr('letter', matched ? '' : '');
    final digits = fields.getOr('digits', '');
    final series = fields.getOr('series', '');
    final region = fields.getOr(
      'region',
      normalized.length >= 2
          ? normalized.substring(normalized.length - 2)
          : '··',
    );

    // Characters fill ~72% of plate height — real metal look, not corner crumbs.
    final mainSize = height * 0.72;
    final regionSize = height * 0.38;
    final stripW = height * 0.92;
    final radius = compact ? 5.0 : 7.0;
    final gap = height * 0.06;

    return Container(
      decoration: BoxDecoration(
        color: visual.faceColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: visual.borderColor,
          width: compact ? 2.4 : visual.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: compact ? 8 : 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: height * 0.08,
                  vertical: height * 0.08,
                ),
                child: matched
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 10,
                            child: _FitGlyph(
                              letter,
                              style: _plateTypeface(
                                visual.fontKey,
                                color: visual.inkColor,
                                size: mainSize,
                                weight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          SizedBox(width: gap * 0.7),
                          Expanded(
                            flex: 28,
                            child: _FitGlyph(
                              digits,
                              style: _plateTypeface(
                                visual.fontKey,
                                color: visual.inkColor,
                                size: mainSize,
                                weight: FontWeight.w900,
                                letterSpacing: height * 0.01,
                              ),
                            ),
                          ),
                          SizedBox(width: gap * 0.7),
                          Expanded(
                            flex: 18,
                            child: _FitGlyph(
                              series,
                              style: _plateTypeface(
                                visual.fontKey,
                                color: visual.inkColor,
                                size: mainSize,
                                weight: FontWeight.w900,
                                letterSpacing: height * 0.008,
                              ),
                            ),
                          ),
                        ],
                      )
                    : _FitGlyph(
                        normalized.isEmpty ? '· · ·' : normalized,
                        style: _plateTypeface(
                          visual.fontKey,
                          color: visual.inkColor,
                          size: mainSize * 0.85,
                          weight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ),
            Container(width: compact ? 2 : 2.5, color: visual.borderColor),
            SizedBox(
              width: stripW,
              child: Column(
                children: [
                  Expanded(
                    flex: 11,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (visual.showFlag) ...[
                          _MiniRuFlag(width: height * 0.34),
                          SizedBox(height: height * 0.03),
                        ],
                        Text(
                          visual.countryLabel,
                          style: GoogleFonts.robotoCondensed(
                            color: visual.stripInkColor,
                            fontSize: height * 0.14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1.5, color: visual.borderColor),
                  Expanded(
                    flex: 10,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: height * 0.04,
                        vertical: height * 0.06,
                      ),
                      child: _FitGlyph(
                        region.isEmpty ? '··' : region,
                        style: _plateTypeface(
                          visual.fontKey,
                          color: visual.inkColor,
                          size: regionSize,
                          weight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FitGlyph extends StatelessWidget {
  const _FitGlyph(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: style,
      ),
    );
  }
}

class _MiniRuFlag extends StatelessWidget {
  const _MiniRuFlag({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final h = width * 0.66;
    return Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF222222), width: 0.5),
      ),
      child: const Column(
        children: [
          Expanded(child: ColoredBox(color: Colors.white)),
          Expanded(child: ColoredBox(color: Color(0xFF0039A6))),
          Expanded(child: ColoredBox(color: Color(0xFFD52B1E))),
        ],
      ),
    );
  }
}

class _EuBlueLeftPlate extends StatelessWidget {
  const _EuBlueLeftPlate({
    required this.visual,
    required this.fields,
    required this.compact,
    required this.height,
  });

  final PlateVisualSpec visual;
  final ParsedPlateFields fields;
  final bool compact;
  final double height;

  @override
  Widget build(BuildContext context) {
    final display = fields.displayText.isEmpty ? '· · ·' : fields.displayText;
    final radius = compact ? 5.0 : 7.0;
    final stripW = height * 0.55;

    return Container(
      decoration: BoxDecoration(
        color: visual.faceColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: visual.borderColor,
          width: compact ? 2.2 : visual.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: Row(
          children: [
            Container(
              width: stripW,
              color: visual.stripColor ?? const Color(0xFF003399),
              padding: EdgeInsets.symmetric(vertical: height * 0.1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(
                    Icons.star,
                    size: height * 0.16,
                    color: const Color(0xFFFFCC00),
                  ),
                  Text(
                    visual.countryLabel,
                    style: GoogleFonts.robotoCondensed(
                      color: visual.stripInkColor,
                      fontSize: height * 0.22,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: height * 0.12,
                  vertical: height * 0.1,
                ),
                child: _FitGlyph(
                  display,
                  style: _plateTypeface(
                    visual.fontKey,
                    color: visual.inkColor,
                    size: height * 0.62,
                    weight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UkPlate extends StatelessWidget {
  const _UkPlate({
    required this.visual,
    required this.fields,
    required this.compact,
    required this.height,
  });

  final PlateVisualSpec visual;
  final ParsedPlateFields fields;
  final bool compact;
  final double height;

  @override
  Widget build(BuildContext context) {
    final display = fields.displayText.isEmpty ? '· · ·' : fields.displayText;
    final radius = compact ? 5.0 : 7.0;
    return Container(
      decoration: BoxDecoration(
        color: visual.faceColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: visual.borderColor, width: 2.4),
      ),
      child: Row(
        children: [
          Container(
            width: height * 0.5,
            decoration: BoxDecoration(
              color: visual.stripColor,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(radius - 1),
              ),
            ),
            child: Center(
              child: Text(
                visual.countryLabel,
                style: GoogleFonts.robotoCondensed(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: height * 0.2,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(height * 0.1),
              child: _FitGlyph(
                display,
                style: _plateTypeface(
                  visual.fontKey,
                  color: visual.inkColor,
                  size: height * 0.65,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsPlate extends StatelessWidget {
  const _UsPlate({
    required this.visual,
    required this.fields,
    required this.compact,
    required this.height,
  });

  final PlateVisualSpec visual;
  final ParsedPlateFields fields;
  final bool compact;
  final double height;

  @override
  Widget build(BuildContext context) {
    final display = fields.displayText.isEmpty ? '· · ·' : fields.displayText;
    return Container(
      decoration: BoxDecoration(
        color: visual.faceColor,
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(color: visual.borderColor, width: 2.5),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: height * 0.12,
        vertical: height * 0.12,
      ),
      child: Column(
        children: [
          Text(
            visual.countryLabel,
            style: GoogleFonts.manrope(
              color: visual.inkColor.withValues(alpha: 0.7),
              fontSize: height * 0.14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          Expanded(
            child: _FitGlyph(
              display,
              style: _plateTypeface(
                visual.fontKey,
                color: visual.inkColor,
                size: height * 0.5,
                letterSpacing: 2.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenericPlate extends StatelessWidget {
  const _GenericPlate({
    required this.visual,
    required this.fields,
    required this.countryCode,
    required this.compact,
    required this.height,
  });

  final PlateVisualSpec visual;
  final ParsedPlateFields fields;
  final String countryCode;
  final bool compact;
  final double height;

  @override
  Widget build(BuildContext context) {
    final display = fields.displayText.isEmpty ? '· · ·' : fields.displayText;
    return Container(
      decoration: BoxDecoration(
        color: visual.faceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: visual.borderColor, width: 2.2),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 30 : 36,
            color: visual.stripColor,
            child: Center(
              child: Text(
                countryCode.length > 3 ? countryCode.substring(0, 3) : countryCode,
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: height * 0.18,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _FitGlyph(
                display,
                style: _plateTypeface(
                  visual.fontKey,
                  color: visual.inkColor,
                  size: height * 0.55,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
