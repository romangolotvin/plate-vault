/// Anti-cheat / collector trust for portfolio flex + leaderboards.
///
/// - [street]: live in-app camera capture meeting Street standards.
/// - [unverified]: manual entry, gallery pick, or failed liveness.
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
          'Снято камерой в приложении — засчитывается в Street-рейтинг',
        TrustLevel.unverified =>
          'Ручной ввод / галерея — виден в коллекции, но не в Street-лидерборде',
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
  /// Live ImageSource.camera via in-app picker (Street path).
  liveCamera,

  /// ImageSource.gallery — Unverified for Street credit.
  gallery,

  /// Typed manually with no photo — Unverified.
  manual,

  /// Legacy / unknown — treat as Unverified.
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
