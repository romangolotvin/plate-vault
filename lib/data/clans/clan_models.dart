import 'dart:math';

/// Local-first clan: invite code, members, Street portfolio sum.
class ClanMember {
  const ClanMember({
    required this.userId,
    required this.displayName,
    required this.streetPortfolioRub,
    required this.joinedAtIso,
    this.isOwner = false,
  });

  final String userId;
  final String displayName;
  final double streetPortfolioRub;
  final String joinedAtIso;
  final bool isOwner;

  ClanMember copyWith({
    String? displayName,
    double? streetPortfolioRub,
  }) {
    return ClanMember(
      userId: userId,
      displayName: displayName ?? this.displayName,
      streetPortfolioRub: streetPortfolioRub ?? this.streetPortfolioRub,
      joinedAtIso: joinedAtIso,
      isOwner: isOwner,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'streetPortfolioRub': streetPortfolioRub,
        'joinedAtIso': joinedAtIso,
        'isOwner': isOwner,
      };

  factory ClanMember.fromJson(Map<String, dynamic> json) {
    return ClanMember(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String? ?? 'Collector',
      streetPortfolioRub:
          (json['streetPortfolioRub'] as num?)?.toDouble() ?? 0,
      joinedAtIso: json['joinedAtIso'] as String? ??
          DateTime.now().toIso8601String(),
      isOwner: json['isOwner'] as bool? ?? false,
    );
  }
}

class Clan {
  const Clan({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.members,
    required this.createdAtIso,
  });

  final String id;
  final String name;
  final String inviteCode;
  final List<ClanMember> members;
  final String createdAtIso;

  double get portfolioSum =>
      members.fold(0.0, (s, m) => s + m.streetPortfolioRub);

  int get memberCount => members.length;

  ClanMember? member(String userId) {
    for (final m in members) {
      if (m.userId == userId) return m;
    }
    return null;
  }

  bool contains(String userId) => member(userId) != null;

  Clan copyWith({
    String? name,
    List<ClanMember>? members,
  }) {
    return Clan(
      id: id,
      name: name ?? this.name,
      inviteCode: inviteCode,
      members: members ?? this.members,
      createdAtIso: createdAtIso,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'inviteCode': inviteCode,
        'members': members.map((m) => m.toJson()).toList(),
        'createdAtIso': createdAtIso,
      };

  factory Clan.fromJson(Map<String, dynamic> json) {
    final raw = json['members'] as List<dynamic>? ?? const [];
    return Clan(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Клан',
      inviteCode: (json['inviteCode'] as String? ?? '').toUpperCase(),
      members: raw
          .map((e) => ClanMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAtIso: json['createdAtIso'] as String? ??
          DateTime.now().toIso8601String(),
    );
  }
}

class ClanService {
  ClanService({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String generateInviteCode({int length = 6}) {
    final buf = StringBuffer();
    for (var i = 0; i < length; i++) {
      buf.write(_alphabet[_random.nextInt(_alphabet.length)]);
    }
    return buf.toString();
  }

  Clan create({
    required String ownerId,
    required String ownerName,
    required String clanName,
    required double ownerStreetRub,
  }) {
    final now = DateTime.now().toIso8601String();
    final code = generateInviteCode();
    return Clan(
      id: 'clan_${DateTime.now().millisecondsSinceEpoch}',
      name: clanName.trim().isEmpty ? 'Клан $code' : clanName.trim(),
      inviteCode: code,
      createdAtIso: now,
      members: [
        ClanMember(
          userId: ownerId,
          displayName: ownerName,
          streetPortfolioRub: ownerStreetRub,
          joinedAtIso: now,
          isOwner: true,
        ),
      ],
    );
  }

  /// Join by invite code against a registry of known clans (local store).
  Clan? join({
    required List<Clan> knownClans,
    required String inviteCode,
    required String userId,
    required String displayName,
    required double streetRub,
  }) {
    final code = inviteCode.trim().toUpperCase();
    if (code.isEmpty) return null;
    Clan? target;
    for (final c in knownClans) {
      if (c.inviteCode == code) {
        target = c;
        break;
      }
    }
    if (target == null) return null;
    if (target.contains(userId)) return target;

    final now = DateTime.now().toIso8601String();
    final members = [
      ...target.members,
      ClanMember(
        userId: userId,
        displayName: displayName,
        streetPortfolioRub: streetRub,
        joinedAtIso: now,
      ),
    ];
    return target.copyWith(members: members);
  }

  Clan refreshMemberPortfolio(Clan clan, String userId, double streetRub) {
    final next = [
      for (final m in clan.members)
        if (m.userId == userId)
          m.copyWith(streetPortfolioRub: streetRub)
        else
          m,
    ];
    return clan.copyWith(members: next);
  }

  /// Normalize invite input: strip spaces, uppercase.
  static String normalizeCode(String raw) =>
      raw.replaceAll(RegExp(r'\s+'), '').toUpperCase();
}
