class AppConstants {
  static const appName = 'Plate Vault';
  static const applicationId = 'com.platevault.app';

  /// GitHub repo used by the interim update checker (owner/name).
  /// Change after you create the public releases repository.
  static const githubOwner = 'romangolotvin';
  static const githubRepo = 'plate-vault';

  /// Numeric App Store ID from App Store Connect (digits only).
  /// Leave the placeholder until the listing exists.
  static const appStoreId = 'YOUR_APP_ID';

  /// Store listing placeholders — fill before Play / App Store launch.
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=$applicationId';
  static const appStoreUrl = 'https://apps.apple.com/app/id$appStoreId';

  static const githubReleasesUrl =
      'https://github.com/$githubOwner/$githubRepo/releases';

  static bool get isAppStoreConfigured =>
      appStoreId.isNotEmpty &&
      !appStoreId.contains('YOUR_') &&
      int.tryParse(appStoreId) != null;
}
