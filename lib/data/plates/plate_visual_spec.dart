import 'package:flutter/material.dart';

/// How close the widget is to a real metal plate.
enum PlateVisualFidelity {
  /// Layout, proportions, strip, and typography tuned to the real plate.
  authentic,

  /// Correct colors / EU strip / rough proportions; not letter-perfect.
  approximate,

  /// Generic white plate with country code — placeholder until detailed.
  placeholder,
}

/// Font keys — mapped to google_fonts / defaults in LicensePlateView.
/// Real plate typefaces are proprietary; these are legal approximations.
enum PlateFontKey {
  /// RU ГОСТ white plates ≈ RoadNumbers → Roboto Condensed / Oswald.
  ruGostApprox,

  /// DE FE-Schrift ≈ Ubuntu Condensed / Roboto Condensed.
  deFeApprox,

  /// UK Charles Wright–like → Oswald.
  ukCharlesApprox,

  /// Generic DIN / Euro → Roboto Condensed.
  dinApprox,

  /// US vanity / generic → Oswald.
  usBlock,
}

enum PlateLayoutKind {
  /// RU: [ L · DDD · LL | flag/RUS | region ]
  ruGostStripRight,

  /// EU: [ blue country | main text ]
  euBlueLeft,

  /// UK yellow/white rear/front style without blue strip (optional GB strip).
  ukPlain,

  /// US: plain rectangular, centered text.
  usPlain,

  /// Fallback generic with dark left badge.
  generic,
}

class PlateVisualSpec {
  const PlateVisualSpec({
    required this.layout,
    required this.fidelity,
    required this.fontKey,
    required this.faceColor,
    required this.inkColor,
    required this.borderColor,
    this.stripColor,
    this.stripInkColor = Colors.white,
    this.countryLabel = '',
    this.showFlag = false,
    this.borderWidth = 2.6,
    this.aspectRatio = 4.6,
    this.fontNotes = '',
  });

  final PlateLayoutKind layout;
  final PlateVisualFidelity fidelity;
  final PlateFontKey fontKey;
  final Color faceColor;
  final Color inkColor;
  final Color borderColor;
  final Color? stripColor;
  final Color stripInkColor;
  final String countryLabel;
  final bool showFlag;
  final double borderWidth;

  /// Typical width/height of the metal plate (RU ~4.6, EU ~4.7).
  final double aspectRatio;

  /// Documented font approximation for maintainers / README.
  final String fontNotes;
}
