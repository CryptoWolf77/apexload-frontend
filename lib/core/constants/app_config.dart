class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = 'https://api.apexload.org';
  static const bool useMockFallback = false;

  static const String termsUrl = 'https://apexload.org/terms';
  static const String privacyUrl = 'https://apexload.org/privacy';
  static const String acceptableUseUrl = 'https://apexload.org/acceptable-use';
  static const String copyrightUrl = 'https://apexload.org/copyright';
  static const String takedownUrl = 'https://apexload.org/takedown';

  static const String androidStoreUrl = String.fromEnvironment(
    'ANDROID_STORE_URL',
  );
  static const String iosStoreUrl = String.fromEnvironment('IOS_STORE_URL');

  /// Unlocks Premium only in binaries built explicitly for testers.
  ///
  /// App Store builds must omit this define so verified StoreKit
  /// entitlements remain the only way to unlock Premium.
  static const bool testerPremiumEnabled = bool.fromEnvironment(
    'APEXLOAD_TESTER_PREMIUM',
    defaultValue: false,
  );
}
