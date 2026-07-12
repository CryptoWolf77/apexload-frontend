class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = 'https://api.apexload.org';
  static const bool useMockFallback = false;

  static const String androidStoreUrl = String.fromEnvironment(
    'ANDROID_STORE_URL',
  );
  static const String iosStoreUrl = String.fromEnvironment('IOS_STORE_URL');
}
