import 'package:flutter_test/flutter_test.dart';
import 'package:plate_vault/data/models/rarity.dart';
import 'package:plate_vault/data/rarity/rarity_engine.dart';
import 'package:plate_vault/data/series/series_catalog.dart';

void main() {
  final engine = RarityEngine();

  test('normalizes Russian plate text', () {
    expect(engine.normalize('а 123 вс 77'), 'А123ВС77');
  });

  test('marks repeating digits as at least rare', () {
    final result = engine.evaluate(
      countryCode: 'RU',
      rawText: 'А777АА77',
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
      rawText: 'В001ОР77',
    );
    expect(result.meanings.any((m) => m.labelRu.contains('ВОР')), isTrue);
    expect(result.score > 40, isTrue);
  });

  test('catalog parses civilian series key', () {
    final parts = RuCivilianSeriesCatalog.parse('А123ВС199');
    expect(parts?.seriesKey, 'АВС');
    expect(parts?.digits, '123');
    expect(parts?.region, '199');
  });
}
