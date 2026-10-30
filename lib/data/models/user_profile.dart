class UserProfile {
  UserProfile({
    required this.uid,
    required this.displayName,
    this.email,
    this.bio = '',
    this.publicCollectionEnabled = false,
    this.itemCount = 0,
    this.isLocalOnly = false,
  });

  final String uid;
  final String displayName;
  final String? email;
  final String bio;
  final bool publicCollectionEnabled;
  final int itemCount;
  final bool isLocalOnly;

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? bio,
    bool? publicCollectionEnabled,
    int? itemCount,
    bool? isLocalOnly,
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
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String? ?? 'Collector',
      email: json['email'] as String?,
      bio: json['bio'] as String? ?? '',
      publicCollectionEnabled:
          json['publicCollectionEnabled'] as bool? ?? false,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      isLocalOnly: json['isLocalOnly'] as bool? ?? false,
    );
  }
}
