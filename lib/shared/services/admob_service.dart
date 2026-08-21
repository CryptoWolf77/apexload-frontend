import 'dart:async';

import 'package:apexload/shared/services/admob_config.dart';
import 'package:apexload/shared/services/admob_runtime_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DownloadAdOutcome { successful, failed, cancelled }

enum InterstitialShowResult { dismissed, failed }

abstract interface class AdMobInterstitial {
  Future<InterstitialShowResult> show();

  Future<void> dispose();
}

abstract interface class AdMobGateway {
  Future<bool> gatherConsent();

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

  Future<void>? _initialization;
  AdMobInterstitial? _interstitial;
  var _adsReady = false;
  var _loading = false;
  var _showing = false;
  var _disposed = false;

  bool get hasLoadedInterstitial => _interstitial != null;

  Future<void> initialize() {
    if (!_isAndroid || _disposed) return Future<void>.value();
    return _initialization ??= _initializeSafely();
  }

  Future<void> _initializeSafely() async {
    try {
      final canRequestAds = await _gateway.gatherConsent();
      if (!canRequestAds || _disposed) return;
      await _gateway.initialize();
      if (_disposed) return;
      _adsReady = true;
      if (!_isPremium()) await _preload();
    } on Object {
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
      if (_disposed || _isPremium() || _interstitial != null) {
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

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final ad = _interstitial;
    _interstitial = null;
    if (ad != null) await _disposeAd(ad);
  }

  void _debugLog(String message) {
    if (kDebugMode) debugPrint('ApexLoad ads: $message');
  }
}
