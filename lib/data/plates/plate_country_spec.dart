import 'plate_fields.dart';
import 'plate_format.dart';
import 'plate_visual_spec.dart';

/// Full catalog entry for one country (formats + visual + OCR hints).
class PlateCountrySpec {
  const PlateCountrySpec({
    required this.code,
    required this.nameEn,
    required this.nameRu,
    required this.formats,
    required this.visual,
    this.aliases = const [],
    this.ocrAlphabetHint = '',
    this.normalizeHint,
  });

  final String code;
  final String nameEn;
  final String nameRu;
  final List<PlateFormat> formats;
  final PlateVisualSpec visual;

  /// Alternate ISO / common codes (e.g. UK → GB).
  final List<String> aliases;

  /// Free-text OCR hint (Cyrillic plate letters, etc.).
  final String ocrAlphabetHint;

  /// Optional extra normalize step before format match.
  final String Function(String normalized)? normalizeHint;

  ParsedPlateFields parse(String normalized) {
    var text = normalized;
    if (normalizeHint != null) text = normalizeHint!(text);
    for (final f in formats) {
      final parsed = f.tryParse(text);
      if (parsed != null) return parsed;
    }
    return ParsedPlateFields(
      slots: {'main': text},
      displayText: text,
      matched: false,
    );
  }

  bool matches(String normalized) {
    var text = normalized;
    if (normalizeHint != null) text = normalizeHint!(text);
    return formats.any((f) => f.matches(text));
  }

  /// Best OCR bonus among matching formats (0 if none).
  int ocrScoreBonus(String normalized) {
    var text = normalized;
    if (normalizeHint != null) text = normalizeHint!(text);
    var best = 0;
    for (final f in formats) {
      if (f.matches(text) && f.ocrBonus > best) best = f.ocrBonus;
    }
    return best;
  }
}
