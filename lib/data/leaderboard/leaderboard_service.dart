import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/collection_item.dart';
import '../models/trust_level.dart';
import '../models/user_profile.dart';
import '../valuation/plate_valuation_engine.dart';

enum LeaderboardKind {
  /// Legacy: all plates (kept for tests / old data).
  unverified,

  /// Only Street-verified plates — the sole public leaderboard.
  street,
}

extension LeaderboardKindX on LeaderboardKind {
  String get labelRu => switch (this) {
        LeaderboardKind.unverified => 'Неквалифицированный',
        LeaderboardKind.street => 'Street',
      };

  String get subtitleRu => switch (this) {
        LeaderboardKind.unverified =>
          'Устаревший режим · больше не показывается',
        LeaderboardKind.street =>
          'Портфель Street · два ракурса камерой в приложении',
      };
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.portfolioRub,
    required this.plateCount,
    required this.kind,
    this.isMe = false,
  });

  final int rank;
  final String userId;
  final String displayName;
  final double portfolioRub;
  final int plateCount;
  final LeaderboardKind kind;
  final bool isMe;
}

/// Local-first leaderboards; mirrors to Firestore when cloud is configured.
class LeaderboardService {
  LeaderboardService({
    FirebaseFirestore? firestore,
    bool cloudEnabled = false,
  })  : _firestore = firestore,
        _cloudEnabled = cloudEnabled;

  final FirebaseFirestore? _firestore;
  final bool _cloudEnabled;
  final _valuation = PlateValuationEngine.instance;

  double portfolioWorth(
    List<CollectionItem> items, {
    required LeaderboardKind kind,
  }) {
    var sum = 0.0;
    for (final item in items) {
      if (kind == LeaderboardKind.street && !item.isStreet) continue;
      // Unverified board: all plates, but Street plates still count full value.
      sum += _valuation
          .estimate(countryCode: item.countryCode, rawText: item.rawText)
          .amountRub;
    }
    return sum;
  }

  int plateCount(
    List<CollectionItem> items, {
    required LeaderboardKind kind,
  }) {
    if (kind == LeaderboardKind.street) {
      return items.where((e) => e.isStreet).length;
    }
    return items.length;
  }

  /// Build rankings from local public profiles + their public items,
  /// then optionally merge cloud snapshots.
  Future<List<LeaderboardEntry>> build({
    required LeaderboardKind kind,
    required List<UserProfile> profiles,
    required List<CollectionItem> allVisibleItems,
    UserProfile? me,
    List<CollectionItem>? myItems,
  }) async {
    final byUser = <String, List<CollectionItem>>{};
    for (final item in allVisibleItems) {
      byUser.putIfAbsent(item.userId, () => []).add(item);
    }
    if (me != null && myItems != null) {
      byUser[me.uid] = myItems;
    }

    final rows = <LeaderboardEntry>[];
    final seen = <String>{};

    void addProfile(UserProfile p, List<CollectionItem> items) {
      if (!seen.add(p.uid)) return;
      final worth = portfolioWorth(items, kind: kind);
      final count = plateCount(items, kind: kind);
      if (count == 0 && worth == 0 && p.uid != me?.uid) return;
      rows.add(
        LeaderboardEntry(
          rank: 0,
          userId: p.uid,
          displayName: p.displayName,
          portfolioRub: worth,
          plateCount: count,
          kind: kind,
          isMe: me?.uid == p.uid,
        ),
      );
    }

    if (me != null) {
      addProfile(me, myItems ?? byUser[me.uid] ?? const []);
    }
    for (final p in profiles) {
      addProfile(p, byUser[p.uid] ?? const []);
    }

    // Cloud overlay when available.
    if (_cloudEnabled && _firestore != null) {
      try {
        final snap = await _firestore!
            .collection('leaderboards')
            .doc(kind.name)
            .collection('entries')
            .orderBy('portfolioRub', descending: true)
            .limit(50)
            .get();
        for (final doc in snap.docs) {
          final d = doc.data();
          final uid = d['userId'] as String? ?? doc.id;
          if (seen.contains(uid)) continue;
          seen.add(uid);
          rows.add(
            LeaderboardEntry(
              rank: 0,
              userId: uid,
              displayName: d['displayName'] as String? ?? 'Collector',
              portfolioRub: (d['portfolioRub'] as num?)?.toDouble() ?? 0,
              plateCount: d['plateCount'] as int? ?? 0,
              kind: kind,
              isMe: me?.uid == uid,
            ),
          );
        }
      } catch (_) {
        // Stay local if rules / index missing.
      }
    }

    rows.sort((a, b) {
      final c = b.portfolioRub.compareTo(a.portfolioRub);
      if (c != 0) return c;
      return b.plateCount.compareTo(a.plateCount);
    });

    return [
      for (var i = 0; i < rows.length; i++)
        LeaderboardEntry(
          rank: i + 1,
          userId: rows[i].userId,
          displayName: rows[i].displayName,
          portfolioRub: rows[i].portfolioRub,
          plateCount: rows[i].plateCount,
          kind: rows[i].kind,
          isMe: rows[i].isMe,
        ),
    ];
  }

  /// Push Street portfolio so other devices can see it when cloud is on.
  Future<void> publishMine({
    required UserProfile me,
    required List<CollectionItem> myItems,
    double dailyBonusRub = 0,
  }) async {
    if (!_cloudEnabled || _firestore == null) return;
    try {
      const kind = LeaderboardKind.street;
      final worth = portfolioWorth(myItems, kind: kind) + dailyBonusRub;
      final count = plateCount(myItems, kind: kind);
      await _firestore!
          .collection('leaderboards')
          .doc(kind.name)
          .collection('entries')
          .doc(me.uid)
          .set({
        'userId': me.uid,
        'displayName': me.displayName,
        'portfolioRub': worth,
        'plateCount': count,
        'updatedAt': FieldValue.serverTimestamp(),
        'trust': TrustLevel.street.name,
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
