import '../models/collection_item.dart';
import '../models/rarity.dart';
import '../models/trust_level.dart';
import '../valuation/plate_valuation_engine.dart';

class Achievement {
  const Achievement({
    required this.id,
    required this.titleRu,
    required this.detailRu,
    required this.unlocked,
    this.progress = 1,
    this.goal = 1,
  });

  final String id;
  final String titleRu;
  final String detailRu;
  final bool unlocked;
  final int progress;
  final int goal;
}

class AchievementsEngine {
  const AchievementsEngine();

  List<Achievement> evaluate(List<CollectionItem> items) {
    final street = items.where((e) => e.trust == TrustLevel.street).length;
    final countries = items.map((e) => e.countryCode).toSet().length;
    final legend =
        items.where((e) => e.rarity == Rarity.legendary).length;
    final epic = items.where((e) => e.rarity.index >= Rarity.epic.index).length;
    final fav = items.where((e) => e.isFavorite).length;
    final showcase = items.where((e) => e.isShowcase).length;
    var worth = 0.0;
    for (final i in items) {
      worth += PlateValuationEngine.instance
          .estimate(countryCode: i.countryCode, rawText: i.rawText)
          .amountRub;
    }
    final norms = <String, int>{};
    for (final i in items) {
      norms[i.normalizedText] = (norms[i.normalizedText] ?? 0) + 1;
    }
    final hasDup = norms.values.any((c) => c > 1);

    return [
      Achievement(
        id: 'first_plate',
        titleRu: 'Первый трофей',
        detailRu: 'Добавь первый номер в сейф',
        unlocked: items.isNotEmpty,
        progress: items.isEmpty ? 0 : 1,
      ),
      Achievement(
        id: 'street_hunter',
        titleRu: 'Street hunter',
        detailRu: '3 номера сняты камерой в приложении',
        unlocked: street >= 3,
        progress: street.clamp(0, 3),
        goal: 3,
      ),
      Achievement(
        id: 'street_ten',
        titleRu: 'Уличный сейф',
        detailRu: '10 Street-verified номеров',
        unlocked: street >= 10,
        progress: street.clamp(0, 10),
        goal: 10,
      ),
      Achievement(
        id: 'globe',
        titleRu: 'Международный охотник',
        detailRu: 'Номера из 3 стран',
        unlocked: countries >= 3,
        progress: countries.clamp(0, 3),
        goal: 3,
      ),
      Achievement(
        id: 'epic_catch',
        titleRu: 'Эпик в сейфе',
        detailRu: 'Поймай epic или legendary',
        unlocked: epic >= 1,
        progress: epic.clamp(0, 1),
      ),
      Achievement(
        id: 'legend',
        titleRu: 'Легенда улиц',
        detailRu: 'Легендарный номер',
        unlocked: legend >= 1,
        progress: legend.clamp(0, 1),
      ),
      Achievement(
        id: 'millionaire',
        titleRu: 'Портфель на миллион',
        detailRu: 'Суммарная оценка ≥ 1 000 000 ₽',
        unlocked: worth >= 1_000_000,
        progress: worth >= 1_000_000 ? 1 : 0,
      ),
      Achievement(
        id: 'showcase',
        titleRu: 'Витрина',
        detailRu: 'Отметь номер как showcase',
        unlocked: showcase >= 1,
        progress: showcase.clamp(0, 1),
      ),
      Achievement(
        id: 'favorites',
        titleRu: 'Избранное',
        detailRu: '3 избранных номера',
        unlocked: fav >= 3,
        progress: fav.clamp(0, 3),
        goal: 3,
      ),
      Achievement(
        id: 'twin_detect',
        titleRu: 'Двойник',
        detailRu: 'Найди дубликат в коллекции',
        unlocked: hasDup,
        progress: hasDup ? 1 : 0,
      ),
    ];
  }
}
