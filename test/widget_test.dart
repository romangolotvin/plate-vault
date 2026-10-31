import 'package:flutter_test/flutter_test.dart';
import 'package:plate_vault/data/leaderboard/leaderboard_service.dart';
import 'package:plate_vault/data/models/collection_item.dart';
import 'package:plate_vault/data/models/rarity.dart';
import 'package:plate_vault/data/models/trust_level.dart';
import 'package:plate_vault/data/plates/plate_registry.dart';
import 'package:plate_vault/data/rarity/rarity_engine.dart';
import 'package:plate_vault/data/series/plate_meaning.dart';
import 'package:plate_vault/data/series/series_catalog.dart';
import 'package:plate_vault/data/sightings/sighting_service.dart';
import 'package:plate_vault/data/valuation/currency.dart';
import 'package:plate_vault/data/valuation/plate_valuation_engine.dart';

void main() {
  final engine = RarityEngine();
  final registry = PlateRegistry.instance;
  final valuation = PlateValuationEngine();

  // Cyrillic via escapes so file encoding cannot break plate letters.
  const mer = '\u041C\u0415\u0420'; // МЕР
  const merPlateTyped = '\u041C\u0415\u0420777178'; // МЕР777178
  const merPlateOfficial = '\u041C777\u0415\u0420178'; // М777ЕР178

  test('normalizes Russian plate text', () {
    expect(
      engine.normalize('\u0430 123 \u0432\u0441 77'),
      '\u0410123\u0412\u042177',
    );
  });

  test('maps latin lookalikes and reshapes series-first typing', () {
    expect(engine.normalize('MER777178'), merPlateOfficial);
    expect(engine.normalize('MEP777178'), merPlateOfficial);
    expect(engine.normalize('mer 777 178'), merPlateOfficial);
    expect(engine.normalize(merPlateTyped), merPlateOfficial);
    expect(engine.normalize('A123BC77'), '\u0410123\u0412\u042177');
  });

  test('marks repeating digits as at least rare', () {
    final result = engine.evaluate(
      countryCode: 'RU',
      rawText: '\u0410777\u0410\u041077',
    );
    expect(result.score >= 35, isTrue);
    expect(
      result.rarity.index >= Rarity.rare.index,
      isTrue,
    );
  });

  test('detects blatnaya series VOR with explanation', () {
    final result = engine.evaluate(
      countryCode: 'RU',
      rawText: '\u0412001\u041E\u042077',
    );
    expect(result.meanings.any((m) => m.labelRu.contains('\u0412\u041E\u0420')), isTrue);
    expect(result.score > 40, isTrue);
  });

  test('catalog parses civilian series key', () {
    final parts = RuCivilianSeriesCatalog.parse('\u0410123\u0412\u0421199');
    expect(parts?.seriesKey, '\u0410\u0412\u0421');
    expect(parts?.digits, '123');
    expect(parts?.region, '199');
  });

  test('parses МЕР777178 as МЕР with region 178', () {
    final parts = RuCivilianSeriesCatalog.parse(
      engine.normalize(merPlateTyped),
    );
    expect(parts?.firstLetter, '\u041C');
    expect(parts?.digits, '777');
    expect(parts?.seriesLetters, '\u0415\u0420');
    expect(parts?.seriesKey, mer);
    expect(parts?.region, '178');
  });

  test('registry RU visual fields for МЕР777178', () {
    final normalized = engine.normalize(merPlateTyped);
    final fields = registry.parse('RU', normalized);
    expect(fields.matched, isTrue);
    expect(fields['letter'], '\u041C');
    expect(fields['digits'], '777');
    expect(fields['series'], '\u0415\u0420');
    expect(fields['region'], '178');
    expect(registry.resolve('RU').visual.fidelity.name, 'authentic');
  });

  test('МЕР777178 is recognized as FSB / security, not ordinary', () {
    final result = engine.evaluate(
      countryCode: 'RU',
      rawText: merPlateTyped,
    );
    expect(result.meanings.any((m) => m.kind == MeaningKind.security), isTrue);
    expect(
      result.meanings.any(
        (m) =>
            m.labelRu.contains(mer) ||
            m.labelRu.contains('\u0424\u0421\u0411') ||
            m.explanationRu.contains('\u0424\u0421\u0411'),
      ),
      isTrue,
    );
    expect(result.reason.contains('\u041D\u0435\u0441\u0442\u0430\u043D\u0434\u0430\u0440\u0442\u043D\u044B\u0439'), isFalse);
    expect(result.score >= 55, isTrue);
    expect(result.rarity.index >= Rarity.epic.index, isTrue);
  });

  test('latin MER 777 178 also maps to FSB meaning', () {
    final result = engine.evaluate(
      countryCode: 'RU',
      rawText: 'mer 777 178',
    );
    expect(engine.normalize('mer 777 178'), merPlateOfficial);
    expect(
      result.meanings.any((m) => m.kind == MeaningKind.security),
      isTrue,
    );
  });

  test('ЕКХ and АМР series still resolve', () {
    final ekh = engine.evaluate(
      countryCode: 'RU',
      rawText: '\u0415001\u041A\u042577',
    );
    expect(ekh.meanings.any((m) => m.labelRu.contains('\u0415\u041A\u0425')), isTrue);

    final amr = engine.evaluate(
      countryCode: 'RU',
      rawText: '\u0410001\u041C\u042077',
    );
    expect(amr.meanings.any((m) => m.labelRu.contains('\u0410\u041C\u0420')), isTrue);
  });

  test('parses EU France SIV format AB123CD', () {
    final fields = registry.parse('FR', 'AB123CD');
    expect(fields.matched, isTrue);
    expect(fields['prefix'], 'AB');
    expect(fields['digits'], '123');
    expect(fields['suffix'], 'CD');
  });

  test('parses German plate BAB1234', () {
    final fields = registry.parse('DE', 'BAB1234');
    expect(fields.matched, isTrue);
    expect(fields['prefix'], 'B');
    expect(fields['letters'], 'AB');
    expect(fields['digits'], '1234');
  });

  test('valuation currency switch RUB/USD/EUR uses fixed rates', () {
    final v = valuation.estimate(
      countryCode: 'RU',
      rawText: merPlateTyped,
    );
    expect(v.amountRub > 0, isTrue);
    expect(
      v.inCurrency(AppCurrency.usd),
      closeTo(v.amountRub / PlateValuationEngine.rubPerUsd, 0.01),
    );
    expect(
      v.inCurrency(AppCurrency.eur),
      closeTo(v.amountRub / PlateValuationEngine.rubPerEur, 0.01),
    );
    final rubLabel = valuation.formatDetailed(v, AppCurrency.rub);
    final usdLabel = valuation.formatDetailed(v, AppCurrency.usd);
    expect(rubLabel.contains('₽'), isTrue);
    expect(usdLabel.startsWith('\$'), isTrue);
    expect(AppCurrency.fromCode('USD'), AppCurrency.usd);
    expect(AppCurrency.fromCode('EUR'), AppCurrency.eur);
    expect(AppCurrency.fromCode(null), AppCurrency.rub);
  });

  // Folklore RUB ranges (hobby estimate, not market quote):
  // - Mirror letters/digits on Caucasian / provincial region: ~50–150k
  // - МЕР + 777 + MSK/SPB (МЕР777178): Tier 5 top combo ~800k–several million
  // User complaint: ~70k for МЕР+777+capital was wrong — that bucket is mirrors.
  test('МЕР777178 valuation is top-tier, far above Caucasian mirror', () {
    // А101ВА05 — mirror letters АВА + mirror digits 101 + Dagestan 05.
    const mirrorCaucasus = '\u0410101\u0412\u041005'; // А101ВА05
    final top = valuation.estimate(
      countryCode: 'RU',
      rawText: merPlateTyped, // МЕР777178
    );
    final mirror = valuation.estimate(
      countryCode: 'RU',
      rawText: mirrorCaucasus,
    );

    // Expected: mirror Caucasian ~50–150k; МЕР777178 >> that (800k–millions).
    expect(
      mirror.amountRub,
      inInclusiveRange(40_000, 200_000),
      reason:
          'mirror+Caucasus should land ~50–150k folklore (got ${mirror.amountRub})',
    );
    expect(
      top.amountRub,
      greaterThanOrEqualTo(800_000),
      reason:
          'МЕР+777+178 must be ≥800k folklore, not ~70k (got ${top.amountRub})',
    );
    expect(top.amountRub, greaterThan(mirror.amountRub * 4));
    expect(
      top.factors.any((f) => f.category == ValuationFactorCategory.combo),
      isTrue,
    );
    expect(
      top.factors.any((f) => f.category == ValuationFactorCategory.series),
      isTrue,
    );
    expect(
      top.factors.any((f) => f.category == ValuationFactorCategory.region),
      isTrue,
    );
  });

  test('UK alias resolves to GB', () {
    expect(registry.resolve('UK').code, 'GB');
  });

  test('expanded folklore series СКР / ХАН resolve', () {
    // С001КР77 → series key СКР (civilian alphabet only).
    final skr = engine.evaluate(
      countryCode: 'RU',
      rawText: '\u0421001\u041A\u042077',
    );
    expect(skr.meanings.any((m) => m.labelRu.contains('\u0421\u041A\u0420')), isTrue);

    final han = engine.evaluate(
      countryCode: 'RU',
      rawText: '\u0425001\u0410\u041D77',
    );
    expect(han.meanings.any((m) => m.labelRu.contains('\u0425\u0410\u041D')), isTrue);
  });

  test('capture source maps to Street vs Unverified', () {
    expect(CaptureSource.liveCamera.qualifiesStreet, isTrue);
    expect(CaptureSource.liveCamera.defaultTrust, TrustLevel.street);
    expect(CaptureSource.gallery.qualifiesStreet, isFalse);
    expect(CaptureSource.manual.defaultTrust, TrustLevel.unverified);
  });

  test('sighting plate id normalizes country + text', () {
    final id = SightingService.plateId(
      countryCode: 'ru',
      rawOrNormalized: merPlateTyped,
      engine: engine,
    );
    expect(id.startsWith('RU_'), isTrue);
    expect(id.contains(engine.normalize(merPlateTyped)), isTrue);
    expect(sightingLabelRu(1), contains('1 раз'));
    expect(sightingLabelRu(3), contains('3 раза'));
    expect(sightingLabelRu(0), isEmpty);
  });

  test('Street board ignores Unverified plates', () {
    final lb = LeaderboardService();
    final street = CollectionItem(
      id: '1',
      userId: 'u',
      type: CollectionType.licensePlate,
      countryCode: 'RU',
      rawText: merPlateTyped,
      normalizedText: engine.normalize(merPlateTyped),
      rarity: Rarity.legendary,
      rarityReason: 't',
      createdAt: DateTime.now(),
      trust: TrustLevel.street,
      captureSource: CaptureSource.liveCamera,
    );
    final manual = CollectionItem(
      id: '2',
      userId: 'u',
      type: CollectionType.licensePlate,
      countryCode: 'RU',
      rawText: merPlateTyped,
      normalizedText: engine.normalize(merPlateTyped),
      rarity: Rarity.legendary,
      rarityReason: 't',
      createdAt: DateTime.now(),
      trust: TrustLevel.unverified,
      captureSource: CaptureSource.manual,
    );
    final streetWorth = lb.portfolioWorth(
      [street, manual],
      kind: LeaderboardKind.street,
    );
    final allWorth = lb.portfolioWorth(
      [street, manual],
      kind: LeaderboardKind.unverified,
    );
    expect(streetWorth, greaterThan(0));
    expect(allWorth, closeTo(streetWorth * 2, 1));
    expect(lb.plateCount([street, manual], kind: LeaderboardKind.street), 1);
    expect(lb.plateCount([street, manual], kind: LeaderboardKind.unverified), 2);
  });
}
