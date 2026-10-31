/// Anti-cheat / collector trust for portfolio flex + leaderboards.
///
/// - [street]: dual-angle live in-app camera capture.
/// - [unverified]: legacy manual/gallery entries (no longer creatable in UI).
enum TrustLevel {
  street,
  unverified;

  String get labelRu => switch (this) {
        TrustLevel.street => 'Street',
        TrustLevel.unverified => 'Неквалифицированный',
      };

  String get shortRu => switch (this) {
        TrustLevel.street => 'Street',
        TrustLevel.unverified => 'Unverified',
      };

  String get hintRu => switch (this) {
        TrustLevel.street =>
          'Два ракурса камерой в приложении — Street-рейтинг',
        TrustLevel.unverified =>
          'Старая запись (галерея/ручной ввод) — не в Street-лидерборде',
      };

  static TrustLevel fromName(String? value) {
    return TrustLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TrustLevel.unverified,
    );
  }
}

/// How the plate photo/text entered the vault.
enum CaptureSource {
  /// Dual-angle live camera via in-app picker (Street path).
  liveCamera,

  /// Legacy gallery — Unverified.
  gallery,

  /// Legacy manual — Unverified.
  manual,

  /// Legacy / unknown — Unverified.
  unknown;

  bool get qualifiesStreet => this == CaptureSource.liveCamera;

  TrustLevel get defaultTrust =>
      qualifiesStreet ? TrustLevel.street : TrustLevel.unverified;

  static CaptureSource fromName(String? value) {
    return CaptureSource.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CaptureSource.unknown,
    );
  }
}
