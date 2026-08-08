import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/features/whatsapp_status/whatsapp_status_models.dart';
import 'package:apexload/features/whatsapp_status/whatsapp_status_screen.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/services/local_media_service.dart';
import 'package:apexload/shared/services/whatsapp_status_service.dart';
import 'package:apexload/shared/widgets/premium_locked_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'individual Android save adds to library and Keep Browsing stays put',
    (tester) async {
      final service = _FakeWhatsAppStatusService([_status('one')]);
      final harness = await _pumpStatusScreen(tester, service: service);

      await _tapTooltip(tester, 'Save');

      expect(service.saveCalls, 1);
      expect(
        harness.container.read(libraryControllerProvider),
        contains(
          predicate<DownloadItemModel>((item) => item.id == 'saved_one'),
        ),
      );
      expect(
        find.byKey(const Key('android_status_saved_actions')),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((widget) => widget.data)
            .whereType<String>()
            .join(' | '),
      );
      expect(find.text('Status saved'), findsOneWidget);
      expect(find.text('Keep Browsing'), findsOneWidget);
      expect(find.text('Go to Downloads'), findsOneWidget);

      await tester.tap(find.text('Keep Browsing'));
      await _pumpAsyncWork(tester);

      expect(
        find.byKey(const Key('android_status_saved_actions')),
        findsNothing,
      );
      expect(find.byType(WhatsAppStatusScreen), findsOneWidget);
      expect(harness.router.routeInformationProvider.value.uri.path, '/status');
      expect(find.text('one.jpg'), findsOneWidget);
    },
  );

  testWidgets('Go to Downloads navigates only after library update', (
    tester,
  ) async {
    final service = _FakeWhatsAppStatusService([_status('one')]);
    final harness = await _pumpStatusScreen(tester, service: service);

    await _tapTooltip(tester, 'Save');

    expect(
      harness.container.read(libraryControllerProvider),
      contains(predicate<DownloadItemModel>((item) => item.id == 'saved_one')),
    );
    await tester.tap(find.text('Go to Downloads'));
    await _pumpAsyncWork(tester);

    expect(
      harness.router.routeInformationProvider.value.uri.path,
      '/downloads',
    );
    expect(find.text('Downloads destination'), findsOneWidget);
  });

  testWidgets('save failure does not show post-save actions', (tester) async {
    final service = _FakeWhatsAppStatusService([
      _status('one'),
    ], saveErrorKey: 'whatsappFolderAccessError');
    await _pumpStatusScreen(tester, service: service);

    await _tapTooltip(tester, 'Save');

    expect(service.saveCalls, 1);
    expect(find.byKey(const Key('android_status_saved_actions')), findsNothing);
    expect(
      find.text(
        'Could not access the selected WhatsApp folder. Please connect it again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('already-saved result does not show false success actions', (
    tester,
  ) async {
    final service = _FakeWhatsAppStatusService([
      _status('one'),
    ], saveErrorKey: 'statusAlreadySaved');
    await _pumpStatusScreen(tester, service: service);

    await _tapTooltip(tester, 'Save');

    expect(service.saveCalls, 1);
    expect(find.byKey(const Key('android_status_saved_actions')), findsNothing);
    expect(find.text('This status is already saved.'), findsOneWidget);
  });

  testWidgets('bulk Save Selected never opens repeated action sheets', (
    tester,
  ) async {
    final service = _FakeWhatsAppStatusService([
      _status('one'),
      _status('two'),
    ]);
    final harness = await _pumpStatusScreen(tester, service: service);

    final selectors = find.byIcon(Icons.add_rounded);
    expect(selectors, findsNWidgets(2));
    await tester.tap(selectors.at(0));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pump();
    await tester.tap(find.text('Save selected (2)'));
    await _pumpAsyncWork(tester);

    expect(service.saveCalls, 2);
    expect(harness.container.read(libraryControllerProvider), hasLength(2));
    expect(find.byKey(const Key('android_status_saved_actions')), findsNothing);
  });

  testWidgets('existing View and Share card actions still delegate', (
    tester,
  ) async {
    final service = _FakeWhatsAppStatusService([_status('one')]);
    final media = _FakeLocalMediaService();
    await _pumpStatusScreen(tester, service: service, media: media);

    await _tapTooltip(tester, 'Preview');
    await _tapTooltip(tester, 'Share');

    expect(media.openCalls, 1);
    expect(media.shareCalls, 1);
    expect(service.saveCalls, 0);
  });

  testWidgets('Android Premium gating remains in place', (tester) async {
    final service = _FakeWhatsAppStatusService([_status('one')]);
    await _pumpStatusScreen(tester, service: service, premium: false);

    expect(find.byType(PremiumLockedCard), findsOneWidget);
    await _tapTooltip(tester, 'Save');

    expect(service.saveCalls, 0);
    expect(find.byKey(const Key('android_status_saved_actions')), findsNothing);
  });

  test('post-save actions have English and Arabic localization', () {
    final english = AppLocalizations(const Locale('en'));
    final arabic = AppLocalizations(const Locale('ar'));

    expect(english.t('statusSavedActionsTitle'), 'Status saved');
    expect(english.t('statusKeepBrowsing'), 'Keep Browsing');
    expect(english.t('statusGoToDownloads'), 'Go to Downloads');
    expect(arabic.t('statusSavedActionsTitle'), 'تم حفظ الحالة');
    expect(arabic.t('statusKeepBrowsing'), 'متابعة التصفح');
    expect(arabic.t('statusGoToDownloads'), 'الانتقال إلى التنزيلات');
  });
}

Future<void> _tapTooltip(WidgetTester tester, String tooltip) async {
  final finder = find.byTooltip(tooltip);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _pumpAsyncWork(tester);
}

Future<void> _pumpAsyncWork(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<_StatusHarness> _pumpStatusScreen(
  WidgetTester tester, {
  required _FakeWhatsAppStatusService service,
  _FakeLocalMediaService? media,
  bool premium = true,
}) async {
  SharedPreferences.setMockInitialValues({
    'subscription_is_premium': premium,
    'subscription_plan_name': premium ? 'Google Play Reviewer' : 'Free',
    'subscription_premium_mock': premium,
  });
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [
      whatsappStatusServiceProvider.overrideWithValue(service),
      localMediaServiceProvider.overrideWithValue(
        media ?? _FakeLocalMediaService(),
      ),
    ],
  );
  final router = GoRouter(
    initialLocation: '/status',
    routes: [
      GoRoute(
        path: '/status',
        builder: (context, state) => const WhatsAppStatusScreen(),
      ),
      GoRoute(
        path: '/downloads',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Downloads destination'))),
      ),
    ],
  );
  addTearDown(router.dispose);
  addTearDown(container.dispose);

  container.read(libraryControllerProvider);
  await tester.runAsync(() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  });

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _StatusHarness(container: container, router: router);
}

class _StatusHarness {
  const _StatusHarness({required this.container, required this.router});

  final ProviderContainer container;
  final GoRouter router;
}

WhatsAppStatusItem _status(String id) {
  return WhatsAppStatusItem(
    id: id,
    title: 'Status $id',
    sourcePath: '/source/$id.jpg',
    fileName: '$id.jpg',
    type: DownloadType.image,
    sizeLabel: '1 MB',
    modifiedAt: DateTime(2026, 8, 9),
    duplicateKey: 'duplicate-$id',
  );
}

class _FakeWhatsAppStatusService extends WhatsAppStatusService {
  _FakeWhatsAppStatusService(this.items, {this.saveErrorKey});

  final List<WhatsAppStatusItem> items;
  final String? saveErrorKey;
  final Set<String> _savedIds = {};
  int saveCalls = 0;

  @override
  Future<List<WhatsAppStatusSource>> detectSources() async => const [
    WhatsAppStatusSource(
      id: 'standard',
      label: 'WhatsApp',
      business: false,
      state: WhatsAppStatusConnectionState.connectedAutomatic,
      folderPath: 'content://statuses',
      installed: true,
    ),
  ];

  @override
  Future<List<WhatsAppStatusItem>> scan({bool business = false}) async => [
    for (final item in items)
      item.copyWith(isSaved: item.isSaved || _savedIds.contains(item.id)),
  ];

  @override
  Future<DownloadItemModel> saveStatus(WhatsAppStatusItem item) async {
    saveCalls++;
    if (saveErrorKey case final errorKey?) {
      throw WhatsAppStatusException(errorKey);
    }
    _savedIds.add(item.id);
    return DownloadItemModel(
      id: 'saved_${item.id}',
      title: item.title,
      platform: 'WhatsApp Status',
      date: DateTime(2026, 8, 9),
      sizeLabel: item.sizeLabel,
      type: item.type,
      thumbnailUrl: '',
      fileName: item.fileName,
      localFilePath: '/saved/${item.fileName}',
      quality: 'Status',
      isEdited: true,
    );
  }
}

class _FakeLocalMediaService extends LocalMediaService {
  int openCalls = 0;
  int shareCalls = 0;

  @override
  Future<void> openItem(DownloadItemModel item) async {
    openCalls++;
  }

  @override
  Future<void> shareItem(DownloadItemModel item) async {
    shareCalls++;
  }

  @override
  Future<List<DownloadItemModel>> discoverExistingDownloads({
    List<DownloadItemModel> existing = const [],
  }) async => existing;
}
