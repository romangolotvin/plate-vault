/// Consecutive local calendar days with ≥1 Street save.
///
/// Break rule: if the last Street save day is older than yesterday
/// (local timezone), the streak resets to 0. Same-day saves do not
/// increment twice.
class HuntStreak {
  const HuntStreak({
    required this.current,
    required this.best,
    this.lastDayKey,
  });

  final int current;
  final int best;
  final String? lastDayKey;

  static String dayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    final local = DateTime(d.year, d.month, d.day);
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static DateTime parseDayKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Effective streak for UI — applies break if last day is stale.
  HuntStreak resolved([DateTime? now]) {
    if (lastDayKey == null || current <= 0) {
      return HuntStreak(current: 0, best: best, lastDayKey: lastDayKey);
    }
    final today = dayKey(now);
    if (lastDayKey == today) {
      return this;
    }
    final yesterday = dayKey((now ?? DateTime.now()).subtract(const Duration(days: 1)));
    if (lastDayKey == yesterday) {
      return this;
    }
    return HuntStreak(current: 0, best: best, lastDayKey: lastDayKey);
  }

  /// Record a Street save on [now]'s calendar day.
  HuntStreak recordStreetSave([DateTime? now]) {
    final today = dayKey(now);
    if (lastDayKey == today) {
      // Already counted today.
      return resolved(now);
    }
    final yesterday =
        dayKey((now ?? DateTime.now()).subtract(const Duration(days: 1)));
    final nextCurrent = (lastDayKey == yesterday) ? current + 1 : 1;
    final nextBest = nextCurrent > best ? nextCurrent : best;
    return HuntStreak(
      current: nextCurrent,
      best: nextBest,
      lastDayKey: today,
    );
  }

  Map<String, dynamic> toJson() => {
        'current': current,
        'best': best,
        'lastDayKey': lastDayKey,
      };

  factory HuntStreak.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const HuntStreak(current: 0, best: 0);
    }
    return HuntStreak(
      current: (json['current'] as num?)?.toInt() ?? 0,
      best: (json['best'] as num?)?.toInt() ?? 0,
      lastDayKey: json['lastDayKey'] as String?,
    );
  }
}
