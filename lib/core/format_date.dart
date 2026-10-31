/// Safe date labels without intl locale init (DateFormat('ru') can crash → blank screen).
String formatDateRu(DateTime d) {
  const months = [
    'янв',
    'фев',
    'мар',
    'апр',
    'мая',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];
  final m = months[(d.month - 1).clamp(0, 11)];
  return '${d.day} $m ${d.year}';
}
