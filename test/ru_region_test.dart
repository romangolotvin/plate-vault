import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_vault/core/theme.dart';
import 'package:plate_vault/data/ocr/plate_ocr_service.dart';
import 'package:plate_vault/data/plates/plate_registry.dart';
import 'package:plate_vault/data/plates/ru_plate.dart';
import 'package:plate_vault/features/scan/country_switch.dart';

void main() {
  final registry = PlateRegistry.instance;
  final ocr = PlateOcrService();

  const ru77 = '\u0410123\u0412\u042177'; // А123ВС77
  const ru178 = '\u0410123\u0412\u0421178'; // А123ВС178

  test('a Russian region code is Russia, not the US', () {
    for (final raw in ['A123BC77', 'A123BC178', 'A123BC777', 'A123BC05', ru77]) {
      final detected = registry.detectCountry(raw);
      expect(detected.code, 'RU', reason: raw);
      expect(detected.code, isNot('US'));
    }
    expect(registry.detectCountry('A123BC77').fields['region'], '77');
    expect(registry.detectCountry('A123BC178').fields['region'], '178');
    expect(registry.detectCountry('A123BC05').fields['region'], '05');
    expect(RuRegions.isKnown(777), isTrue);
    expect(RuRegions.isKnown(0), isFalse);
    expect(RuRegions.isKnown(999), isFalse);
  });

  test('a missing or split region does not fall through to the US', () {
    expect(registry.detectCountry('A123BC').code, 'RU');
    expect(registry.detectCountry('A123BC7').code, 'RU');
    expect(registry.detectCountry('A123BC00').code, 'RU');

    final split = ocr.interpretText('A123BC\n178');
    expect(split?.suggestedCountry, 'RU');
    expect(split?.text, ru178);

    final junk = ocr.interpretText('РОССИЯ\nA123BC\nRUS\n77');
    expect(junk?.suggestedCountry, 'RU');
    expect(junk?.text, ru77);
  });

  test('an explicit country wins only when the region is not Russian', () {
    expect(registry.detectCountry('A123BC77', hintCountry: 'US').code, 'RU');
    expect(registry.detectCountry('A123BC', hintCountry: 'US').code, 'US');
    expect(registry.detectCountry('A123BC', hintCountry: 'DE').code, 'DE');
    expect(registry.detectCountry('HELLO', hintCountry: 'RU').code, 'RU');
    expect(registry.detectCountry('HELLO').code, 'US');
    expect(registry.detectCountry('BAB1234', hintCountry: 'RU').code, 'DE');
    expect(registry.detectCountry('AB123CD').code, 'FR');
  });

  test('series-first latin typing is still read as a Russian plate', () {
    final read = ocr.interpretText('MER777178');
    expect(read?.suggestedCountry, 'RU');
    expect(read?.text, '\u041C777\u0415\u0420178');
  });

  testWidgets('country switch offers Russia, the US, and other', (tester) async {
    String selected = 'RU';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return CountrySwitch(
                countryCode: selected,
                onChanged: (value) => setState(() => selected = value),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Россия'), findsOneWidget);
    expect(find.text('США'), findsOneWidget);
    expect(find.text('Другая'), findsOneWidget);

    await tester.tap(find.text('США'));
    await tester.pumpAndSettle();
    expect(selected, 'US');

    await tester.tap(find.text('Другая'));
    await tester.pumpAndSettle();
    expect(selected, 'XX');
    expect(find.text('Какая страна'), findsOneWidget);

    await tester.tap(find.text('Россия'));
    await tester.pumpAndSettle();
    expect(selected, 'RU');
  });
}
