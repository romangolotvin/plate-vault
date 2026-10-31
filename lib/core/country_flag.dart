/// Regional-indicator flag emoji for ISO 3166-1 alpha-2 (e.g. RU → 🇷🇺).
String countryFlagEmoji(String countryCode) {
  final code = countryCode.trim().toUpperCase();
  if (code.length != 2) return '🏳️';
  final a = code.codeUnitAt(0);
  final b = code.codeUnitAt(1);
  if (a < 65 || a > 90 || b < 65 || b > 90) return '🏳️';
  return String.fromCharCodes([
    0x1F1E6 + (a - 65),
    0x1F1E6 + (b - 65),
  ]);
}

const kProfileCountries = <String>[
  'RU',
  'BY',
  'KZ',
  'UA',
  'US',
  'DE',
  'FR',
  'PL',
  'GB',
  'IT',
  'ES',
  'TR',
  'CN',
  'JP',
  'XX',
];
