import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/features/settings/settings_screen.dart';
import 'package:apexload/shared/services/admob_service.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Android required shows localized row in the legal section', (
    tester,
  ) async {
    final fixture = await _pumpSettings(
      tester,
      requirements: [AdMobPrivacyOptionsRequirement.required],
    );
    addTearDown(fixture.dispose);

    expect(find.byKey(privacyChoicesSettingsTileKey), findsOneWidget);
    expect(find.text('Privacy choices'), findsOneWidget);
    expect(find.text('Manage advertising and privacy consent'), findsOneWidget);

    final privacyPolicyY = tester.getTopLeft(find.text('Privacy Policy')).dy;
    final privacyChoicesY = tester.getTopLeft(find.text('Privacy choices')).dy;
    final termsY = tester.getTopLeft(find.text('Terms of Use')).dy;
    expect(privacyChoicesY, greaterThan(privacyPolicyY));
    expect(privacyChoicesY, lessThan(termsY));
    expect(find.text('Acceptable Use Policy'), findsOneWidget);
    expect(find.text('Copyright Policy'), findsOneWidget);
    expect(find.text('Submit Takedown Request'), findsOneWidget);
  });

  for (final requirement in [
    AdMobPrivacyOptionsRequirement.notRequired,
    AdMobPrivacyOptionsRequirement.unknown,
  ]) {
    testWidgets('Android $requirement hides Privacy choices', (tester) async {
      final fixture = await _pumpSettings(tester, requirements: [requirement]);
      addTearDown(fixture.dispose);

      expect(find.byKey(privacyChoicesSettingsTileKey), findsNothing);
      expect(find.text('Privacy choices'), findsNothing);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Use'), findsOneWidget);
    });
  }

  testWidgets('non-Android hides Privacy choices without calling UMP', (
    tester,
  ) async {
    final fixture = await _pumpSettings(
      tester,
      isAndroid: false,
      requirements: [AdMobPrivacyOptionsRequirement.required],
    );
    addTearDown(fixture.dispose);

    expect(find.byKey(privacyChoicesSettingsTileKey), findsNothing);
    expect(fixture.gateway.consentCalls, 0);
    expect(fixture.gateway.requirementCalls, 0);
    expect(await fixture.service.showPrivacyOptions(), isFalse);
    expect(fixture.gateway.showPrivacyOptionsCalls, 0);
  });

  testWidgets('tapping Privacy choices opens and refreshes Google UMP', (
    tester,
  ) async {
    final fixture = await _pumpSettings(
      tester,
      initialConsentAllowed: false,
      canRequestAdsResults: [true],
      requirements: [
        AdMobPrivacyOptionsRequirement.required,
        AdMobPrivacyOptionsRequirement.required,
      ],
    );
    addTearDown(fixture.dispose);

    await tester.tap(find.byKey(privacyChoicesSettingsTileKey));
    await tester.pumpAndSettle();

    expect(fixture.gateway.showPrivacyOptionsCalls, 1);
    expect(fixture.gateway.canRequestAdsCalls, 1);
    expect(fixture.gateway.requirementCalls, 2);
  });

  testWidgets('privacy form error stays on Settings and shows a safe message', (
    tester,
  ) async {
    final fixture = await _pumpSettings(
      tester,
      initialConsentAllowed: false,
      formThrows: true,
      canRequestAdsResults: [false],
      requirements: [
        AdMobPrivacyOptionsRequirement.required,
        AdMobPrivacyOptionsRequirement.required,
      ],
    );
    addTearDown(fixture.dispose);

    await tester.tap(find.byKey(privacyChoicesSettingsTileKey));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(
      find.text(
        'Privacy options are temporarily unavailable. Please try again later.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Arabic Settings keeps RTL privacy choices localization', (
    tester,
  ) async {
    final fixture = await _pumpSettings(
      tester,
      locale: const Locale('ar'),
      requirements: [AdMobPrivacyOptionsRequirement.required],
    );
    addTearDown(fixture.dispose);

    final row = find.byKey(privacyChoicesSettingsTileKey);
    expect(row, findsOneWidget);
    expect(find.text('خيارات الخصوصية'), findsOneWidget);
    expect(find.text('إدارة موافقات الإعلانات والخصوصية'), findsOneWidget);
    expect(Directionality.of(tester.element(row)), TextDirection.rtl);
  });
}

Future<_SettingsFixture> _pumpSettings(
  WidgetTester tester, {
  bool isAndroid = true,
  bool initialConsentAllowed = true,
  bool formThrows = false,
  List<bool> canRequestAdsResults = const [],
  required List<AdMobPrivacyOptionsRequirement> requirements,
  Locale locale = const Locale('en'),
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(900, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final gateway = _SettingsGateway(
    initialConsentAllowed: initialConsentAllowed,
    formThrows: formThrows,
    canRequestAdsResults: canRequestAdsResults,
    requirements: requirements,
  );
  final service = AdMobService(
    isPremium: () => false,
    gateway: gateway,
    counterStore: _SettingsCounter(),
    isAndroid: isAndroid,
  );
  await service.initialize();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [adMobServiceProvider.overrideWithValue(service)],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(body: SettingsScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return _SettingsFixture(service: service, gateway: gateway);
}

class _SettingsFixture {
  const _SettingsFixture({required this.service, required this.gateway});

  final AdMobService service;
  final _SettingsGateway gateway;

  Future<void> dispose() => service.dispose();
}

class _SettingsGateway implements AdMobGateway {
  _SettingsGateway({
    required this.initialConsentAllowed,
    required this.formThrows,
    required List<bool> canRequestAdsResults,
    required List<AdMobPrivacyOptionsRequirement> requirements,
  }) : _canRequestAdsResults = List<bool>.of(canRequestAdsResults),
       _requirements = List<AdMobPrivacyOptionsRequirement>.of(requirements);

  final bool initialConsentAllowed;
  final bool formThrows;
  final List<bool> _canRequestAdsResults;
  final List<AdMobPrivacyOptionsRequirement> _requirements;
  var consentCalls = 0;
  var canRequestAdsCalls = 0;
  var requirementCalls = 0;
  var showPrivacyOptionsCalls = 0;

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
  Future<void> initialize() async {}

  @override
  Future<AdMobInterstitial?> loadInterstitial(String adUnitId) async => null;
}

class _SettingsCounter implements AdSuccessCounterStore {
  @override
  Future<int> increment() async => 1;

  @override
  Future<int> read() async => 0;
}
