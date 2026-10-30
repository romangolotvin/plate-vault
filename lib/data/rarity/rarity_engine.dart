import '../models/rarity.dart';
import '../series/plate_meaning.dart';
import '../series/series_catalog.dart';

class RarityEngine {
  RarityEngine({SeriesCatalog? seriesCatalog})
      : _series = seriesCatalog ?? SeriesCatalog();

  final SeriesCatalog _series;

  static final RarityEngine instance = RarityEngine();

  static final _repeating = RegExp(r'(.)\1{2,}');
  static final _sequentialAsc = RegExp(
    r'(012|123|234|345|456|567|678|789|890)',
  );
  static final _allSameDigit = RegExp(r'^(\d)\1+$');

  /// Russian passenger format: A123BC77 / A123BC777
  static final _ruPlate = RegExp(
    r'^[АВЕКМНОРСТУХ]\d{3}[АВЕКМНОРСТУХ]{2}\d{2,3}$',
  );

  /// Generic EU-ish: letters + digits mixed, 5–10 chars.
  static final _euLike = RegExp(r'^[A-Z]{1,3}[-\s]?\d{1,4}[-\s]?[A-Z]{0,3}$');

  /// US-ish vanity / short plates.
  static final _usLike = RegExp(r'^[A-Z0-9]{2,8}$');

  RarityResult evaluate({
    required String countryCode,
    required String rawText,
  }) {
    final normalized = normalize(rawText);
    if (normalized.isEmpty) {
      return const RarityResult(
        rarity: Rarity.common,
        reason: 'Пустой номер',
        score: 0,
      );
    }

    final country = countryCode.toUpperCase();
    var score = 10;
    final reasons = <String>[];

    score += _patternScore(country, normalized, reasons);
    score += _beautyScore(normalized, reasons);
    score += _lengthScore(normalized, reasons);

    final meanings = _series.analyze(
      countryCode: country,
      normalized: normalized,
    );
    for (final m in meanings) {
      score += m.scoreBoost;
      reasons.add(m.labelRu);
    }

    final rarity = _scoreToRarity(score);
    final reason = reasons.isEmpty
        ? 'Стандартная оценка для $country'
        : reasons.join('; ');

    return RarityResult(
      rarity: rarity,
      reason: reason,
      score: score,
      meanings: meanings,
    );
  }

  List<PlateMeaningTag> meaningsFor({
    required String countryCode,
    required String rawText,
  }) {
    return _series.analyze(
      countryCode: countryCode,
      normalized: normalize(rawText),
    );
  }

  /// Latin glyphs that look like RU plate letters (АВЕКМНОРСТУХ).
  /// OCR / QWERTY often emit these instead of Cyrillic.
  /// Also map phonetic R→Р (users type MER for МЕР; visual lookalike is P).
  static const _latinToRuPlate = <String, String>{
    'A': 'А',
    'B': 'В',
    'E': 'Е',
    'K': 'К',
    'M': 'М',
    'H': 'Н',
    'O': 'О',
    'P': 'Р',
    'R': 'Р',
    'C': 'С',
    'T': 'Т',
    'Y': 'У',
    'X': 'Х',
  };

  static final _cyrillic = RegExp(r'[А-ЯЁ]');
  static final _latinRuShape = RegExp(
    r'^[ABEKMHOPCTYXR]\d{3}[ABEKMHOPCTYXR]{2}\d{2,3}$',
  );
  /// Typed as series-first: МЕР777178 → official М777ЕР178.
  static final _latinSeriesFirst = RegExp(
    r'^[ABEKMHOPCTYXR]{3}\d{3}\d{2,3}$',
  );
  static final _ruSeriesFirst = RegExp(
    r'^([АВЕКМНОРСТУХ]{3})(\d{3})(\d{2,3})$',
  );

  String normalize(String raw) {
    var text = raw.toUpperCase().trim();
    text = text
        .replaceAll('Ё', 'Е')
        .replaceAll(RegExp(r'[\s\-·•.]'), '');
    // Keep only letters and digits first for shape checks.
    text = text.replaceAll(RegExp(r'[^A-ZА-Я0-9]'), '');

    // Map Latin lookalikes → Cyrillic when input is already RU / RU-shaped.
    // Avoid rewriting genuine Latin plates (US/EU).
    final mapToRu = _cyrillic.hasMatch(text) ||
        _latinRuShape.hasMatch(text) ||
        _latinSeriesFirst.hasMatch(text);
    if (mapToRu) {
      final mapped = StringBuffer();
      for (final rune in text.runes) {
        final ch = String.fromCharCode(rune);
        mapped.write(_latinToRuPlate[ch] ?? ch);
      }
      text = mapped.toString();
    }

    // Reshape collector typing «МЕР777178» → official «М777ЕР178».
    final seriesFirst = _ruSeriesFirst.firstMatch(text);
    if (seriesFirst != null) {
      final letters = seriesFirst.group(1)!;
      final digits = seriesFirst.group(2)!;
      final region = seriesFirst.group(3)!;
      text = '${letters[0]}$digits${letters[1]}${letters[2]}$region';
    }

    return text;
  }

  int _patternScore(String country, String text, List<String> reasons) {
    switch (country) {
      case 'RU':
      case 'BY':
      case 'KZ':
        if (_ruPlate.hasMatch(text)) {
          reasons.add('Соответствует формату СНГ');
          final region = int.tryParse(
                RegExp(r'\d{2,3}$').firstMatch(text)?.group(0) ?? '',
              ) ??
              0;
          if (region == 77 || region == 97 || region == 177 || region == 199) {
            reasons.add('Московский регион');
            return 15;
          }
          if (region == 78 || region == 98 || region == 178) {
            reasons.add('Санкт-Петербург');
            return 12;
          }
          return 8;
        }
        reasons.add('Нестандартный формат для RU');
        return 20;
      case 'US':
      case 'CA':
        if (text.length <= 4) {
          reasons.add('Короткий североамериканский номер');
          return 25;
        }
        if (_usLike.hasMatch(text)) return 8;
        return 12;
      case 'DE':
      case 'FR':
      case 'PL':
      case 'IT':
      case 'ES':
      case 'NL':
      case 'GB':
      case 'UK':
      case 'EU':
        if (_euLike.hasMatch(text) || text.length <= 7) {
          reasons.add('Европейский паттерн');
          return 10;
        }
        return 14;
      default:
        reasons.add('Страна без детальных правил — базовая оценка');
        return 5;
    }
  }

  int _beautyScore(String text, List<String> reasons) {
    var bonus = 0;
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty) {
      if (_allSameDigit.hasMatch(digits)) {
        bonus += 40;
        reasons.add('Все цифры одинаковые');
      } else if (_repeating.hasMatch(digits)) {
        bonus += 18;
        reasons.add('Повторяющиеся цифры');
      }
      if (_sequentialAsc.hasMatch(digits)) {
        bonus += 15;
        reasons.add('Последовательные цифры');
      }
      if (digits == '777' || digits.contains('777')) {
        bonus += 20;
        reasons.add('Счастливые 777');
      }
      if (digits == '000' || digits == '001') {
        bonus += 25;
        reasons.add('Особый числовой ряд');
      }
    }

    final letters = text.replaceAll(RegExp(r'\d'), '');
    if (letters.length >= 3 && letters.split('').toSet().length == 1) {
      bonus += 22;
      reasons.add('Одинаковые буквы');
    }
    return bonus;
  }

  int _lengthScore(String text, List<String> reasons) {
    if (text.length <= 3) {
      reasons.add('Очень короткий номер');
      return 30;
    }
    if (text.length <= 5) {
      reasons.add('Короткий номер');
      return 15;
    }
    if (text.length >= 12) {
      reasons.add('Длинный / спецформат');
      return 8;
    }
    return 0;
  }

  Rarity _scoreToRarity(int score) {
    if (score >= 80) return Rarity.legendary;
    if (score >= 55) return Rarity.epic;
    if (score >= 35) return Rarity.rare;
    if (score >= 20) return Rarity.uncommon;
    return Rarity.common;
  }
}
