/// Russian civilian plates (ГОСТ): one letter, three digits, two letters, region.
///
/// OCR often returns Latin lookalikes and drops the small region on the right,
/// or puts that region on its own line. A plate in this shape used to match the
/// loose US rule `^[A-Z0-9]{2,8}$` and was saved as United States.
class RuPlateRead {
  const RuPlateRead({
    required this.display,
    required this.region,
    required this.knownRegion,
    required this.complete,
  });

  /// Cyrillic letters, digits kept. Region digits stay as read, including a
  /// leading zero (`05`).
  final String display;

  /// Region digits, or null when the region was not in the text at all.
  final String? region;

  /// [region] is a code issued for a Russian subject (01–99 or a known
  /// three-digit code such as 178, 777).
  final bool knownRegion;

  /// Two or three region digits were present (they may still be unknown).
  final bool complete;

  bool get bodyOnly => region == null;
}

class RuRegions {
  RuRegions._();

  /// Three-digit codes issued once a two-digit series is exhausted.
  static const threeDigit = <int>{
    102, 113, 116, 121, 122, 123, 124, 125, 126, 134, 136, 138, 142, 147,
    150, 152, 154, 156, 159, 161, 163, 164, 173, 174, 177, 178, 186, 190,
    193, 196, 197, 198, 199, 702, 716, 725, 750, 754, 761, 763, 774, 777,
    790, 797, 799, 977,
  };

  static bool isKnown(int code) {
    if (code >= 1 && code <= 99) return true;
    return threeDigit.contains(code);
  }
}

class RuPlate {
  RuPlate._();

  static const _latinToRu = <String, String>{
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

  static final _letters = '[ABEKMHOPCTYXRАВЕКМНОРСТУХ]';
  static final _full = RegExp('^($_letters)(\\d{3})($_letters{2})(\\d{2,3})\$');
  static final _truncated = RegExp('^($_letters)(\\d{3})($_letters{2})(\\d)\$');
  static final _body = RegExp('^($_letters)(\\d{3})($_letters{2})\$');

  static String clean(String raw) {
    var text = raw.toUpperCase().trim().replaceAll('Ё', 'Е');
    return text.replaceAll(RegExp(r'[^A-ZА-Я0-9]'), '');
  }

  static String mapLetters(String text) {
    final mapped = StringBuffer();
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      mapped.write(_latinToRu[ch] ?? ch);
    }
    return mapped.toString();
  }

  /// Reads one token. Newlines and spaces are removed, so `A123BC\\n77`
  /// is the same plate as `A123BC77`.
  static RuPlateRead? read(String raw) {
    var text = clean(raw);
    if (text.startsWith('RUS') && text.length > 3) {
      text = text.substring(3);
    }
    final full = _full.firstMatch(text);
    if (full != null) {
      final region = full.group(4)!;
      final code = int.tryParse(region) ?? 0;
      return RuPlateRead(
        display: mapLetters(text),
        region: region,
        knownRegion: RuRegions.isKnown(code),
        complete: true,
      );
    }
    final cut = _truncated.firstMatch(text);
    if (cut != null) {
      return RuPlateRead(
        display: mapLetters(text),
        region: cut.group(4),
        knownRegion: false,
        complete: false,
      );
    }
    final body = _body.firstMatch(text);
    if (body != null) {
      return RuPlateRead(
        display: mapLetters(text),
        region: null,
        knownRegion: false,
        complete: false,
      );
    }
    return null;
  }

  /// Joins a plate body and a region that OCR split across lines
  /// (`A123BC` + `178`, or `A123BC` + `RUS` + `77`).
  static String? combine(String fullText) {
    if (fullText.trim().isEmpty) return null;

    final direct = read(fullText);
    if (direct != null && direct.knownRegion) return direct.display;

    final tokens = fullText
        .split(RegExp(r'[\s,;|/]+'))
        .map(clean)
        .where((token) => token.isNotEmpty)
        .toList();

    String? body;
    String? regionDigits;
    for (final token in tokens) {
      var piece = token;
      if (piece.startsWith('RUS') && piece.length > 3) {
        piece = piece.substring(3);
      }
      if (piece.endsWith('RUS') && piece.length > 3) {
        piece = piece.substring(0, piece.length - 3);
      }
      final whole = read(piece);
      if (whole != null && whole.knownRegion) return whole.display;
      final regionOnly = RegExp(r'^(\d{2,3})$').firstMatch(piece);
      if (regionOnly != null) {
        final code = int.tryParse(regionOnly.group(1)!) ?? 0;
        if (RuRegions.isKnown(code)) {
          regionDigits ??= regionOnly.group(1)!;
        }
        continue;
      }
      if (whole != null && whole.bodyOnly) {
        body ??= whole.display;
      }
    }

    if (body != null && regionDigits != null) {
      final joined = read('$body$regionDigits');
      if (joined != null) return joined.display;
    }
    if (direct != null) return direct.display;
    for (final token in tokens) {
      final whole = read(token);
      if (whole != null) return whole.display;
    }
    return body;
  }

  /// Russian shape with a real region is Russia even if the user expected
  /// another country. A body with no confirmed region stays Russia unless
  /// they explicitly chose US or some other country.
  static bool preferRussia(RuPlateRead read, String? hint) {
    if (read.knownRegion) return true;
    final hinted = hint?.trim().toUpperCase() ?? '';
    return hinted.isEmpty || hinted == 'RU';
  }
}
