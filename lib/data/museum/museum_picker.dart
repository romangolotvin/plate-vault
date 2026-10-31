import '../models/collection_item.dart';
import '../valuation/plate_valuation_engine.dart';

/// Museum: up to [max] best Street plates for profile / public showcase.
class MuseumPicker {
  MuseumPicker._();

  static const defaultMax = 6;

  /// Prefer manually flagged showcase Street plates, then fill by valuation.
  static List<CollectionItem> pick(
    List<CollectionItem> items, {
    int max = defaultMax,
  }) {
    if (max <= 0) return const [];
    final street = items.where((e) => e.isStreet).toList();
    if (street.isEmpty) return const [];

    final valuation = PlateValuationEngine.instance;
    double worth(CollectionItem i) => valuation
        .estimate(countryCode: i.countryCode, rawText: i.rawText)
        .amountRub;

    final showcase = street.where((e) => e.isShowcase).toList()
      ..sort((a, b) => worth(b).compareTo(worth(a)));

    final picked = <CollectionItem>[];
    final seen = <String>{};

    void take(CollectionItem item) {
      if (picked.length >= max) return;
      if (!seen.add(item.id)) return;
      picked.add(item);
    }

    for (final item in showcase) {
      take(item);
    }

    final rest = street.where((e) => !seen.contains(e.id)).toList()
      ..sort((a, b) {
        final c = worth(b).compareTo(worth(a));
        if (c != 0) return c;
        return b.createdAt.compareTo(a.createdAt);
      });
    for (final item in rest) {
      take(item);
    }
    return picked;
  }

  /// How many Street plates are already on the museum showcase flag.
  static int showcaseCount(List<CollectionItem> items) =>
      items.where((e) => e.isStreet && e.isShowcase).length;

  static bool canAddShowcase(List<CollectionItem> items, {int max = defaultMax}) =>
      showcaseCount(items) < max;
}
