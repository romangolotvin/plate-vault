/// Display / preference currency for plate collector estimates.
enum AppCurrency {
  rub,
  usd,
  eur;

  String get code => switch (this) {
        AppCurrency.rub => 'RUB',
        AppCurrency.usd => 'USD',
        AppCurrency.eur => 'EUR',
      };

  String get symbol => switch (this) {
        AppCurrency.rub => '₽',
        AppCurrency.usd => '\$',
        AppCurrency.eur => '€',
      };

  String get labelRu => switch (this) {
        AppCurrency.rub => 'Рубли (₽)',
        AppCurrency.usd => 'Доллары (\$)',
        AppCurrency.eur => 'Евро (€)',
      };

  static AppCurrency fromCode(String? value) {
    final v = (value ?? '').toUpperCase();
    return switch (v) {
      'USD' => AppCurrency.usd,
      'EUR' => AppCurrency.eur,
      _ => AppCurrency.rub,
    };
  }
}
