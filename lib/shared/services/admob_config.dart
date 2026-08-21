class AdMobConfig {
  const AdMobConfig._();

  static const liveAdsEnabled = bool.fromEnvironment(
    'APEXLOAD_ADMOB_LIVE',
    defaultValue: false,
  );

  static const androidTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const androidProductionInterstitialAdUnitId =
      'ca-app-pub-8135847965072867/5643467625';

  static String get androidInterstitialAdUnitId =>
      resolveAndroidInterstitialAdUnitId(liveAdsEnabled: liveAdsEnabled);

  static String resolveAndroidInterstitialAdUnitId({
    required bool liveAdsEnabled,
  }) => liveAdsEnabled
      ? androidProductionInterstitialAdUnitId
      : androidTestInterstitialAdUnitId;
}
