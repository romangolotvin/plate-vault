import 'package:flutter/material.dart';

import 'plate_country_spec.dart';
import 'plate_fields.dart';
import 'plate_format.dart';
import 'plate_visual_spec.dart';
import 'ru_plate.dart';

/// Central catalog of country plate specs. Extensible via [register].
class PlateRegistry {
  PlateRegistry._();

  static final PlateRegistry instance = PlateRegistry._();

  final Map<String, PlateCountrySpec> _byCode = {
    for (final s in _builtIn) s.code.toUpperCase(): s,
  };

  static final List<PlateCountrySpec> _builtIn = [
    _ru,
    _by,
    _kz,
    _ua,
    _de,
    _pl,
    _fr,
    _it,
    _es,
    _gb,
    _us,
    _tr,
    _generic,
  ];

  /// Alias map: UK→GB, etc.
  static const _aliasToCode = <String, String>{
    'UK': 'GB',
    'XX': 'GEN',
    'EU': 'GEN',
  };

  List<PlateCountrySpec> get all => List.unmodifiable(_byCode.values);

  List<String> get codes => _byCode.keys.toList()..sort();

  PlateCountrySpec resolve(String countryCode) {
    final raw = countryCode.toUpperCase().trim();
    final code = _aliasToCode[raw] ?? raw;
    return _byCode[code] ?? _byCode['GEN']!;
  }

  void register(PlateCountrySpec spec) {
    _byCode[spec.code.toUpperCase()] = spec;
  }

  /// Score how well [normalized] fits a country; used by OCR.
  int scoreForCountry(String countryCode, String normalized) {
    final spec = resolve(countryCode);
    return spec.ocrScoreBonus(normalized);
  }

  /// Best matching country among [preferred] then all catalog entries.
  ///
  /// [hintCountry] is the country the user picked before the scan. It wins
  /// only when no real format matches. A Russian civilian plate whose region
  /// code is a real Russian region is Russia either way — it must not fall
  /// through to the generic US pattern.
  ({String code, int score, ParsedPlateFields fields}) detectCountry(
    String normalized, {
    String? hintCountry,
    List<String> preferred = const ['RU', 'BY', 'KZ', 'UA', 'DE', 'PL', 'FR', 'IT', 'ES', 'GB', 'US', 'TR'],
  }) {
    final read = RuPlate.read(normalized);
    if (read != null && RuPlate.preferRussia(read, hintCountry)) {
      return (
        code: 'RU',
        score: read.knownRegion ? 80 : 36,
        fields: _ruFields(read),
      );
    }

    var bestCode = preferred.isNotEmpty ? preferred.first : 'GEN';
    var bestScore = -1;
    ParsedPlateFields bestFields = ParsedPlateFields(
      slots: {'main': normalized},
      displayText: normalized,
    );

    final ordered = <String>{
      ...preferred.map((e) => e.toUpperCase()),
      ..._byCode.keys,
    };

    for (final code in ordered) {
      final spec = resolve(code);
      var bonus = spec.ocrScoreBonus(normalized);
      // The US catalog entry is "any 2–8 letters or digits". That also
      // matches a Russian body whose region was not read. Don't let it win.
      if (spec.code == 'US' && read != null) bonus = 0;
      if (bonus > bestScore) {
        bestScore = bonus;
        bestCode = spec.code;
        bestFields = spec.parse(normalized);
      }
    }
    if (bestScore < 0) bestScore = 0;

    final hinted = _hintCode(hintCountry);
    if (hinted != null && bestScore <= 12 && hinted != bestCode) {
      final spec = resolve(hinted);
      return (
        code: hinted,
        score: 16,
        fields: spec.parse(normalized),
      );
    }
    return (code: bestCode, score: bestScore, fields: bestFields);
  }

  String? _hintCode(String? hintCountry) {
    final raw = hintCountry?.trim().toUpperCase() ?? '';
    if (raw.isEmpty) return null;
    if (raw == 'XX' || raw == 'EU') return 'XX';
    return resolve(raw).code;
  }

  ParsedPlateFields _ruFields(RuPlateRead read) {
    final parsed = resolve('RU').parse(read.display);
    if (parsed.matched) return parsed;
    return ParsedPlateFields(
      slots: {
        'main': read.display,
        if (read.region != null) 'region': read.region!,
      },
      displayText: read.display,
    );
  }

  ParsedPlateFields parse(String countryCode, String normalized) =>
      resolve(countryCode).parse(normalized);
}

// ─── Built-in country specs ─────────────────────────────────────────────────

final _ruLetters = r'[АВЕКМНОРСТУХ]';

final _ru = PlateCountrySpec(
  code: 'RU',
  nameEn: 'Russia',
  nameRu: 'Россия',
  ocrAlphabetHint: 'АВЕКМНОРСТУХ + digits',
  formats: [
    PlateFormat(
      id: 'ru_civilian_white',
      description: 'ГОСТ white passenger: LDDDLLRR / LDDDLLRRR',
      pattern: RegExp('^($_ruLetters)(\\d{3})($_ruLetters{2})(\\d{2,3})\$'),
      extract: PlateExtractors.ruCivilian,
      ocrBonus: 40,
    ),
  ],
  visual: const PlateVisualSpec(
    layout: PlateLayoutKind.ruGostStripRight,
    fidelity: PlateVisualFidelity.authentic,
    fontKey: PlateFontKey.ruGostApprox,
    faceColor: Color(0xFFF5F5F0),
    inkColor: Color(0xFF0A0A0A),
    borderColor: Color(0xFF0A0A0A),
    stripColor: Color(0xFFF5F5F0),
    stripInkColor: Color(0xFF0A0A0A),
    countryLabel: 'RUS',
    showFlag: true,
    borderWidth: 3.0,
    aspectRatio: 4.64,
    fontNotes:
        'Approx. ГОСТ «дорожные номера»: google_fonts Roboto Condensed '
        '(heavy). Not a redistributed RoadNumbers/FE font.',
  ),
);

final _by = PlateCountrySpec(
  code: 'BY',
  nameEn: 'Belarus',
  nameRu: 'Беларусь',
  ocrAlphabetHint: 'Cyrillic + digits',
  formats: [
    PlateFormat(
      id: 'by_civilian',
      description: 'BY often similar LDDDLL + region',
      pattern: RegExp('^($_ruLetters)(\\d{3})($_ruLetters{2})(\\d{2,3})\$'),
      extract: PlateExtractors.ruCivilian,
      ocrBonus: 28,
    ),
    PlateFormat(
      id: 'by_alt',
      pattern: RegExp(r'^[0-9]{4}[A-ZА-Я]{2}[0-9]{1,2}$'),
      extract: PlateExtractors.singleMain,
      ocrBonus: 22,
    ),
  ],
  visual: const PlateVisualSpec(
    layout: PlateLayoutKind.ruGostStripRight,
    fidelity: PlateVisualFidelity.approximate,
    fontKey: PlateFontKey.ruGostApprox,
    faceColor: Color(0xFFF5F5F0),
    inkColor: Color(0xFF0A0A0A),
    borderColor: Color(0xFF0A0A0A),
    countryLabel: 'BY',
    showFlag: false,
    aspectRatio: 4.5,
    fontNotes: 'Reuses RU GOST-like layout; BY strip label only.',
  ),
);

final _kz = PlateCountrySpec(
  code: 'KZ',
  nameEn: 'Kazakhstan',
  nameRu: 'Казахстан',
  formats: [
    PlateFormat(
      id: 'kz_civilian',
      pattern: RegExp(r'^\d{3}[A-ZА-Я]{3}\d{2}$'),
      extract: PlateExtractors.singleMain,
      ocrBonus: 26,
    ),
    PlateFormat(
      id: 'kz_ru_shape',
      pattern: RegExp('^($_ruLetters)(\\d{3})($_ruLetters{2})(\\d{2,3})\$'),
      extract: PlateExtractors.ruCivilian,
      ocrBonus: 24,
    ),
  ],
  visual: const PlateVisualSpec(
    layout: PlateLayoutKind.ruGostStripRight,
    fidelity: PlateVisualFidelity.approximate,
    fontKey: PlateFontKey.ruGostApprox,
    faceColor: Color(0xFFF5F5F0),
    inkColor: Color(0xFF0A0A0A),
    borderColor: Color(0xFF0A0A0A),
    countryLabel: 'KZ',
    aspectRatio: 4.5,
    fontNotes: 'Approximate CIS layout pending detailed KZ template.',
  ),
);

final _ua = PlateCountrySpec(
  code: 'UA',
  nameEn: 'Ukraine',
  nameRu: 'Украина',
  formats: [
    PlateFormat(
      id: 'ua_2004',
      description: 'AA 1234 BB',
      pattern: RegExp(r'^([A-ZА-ЯІЇЄ]{2})(\d{4})([A-ZА-ЯІЇЄ]{2})$'),
      extract: (m) => ParsedPlateFields(
        slots: {
          'prefix': m.group(1)!,
          'digits': m.group(2)!,
          'suffix': m.group(3)!,
          'main': '${m.group(1)}${m.group(2)}${m.group(3)}',
        },
        displayText: '${m.group(1)}${m.group(2)}${m.group(3)}',
        matched: true,
      ),
      ocrBonus: 32,
    ),
  ],
  visual: const PlateVisualSpec(
    layout: PlateLayoutKind.euBlueLeft,
    fidelity: PlateVisualFidelity.approximate,
    fontKey: PlateFontKey.dinApprox,
    faceColor: Color(0xFFFFFFFF),
    inkColor: Color(0xFF111111),
    borderColor: Color(0xFF111111),
    stripColor: Color(0xFF003399),
    countryLabel: 'UA',
    aspectRatio: 4.7,
    fontNotes: 'EU-style blue strip; DIN-like via Roboto Condensed.',
  ),
);

final _de = PlateCountrySpec(
  code: 'DE',
  nameEn: 'Germany',
  nameRu: 'Германия',
  formats: [
    PlateFormat(
      id: 'de_standard',
      description: 'B AB 1234 / M X 123',
      // Non-greedy city code so B+AB+1234 wins over BA+B+1234.
      pattern: RegExp(r'^([A-ZÄÖÜ]{1,3}?)([A-Z]{1,2})(\d{1,4})$'),
      extract: (m) => ParsedPlateFields(
        slots: {
          'prefix': m.group(1)!,
          'letters': m.group(2)!,
          'digits': m.group(3)!,
          'main': '${m.group(1)} ${m.group(2)} ${m.group(3)}',
        },
        displayText: '${m.group(1)} ${m.group(2)} ${m.group(3)}',
        matched: true,
      ),
      ocrBonus: 34,
    ),
  ],
  visual: const PlateVisualSpec(
    layout: PlateLayoutKind.euBlueLeft,
    fidelity: PlateVisualFidelity.approximate,
    fontKey: PlateFontKey.deFeApprox,
    faceColor: Color(0xFFFFFFFF),
    inkColor: Color(0xFF111111),
    borderColor: Color(0xFF111111),
    stripColor: Color(0xFF003399),
    countryLabel: 'D',
    aspectRatio: 4.7,
    fontNotes:
        'FE-Schrift approximated with Roboto Condensed — not real FE font.',
  ),
);

final _pl = PlateCountrySpec(
  code: 'PL',
  nameEn: 'Poland',
  nameRu: 'Польша',
  formats: [
    PlateFormat(
      id: 'pl_standard',
      description: 'WW 12345 / KR 1A234',
      pattern: RegExp(r'^([A-Z]{2,3})([A-Z0-9]{4,5})$'),
      extract: (m) => ParsedPlateFields(
        slots: {
          'prefix': m.group(1)!,
          'body': m.group(2)!,
          'main': '${m.group(1)} ${m.group(2)}',
        },
        displayText: '${m.group(1)} ${m.group(2)}',
        matched: true,
      ),
      ocrBonus: 30,
    ),
  ],
  visual: const PlateVisualSpec(
    layout: PlateLayoutKind.euBlueLeft,
    fidelity: PlateVisualFidelity.approximate,
    fontKey: PlateFontKey.dinApprox,
    faceColor: Color(0xFFFFFFFF),
    inkColor: Color(0xFF111111),
    borderColor: Color(0xFF111111),
    stripColor: Color(0xFF003399),
    countryLabel: 'PL',
    aspectRatio: 4.7,
    fontNotes: 'EU blue strip + DIN-ish condensed.',
  ),
);

final _fr = PlateCountrySpec(
  code: 'FR',
  nameEn: 'France',
  nameRu: 'Франция',
  formats: [
    PlateFormat(
      id: 'fr_siv',
      description: 'AB-123-CD',
      pattern: RegExp(r'^([A-Z]{2})(\d{3})([A-Z]{2})$'),
      extract: (m) => ParsedPlateFields(
        slots: {
          'prefix': m.group(1)!,
          'digits': m.group(2)!,
          'suffix': m.group(3)!,
          'main': '${m.group(1)}-${m.group(2)}-${m.group(3)}',
        },
        displayText: '${m.group(1)}-${m.group(2)}-${m.group(3)}',
        matched: true,
      ),
      ocrBonus: 34,
    ),
  ],
  visual: const PlateVisualSpec(
    layout: PlateLayoutKind.euBlueLeft,
    fidelity: PlateVisualFidelity.approximate,
    fontKey: PlateFontKey.dinApprox,
    faceColor: Color(0xFFFFFFFF),
    inkColor: Color(0xFF111111),
    borderColor: Color(0xFF111111),
    stripColor: Color(0xFF003399),
    countryLabel: 'F',
    aspectRatio: 4.7,
    fontNotes: 'SIV format; EU strip both ends simplified to left strip.',
  ),
);

final _it = PlateCountrySpec(
  code: 'IT',
  nameEn: 'Italy',
  nameRu: 'Италия',
  formats: [
    PlateFormat(
      id: 'it_standard',
      description: 'AB 123 CD',
      pattern: RegExp(r'^([A-Z]{2})(\d{3})([A-Z]{2})$'),
      extract: (m) => ParsedPlateFields(
        slots: {
          'prefix': m.group(1)!,
          'digits': m.group(2)!,
          'suffix': m.group(3)!,
          'main': '${m.group(1)} ${m.group(2)} ${m.group(3)}',
        },
        displayText: '${m.group(1)} ${m.group(2)} ${m.group(3)}',
        matched: true,
      ),
      ocrBonus: 34,
    ),
  ],
  visual: const PlateVisualSpec(
    layout: PlateLayoutKind.euBlueLeft,
    fidelity: PlateVisualFidelity.approximate,
    fontKey: PlateFontKey.dinApprox,
    faceColor: Color(0xFFFFFFFF),
    inkColor: Color(0xFF111111),
    borderColor: Color(0xFF111111),
    stripColor: Color(0xFF003399),
    countryLabel: 'I',
    aspectRatio: 4.7,
    fontNotes: 'EU blue strips simplified.',
  ),
);

final _es = PlateCountrySpec(
  code: 'ES',
  nameEn: 'Spain',
  nameRu: 'Испания',
  formats: [
    PlateFormat(
      id: 'es_2000',
      description: '1234 ABC',
      pattern: RegExp(r'^(\d{4})([BCDFGHJKLMNPRSTVWXYZ]{3})$'),
      extract: (m) => ParsedPlateFields(
        slots: {
          'digits': m.group(1)!,
          'letters': m.group(2)!,
          'main': '${m.group(1)} ${m.group(2)}',
        },
        displayText: '${m.group(1)} ${m.group(2)}',
        matched: true,
      ),
      ocrBonus: 34,
    ),
  ],
  visual: const PlateVisualSpec(
    layout: PlateLayoutKind.euBlueLeft,
    fidelity: PlateVisualFidelity.approximate,
    fontKey: PlateFontKey.dinApprox,
    faceColor: Color(0xFFFFFFFF),
    inkColor: Color(0xFF111111),
    borderColor: Color(0xFF111111),
    stripColor: Color(0xFF003399),
    countryLabel: 'E',
    aspectRatio: 4.7,
    fontNotes: 'EU blue strip + condensed sans.',
  ),
);

final _gb = PlateCountrySpec(
  code: 'GB',
  nameEn: 'United Kingdom',
  nameRu: 'Великобритания',
  aliases: const ['UK'],
  formats: [
    PlateFormat(
      id: 'gb_current',
      description: 'AB12 CDE',
      pattern: RegExp(r'^([A-Z]{2})(\d{2})([A-Z]{3})$'),
      extract: (m) => ParsedPlateFields(
        slots: {
          'prefix': m.group(1)!,
          'digits': m.group(2)!,
          'suffix': m.group(3)!,
          'main': '${m.group(1)}${m.group(2)} ${m.group(3)}',
        },
        displayText: '${m.group(1)}${m.group(2)} ${m.group(3)}',
        matched: true,
      ),
      ocrBonus: 34,
    ),
  ],
  visual: const PlateVisualSpec(
    layout: PlateLayoutKind.ukPlain,
    fidelity: PlateVisualFidelity.approximate,
    fontKey: PlateFontKey.ukCharlesApprox,
    faceColor: Color(0xFFF7D117), // rear yellow default
    inkColor: Color(0xFF111111),
    borderColor: Color(0xFF111111),
    stripColor: Color(0xFF003399),
    countryLabel: 'GB',
    aspectRatio: 4.7,
    fontNotes: 'Charles Wright–like via Oswald; yellow rear style.',
  ),
);

final _us = PlateCountrySpec(
  code: 'US',
  nameEn: 'United States',
  nameRu: 'США',
  formats: [
    PlateFormat(
      id: 'us_generic',
      description: 'Generic 2–8 alnum (state formats vary)',
      pattern: RegExp(r'^[A-Z0-9]{2,8}$'),
      extract: PlateExtractors.singleMain,
      ocrBonus: 12,
    ),
  ],
  visual: const PlateVisualSpec(
    layout: PlateLayoutKind.usPlain,
    fidelity: PlateVisualFidelity.placeholder,
    fontKey: PlateFontKey.usBlock,
    faceColor: Color(0xFFF0F4FA),
    inkColor: Color(0xFF1A2A5C),
    borderColor: Color(0xFF1A2A5C),
    countryLabel: 'USA',
    aspectRatio: 2.0,
    fontNotes: 'Generic US — state plates differ; Oswald block letters.',
  ),
);

final _tr = PlateCountrySpec(
  code: 'TR',
  nameEn: 'Turkey',
  nameRu: 'Турция',
  formats: [
    PlateFormat(
      id: 'tr_standard',
      description: '34 ABC 123',
      pattern: RegExp(r'^(\d{2})([A-Z]{1,3})(\d{2,4})$'),
      extract: (m) => ParsedPlateFields(
        slots: {
          'region': m.group(1)!,
          'letters': m.group(2)!,
          'digits': m.group(3)!,
          'main': '${m.group(1)} ${m.group(2)} ${m.group(3)}',
        },
        displayText: '${m.group(1)} ${m.group(2)} ${m.group(3)}',
        matched: true,
      ),
      ocrBonus: 30,
    ),
  ],
  visual: const PlateVisualSpec(
    layout: PlateLayoutKind.euBlueLeft,
    fidelity: PlateVisualFidelity.placeholder,
    fontKey: PlateFontKey.dinApprox,
    faceColor: Color(0xFFFFFFFF),
    inkColor: Color(0xFF111111),
    borderColor: Color(0xFF111111),
    stripColor: Color(0xFF003399),
    countryLabel: 'TR',
    aspectRatio: 4.7,
    fontNotes: 'Placeholder EU-like TR plate.',
  ),
);

final _generic = PlateCountrySpec(
  code: 'GEN',
  nameEn: 'Generic',
  nameRu: 'Другая страна',
  aliases: const ['XX', 'EU'],
  formats: [
    PlateFormat(
      id: 'generic_alnum',
      pattern: RegExp(r'^[A-ZА-Я0-9]{3,12}$'),
      extract: PlateExtractors.singleMain,
      ocrBonus: 5,
    ),
  ],
  visual: const PlateVisualSpec(
    layout: PlateLayoutKind.generic,
    fidelity: PlateVisualFidelity.placeholder,
    fontKey: PlateFontKey.dinApprox,
    faceColor: Color(0xFFF7F3E8),
    inkColor: Color(0xFF12151C),
    borderColor: Color(0xFF2A2F3A),
    stripColor: Color(0xFF1B3A6B),
    countryLabel: 'PLT',
    aspectRatio: 4.2,
    fontNotes: 'Fallback generic plate card.',
  ),
);
