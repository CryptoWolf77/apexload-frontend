import 'package:apexload/shared/services/admob_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'consent refresh publishes the required privacy options status',
    () async {
      final gateway = _PrivacyGateway(
        requirements: [AdMobPrivacyOptionsRequirement.required],
      );
      final service = _service(gateway);
      addTearDown(service.dispose);

      await service.initialize();

      expect(gateway.consentCalls, 1);
      expect(gateway.requirementCalls, 1);
      expect(
        service.privacyOptionsRequirement.value,
        AdMobPrivacyOptionsRequirement.required,
      );
    },
  );

  test(
    'privacy form rechecks ad permission and refreshes requirement status',
    () async {
      final gateway = _PrivacyGateway(
        initialConsentAllowed: false,
        canRequestAdsResults: [true],
        requirements: [
          AdMobPrivacyOptionsRequirement.required,
          AdMobPrivacyOptionsRequirement.notRequired,
        ],
      );
      final service = _service(gateway);
      addTearDown(service.dispose);
      await service.initialize();

      final shown = await service.showPrivacyOptions();

      expect(shown, isTrue);
      expect(gateway.showPrivacyOptionsCalls, 1);
      expect(gateway.canRequestAdsCalls, 1);
      expect(gateway.requirementCalls, 2);
      expect(
        service.privacyOptionsRequirement.value,
        AdMobPrivacyOptionsRequirement.notRequired,
      );
    },
  );

  test(
    'privacy form error is safe and still reconciles consent state',
    () async {
      final gateway = _PrivacyGateway(
        initialConsentAllowed: false,
        formThrows: true,
        canRequestAdsResults: [false],
        requirements: [
          AdMobPrivacyOptionsRequirement.required,
          AdMobPrivacyOptionsRequirement.unknown,
        ],
      );
      final service = _service(gateway);
      addTearDown(service.dispose);
      await service.initialize();

      await expectLater(service.showPrivacyOptions(), completion(isFalse));

      expect(gateway.showPrivacyOptionsCalls, 1);
      expect(gateway.canRequestAdsCalls, 1);
      expect(gateway.requirementCalls, 2);
      expect(
        service.privacyOptionsRequirement.value,
        AdMobPrivacyOptionsRequirement.unknown,
      );
    },
  );

  test(
    'ads becoming unavailable disposes and prevents interstitials',
    () async {
      final loadedAd = _PrivacyInterstitial();
      final gateway = _PrivacyGateway(
        canRequestAdsResults: [false],
        requirements: [
          AdMobPrivacyOptionsRequirement.required,
          AdMobPrivacyOptionsRequirement.required,
        ],
        loads: [loadedAd],
      );
      final counter = _PrivacyCounter();
      final service = _service(gateway, counter: counter);
      addTearDown(service.dispose);
      await service.initialize();
      expect(service.hasLoadedInterstitial, isTrue);

      expect(await service.showPrivacyOptions(), isTrue);
      await service.handleDownloadOperation(DownloadAdOutcome.successful);
      await service.handleDownloadOperation(DownloadAdOutcome.successful);

      expect(loadedAd.disposed, isTrue);
      expect(loadedAd.showCalls, 0);
      expect(service.hasLoadedInterstitial, isFalse);
      expect(gateway.loadCalls, 1);
      expect(counter.value, 2);
    },
  );

  test('free users resume normal preload when ads become allowed', () async {
    final loadedAd = _PrivacyInterstitial();
    final gateway = _PrivacyGateway(
      initialConsentAllowed: false,
      canRequestAdsResults: [true],
      requirements: [
        AdMobPrivacyOptionsRequirement.required,
        AdMobPrivacyOptionsRequirement.required,
      ],
      loads: [loadedAd],
    );
    final service = _service(gateway);
    addTearDown(service.dispose);
    await service.initialize();
    expect(gateway.initializeCalls, 0);
    expect(gateway.loadCalls, 0);

    expect(await service.showPrivacyOptions(), isTrue);

    expect(gateway.initializeCalls, 1);
    expect(gateway.loadCalls, 1);
    expect(service.hasLoadedInterstitial, isTrue);
  });

  test(
    'Premium never preloads or displays ads after privacy changes',
    () async {
      final ad = _PrivacyInterstitial();
      final gateway = _PrivacyGateway(
        initialConsentAllowed: false,
        canRequestAdsResults: [true],
        requirements: [
          AdMobPrivacyOptionsRequirement.required,
          AdMobPrivacyOptionsRequirement.required,
        ],
        loads: [ad],
      );
      final counter = _PrivacyCounter();
      final service = _service(gateway, isPremium: true, counter: counter);
      addTearDown(service.dispose);
      await service.initialize();

      expect(await service.showPrivacyOptions(), isTrue);
      await service.handleDownloadOperation(DownloadAdOutcome.successful);
      await service.handleDownloadOperation(DownloadAdOutcome.successful);

      expect(gateway.initializeCalls, 1);
      expect(gateway.loadCalls, 0);
      expect(ad.showCalls, 0);
      expect(counter.value, 0);
    },
  );

  test('non-Android privacy options are hidden and a safe no-op', () async {
    final gateway = _PrivacyGateway(
      requirements: [AdMobPrivacyOptionsRequirement.required],
    );
    final service = _service(gateway, isAndroid: false);
    addTearDown(service.dispose);

    await service.initialize();
    expect(service.supportsPrivacyOptions, isFalse);
    expect(await service.showPrivacyOptions(), isFalse);
    expect(gateway.consentCalls, 0);
    expect(gateway.requirementCalls, 0);
    expect(gateway.showPrivacyOptionsCalls, 0);
  });
}

AdMobService _service(
  _PrivacyGateway gateway, {
  bool isPremium = false,
  bool isAndroid = true,
  _PrivacyCounter? counter,
}) => AdMobService(
  isPremium: () => isPremium,
  gateway: gateway,
  counterStore: counter ?? _PrivacyCounter(),
  isAndroid: isAndroid,
);

class _PrivacyGateway implements AdMobGateway {
  _PrivacyGateway({
    this.initialConsentAllowed = true,
    this.formThrows = false,
    List<bool> canRequestAdsResults = const [],
    List<AdMobPrivacyOptionsRequirement> requirements = const [
      AdMobPrivacyOptionsRequirement.notRequired,
    ],
    List<AdMobInterstitial?> loads = const [],
  }) : _canRequestAdsResults = List<bool>.of(canRequestAdsResults),
       _requirements = List<AdMobPrivacyOptionsRequirement>.of(requirements),
       _loads = List<AdMobInterstitial?>.of(loads);

  final bool initialConsentAllowed;
  final bool formThrows;
  final List<bool> _canRequestAdsResults;
  final List<AdMobPrivacyOptionsRequirement> _requirements;
  final List<AdMobInterstitial?> _loads;
  var consentCalls = 0;
  var canRequestAdsCalls = 0;
  var requirementCalls = 0;
  var showPrivacyOptionsCalls = 0;
  var initializeCalls = 0;
  var loadCalls = 0;

  @override
  Future<bool> gatherConsent() async {
    consentCalls += 1;
    return initialConsentAllowed;
  }

  @override
  Future<bool> canRequestAds() async {
    canRequestAdsCalls += 1;
    return _canRequestAdsResults.isEmpty
        ? initialConsentAllowed
        : _canRequestAdsResults.removeAt(0);
  }

  @override
  Future<AdMobPrivacyOptionsRequirement>
  getPrivacyOptionsRequirementStatus() async {
    requirementCalls += 1;
    if (_requirements.length > 1) return _requirements.removeAt(0);
    return _requirements.single;
  }

  @override
  Future<void> showPrivacyOptionsForm() async {
    showPrivacyOptionsCalls += 1;
    if (formThrows) throw StateError('simulated privacy form failure');
  }

  @override
  Future<void> initialize() async {
    initializeCalls += 1;
  }

  @override
  Future<AdMobInterstitial?> loadInterstitial(String adUnitId) async {
    loadCalls += 1;
    if (_loads.isEmpty) return null;
    return _loads.removeAt(0);
  }
}

class _PrivacyInterstitial implements AdMobInterstitial {
  var showCalls = 0;
  var disposed = false;

  @override
  Future<InterstitialShowResult> show() async {
    showCalls += 1;
    return InterstitialShowResult.dismissed;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class _PrivacyCounter implements AdSuccessCounterStore {
  var value = 0;

  @override
  Future<int> increment() async => ++value;

  @override
  Future<int> read() async => value;
}
