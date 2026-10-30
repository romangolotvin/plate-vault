import '../series/plate_meaning.dart';

enum Rarity {
  common,
  uncommon,
  rare,
  epic,
  legendary;

  String get labelRu => switch (this) {
        Rarity.common => 'Обычный',
        Rarity.uncommon => 'Необычный',
        Rarity.rare => 'Редкий',
        Rarity.epic => 'Эпический',
        Rarity.legendary => 'Легендарный',
      };

  String get nameKey => name;

  static Rarity fromName(String? value) {
    return Rarity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Rarity.common,
    );
  }
}

class RarityResult {
  const RarityResult({
    required this.rarity,
    required this.reason,
    this.score = 0,
    this.meanings = const [],
  });

  final Rarity rarity;
  final String reason;
  final int score;
  final List<PlateMeaningTag> meanings;

  List<String> get meaningLabels =>
      meanings.map((m) => m.labelRu).toList(growable: false);

  Map<String, dynamic> toJson() => {
        'rarity': rarity.name,
        'reason': reason,
        'score': score,
        'meanings': meanings.map((m) => m.toJson()).toList(),
      };

  factory RarityResult.fromJson(Map<String, dynamic> json) {
    return RarityResult(
      rarity: Rarity.fromName(json['rarity'] as String?),
      reason: json['reason'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      meanings: (json['meanings'] as List?)
              ?.whereType<Map>()
              .map((e) => PlateMeaningTag.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
    );
  }
}
