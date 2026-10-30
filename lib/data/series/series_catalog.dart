import 'plate_meaning.dart';

/// Country-specific civilian plate meaning rules.
/// Expand later with US / EU catalogs without touching RU logic.
abstract class CountrySeriesCatalog {
  String get countryCode;

  /// Analyze a normalized plate (letters+digits, no separators).
  List<PlateMeaningTag> analyze(String normalized);
}

/// Facade: picks catalog by country, falls back to empty / shared heuristics.
class SeriesCatalog {
  SeriesCatalog({
    List<CountrySeriesCatalog>? catalogs,
  }) : _catalogs = {
          for (final c in catalogs ??
              const [
                RuCivilianSeriesCatalog(),
                CisCivilianSeriesCatalog(countryCode: 'BY'),
                CisCivilianSeriesCatalog(countryCode: 'KZ'),
              ])
            c.countryCode.toUpperCase(): c,
        };

  final Map<String, CountrySeriesCatalog> _catalogs;

  List<PlateMeaningTag> analyze({
    required String countryCode,
    required String normalized,
  }) {
    if (normalized.isEmpty) return const [];
    final code = countryCode.toUpperCase();
    final catalog = _catalogs[code];
    if (catalog != null) return catalog.analyze(normalized);
    return const [];
  }

  /// Register additional country catalogs at runtime (future markets).
  void register(CountrySeriesCatalog catalog) {
    _catalogs[catalog.countryCode.toUpperCase()] = catalog;
  }
}

/// Russian passenger (white) plates: A123BC77 / A123BC777.
class RuCivilianSeriesCatalog implements CountrySeriesCatalog {
  const RuCivilianSeriesCatalog();

  @override
  String get countryCode => 'RU';

  static final _ruCivilian = RegExp(
    r'^([АВЕКМНОРСТУХ])(\d{3})([АВЕКМНОРСТУХ]{2})(\d{2,3})$',
  );

  /// Known status / folklore series among collectors (civilian alphabet only).
  /// Not official registry — collector lore for meaning + rarity boost.
  static const _knownSeries = <String, _KnownSeries>{
    // Блатные / статусные
    'ВОР': _KnownSeries(
      label: 'ВОР',
      kind: MeaningKind.blatnye,
      boost: 38,
      text:
          'Классическая «блатная» серия: читается как «вор». У коллекционеров — сильный статусный маркер.',
    ),
    'ХАМ': _KnownSeries(
      label: 'ХАМ',
      kind: MeaningKind.blatnye,
      boost: 32,
      text:
          'Серия «ХАМ» — известный блатной / дерзкий читаемый набор букв на гражданских номерах.',
    ),
    'МУР': _KnownSeries(
      label: 'МУР',
      kind: MeaningKind.blatnye,
      boost: 28,
      text:
          'Читается как «МУР» — у коллекционеров ассоциируется со «старым» милицейским сленгом и статусом.',
    ),

    // Силовые / спецсвязь (фольклор коллекционеров)
    'ЕКХ': _KnownSeries(
      label: 'ЕКХ',
      kind: MeaningKind.security,
      boost: 36,
      text:
          'Серия часто связывают с силовыми / спецструктурами Москвы (фольклор коллекционеров, не официальный реестр).',
    ),
    'ККХ': _KnownSeries(
      label: 'ККХ',
      kind: MeaningKind.security,
      boost: 30,
      text:
          'Соседняя к «ЕКХ» серия — у охотников за номерами считается «служебной» по молве.',
    ),
    'ХХХ': _KnownSeries(
      label: 'ХХХ',
      kind: MeaningKind.security,
      boost: 26,
      text:
          'Тройные «Х» — редкая и заметная серия; иногда относят к «закрытым» пулам.',
    ),
    'ММР': _KnownSeries(
      label: 'ММР',
      kind: MeaningKind.security,
      boost: 24,
      text:
          'Серия ММР в разговорах коллекционеров часто рядом с ведомственными пулами.',
    ),
    'ООО': _KnownSeries(
      label: 'ООО',
      kind: MeaningKind.coolSeries,
      boost: 22,
      text:
          'Тройные «О» — красивая и заметная серия; иногда воспринимается как статусная.',
    ),

    // Администрация / регион власти
    'АМО': _KnownSeries(
      label: 'АМО',
      kind: MeaningKind.administration,
      boost: 34,
      text:
          'Серия АМО ассоциируется с администрацией Москвы / «правительственным» гражданским пулом.',
    ),
    'АМР': _KnownSeries(
      label: 'АМР',
      kind: MeaningKind.administration,
      boost: 34,
      text:
          'АМР — одна из самых известных «административных» гражданских серий Москвы.',
    ),
    'МОО': _KnownSeries(
      label: 'МОО',
      kind: MeaningKind.administration,
      boost: 26,
      text:
          'МОО часто упоминают рядом с московскими административными сериями.',
    ),
    'МОС': _KnownSeries(
      label: 'МОС',
      kind: MeaningKind.administration,
      boost: 28,
      text:
          'Читается как «МОС» — московский административный оттенок для коллекционеров.',
    ),
    'РМО': _KnownSeries(
      label: 'РМО',
      kind: MeaningKind.administration,
      boost: 22,
      text: 'Серия с «московским» читаемым оттенком (РМО).',
    ),
    'УУР': _KnownSeries(
      label: 'УУР',
      kind: MeaningKind.administration,
      boost: 20,
      text: 'Редкая буквенная комбинация с «служебным» звучанием у охотников за сериями.',
    ),

    // Гос. оттенок на гражданских (читаемые слова / аббревиатуры)
    'СОС': _KnownSeries(
      label: 'СОС',
      kind: MeaningKind.government,
      boost: 18,
      text: 'Читаемая серия СОС — заметный «сигнальный» набор на гражданском номере.',
    ),
    'РОС': _KnownSeries(
      label: 'РОС',
      kind: MeaningKind.government,
      boost: 24,
      text:
          'Серия РОС читается как начало «Рос…» — у коллекционеров воспринимается как «государственный» оттенок на гражданском номере.',
    ),
    'РУС': _KnownSeries(
      label: 'РУС',
      kind: MeaningKind.government,
      boost: 22,
      text: 'Читается как «РУС» — патриотичный / гос. оттенок на белом гражданском номере.',
    ),
    'ССС': _KnownSeries(
      label: 'ССС',
      kind: MeaningKind.coolSeries,
      boost: 22,
      text: 'Тройные «С» — культовая красивая гражданская серия.',
    ),
    'ААА': _KnownSeries(
      label: 'ААА',
      kind: MeaningKind.coolSeries,
      boost: 24,
      text: 'Серия ААА — одна из самых желанных «красивых» гражданских серий.',
    ),
  };

  @override
  List<PlateMeaningTag> analyze(String normalized) {
    final parts = parse(normalized);
    if (parts == null) return const [];

    final tags = <PlateMeaningTag>[];
    final seen = <String>{};

    void add(PlateMeaningTag tag) {
      if (seen.add(tag.id)) tags.add(tag);
    }

    // Known series by three-letter key
    final known = _knownSeries[parts.seriesKey];
    if (known != null) {
      add(
        PlateMeaningTag(
          id: 'series_${parts.seriesKey}',
          labelRu: known.label,
          explanationRu: known.text,
          kind: known.kind,
          scoreBoost: known.boost,
        ),
      );
    }

    // Cool triple letters AAA / CCC / … (skip if already a known series entry)
    if (known == null &&
        parts.seriesKey.length == 3 &&
        parts.seriesKey.split('').toSet().length == 1) {
      add(
        PlateMeaningTag(
          id: 'cool_triple_${parts.seriesKey}',
          labelRu: 'Серия ${parts.seriesKey}',
          explanationRu:
              'Три одинаковые буквы (${parts.seriesKey}) — классическая «красивая» гражданская серия.',
          kind: MeaningKind.coolSeries,
          scoreBoost: 20,
        ),
      );
    }

    // Mirror letters: first == third of series key (АВА, ВОВ, …)
    if (parts.seriesKey.length == 3 &&
        parts.seriesKey[0] == parts.seriesKey[2] &&
        parts.seriesKey[0] != parts.seriesKey[1]) {
      add(
        PlateMeaningTag(
          id: 'mirror_letters_${parts.seriesKey}',
          labelRu: 'Зеркало ${parts.seriesKey}',
          explanationRu:
              'Буквы серии зеркальные: первая и третья совпадают (${parts.seriesKey}).',
          kind: MeaningKind.mirrorLetters,
          scoreBoost: 16,
        ),
      );
    }

    // Mirror / palindrome digits
    final d = parts.digits;
    if (d.length == 3 && d[0] == d[2] && d[0] != d[1]) {
      add(
        PlateMeaningTag(
          id: 'mirror_digits_$d',
          labelRu: 'Зеркало $d',
          explanationRu: 'Цифры номера зеркальные (палиндром $d).',
          kind: MeaningKind.mirrorDigits,
          scoreBoost: 14,
        ),
      );
    }

    // Region flavour (Moscow / SPb) as mild meaning, not rarity duplicate heavy
    final region = int.tryParse(parts.region) ?? 0;
    if ({77, 97, 177, 197, 199, 777, 799}.contains(region)) {
      add(
        PlateMeaningTag(
          id: 'region_msk_$region',
          labelRu: 'Москва · $region',
          explanationRu:
              'Регион $region — московский пул; усиливает интерес к «статусным» сериям.',
          kind: MeaningKind.regional,
          scoreBoost: 6,
        ),
      );
    } else if ({78, 98, 178, 198}.contains(region)) {
      add(
        PlateMeaningTag(
          id: 'region_spb_$region',
          labelRu: 'СПб · $region',
          explanationRu: 'Регион $region — Санкт-Петербург.',
          kind: MeaningKind.regional,
          scoreBoost: 5,
        ),
      );
    }

    // GOS vibe: status series + Moscow region on civilian plates
    if ({'ААА', 'ВОР', 'АМР', 'АМО', 'РОС', 'РУС', 'МОО'}.contains(parts.seriesKey) &&
        {77, 97, 177, 197, 199, 777, 799}.contains(region)) {
      add(
        PlateMeaningTag(
          id: 'gos_vibe_${parts.seriesKey}_$region',
          labelRu: 'Гос. оттенок',
          explanationRu:
              'Сочетание серии ${parts.seriesKey} и московского региона часто читается как «правительственный» гражданский номер (GOS-вайб без синего спецформата).',
          kind: MeaningKind.government,
          scoreBoost: 10,
        ),
      );
    }

    tags.sort((a, b) => b.scoreBoost.compareTo(a.scoreBoost));
    return tags;
  }

  static RuCivilianParts? parse(String normalized) {
    final m = _ruCivilian.firstMatch(normalized);
    if (m == null) return null;
    final first = m.group(1)!;
    final digits = m.group(2)!;
    final series = m.group(3)!;
    final region = m.group(4)!;
    return RuCivilianParts(
      firstLetter: first,
      digits: digits,
      seriesLetters: series,
      region: region,
      seriesKey: '$first$series',
    );
  }
}

/// BY / KZ reuse RU civilian letter rules when the plate matches the same shape.
class CisCivilianSeriesCatalog implements CountrySeriesCatalog {
  const CisCivilianSeriesCatalog({required this.countryCode});

  @override
  final String countryCode;

  static const _ru = RuCivilianSeriesCatalog();

  @override
  List<PlateMeaningTag> analyze(String normalized) {
    final tags = _ru.analyze(normalized);
    if (tags.isEmpty) return tags;
    return [
      ...tags,
      PlateMeaningTag(
        id: 'cis_format_$countryCode',
        labelRu: 'Формат СНГ',
        explanationRu:
            'Номер разобран правилами гражданской серии RU (расширяемо для $countryCode).',
        kind: MeaningKind.other,
        scoreBoost: 2,
      ),
    ];
  }
}

class _KnownSeries {
  const _KnownSeries({
    required this.label,
    required this.kind,
    required this.boost,
    required this.text,
  });

  final String label;
  final MeaningKind kind;
  final int boost;
  final String text;
}
