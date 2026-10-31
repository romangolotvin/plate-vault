import '../models/collection_item.dart';
import '../rarity/rarity_engine.dart';
import '../series/plate_meaning.dart';
import '../series/series_catalog.dart';

/// Collector album / set definition with progress fill against Street plates.
class PlateSetDefinition {
  const PlateSetDefinition({
    required this.id,
    required this.titleRu,
    required this.subtitleRu,
    required this.goal,
    required this.accentArgb,
    required this.matchesNormalized,
  });

  final String id;
  final String titleRu;
  final String subtitleRu;
  final int goal;
  final int accentArgb;

  /// Match against RU-normalized text (letters+digits).
  final bool Function(String countryCode, String normalized) matchesNormalized;

  bool matchesItem(CollectionItem item) {
    if (!item.isStreet) return false;
    final normalized = item.normalizedText.isNotEmpty
        ? item.normalizedText
        : RarityEngine.instance.normalize(item.rawText);
    return matchesNormalized(item.countryCode.toUpperCase(), normalized);
  }
}

class PlateSetProgress {
  const PlateSetProgress({
    required this.definition,
    required this.matched,
  });

  final PlateSetDefinition definition;
  final List<CollectionItem> matched;

  int get count => matched.length;
  int get goal => definition.goal;
  double get fill => goal <= 0 ? 0 : (count / goal).clamp(0.0, 1.0);
  bool get complete => count >= goal;
}

class PlateSetsCatalog {
  PlateSetsCatalog._();

  static final _engine = RarityEngine.instance;

  static const _spbRegions = {78, 98, 178, 198};
  static const _mskRegions = {77, 97, 177, 197, 199, 777, 799};
  static const _adminSeries = {
    'АМО',
    'АМР',
    'МОО',
    'МОС',
    'РМО',
    'ООС',
    'ААМ',
  };
  static const _blatnye = {'ВОР', 'ХАМ', 'МУР', 'ХАН'};
  static const _sevens = {'777', '007', '070', '700', '707', '770'};

  static final List<PlateSetDefinition> all = [
    PlateSetDefinition(
      id: 'spb_178',
      titleRu: 'Питер 178',
      subtitleRu: 'Street-номера СПб: 78 · 98 · 178 · 198',
      goal: 5,
      accentArgb: 0xFF6EC8FF,
      matchesNormalized: (cc, n) {
        if (cc != 'RU') return false;
        final parts = RuCivilianSeriesCatalog.parse(n);
        if (parts == null) return false;
        final region = int.tryParse(parts.region) ?? -1;
        return _spbRegions.contains(region);
      },
    ),
    PlateSetDefinition(
      id: 'sevens',
      titleRu: 'Семёрки',
      subtitleRu: '777 и родственные «семёрочные» тройки на Street',
      goal: 3,
      accentArgb: 0xFFFFB020,
      matchesNormalized: (cc, n) {
        if (cc != 'RU') return false;
        final parts = RuCivilianSeriesCatalog.parse(n);
        if (parts == null) return false;
        return _sevens.contains(parts.digits) ||
            parts.digits.split('').where((c) => c == '7').length >= 2;
      },
    ),
    PlateSetDefinition(
      id: 'admin_series',
      titleRu: 'Админ-серии',
      subtitleRu: 'АМР · АМО · МОО · МОС и соседние админ-пулы',
      goal: 4,
      accentArgb: 0xFFB56BFF,
      matchesNormalized: (cc, n) {
        if (cc != 'RU') return false;
        final parts = RuCivilianSeriesCatalog.parse(n);
        return parts != null && _adminSeries.contains(parts.seriesKey);
      },
    ),
    PlateSetDefinition(
      id: 'mer_fsb',
      titleRu: 'МЕР / ФСБ',
      subtitleRu: 'Фольклор спецсвязи: серия МЕР на Street',
      goal: 2,
      accentArgb: 0xFF7B8CFF,
      matchesNormalized: (cc, n) {
        if (cc != 'RU') return false;
        final parts = RuCivilianSeriesCatalog.parse(n);
        return parts?.seriesKey == 'МЕР';
      },
    ),
    PlateSetDefinition(
      id: 'mirrors',
      titleRu: 'Зеркала',
      subtitleRu: 'Зеркальные буквы или цифры на гражданском формате',
      goal: 5,
      accentArgb: 0xFFE879F9,
      matchesNormalized: (cc, n) {
        final tags = SeriesCatalog().analyze(countryCode: cc, normalized: n);
        return tags.any(
          (t) =>
              t.kind == MeaningKind.mirrorDigits ||
              t.kind == MeaningKind.mirrorLetters,
        );
      },
    ),
    PlateSetDefinition(
      id: 'blatnye',
      titleRu: 'Блатные',
      subtitleRu: 'ВОР · ХАМ · МУР · ХАН — статусный уличный фольклор',
      goal: 3,
      accentArgb: 0xFFFF5C7A,
      matchesNormalized: (cc, n) {
        if (cc != 'RU') return false;
        final parts = RuCivilianSeriesCatalog.parse(n);
        return parts != null && _blatnye.contains(parts.seriesKey);
      },
    ),
    PlateSetDefinition(
      id: 'msk_pool',
      titleRu: 'Москва',
      subtitleRu: 'Столичные регионы 77 / 97 / 177 / 199 / 777…',
      goal: 6,
      accentArgb: 0xFFD4A0FF,
      matchesNormalized: (cc, n) {
        if (cc != 'RU') return false;
        final parts = RuCivilianSeriesCatalog.parse(n);
        if (parts == null) return false;
        final region = int.tryParse(parts.region) ?? -1;
        return _mskRegions.contains(region);
      },
    ),
  ];

  static List<PlateSetProgress> progressFor(List<CollectionItem> items) {
    return [
      for (final def in all)
        PlateSetProgress(
          definition: def,
          matched: items.where(def.matchesItem).toList(),
        ),
    ];
  }

  /// Convenience for tests: normalize then match set id.
  static bool itemMatchesSet({
    required String setId,
    required String countryCode,
    required String rawText,
    bool street = true,
  }) {
    if (!street) return false;
    PlateSetDefinition? def;
    for (final e in all) {
      if (e.id == setId) {
        def = e;
        break;
      }
    }
    if (def == null) return false;
    final n = _engine.normalize(rawText);
    return def.matchesNormalized(countryCode.toUpperCase(), n);
  }
}
