import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/core/theme/app_theme.dart';
import 'package:apexload/features/quick_editor/quick_editor_controller.dart';
import 'package:apexload/features/quick_editor/quick_editor_models.dart';
import 'package:apexload/features/video_optimizer/video_optimizer_screen.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/services/active_operation_wakelock_service.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/services/local_editor_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('optimizer reveals its completion panel after finishing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final source = _item(id: 'source', fileName: 'source.mp4');
    final completed = _item(id: 'completed', fileName: 'optimized.mp4');
    final wakelock = ActiveOperationWakelockService(
      adapter: const _NoopWakelockAdapter(),
      initiallyEnabled: false,
    );
    addTearDown(wakelock.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localEditorServiceProvider.overrideWithValue(
            _FakeLocalEditorService(completed),
          ),
          activeOperationWakelockServiceProvider.overrideWithValue(wakelock),
          libraryControllerProvider.overrideWith(_MemoryLibraryController.new),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: VideoOptimizerScreen(item: source),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final list = find.byType(ListView);
    await tester.drag(list, const Offset(0, -450));
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: list, matching: find.byType(Scrollable)).first,
    );
    expect(scrollable.position.pixels, greaterThan(0));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(VideoOptimizerScreen)),
    );
    await container
        .read(quickEditorControllerProvider.notifier)
        .runJob(
          job: const QuickEditorJob(
            type: QuickEditorJobType.compress,
            operation: 'optimize',
            successMessageKey: 'optimizerSuccess',
          ),
          sourceItem: source,
          options: const {'quality': 'balanced', 'format': 'mp4'},
        );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Your edited file is ready'), findsOneWidget);
    expect(scrollable.position.pixels, closeTo(0, 0.1));
    expect(tester.takeException(), isNull);
  });
}

class _FakeLocalEditorService extends LocalEditorService {
  _FakeLocalEditorService(this.result);

  final DownloadItemModel result;

  @override
  Future<DownloadItemModel> runJob({
    required DownloadItemModel source,
    required QuickEditorJob job,
    required Map<String, Object?> options,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.7);
    return result;
  }
}

class _MemoryLibraryController extends LibraryController {
  @override
  List<DownloadItemModel> build() => const [];

  @override
  void add(DownloadItemModel item) {
    state = [item, ...state.where((existing) => existing.id != item.id)];
  }
}

class _NoopWakelockAdapter implements WakelockAdapter {
  const _NoopWakelockAdapter();

  @override
  Future<void> disable() async {}

  @override
  Future<void> enable() async {}
}

DownloadItemModel _item({required String id, required String fileName}) {
  return DownloadItemModel(
    id: id,
    title: fileName,
    platform: 'Editor',
    date: DateTime(2026, 7, 23),
    sizeLabel: '14 MB',
    type: DownloadType.video,
    thumbnailUrl: '',
    fileName: fileName,
    localFilePath: '/tmp/$fileName',
    quality: '1080p',
    isEdited: id == 'completed',
  );
}
