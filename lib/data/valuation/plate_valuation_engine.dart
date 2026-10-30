import '../models/rarity.dart';
import '../rarity/rarity_engine.dart';
import '../series/plate_meaning.dart';
import 'currency.dart';

/// Heuristic collector estimate. Base unit is RUB; convert with fixed rates.
///
/// Documented rates (app constant, not live FX):
/// - 1 USD = 92 RUB
/// - 1 EUR = 100 RUB
class PlateValuationEngine {
  PlateValuationEngine({RarityEngine? rarityEngine})
      : _rarity = rarityEngine ?? RarityEngine.instance;

  final RarityEngine _rarity;

  static final PlateValuationEngine instance = PlateValuationEngine();

  /// Fixed FX: how many RUB per 1 unit of foreign currency.
  static const rubPerUsd = 92.0;
  static const rubPerEur = 100.0;

  PlateValuation estimate({
    required String countryCode,
    required String rawText,
    RarityResult? precomputed,
  }) {
    final result = precomputed ??
        _rarity.evaluate(countryCode: countryCode, rawText: rawText);
    final score = result.score;
    final meanings = result.meanings;

    // Base RUB from rarity score (collector hobby scale, not market quote).
    var rub = 800.0 + score * 180.0;

    // Series folklore multipliers.
    for (final m in meanings) {
      rub += m.scoreBoost * 220.0;
      if (m.kind == MeaningKind.security) rub *= 1.35;
      if (m.kind == MeaningKind.blatnye) rub *= 1.25;
      if (m.kind == MeaningKind.administration) rub *= 1.2;
      if (m.kind == MeaningKind.coolSeries) rub *= 1.12;
    }

    // Region folklore (Moscow / SPb bump already partly in score).
    final normalized = _rarity.normalize(rawText);
    final region = int.tryParse(
          RegExp(r'\d{2,3}$').firstMatch(normalized)?.group(0) ?? '',
        ) ??
        0;
    if ({77, 97, 177, 197, 199, 777, 799}.contains(region)) {
      rub *= 1.15;
    } else if ({78, 98, 178, 198}.contains(region)) {
      rub *= 1.08;
    }

    // Rarity floor/ceiling soft clamp for display sanity.
    rub = rub.clamp(500.0, 2_500_000.0);

    return PlateValuation(
      amountRub: rub.roundToDouble(),
      rarityScore: score,
      rarity: result.rarity,
      rationale: _rationale(result, rub),
    );
  }

  String format(PlateValuation v, AppCurrency currency) {
    final amount = v.inCurrency(currency);
    final rounded = amount >= 1000
        ? amount.round().toString()
        : amount.toStringAsFixed(amount >= 100 ? 0 : 0);
    return '${currency.symbol}$rounded';
  }

  String formatDetailed(PlateValuation v, AppCurrency currency) {
    final amount = v.inCurrency(currency);
    final n = amount.round();
    return switch (currency) {
      AppCurrency.rub => '$n ₽',
      AppCurrency.usd => '\$$n',
      AppCurrency.eur => '€$n',
    };
  }

  String _rationale(RarityResult result, double rub) {
    final bits = <String>[
      'оценка ~${rub.round()} ₽',
      'score ${result.score}',
      result.rarity.labelRu,
    ];
    if (result.meanings.isNotEmpty) {
      bits.add(result.meanings.first.labelRu);
    }
    return bits.join(' · ');
  }
}

class PlateValuation {
  const PlateValuation({
    required this.amountRub,
    required this.rarityScore,
    required this.rarity,
    required this.rationale,
  });

  /// Collector estimate in RUB (base).
  final double amountRub;
  final int rarityScore;
  final Rarity rarity;
  final String rationale;

  double inCurrency(AppCurrency currency) => switch (currency) {
        AppCurrency.rub => amountRub,
        AppCurrency.usd => amountRub / PlateValuationEngine.rubPerUsd,
        AppCurrency.eur => amountRub / PlateValuationEngine.rubPerEur,
      };
}
