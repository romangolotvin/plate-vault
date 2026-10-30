import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Categories of plate-letter / digit meaning (civilian formats first).
enum MeaningKind {
  mirrorLetters,
  mirrorDigits,
  coolSeries,
  blatnye,
  security,
  administration,
  government,
  regional,
  other;

  String get labelRu => switch (this) {
        MeaningKind.mirrorLetters => 'Зеркальные буквы',
        MeaningKind.mirrorDigits => 'Зеркальные цифры',
        MeaningKind.coolSeries => 'Красивая серия',
        MeaningKind.blatnye => 'Блатная серия',
        MeaningKind.security => 'Силовой / спецсвязь',
        MeaningKind.administration => 'Администрация',
        MeaningKind.government => 'Гос. оттенок',
        MeaningKind.regional => 'Регион',
        MeaningKind.other => 'Особенность',
      };

  Color get accent => switch (this) {
        MeaningKind.mirrorLetters => VaultColors.teal,
        MeaningKind.mirrorDigits => const Color(0xFF6EC8FF),
        MeaningKind.coolSeries => const Color(0xFFFF8F6B),
        MeaningKind.blatnye => const Color(0xFFFF5C7A),
        MeaningKind.security => const Color(0xFF7B8CFF),
        MeaningKind.administration => VaultColors.gold,
        MeaningKind.government => const Color(0xFFD4AF37),
        MeaningKind.regional => VaultColors.uncommon,
        MeaningKind.other => VaultColors.mist,
      };
}

class PlateMeaningTag {
  const PlateMeaningTag({
    required this.id,
    required this.labelRu,
    required this.explanationRu,
    required this.kind,
    this.scoreBoost = 0,
  });

  final String id;
  final String labelRu;
  final String explanationRu;
  final MeaningKind kind;
  final int scoreBoost;

  Color get accent => kind.accent;

  Map<String, dynamic> toJson() => {
        'id': id,
        'labelRu': labelRu,
        'explanationRu': explanationRu,
        'kind': kind.name,
        'scoreBoost': scoreBoost,
      };

  factory PlateMeaningTag.fromJson(Map<String, dynamic> json) {
    return PlateMeaningTag(
      id: json['id'] as String? ?? '',
      labelRu: json['labelRu'] as String? ?? '',
      explanationRu: json['explanationRu'] as String? ?? '',
      kind: MeaningKind.values.firstWhere(
        (e) => e.name == json['kind'],
        orElse: () => MeaningKind.other,
      ),
      scoreBoost: (json['scoreBoost'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Parsed civilian RU-style plate parts (letter + 3 digits + 2 letters + region).
class RuCivilianParts {
  const RuCivilianParts({
    required this.firstLetter,
    required this.digits,
    required this.seriesLetters,
    required this.region,
    required this.seriesKey,
  });

  final String firstLetter;
  final String digits;
  final String seriesLetters;
  final String region;

  /// Three-letter series key, e.g. ВОР from В + ОР.
  final String seriesKey;
}
