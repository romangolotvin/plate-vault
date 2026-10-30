import 'plate_fields.dart';

typedef PlateFieldExtractor = ParsedPlateFields Function(RegExpMatch match);

/// Regex + field extractor for one official / common plate shape.
class PlateFormat {
  const PlateFormat({
    required this.id,
    required this.pattern,
    required this.extract,
    this.description = '',
    this.ocrBonus = 30,
  });

  final String id;
  final RegExp pattern;
  final PlateFieldExtractor extract;
  final String description;

  /// Extra OCR candidate score when this format matches.
  final int ocrBonus;

  ParsedPlateFields? tryParse(String normalized) {
    final m = pattern.firstMatch(normalized);
    if (m == null) return null;
    final fields = extract(m);
    return ParsedPlateFields(
      slots: fields.slots,
      displayText: fields.displayText.isEmpty ? normalized : fields.displayText,
      matched: true,
    );
  }

  bool matches(String normalized) => pattern.hasMatch(normalized);
}

/// Shared extractors for common layouts.
class PlateExtractors {
  PlateExtractors._();

  /// RU/BY-style: L DDD LL region
  static ParsedPlateFields ruCivilian(RegExpMatch m) {
    final letter = m.group(1)!;
    final digits = m.group(2)!;
    final series = m.group(3)!;
    final region = m.group(4)!;
    return ParsedPlateFields(
      slots: {
        'letter': letter,
        'digits': digits,
        'series': series,
        'region': region,
        'seriesKey': '$letter$series',
        'main': '$letter$digits$series',
      },
      displayText: '$letter$digits$series$region',
      matched: true,
    );
  }

  /// EU blue-strip: whole plate as `main`, optional region/city prefix.
  static ParsedPlateFields euMain(RegExpMatch m, {String? regionGroup}) {
    final main = m.group(0)!;
    final slots = <String, String>{'main': main};
    if (regionGroup != null) {
      final r = m.namedGroup(regionGroup);
      if (r != null) slots['region'] = r;
    }
    // Prefer numbered groups if present.
    if (m.groupCount >= 1 && m.group(1) != null) {
      slots['prefix'] = m.group(1)!;
    }
    if (m.groupCount >= 2 && m.group(2) != null) {
      slots['body'] = m.group(2)!;
    }
    if (m.groupCount >= 3 && m.group(3) != null) {
      slots['suffix'] = m.group(3)!;
    }
    return ParsedPlateFields(slots: slots, displayText: main, matched: true);
  }

  static ParsedPlateFields singleMain(RegExpMatch m) {
    final main = m.group(0)!;
    return ParsedPlateFields(
      slots: {'main': main},
      displayText: main,
      matched: true,
    );
  }
}
