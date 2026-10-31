import '../leaderboard/leaderboard_service.dart';

/// ISO-ish week id: `YYYY-Www` using local Thursday-week (ISO 8601).
String duelWeekId([DateTime? now]) {
  final d = now ?? DateTime.now();
  // ISO week: week containing Thursday; Monday = day 1.
  final date = DateTime(d.year, d.month, d.day);
  final thursday = date.add(Duration(days: 4 - (date.weekday)));
  final firstThursday = DateTime(thursday.year, 1, 4);
  final week1Monday = firstThursday.subtract(
    Duration(days: firstThursday.weekday - 1),
  );
  final week =
      1 + thursday.difference(week1Monday).inDays ~/ 7;
  final y = thursday.year.toString().padLeft(4, '0');
  final w = week.toString().padLeft(2, '0');
  return '$y-W$w';
}

enum DuelOpponentKind { human, bot }

class DuelOpponent {
  const DuelOpponent({
    required this.id,
    required this.displayName,
    required this.portfolioRub,
    required this.kind,
    this.rank,
  });

  final String id;
  final String displayName;
  final double portfolioRub;
  final DuelOpponentKind kind;
  final int? rank;

  bool get isBot => kind == DuelOpponentKind.bot;

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'portfolioRub': portfolioRub,
        'kind': kind.name,
        'rank': rank,
      };

  factory DuelOpponent.fromJson(Map<String, dynamic> json) {
    return DuelOpponent(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? 'Оппонент',
      portfolioRub: (json['portfolioRub'] as num?)?.toDouble() ?? 0,
      kind: DuelOpponentKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => DuelOpponentKind.bot,
      ),
      rank: (json['rank'] as num?)?.toInt(),
    );
  }
}

class WeeklyDuel {
  const WeeklyDuel({
    required this.weekId,
    required this.myPortfolioRub,
    required this.opponent,
    required this.matchedAtIso,
  });

  final String weekId;
  final double myPortfolioRub;
  final DuelOpponent opponent;
  final String matchedAtIso;

  bool get winning => myPortfolioRub > opponent.portfolioRub;
  bool get tied => (myPortfolioRub - opponent.portfolioRub).abs() < 0.5;
  double get deltaRub => myPortfolioRub - opponent.portfolioRub;

  WeeklyDuel withMyPortfolio(double rub) => WeeklyDuel(
        weekId: weekId,
        myPortfolioRub: rub,
        opponent: opponent,
        matchedAtIso: matchedAtIso,
      );

  Map<String, dynamic> toJson() => {
        'weekId': weekId,
        'myPortfolioRub': myPortfolioRub,
        'opponent': opponent.toJson(),
        'matchedAtIso': matchedAtIso,
      };

  factory WeeklyDuel.fromJson(Map<String, dynamic> json) {
    return WeeklyDuel(
      weekId: json['weekId'] as String,
      myPortfolioRub: (json['myPortfolioRub'] as num?)?.toDouble() ?? 0,
      opponent: DuelOpponent.fromJson(
        json['opponent'] as Map<String, dynamic>? ?? const {},
      ),
      matchedAtIso: json['matchedAtIso'] as String? ??
          DateTime.now().toIso8601String(),
    );
  }
}

/// Pick nearest-rank opponent from Street board; seed bots if alone.
class DuelMatcher {
  const DuelMatcher();

  static const _botSeeds = <DuelOpponent>[
    DuelOpponent(
      id: 'bot_neon',
      displayName: 'Neon Hunter (бот)',
      portfolioRub: 42000,
      kind: DuelOpponentKind.bot,
      rank: null,
    ),
    DuelOpponent(
      id: 'bot_metro',
      displayName: 'Metro Ghost (бот)',
      portfolioRub: 128000,
      kind: DuelOpponentKind.bot,
    ),
    DuelOpponent(
      id: 'bot_fsb',
      displayName: 'Серия МЕР (бот)',
      portfolioRub: 890000,
      kind: DuelOpponentKind.bot,
    ),
    DuelOpponent(
      id: 'bot_spb',
      displayName: 'Питер 178 (бот)',
      portfolioRub: 256000,
      kind: DuelOpponentKind.bot,
    ),
  ];

  WeeklyDuel match({
    required String myUserId,
    required double myPortfolioRub,
    required List<LeaderboardEntry> board,
    DateTime? now,
  }) {
    final week = duelWeekId(now);
    final others = board.where((e) => e.userId != myUserId).toList();
    DuelOpponent opponent;

    if (others.isEmpty) {
      opponent = _pickBot(myPortfolioRub);
    } else {
      // Prefer closest portfolio; fall back to adjacent rank.
      others.sort((a, b) {
        final da = (a.portfolioRub - myPortfolioRub).abs();
        final db = (b.portfolioRub - myPortfolioRub).abs();
        return da.compareTo(db);
      });
      final best = others.first;
      opponent = DuelOpponent(
        id: best.userId,
        displayName: best.displayName,
        portfolioRub: best.portfolioRub,
        kind: DuelOpponentKind.human,
        rank: best.rank,
      );
    }

    return WeeklyDuel(
      weekId: week,
      myPortfolioRub: myPortfolioRub,
      opponent: opponent,
      matchedAtIso: (now ?? DateTime.now()).toIso8601String(),
    );
  }

  DuelOpponent _pickBot(double myRub) {
    final sorted = [..._botSeeds]
      ..sort((a, b) {
        final da = (a.portfolioRub - myRub).abs();
        final db = (b.portfolioRub - myRub).abs();
        return da.compareTo(db);
      });
    final base = sorted.first;
    // Nudge bot toward player so duel feels competitive.
    final nudged = myRub <= 0
        ? base.portfolioRub
        : (myRub * 0.92 + base.portfolioRub * 0.08);
    return DuelOpponent(
      id: base.id,
      displayName: base.displayName,
      portfolioRub: nudged,
      kind: DuelOpponentKind.bot,
    );
  }
}
