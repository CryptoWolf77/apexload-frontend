import 'dart:io';

import 'package:apexload/shared/models/user_subscription_model.dart';
import 'package:apexload/shared/services/admob_config.dart';
import 'package:apexload/shared/services/admob_service.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('free successful operation frequency', () {
    test('operation 1 does not show an ad', () async {
      final ad = _FakeInterstitial();
      final fixture = _Fixture(loads: [ad]);
      await fixture.service.initialize();

      await fixture.success();

      expect(fixture.counter.value, 1);
      expect(ad.showCalls, 0);
    });

    test('operation 2 shows one ready interstitial', () async {
      final ad = _FakeInterstitial();
      final fixture = _Fixture(loads: [ad]);
      await fixture.service.initialize();

      await fixture.success();
      await fixture.success();

      expect(fixture.counter.value, 2);
      expect(ad.showCalls, 1);
    });

    test('operation 3 does not show the next preloaded ad', () async {
      final first = _FakeInterstitial();
      final next = _FakeInterstitial();
      final fixture = _Fixture(loads: [first, next]);
      await fixture.service.initialize();

      await fixture.success();
      await fixture.success();
      await fixture.success();

      expect(fixture.counter.value, 3);
      expect(first.showCalls, 1);
      expect(next.showCalls, 0);
    });

    test('operation 4 shows the next preloaded ad', () async {
      final first = _FakeInterstitial();
      final next = _FakeInterstitial();
      final fixture = _Fixture(loads: [first, next]);
      await fixture.service.initialize();

      for (var i = 0; i < 4; i++) {
        await fixture.success();
      }

      expect(fixture.counter.value, 4);
      expect(first.showCalls, 1);
      expect(next.showCalls, 1);
    });
  });

  test('a multi-format job records one advertising operation', () async {
    final fixture = _Fixture();
    await fixture.service.initialize();

    // The service receives a completed job, never the job's MP4/MP3 item list.
    await fixture.success();

    expect(fixture.counter.value, 1);
  });

  test('failed and cancelled jobs never increment the counter', () async {
    final fixture = _Fixture();
    await fixture.service.initialize();

    await fixture.service.handleDownloadOperation(DownloadAdOutcome.failed);
    await fixture.service.handleDownloadOperation(DownloadAdOutcome.cancelled);

    expect(fixture.counter.value, 0);
    expect(fixture.gateway.loadCalls, 1);
  });

  test('premium operations never increment or show ads', () async {
    final ad = _FakeInterstitial();
    final fixture = _Fixture(isPremium: true, loads: [ad]);

    await fixture.service.initialize();
    await fixture.success();

    expect(fixture.counter.value, 0);
    expect(fixture.gateway.loadCalls, 0);
    expect(ad.showCalls, 0);
  });

  test('Google Play Reviewer Premium never shows ads', () async {
    final reviewer = UserSubscriptionModel.premium(
      planName: 'Google Play Reviewer',
      premiumActivatedMock: true,
    );
    final fixture = _Fixture(isPremiumReader: () => reviewer.isPremium);

    await fixture.service.initialize();
    await fixture.success();

    expect(fixture.counter.value, 0);
    expect(fixture.gateway.loadCalls, 0);
  });

  test('tester Premium never shows ads', () async {
    final tester = UserSubscriptionModel.premium(
      planName: 'TestFlight Tester',
      premiumActivatedMock: true,
    );
    final fixture = _Fixture(isPremiumReader: () => tester.isPremium);

    await fixture.service.initialize();
    await fixture.success();

    expect(fixture.counter.value, 0);
    expect(fixture.gateway.loadCalls, 0);
  });

  test('premium is checked again immediately before showing', () async {
    var premium = false;
    final ad = _FakeInterstitial();
    final counter = _MemoryCounter(onIncrement: () => premium = true);
    final fixture = _Fixture(
      counter: counter,
      isPremiumReader: () => premium,
      loads: [ad],
    );
    await fixture.service.initialize();

    await fixture.service.handleDownloadOperation(DownloadAdOutcome.successful);
    await fixture.service.handleDownloadOperation(DownloadAdOutcome.successful);

    expect(counter.value, 1);
    expect(ad.showCalls, 0);
    expect(ad.disposed, isTrue);
  });

  test('an unavailable ad never fails a successful operation', () async {
    final fixture = _Fixture(loads: [null, null, null]);
    await fixture.service.initialize();

    await expectLater(fixture.success(), completes);
    await expectLater(fixture.success(), completes);

    expect(fixture.counter.value, 2);
  });

  test('an ad load failure never fails a successful operation', () async {
    final fixture = _Fixture(throwOnLoad: true);
    await fixture.service.initialize();

    await expectLater(fixture.success(), completes);
    await expectLater(fixture.success(), completes);

    expect(fixture.counter.value, 2);
  });

  test('an ad show failure never fails a successful operation', () async {
    final ad = _FakeInterstitial(result: InterstitialShowResult.failed);
    final fixture = _Fixture(loads: [ad]);
    await fixture.service.initialize();

    await fixture.success();
    await expectLater(fixture.success(), completes);

    expect(fixture.counter.value, 2);
    expect(ad.showCalls, 1);
    expect(ad.disposed, isTrue);
  });

  test('dismissal disposes the shown ad and preloads the next one', () async {
    final shown = _FakeInterstitial();
    final next = _FakeInterstitial();
    final fixture = _Fixture(loads: [shown, next]);
    await fixture.service.initialize();

    await fixture.success();
    await fixture.success();

    expect(shown.disposed, isTrue);
    expect(fixture.gateway.loadCalls, 2);
    expect(fixture.service.hasLoadedInterstitial, isTrue);
    expect(next.showCalls, 0);
  });

  test('a missed opportunity is not queued for operation 3', () async {
    final later = _FakeInterstitial();
    final fixture = _Fixture(loads: [null, null, later]);
    await fixture.service.initialize();

    await fixture.success();
    await fixture.success();
    expect(later.showCalls, 0);

    await fixture.success();
    expect(later.showCalls, 0);

    await fixture.success();
    expect(later.showCalls, 1);
  });

  test('default configuration always selects Google test interstitial', () {
    expect(AdMobConfig.liveAdsEnabled, isFalse);
    expect(
      AdMobConfig.androidInterstitialAdUnitId,
      AdMobConfig.androidTestInterstitialAdUnitId,
    );
  });

  test('production ID requires the explicit live build-time value', () {
    expect(
      AdMobConfig.resolveAndroidInterstitialAdUnitId(liveAdsEnabled: false),
      AdMobConfig.androidTestInterstitialAdUnitId,
    );
    expect(
      AdMobConfig.resolveAndroidInterstitialAdUnitId(liveAdsEnabled: true),
      AdMobConfig.androidProductionInterstitialAdUnitId,
    );
  });

  test('non-Android service is a complete no-op', () async {
    final fixture = _Fixture(isAndroid: false, loads: [_FakeInterstitial()]);

    await fixture.service.initialize();
    await fixture.success();

    expect(fixture.gateway.consentCalls, 0);
    expect(fixture.gateway.initializeCalls, 0);
    expect(fixture.gateway.loadCalls, 0);
    expect(fixture.counter.value, 0);
  });

  test('consent denial prevents SDK initialization and ad requests', () async {
    final fixture = _Fixture(consentAllowed: false);

    await fixture.service.initialize();
    await fixture.success();

    expect(fixture.gateway.consentCalls, 1);
    expect(fixture.gateway.initializeCalls, 0);
    expect(fixture.gateway.loadCalls, 0);
    expect(fixture.counter.value, 1);
  });

  test('advertising success count persists independently', () async {
    SharedPreferences.setMockInitialValues({});
    const first = SharedPreferencesAdSuccessCounterStore();
    const restored = SharedPreferencesAdSuccessCounterStore();

    expect(await first.increment(), 1);
    expect(await restored.read(), 1);
    expect(await restored.increment(), 2);
  });

  test(
    'free quota accounting remains separate for multi-format jobs',
    () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final subscription = container.read(
        subscriptionControllerProvider.notifier,
      );
      await subscription.recordSuccessfulDownload(count: 2);

      final gateway = _FakeGateway(loads: [null]);
      final service = AdMobService(
        isPremium: () =>
            container.read(subscriptionControllerProvider).isPremium,
        gateway: gateway,
        isAndroid: true,
      );
      addTearDown(service.dispose);
      await service.initialize();
      await service.handleDownloadOperation(DownloadAdOutcome.successful);

      final preferences = await SharedPreferences.getInstance();
      expect(
        container.read(subscriptionControllerProvider).downloadsUsedToday,
        2,
      );
      expect(
        preferences.getInt(
          SharedPreferencesAdSuccessCounterStore.preferenceKey,
        ),
        1,
      );
    },
  );

  test('download hook runs after completed UI and success notification', () {
    final source = File(
      'lib/features/download_progress/download_progress_screen.dart',
    ).readAsStringSync();
    final completedState = source.indexOf("_status = 'completed';");
    final successNotification = source.indexOf('AppNotification.success');
    final postFrame = source.indexOf(
      'WidgetsBinding.instance.addPostFrameCallback',
    );
    final adHook = source.indexOf(
      '.handleDownloadOperation(DownloadAdOutcome.successful)',
    );

    expect(completedState, greaterThan(-1));
    expect(successNotification, greaterThan(completedState));
    expect(postFrame, greaterThan(successNotification));
    expect(adHook, greaterThan(postFrame));
    expect(source, contains('.recordSuccessfulDownload(count: items.length)'));
  });
}

class _Fixture {
  _Fixture({
    bool isPremium = false,
    bool Function()? isPremiumReader,
    bool isAndroid = true,
    bool consentAllowed = true,
    bool throwOnLoad = false,
    List<AdMobInterstitial?> loads = const [],
    _MemoryCounter? counter,
  }) : premium = isPremium,
       counter = counter ?? _MemoryCounter(),
       gateway = _FakeGateway(
         consentAllowed: consentAllowed,
         throwOnLoad: throwOnLoad,
         loads: loads,
       ) {
    service = AdMobService(
      isPremium: isPremiumReader ?? () => premium,
      gateway: gateway,
      counterStore: this.counter,
      isAndroid: isAndroid,
    );
  }

  bool premium;
  final _MemoryCounter counter;
  final _FakeGateway gateway;
  late final AdMobService service;

  Future<void> success() =>
      service.handleDownloadOperation(DownloadAdOutcome.successful);
}

class _MemoryCounter implements AdSuccessCounterStore {
  _MemoryCounter({this.onIncrement});

  final void Function()? onIncrement;
  var value = 0;

  @override
  Future<int> increment() async {
    value += 1;
    onIncrement?.call();
    return value;
  }

  @override
  Future<int> read() async => value;
}

class _FakeGateway implements AdMobGateway {
  _FakeGateway({
    this.consentAllowed = true,
    this.throwOnLoad = false,
    List<AdMobInterstitial?> loads = const [],
  }) : _loads = List<AdMobInterstitial?>.of(loads);

  final bool consentAllowed;
  final bool throwOnLoad;
  final List<AdMobInterstitial?> _loads;
  var consentCalls = 0;
  var initializeCalls = 0;
  var loadCalls = 0;

  @override
  Future<bool> gatherConsent() async {
    consentCalls += 1;
    return consentAllowed;
  }

  @override
  Future<void> initialize() async {
    initializeCalls += 1;
  }

  @override
  Future<AdMobInterstitial?> loadInterstitial(String adUnitId) async {
    loadCalls += 1;
    if (throwOnLoad) throw StateError('simulated load failure');
    if (_loads.isEmpty) return null;
    return _loads.removeAt(0);
  }
}

class _FakeInterstitial implements AdMobInterstitial {
  _FakeInterstitial({this.result = InterstitialShowResult.dismissed});

  final InterstitialShowResult result;
  var showCalls = 0;
  var disposed = false;

  @override
  Future<InterstitialShowResult> show() async {
    showCalls += 1;
    return result;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}
