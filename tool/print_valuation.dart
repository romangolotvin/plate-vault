import 'package:plate_vault/data/valuation/plate_valuation_engine.dart';

void main() {
  final e = PlateValuationEngine();
  // МЕР777178
  final top = e.estimate(
    countryCode: 'RU',
    rawText: '\u041C\u0415\u0420777178',
  );
  // А101ВА05 mirror Caucasian
  final mir = e.estimate(
    countryCode: 'RU',
    rawText: '\u0410101\u0412\u041005',
  );
  // К123ОР05 common
  final common = e.estimate(
    countryCode: 'RU',
    rawText: '\u041A123\u041E\u042005',
  );
  print('MER777178 = ${top.amountRub.round()} RUB');
  print('A101VA05  = ${mir.amountRub.round()} RUB (mirror Caucasian)');
  print('K123OR05  = ${common.amountRub.round()} RUB (common)');
  print('--- MER factors ---');
  for (final f in top.factors) {
    print('  [${f.category.name}] ${f.labelRu} x${f.multiplier}');
  }
}
