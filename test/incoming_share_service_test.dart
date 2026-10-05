import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/features/home/home_screen.dart';
import 'package:apexload/shared/services/api_analyze_service.dart';
import 'package:apexload/shared/services/active_operation_wakelock_service.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/services/incoming_share_service.dart';
import 'package:apexload/shared/services/legal_consent_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Analyze extends ApiAnalyzeService {
  final urls = <String>[];
  @override
  Future<AnalyzeResult> analyze(String url) async {
    urls.add(url);
    throw const AnalyzeException('Test response');
  }
}

class _Wakelock implements WakelockAdapter {
  @override
  Future<void> enable() async {}
  @override
  Future<void> disable() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('extracts social URLs from captions and preserves query parameters', () {
    expect(
      extractSharedVideoUrl(
        'Watch this! (https://www.instagram.com/reel/abc/?igsh=x).',
      ),
      'https://www.instagram.com/reel/abc/?igsh=x',
    );
    expect(
      extractSharedVideoUrl('شاهد https://vm.tiktok.com/abc/'),
      'https://vm.tiktok.com/abc/',
    );
    expect(
      extractSharedVideoUrl('https://example.org https://x.com/user/status/12'),
      'https://x.com/user/status/12',
    );
    expect(
      extractSharedVideoUrl('https://fb.watch/abc/?a=1&amp;b=2'),
      'https://fb.watch/abc/?a=1&b=2',
    );
    expect(
      extractSharedVideoUrl('content://video/12 file:///private/video.mp4'),
      isNull,
    );
    expect(extractSharedVideoUrl('no video link'), isNull);
  });

  test(
    'receives cold and warm shares and acknowledges each only once',
    () async {
      const channel = MethodChannel('apexload/share-test');
      String? nativeText = 'https://www.instagram.com/reel/cold/';
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (_) async {
        final value = nativeText;
        nativeText = null;
        return value;
      });
      final service = IncomingShareService(channel: channel);
      addTearDown(() {
        service.dispose();
        messenger.setMockMethodCallHandler(channel, null);
      });
      await service.start();
      expect(service.pendingText.value, 'https://www.instagram.com/reel/cold/');
      service.clear();
      nativeText = 'https://vm.tiktok.com/warm/';
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(
        service.pendingText.value,
        nativeText ?? 'https://vm.tiktok.com/warm/',
      );
      service.clear();
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(service.pendingText.value, isNull);
    },
  );

  testWidgets(
    'a shared caption fills the URL and analyzes automatically; blocked links stay local',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        LegalConsentService.responsibleUseAgreementKey: true,
      });
      final shares = IncomingShareService();
      final analyze = _Analyze();
      final wakelock = ActiveOperationWakelockService(adapter: _Wakelock());
      addTearDown(wakelock.dispose);
      shares.pendingText.value =
          'Watch this video https://www.instagram.com/reel/auto/';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            incomingShareServiceProvider.overrideWithValue(shares),
            analyzeServiceProvider.overrideWithValue(analyze),
            activeOperationWakelockServiceProvider.overrideWithValue(wakelock),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: HomeScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(analyze.urls, ['https://www.instagram.com/reel/auto/']);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        analyze.urls.single,
      );
      expect(shares.pendingText.value, isNull);
      shares.pendingText.value = 'https://youtu.be/blocked';
      await tester.pump();
      await tester.pump();
      expect(analyze.urls, hasLength(1));
      shares.pendingText.value = 'https://vm.tiktok.com/next/';
      await tester.pump();
      await tester.pump();
      expect(analyze.urls.last, 'https://vm.tiktok.com/next/');
      await tester.pumpWidget(const SizedBox());
      shares.dispose();
    },
  );
}
