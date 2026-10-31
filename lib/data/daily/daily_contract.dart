import '../models/collection_item.dart';
import '../rarity/rarity_engine.dart';
import '../series/plate_meaning.dart';
import '../series/series_catalog.dart';

enum DailyChallengeKind {
  mskRegion,
  tripleDigits,
  nonRu,
  mirror,
}

/// One daily hunt challenge. Day key is local calendar `yyyy-MM-dd`.
class DailyContract {
  const DailyContract({
    required this.dayKey,
    required this.kind,
    required this.titleRu,
    required this.bodyRu,
    required this.badgeRu,
    required this.bonusRub,
  });

  final String dayKey;
  final DailyChallengeKind kind;
  final String titleRu;
  final String bodyRu;
  final String badgeRu;
  final double bonusRub;

  static String dayKeyFor(DateTime when) {
    final local = when.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DailyContract forDay([DateTime? when]) {
    final now = when ?? DateTime.now();
    final key = dayKeyFor(now);
    final dayIndex = DateTime(now.year, now.month, now.day)
        .difference(DateTime(now.year))
        .inDays;
    final kind = DailyChallengeKind.values[dayIndex % DailyChallengeKind.values.length];
    return _build(dayKey: key, kind: kind);
  }

  static DailyContract _build({
    required String dayKey,
    required DailyChallengeKind kind,
  }) {
    return switch (kind) {
      DailyChallengeKind.mskRegion => DailyContract(
          dayKey: dayKey,
          kind: kind,
          titleRu: 'Московский регион',
          bodyRu:
              'Сними Street-номер с регионом 77 / 97 / 177 / 197 / 199 / 777 / 799.',
          badgeRu: 'MSK-охотник',
          bonusRub: 25_000,
        ),
      DailyChallengeKind.tripleDigits => DailyContract(
          dayKey: dayKey,
          kind: kind,
          titleRu: 'Тройные цифры',
          bodyRu: 'Найди Street-номер с одинаковыми цифрами: 111 · 222 · … · 777.',
          badgeRu: 'Тройка',
          bonusRub: 20_000,
        ),
      DailyChallengeKind.nonRu => DailyContract(
          dayKey: dayKey,
          kind: kind,
          titleRu: 'Не Россия',
          bodyRu: 'Сними Street-номер любой страны кроме RU (BY, KZ, EU, US…).',
          badgeRu: 'Интер',
          bonusRub: 30_000,
        ),
      DailyChallengeKind.mirror => DailyContract(
          dayKey: dayKey,
          kind: kind,
          titleRu: 'Зеркало',
          bodyRu:
              'Street-номер с зеркальными буквами или цифрами (палиндром серии / 101).',
          badgeRu: 'Зеркало дня',
          bonusRub: 22_000,
        ),
    };
  }

  bool matchesPlate({
    required String countryCode,
    required String rawText,
    String? normalizedText,
  }) {
    final cc = countryCode.toUpperCase();
    final n = (normalizedText != null && normalizedText.isNotEmpty)
        ? normalizedText
        : RarityEngine.instance.normalize(rawText);

    return switch (kind) {
      DailyChallengeKind.mskRegion => _matchMsk(cc, n),
      DailyChallengeKind.tripleDigits => _matchTriple(cc, n),
      DailyChallengeKind.nonRu => cc != 'RU' && n.isNotEmpty,
      DailyChallengeKind.mirror => _matchMirror(cc, n),
    };
  }

  bool matchesItem(CollectionItem item) {
    if (!item.isStreet) return false;
    return matchesPlate(
      countryCode: item.countryCode,
      rawText: item.rawText,
      normalizedText: item.normalizedText,
    );
  }

  static bool _matchMsk(String cc, String n) {
    if (cc != 'RU') return false;
    final parts = RuCivilianSeriesCatalog.parse(n);
    if (parts == null) return false;
    final region = int.tryParse(parts.region) ?? -1;
    return {77, 97, 177, 197, 199, 777, 799}.contains(region);
  }

  static bool _matchTriple(String cc, String n) {
    if (cc != 'RU') return false;
    final parts = RuCivilianSeriesCatalog.parse(n);
    if (parts == null) return false;
    final d = parts.digits;
    return d.length == 3 && d[0] == d[1] && d[1] == d[2];
  }

  static bool _matchMirror(String cc, String n) {
    final tags = SeriesCatalog().analyze(countryCode: cc, normalized: n);
    return tags.any(
      (t) =>
          t.kind == MeaningKind.mirrorDigits ||
          t.kind == MeaningKind.mirrorLetters,
    );
  }
}

class DailyContractState {
  const DailyContractState({
    required this.contract,
    required this.completedDayKey,
    required this.lifetimeBonusRub,
    required this.badges,
  });

  final DailyContract contract;
  final String? completedDayKey;
  final double lifetimeBonusRub;
  final List<String> badges;

  bool get isCompleteToday => completedDayKey == contract.dayKey;
}
