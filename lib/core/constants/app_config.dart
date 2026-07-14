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
}
