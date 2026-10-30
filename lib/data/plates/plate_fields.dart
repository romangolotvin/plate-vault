/// Parsed slots used by [LicensePlateView] and OCR scoring.
class ParsedPlateFields {
  const ParsedPlateFields({
    this.slots = const {},
    this.displayText = '',
    this.matched = false,
  });

  /// Named layout slots, e.g. `letter`, `digits`, `series`, `region`, `main`.
  final Map<String, String> slots;
  final String displayText;
  final bool matched;

  String? operator [](String key) => slots[key];

  String getOr(String key, [String fallback = '']) => slots[key] ?? fallback;
}
