import '../models/rarity.dart';
import '../rarity/rarity_engine.dart';
import '../series/plate_meaning.dart';
import '../series/series_catalog.dart';
import 'currency.dart';

/// Heuristic collector estimate. Base unit is RUB; convert with fixed rates.
///
/// Documented rates (app constant, not live FX):
/// - 1 USD = 92 RUB
/// - 1 EUR = 100 RUB
///
/// # Collector street folklore tiers (RUB hobby scale — not a market quote)
///
/// These are the “сейфовые” orders of magnitude hunters talk about:
///
/// - **Tier 0 — Common civilian**: low thousands (~2–8k). Everyday plate,
///   no pretty digits, no status series, any region.
/// - **Tier 1 — Nice mirrors / pretty triples alone**: ~50–150k.
///   Mirror letters (АВА) or mirror digits (101) + provincial / Caucasian
///   region (01–09, 15, 20…) without blatnye/FSB series — “красивый, но не
///   статус”. User folklore: ~70k is this bucket, NOT МЕР+777+capital.
/// - **Tier 2 — Blatnye series mid** (ВОР, ХАМ, МУР…): ~150–600k depending
///   on digits + region. Status joke plates, not force lore.
/// - **Tier 3 — Security / FSB series** (МЕР, ЕКХ, ККХ…): high multiplier
///   even before lucky digits. Force folklore on civilian white plates.
/// - **Tier 4 — Capital regions**: Moscow (77/97/177/197/199/777/799) and
///   SPb (78/98/178/198) apply a strong region multiplier — capitals price
///   status series far above Caucasian / provincial codes.
/// - **Tier 5 — Top combo** МЕР + 777 + MSK/SPB (e.g. МЕР777178 / МЕР77777):
///   ~800k–several million RUB. Synergy of FSB series + lucky triples +
///   capital region. Ceiling soft-clamped for display sanity.
class PlateValuationEngine {
  PlateValuationEngine({RarityEngine? rarityEngine})
      : _rarity = rarityEngine ?? RarityEngine.instance;

  final RarityEngine _rarity;

  static final PlateValuationEngine instance = PlateValuationEngine();

  /// Fixed FX: how many RUB per 1 unit of foreign currency.
  static const rubPerUsd = 92.0;
  static const rubPerEur = 100.0;

  /// Soft floor / ceiling for hobby display (Tier 0 … Tier 5 folklore).
  static const minRub = 2_000.0;
  static const maxRub = 8_000_000.0;

  static const _mskRegions = {77, 97, 177, 197, 199, 777, 799};
  static const _spbRegions = {78, 98, 178, 198};

  PlateValuation estimate({
    required String countryCode,
    required String rawText,
    RarityResult? precomputed,
  }) {
    final result = precomputed ??
        _rarity.evaluate(countryCode: countryCode, rawText: rawText);
    final meanings = result.meanings;
    final normalized = _rarity.normalize(rawText);
    final parts = RuCivilianSeriesCatalog.parse(normalized);

    final factors = <ValuationFactor>[];

    // Tier 0 base — common civilian hobby floor.
    const base = 3_500.0;
    factors.add(
      const ValuationFactor(
        id: 'base',
        labelRu: 'База обычного номера',
        category: ValuationFactorCategory.base,
        multiplier: 1,
        detailRu: 'Стартовая оценка гражданского номера (~2–8k без бустов)',
      ),
    );

    var rub = base;

    // --- Digits tier ---
    final digitMult = _digitMultiplier(parts?.digits, factors);
    rub *= digitMult;

    // --- Series / meaning multipliers (apply strongest kinds once) ---
    final seriesMult = _seriesMultiplier(meanings, factors);
    rub *= seriesMult;

    // --- Region capital multiplier ---
    final region = int.tryParse(parts?.region ?? '') ??
        int.tryParse(
          RegExp(r'\d{2,3}$').firstMatch(normalized)?.group(0) ?? '',
        ) ??
        0;
    final regionMult = _regionMultiplier(region, factors);
    rub *= regionMult;

    // --- Synergy: FSB/security + lucky 777 + capital → Tier 5 ---
    final hasSecurity = meanings.any((m) => m.kind == MeaningKind.security);
    final hasMer = meanings.any(
      (m) =>
          m.labelRu.contains('МЕР') ||
          m.id.contains('МЕР') ||
          (parts?.seriesKey == 'МЕР'),
    );
    final lucky777 = parts?.digits == '777';
    final capital = _mskRegions.contains(region) || _spbRegions.contains(region);

    if (hasMer && lucky777 && capital) {
      // Classic top-tier folklore combo: МЕР + 777 + MSK/SPB.
      const combo = 2.6;
      rub *= combo;
      factors.add(
        ValuationFactor(
          id: 'combo_mer_777_capital',
          labelRu: 'Топ-комбо МЕР·777·столица',
          category: ValuationFactorCategory.combo,
          multiplier: combo,
          detailRu:
              'ФСБ-серия + счастливые 777 + столичный регион $region — '
              'уличный топ (сотни тысяч → миллионы ₽)',
        ),
      );
    } else if (hasSecurity && lucky777 && capital) {
      const combo = 1.85;
      rub *= combo;
      factors.add(
        ValuationFactor(
          id: 'combo_security_777_capital',
          labelRu: 'Силовая · 777 · столица',
          category: ValuationFactorCategory.combo,
          multiplier: combo,
          detailRu: 'Силовая серия + 777 на регионе $region',
        ),
      );
    } else if (hasSecurity && capital) {
      const combo = 1.35;
      rub *= combo;
      factors.add(
        const ValuationFactor(
          id: 'combo_security_capital',
          labelRu: 'Силовая на столице',
          category: ValuationFactorCategory.combo,
          multiplier: combo,
          detailRu: 'Силовой фольклор сильнее на MSK/SPB',
        ),
      );
    }

    // Mild rarity score polish (does not dominate folklore tiers).
    final scoreSoft = 1.0 + (result.score.clamp(0, 120) / 400.0);
    if (scoreSoft > 1.02) {
      rub *= scoreSoft;
      factors.add(
        ValuationFactor(
          id: 'rarity_score',
          labelRu: 'Score редкости',
          category: ValuationFactorCategory.score,
          multiplier: double.parse(scoreSoft.toStringAsFixed(3)),
          detailRu: 'Мягкая поправка от score ${result.score}',
        ),
      );
    }

    rub = rub.clamp(minRub, maxRub);
    final amount = rub.roundToDouble();

    return PlateValuation(
      amountRub: amount,
      rarityScore: result.score,
      rarity: result.rarity,
      rationale: _rationale(result, amount, factors),
      factors: List.unmodifiable(factors),
    );
  }

  double _digitMultiplier(String? digits, List<ValuationFactor> factors) {
    if (digits == null || digits.length != 3) {
      return 1.0;
    }
    final d = digits;
    // All same: 000 / 111 / 777…
    if (d[0] == d[1] && d[1] == d[2]) {
      if (d == '777') {
        // Lucky triples — strong alone (~pushes toward Tier 1–2 before series).
        const m = 14.0;
        factors.add(
          const ValuationFactor(
            id: 'digits_777',
            labelRu: 'Счастливые 777',
            category: ValuationFactorCategory.digits,
            multiplier: m,
            detailRu: 'Культовые тройки у коллекционеров',
          ),
        );
        return m;
      }
      if (d == '000' || d == '001') {
        const m = 12.0;
        factors.add(
          ValuationFactor(
            id: 'digits_special_$d',
            labelRu: 'Особый ряд $d',
            category: ValuationFactorCategory.digits,
            multiplier: m,
            detailRu: 'Нулевой / стартовый числовой ряд',
          ),
        );
        return m;
      }
      const m = 10.0;
      factors.add(
        ValuationFactor(
          id: 'digits_triple_$d',
          labelRu: 'Тройки $d',
          category: ValuationFactorCategory.digits,
          multiplier: m,
          detailRu: 'Три одинаковые цифры',
        ),
      );
      return m;
    }
    // Mirror / palindrome digits (101, 121, 313…)
    if (d[0] == d[2] && d[0] != d[1]) {
      const m = 9.0;
      factors.add(
        ValuationFactor(
          id: 'digits_mirror_$d',
          labelRu: 'Зеркало цифр $d',
          category: ValuationFactorCategory.digits,
          multiplier: m,
          detailRu: 'Палиндром цифр — «красивый» Tier 1 без статусной серии',
        ),
      );
      return m;
    }
    // Soft sequential
    if (RegExp(r'^(012|123|234|345|456|567|678|789)$').hasMatch(d)) {
      const m = 4.5;
      factors.add(
        const ValuationFactor(
          id: 'digits_seq',
          labelRu: 'Последовательные цифры',
          category: ValuationFactorCategory.digits,
          multiplier: m,
          detailRu: 'Лестница цифр',
        ),
      );
      return m;
    }
    return 1.0;
  }

  double _seriesMultiplier(
    List<PlateMeaningTag> meanings,
    List<ValuationFactor> factors,
  ) {
    if (meanings.isEmpty) return 1.0;

    var mult = 1.0;
    var appliedSecurity = false;
    var appliedBlatnye = false;
    var appliedAdmin = false;
    var appliedGov = false;
    var appliedCool = false;
    var appliedMirrorLetters = false;

    for (final m in meanings) {
      switch (m.kind) {
        case MeaningKind.security:
          if (appliedSecurity) break;
          appliedSecurity = true;
          // МЕР folklore is the strongest security bump.
          final isMer = m.labelRu.contains('МЕР') || m.id.contains('mer');
          final mlt = isMer ? 11.0 : 7.5;
          mult *= mlt;
          factors.add(
            ValuationFactor(
              id: 'series_${m.id}',
              labelRu: m.labelRu,
              category: ValuationFactorCategory.series,
              multiplier: mlt,
              detailRu: isMer
                  ? 'ФСБ-фольклор (МЕР) — высокий множитель'
                  : 'Силовая / спецсвязь серия',
            ),
          );
        case MeaningKind.blatnye:
          if (appliedBlatnye) break;
          appliedBlatnye = true;
          const mlt = 5.5;
          mult *= mlt;
          factors.add(
            ValuationFactor(
              id: 'series_${m.id}',
              labelRu: m.labelRu,
              category: ValuationFactorCategory.series,
              multiplier: mlt,
              detailRu: 'Блатная серия — средний статусный Tier 2',
            ),
          );
        case MeaningKind.administration:
          if (appliedAdmin) break;
          appliedAdmin = true;
          const mlt = 4.2;
          mult *= mlt;
          factors.add(
            ValuationFactor(
              id: 'series_${m.id}',
              labelRu: m.labelRu,
              category: ValuationFactorCategory.series,
              multiplier: mlt,
              detailRu: 'Административная серия',
            ),
          );
        case MeaningKind.government:
          if (appliedGov) break;
          appliedGov = true;
          const mlt = 2.8;
          mult *= mlt;
          factors.add(
            ValuationFactor(
              id: 'series_${m.id}',
              labelRu: m.labelRu,
              category: ValuationFactorCategory.series,
              multiplier: mlt,
              detailRu: 'Гос. оттенок на гражданском',
            ),
          );
        case MeaningKind.coolSeries:
          if (appliedCool) break;
          appliedCool = true;
          const mlt = 2.4;
          mult *= mlt;
          factors.add(
            ValuationFactor(
              id: 'series_${m.id}',
              labelRu: m.labelRu,
              category: ValuationFactorCategory.series,
              multiplier: mlt,
              detailRu: 'Красивая буквенная серия',
            ),
          );
        case MeaningKind.mirrorLetters:
          if (appliedMirrorLetters) break;
          appliedMirrorLetters = true;
          // Alone with mirror digits + province → ~50–150k (Tier 1).
          const mlt = 2.3;
          mult *= mlt;
          factors.add(
            ValuationFactor(
              id: 'series_${m.id}',
              labelRu: m.labelRu,
              category: ValuationFactorCategory.series,
              multiplier: mlt,
              detailRu: 'Зеркальные буквы серии',
            ),
          );
        case MeaningKind.mirrorDigits:
        case MeaningKind.regional:
        case MeaningKind.other:
          break;
      }
    }
    return mult;
  }

  double _regionMultiplier(int region, List<ValuationFactor> factors) {
    if (_mskRegions.contains(region)) {
      const m = 3.8;
      factors.add(
        ValuationFactor(
          id: 'region_msk_$region',
          labelRu: 'Москва · $region',
          category: ValuationFactorCategory.region,
          multiplier: m,
          detailRu: 'Столичный московский пул — сильный множитель',
        ),
      );
      return m;
    }
    if (_spbRegions.contains(region)) {
      const m = 3.4;
      factors.add(
        ValuationFactor(
          id: 'region_spb_$region',
          labelRu: 'СПб · $region',
          category: ValuationFactorCategory.region,
          multiplier: m,
          detailRu: 'Столичный петербургский пул',
        ),
      );
      return m;
    }
    if (region > 0) {
      factors.add(
        ValuationFactor(
          id: 'region_other_$region',
          labelRu: 'Регион $region',
          category: ValuationFactorCategory.region,
          multiplier: 1.0,
          detailRu:
              'Провинция / Кавказ и др. — без столичного буста '
              '(зеркала здесь ~50–150k, не миллионы)',
        ),
      );
    }
    return 1.0;
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
      AppCurrency.rub => _formatRub(n),
      AppCurrency.usd => '\$${_formatGrouped(n)}',
      AppCurrency.eur => '€${_formatGrouped(n)}',
    };
  }

  static String _formatRub(int n) => '${_formatGrouped(n)} ₽';

  static String _formatGrouped(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _rationale(
    RarityResult result,
    double rub,
    List<ValuationFactor> factors,
  ) {
    final highlights = factors
        .where((f) => f.category != ValuationFactorCategory.base)
        .where((f) => f.multiplier > 1.05)
        .take(3)
        .map((f) => f.labelRu)
        .toList();
    final bits = <String>[
      'оценка ~${rub.round()} ₽',
      result.rarity.labelRu,
      if (highlights.isNotEmpty) highlights.join(' · '),
    ];
    return bits.join(' · ');
  }
}

enum ValuationFactorCategory {
  base,
  digits,
  series,
  region,
  combo,
  score,
}

class ValuationFactor {
  const ValuationFactor({
    required this.id,
    required this.labelRu,
    required this.category,
    required this.multiplier,
    this.detailRu = '',
  });

  final String id;
  final String labelRu;
  final ValuationFactorCategory category;
  final double multiplier;
  final String detailRu;

  String get categoryLabelRu => switch (category) {
        ValuationFactorCategory.base => 'База',
        ValuationFactorCategory.digits => 'Цифры',
        ValuationFactorCategory.series => 'Серия',
        ValuationFactorCategory.region => 'Регион',
        ValuationFactorCategory.combo => 'Комбо',
        ValuationFactorCategory.score => 'Score',
      };
}

class PlateValuation {
  const PlateValuation({
    required this.amountRub,
    required this.rarityScore,
    required this.rarity,
    required this.rationale,
    this.factors = const [],
  });

  /// Collector estimate in RUB (base).
  final double amountRub;
  final int rarityScore;
  final Rarity rarity;
  final String rationale;
  final List<ValuationFactor> factors;

  double inCurrency(AppCurrency currency) => switch (currency) {
        AppCurrency.rub => amountRub,
        AppCurrency.usd => amountRub / PlateValuationEngine.rubPerUsd,
        AppCurrency.eur => amountRub / PlateValuationEngine.rubPerEur,
      };
}
