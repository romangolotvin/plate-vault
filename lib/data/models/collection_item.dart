import 'rarity.dart';
import 'trust_level.dart';

/// Extensible collection entry. Today: license plates; later other types.
enum CollectionType {
  licensePlate;

  static CollectionType fromName(String? value) {
    return CollectionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CollectionType.licensePlate,
    );
  }
}

class CollectionItem {
  CollectionItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.countryCode,
    required this.rawText,
    required this.normalizedText,
    required this.rarity,
    required this.rarityReason,
    required this.createdAt,
    this.tags = const [],
    this.photoPath,
    this.photoUrl,
    this.isPublic = false,
    this.notes,
    this.trust = TrustLevel.unverified,
    this.captureSource = CaptureSource.unknown,
    this.isFavorite = false,
    this.isShowcase = false,
  });

  final String id;
  final String userId;
  final CollectionType type;
  final String countryCode;
  final String rawText;
  final String normalizedText;
  final Rarity rarity;
  final String rarityReason;
  final DateTime createdAt;
  final List<String> tags;
  final String? photoPath;
  final String? photoUrl;
  final bool isPublic;
  final String? notes;
  final TrustLevel trust;
  final CaptureSource captureSource;
  final bool isFavorite;
  final bool isShowcase;

  bool get isStreet => trust == TrustLevel.street;

  CollectionItem copyWith({
    String? id,
    String? userId,
    CollectionType? type,
    String? countryCode,
    String? rawText,
    String? normalizedText,
    Rarity? rarity,
    String? rarityReason,
    DateTime? createdAt,
    List<String>? tags,
    String? photoPath,
    String? photoUrl,
    bool? isPublic,
    String? notes,
    TrustLevel? trust,
    CaptureSource? captureSource,
    bool? isFavorite,
    bool? isShowcase,
  }) {
    return CollectionItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      countryCode: countryCode ?? this.countryCode,
      rawText: rawText ?? this.rawText,
      normalizedText: normalizedText ?? this.normalizedText,
      rarity: rarity ?? this.rarity,
      rarityReason: rarityReason ?? this.rarityReason,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      photoPath: photoPath ?? this.photoPath,
      photoUrl: photoUrl ?? this.photoUrl,
      isPublic: isPublic ?? this.isPublic,
      notes: notes ?? this.notes,
      trust: trust ?? this.trust,
      captureSource: captureSource ?? this.captureSource,
      isFavorite: isFavorite ?? this.isFavorite,
      isShowcase: isShowcase ?? this.isShowcase,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type.name,
        'countryCode': countryCode,
        'rawText': rawText,
        'normalizedText': normalizedText,
        'rarity': rarity.name,
        'rarityReason': rarityReason,
        'createdAt': createdAt.toIso8601String(),
        'tags': tags,
        'photoPath': photoPath,
        'photoUrl': photoUrl,
        'isPublic': isPublic,
        'notes': notes,
        'trust': trust.name,
        'captureSource': captureSource.name,
        'isFavorite': isFavorite,
        'isShowcase': isShowcase,
      };

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    // Legacy migration: camera photo without trust → street if tagged, else unverified.
    final trustRaw = json['trust'] as String?;
    final sourceRaw = json['captureSource'] as String?;
    final source = CaptureSource.fromName(sourceRaw);
    final trust = trustRaw != null
        ? TrustLevel.fromName(trustRaw)
        : (source.qualifiesStreet
            ? TrustLevel.street
            : TrustLevel.unverified);

    return CollectionItem(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      type: CollectionType.fromName(json['type'] as String?),
      countryCode: (json['countryCode'] as String? ?? 'XX').toUpperCase(),
      rawText: json['rawText'] as String? ?? '',
      normalizedText: json['normalizedText'] as String? ?? '',
      rarity: Rarity.fromName(json['rarity'] as String?),
      rarityReason: json['rarityReason'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      tags: (json['tags'] as List?)?.map((e) => '$e').toList() ?? const [],
      photoPath: json['photoPath'] as String?,
      photoUrl: json['photoUrl'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      notes: json['notes'] as String?,
      trust: trust,
      captureSource: source,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isShowcase: json['isShowcase'] as bool? ?? false,
    );
  }
}
