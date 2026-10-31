/// Calendar-month season id: `YYYY-MM` (local time).
class Season {
  const Season({required this.id, required this.labelRu});

  final String id;
  final String labelRu;

  static Season current([DateTime? now]) {
    final d = now ?? DateTime.now();
    final local = DateTime(d.year, d.month, d.day);
    final id =
        '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}';
    const months = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    return Season(id: id, labelRu: '${months[local.month - 1]} ${local.year}');
  }

  static bool createdInSeason(DateTime createdAt, String seasonId) {
    final local = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final id =
        '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}';
    return id == seasonId;
  }
}
