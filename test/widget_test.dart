import 'package:flutter_test/flutter_test.dart';
import 'package:plate_vault/data/models/rarity.dart';
import 'package:plate_vault/data/rarity/rarity_engine.dart';
import 'package:plate_vault/data/series/plate_meaning.dart';
import 'package:plate_vault/data/series/series_catalog.dart';

void main() {
  final engine = RarityEngine();

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
}
