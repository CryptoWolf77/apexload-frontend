import 'dart:async';

import 'package:apexload/shared/services/admob_config.dart';
import 'package:apexload/shared/services/admob_runtime_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DownloadAdOutcome { successful, failed, cancelled }

enum InterstitialShowResult { dismissed, failed }

enum AdMobPrivacyOptionsRequirement { unknown, notRequired, required }

abstract interface class AdMobInterstitial {
  Future<InterstitialShowResult> show();

  Future<void> dispose();
}

abstract interface class AdMobGateway {
  Future<bool> gatherConsent();

  Future<bool> canRequestAds();

  Future<AdMobPrivacyOptionsRequirement> getPrivacyOptionsRequirementStatus();

  Future<void> showPrivacyOptionsForm();

  Future<void> initialize();

  Future<AdMobInterstitial?> loadInterstitial(String adUnitId);
}

abstract interface class AdSuccessCounterStore {
  Future<int> read();

  Future<int> increment();
}

class SharedPreferencesAdSuccessCounterStore implements AdSuccessCounterStore {
  static const preferenceKey = 'admob_free_successful_download_operations_v1';

  const SharedPreferencesAdSuccessCounterStore();

  @override
  Future<int> read() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(preferenceKey) ?? 0;
  }

  @override
  Future<int> increment() async {
    final preferences = await SharedPreferences.getInstance();
    final next = (preferences.getInt(preferenceKey) ?? 0) + 1;
    await preferences.setInt(preferenceKey, next);
    return next;
  }
}

class GoogleMobileAdsGateway implements AdMobGateway {
  const GoogleMobileAdsGateway();

  @override
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();

  @override
  Future<bool> gatherConsent() async {
    final updateCompleted = Completer<void>();

    void finishUpdate() {
      if (!updateCompleted.isCompleted) updateCompleted.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        } on Object {
          // A consent form failure must not block the app. canRequestAds below
          // still honors valid consent retained from an earlier session.
        } finally {
          finishUpdate();
        }
      },
      (_) => finishUpdate(),
    );

    await updateCompleted.future;
    return ConsentInformation.instance.canRequestAds();
  }

  @override
  Future<AdMobPrivacyOptionsRequirement>
  getPrivacyOptionsRequirementStatus() async {
    final status = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    return switch (status) {
      PrivacyOptionsRequirementStatus.required =>
        AdMobPrivacyOptionsRequirement.required,
      PrivacyOptionsRequirementStatus.notRequired =>
        AdMobPrivacyOptionsRequirement.notRequired,
      PrivacyOptionsRequirementStatus.unknown =>
        AdMobPrivacyOptionsRequirement.unknown,
    };
  }

  @override
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  @override
  Future<AdMobInterstitial?> loadInterstitial(String adUnitId) async {
    final loaded = Completer<AdMobInterstitial?>();
    try {
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (!loaded.isCompleted) {
              loaded.complete(_GoogleInterstitialAd(ad));
            }
          },
          onAdFailedToLoad: (_) {
            if (!loaded.isCompleted) loaded.complete(null);
          },
        ),
      );
    } on Object catch (error, stackTrace) {
      if (!loaded.isCompleted) loaded.completeError(error, stackTrace);
    }
    return loaded.future;
  }

  @override
  Future<void> showPrivacyOptionsForm() async {
    FormError? dismissalError;
    await ConsentForm.showPrivacyOptionsForm((error) {
      dismissalError = error;
    });
    if (dismissalError != null) {
      throw StateError('Privacy options form unavailable');
    }
  }
}

class _GoogleInterstitialAd implements AdMobInterstitial {
  _GoogleInterstitialAd(this._ad);

  final InterstitialAd _ad;
  var _disposed = false;
  var _showStarted = false;

  @override
  Future<InterstitialShowResult> show() async {
    if (_disposed || _showStarted) return InterstitialShowResult.failed;
    _showStarted = true;
    final completed = Completer<InterstitialShowResult>();

    void finish(InterstitialShowResult result) {
      if (!completed.isCompleted) completed.complete(result);
    }

    _ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (_) {
        finish(InterstitialShowResult.dismissed);
      },
      onAdFailedToShowFullScreenContent: (_, _) {
        finish(InterstitialShowResult.failed);
      },
    );
    try {
      await _ad.show();
    } on Object {
      finish(InterstitialShowResult.failed);
    }
    return completed.future;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _ad.dispose();
  }
}

class AdMobService {
  AdMobService({
    required bool Function() isPremium,
    AdMobGateway gateway = const GoogleMobileAdsGateway(),
    AdSuccessCounterStore counterStore =
        const SharedPreferencesAdSuccessCounterStore(),
    bool? isAndroid,
    bool liveAdsEnabled = AdMobConfig.liveAdsEnabled,
  }) : _isPremium = isPremium,
       _gateway = gateway,
       _counterStore = counterStore,
       _isAndroid = isAndroid ?? isAndroidAdMobRuntime,
       _adUnitId = AdMobConfig.resolveAndroidInterstitialAdUnitId(
         liveAdsEnabled: liveAdsEnabled,
       );

  final bool Function() _isPremium;
  final AdMobGateway _gateway;
  final AdSuccessCounterStore _counterStore;
  final bool _isAndroid;
  final String _adUnitId;
  final ValueNotifier<AdMobPrivacyOptionsRequirement>
  _privacyOptionsRequirement = ValueNotifier(
    AdMobPrivacyOptionsRequirement.unknown,
  );

  Future<void>? _initialization;
  AdMobInterstitial? _interstitial;
  var _adsReady = false;
  var _sdkInitialized = false;
  var _loading = false;
  var _showing = false;
  var _disposed = false;

  bool get hasLoadedInterstitial => _interstitial != null;

  bool get supportsPrivacyOptions => _isAndroid && !_disposed;

  ValueListenable<AdMobPrivacyOptionsRequirement>
  get privacyOptionsRequirement => _privacyOptionsRequirement;

  Future<void> initialize() {
    if (!_isAndroid || _disposed) return Future<void>.value();
    return _initialization ??= _initializeSafely();
  }

  Future<void> _initializeSafely() async {
    var canRequestAds = false;
    try {
      canRequestAds = await _gateway.gatherConsent();
    } on Object {
      _debugLog('initialization unavailable');
    }
    await _refreshPrivacyOptionsRequirement();
    if (!canRequestAds || _disposed) return;
    await _enableAdsAndPreload();
  }

  Future<bool> showPrivacyOptions() async {
    if (!supportsPrivacyOptions ||
        _privacyOptionsRequirement.value !=
            AdMobPrivacyOptionsRequirement.required) {
      return false;
    }

    var shown = false;
    try {
      await _gateway.showPrivacyOptionsForm();
      shown = true;
    } on Object {
      _debugLog('privacy options unavailable');
    }

    await _reconcileConsentAfterPrivacyOptions();
    return shown;
  }

  Future<void> _reconcileConsentAfterPrivacyOptions() async {
    var canRequestAds = false;
    try {
      canRequestAds = await _gateway.canRequestAds();
    } on Object {
      _debugLog('consent status unavailable');
    }
    await _refreshPrivacyOptionsRequirement();
    if (_disposed) return;

    if (!canRequestAds) {
      _adsReady = false;
      await _clearLoadedInterstitial();
      return;
    }
    await _enableAdsAndPreload();
  }

  Future<void> _refreshPrivacyOptionsRequirement() async {
    var requirement = AdMobPrivacyOptionsRequirement.unknown;
    try {
      requirement = await _gateway.getPrivacyOptionsRequirementStatus();
    } on Object {
      _debugLog('privacy options status unavailable');
    }
    if (!_disposed && _privacyOptionsRequirement.value != requirement) {
      _privacyOptionsRequirement.value = requirement;
    }
  }

  Future<void> _enableAdsAndPreload() async {
    try {
      if (!_sdkInitialized) {
        await _gateway.initialize();
        if (_disposed) return;
        _sdkInitialized = true;
      }
      _adsReady = true;
      if (_isPremium()) {
        await _clearLoadedInterstitial();
      } else {
        await _preload();
      }
    } on Object {
      _adsReady = false;
      _debugLog('initialization unavailable');
    }
  }

  Future<void> updatePremiumStatus(bool isPremium) async {
    if (!_isAndroid || _disposed) return;
    if (isPremium) {
      final ad = _interstitial;
      _interstitial = null;
      if (ad != null) await _disposeAd(ad);
      return;
    }
    await initialize();
    await _preload();
  }

  Future<void> handleDownloadOperation(DownloadAdOutcome outcome) async {
    if (outcome != DownloadAdOutcome.successful || !_isAndroid || _disposed) {
      return;
    }

    try {
      if (_isPremium()) {
        await updatePremiumStatus(true);
        return;
      }

      final successfulOperations = await _counterStore.increment();
      final isAdOpportunity = successfulOperations.isEven;
      if (!isAdOpportunity) {
        await _preload();
        return;
      }

      // Subscription state can change while persistence is completing.
      // Re-check immediately before detaching and showing the loaded ad.
      if (_isPremium()) {
        await updatePremiumStatus(true);
        return;
      }

      final ad = _interstitial;
      if (ad == null || _showing) {
        await _preload();
        return;
      }

      _interstitial = null;
      _showing = true;
      try {
        final result = await ad.show();
        if (result == InterstitialShowResult.failed) {
          _debugLog('interstitial show unavailable');
        }
      } on Object {
        _debugLog('interstitial show unavailable');
      } finally {
        await _disposeAd(ad);
        _showing = false;
        await _preload();
      }
    } on Object {
      _debugLog('post-download ad opportunity skipped');
    }
  }

  Future<void> _preload() async {
    if (!_isAndroid ||
        !_adsReady ||
        _disposed ||
        _isPremium() ||
        _loading ||
        _showing ||
        _interstitial != null) {
      return;
    }

    _loading = true;
    try {
      final ad = await _gateway.loadInterstitial(_adUnitId);
      if (ad == null) {
        _debugLog('interstitial load unavailable');
        return;
      }
      if (!_adsReady || _disposed || _isPremium() || _interstitial != null) {
        await _disposeAd(ad);
        return;
      }
      _interstitial = ad;
    } on Object {
      _debugLog('interstitial load unavailable');
    } finally {
      _loading = false;
    }
  }

  Future<void> _disposeAd(AdMobInterstitial ad) async {
    try {
      await ad.dispose();
    } on Object {
      _debugLog('interstitial cleanup skipped');
    }
  }

  Future<void> _clearLoadedInterstitial() async {
    final ad = _interstitial;
    _interstitial = null;
    if (ad != null) await _disposeAd(ad);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _clearLoadedInterstitial();
    _privacyOptionsRequirement.dispose();
  }

  void _debugLog(String message) {
    if (kDebugMode) debugPrint('ApexLoad ads: $message');
  }
}
