class UserProfile {
  UserProfile({
    required this.uid,
    required this.displayName,
    this.email,
    this.bio = '',
    this.publicCollectionEnabled = false,
    this.itemCount = 0,
    this.isLocalOnly = false,
    DateTime? createdAt,
    this.countryCode = 'RU',
    this.avatarPath,
  }) : createdAt = createdAt ?? DateTime.now();

  final String uid;
  final String displayName;
  final String? email;
  final String bio;
  final bool publicCollectionEnabled;
  final int itemCount;
  final bool isLocalOnly;
  final DateTime createdAt;
  final String countryCode;
  final String? avatarPath;

  int get registeredYear => createdAt.year;

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? bio,
    bool? publicCollectionEnabled,
    int? itemCount,
    bool? isLocalOnly,
    DateTime? createdAt,
    String? countryCode,
    String? avatarPath,
    bool clearAvatar = false,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      publicCollectionEnabled:
          publicCollectionEnabled ?? this.publicCollectionEnabled,
      itemCount: itemCount ?? this.itemCount,
      isLocalOnly: isLocalOnly ?? this.isLocalOnly,
      createdAt: createdAt ?? this.createdAt,
      countryCode: countryCode ?? this.countryCode,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'bio': bio,
        'publicCollectionEnabled': publicCollectionEnabled,
        'itemCount': itemCount,
        'isLocalOnly': isLocalOnly,
        'createdAt': createdAt.toIso8601String(),
        'countryCode': countryCode,
        'avatarPath': avatarPath,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['createdAt'];
    DateTime created;
    if (createdRaw is String && createdRaw.isNotEmpty) {
      created = DateTime.tryParse(createdRaw) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }
    return UserProfile(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String? ?? 'Collector',
      email: json['email'] as String?,
      bio: json['bio'] as String? ?? '',
      publicCollectionEnabled:
          json['publicCollectionEnabled'] as bool? ?? false,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      isLocalOnly: json['isLocalOnly'] as bool? ?? false,
      createdAt: created,
      countryCode: (json['countryCode'] as String?)?.toUpperCase() ?? 'RU',
      avatarPath: json['avatarPath'] as String?,
    );
  }
}
