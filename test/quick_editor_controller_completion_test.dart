import 'dart:async';

import 'package:apexload/features/quick_editor/quick_editor_controller.dart';
import 'package:apexload/features/quick_editor/quick_editor_models.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/services/active_operation_wakelock_service.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/services/local_editor_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('completion survives message cleanup and can be dismissed', () async {
    final completed = _item(id: 'edited', fileName: 'clip_trimmed.mp4');
    final editor = _FakeLocalEditorService([Future.value(completed)]);
    final wakelock = ActiveOperationWakelockService(
      adapter: const _NoopWakelockAdapter(),
      initiallyEnabled: false,
    );
    final container = ProviderContainer(
      overrides: [
        localEditorServiceProvider.overrideWithValue(editor),
        activeOperationWakelockServiceProvider.overrideWithValue(wakelock),
      ],
    );
    final subscription = container.listen(
      quickEditorControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(() async {
      subscription.close();
      container.dispose();
      await wakelock.dispose();
    });

    final controller = container.read(quickEditorControllerProvider.notifier);
    await controller.runJob(
      job: const QuickEditorJob(
        type: QuickEditorJobType.trim,
        operation: 'trim',
        successMessageKey: 'trimSuccess',
      ),
      sourceItem: _item(id: 'source', fileName: 'clip.mp4'),
      options: const {},
    );

    expect(
      container.read(quickEditorControllerProvider).completedItem,
      completed,
    );

    controller.clearMessage();
    final cleaned = container.read(quickEditorControllerProvider);
    expect(cleaned.successMessageKey, isNull);
    expect(cleaned.completedItem, completed);

    controller.dismissResult();
    expect(container.read(quickEditorControllerProvider).completedItem, isNull);
  });

  test('starting another job replaces the previous result', () async {
    final first = _item(id: 'first', fileName: 'first.mp4');
    final second = _item(id: 'second', fileName: 'second.mp4');
    final secondResult = Completer<DownloadItemModel>();
    final editor = _FakeLocalEditorService([
      Future.value(first),
      secondResult.future,
    ]);
    final wakelock = ActiveOperationWakelockService(
      adapter: const _NoopWakelockAdapter(),
      initiallyEnabled: false,
    );
    final container = ProviderContainer(
      overrides: [
        localEditorServiceProvider.overrideWithValue(editor),
        activeOperationWakelockServiceProvider.overrideWithValue(wakelock),
      ],
    );
    final subscription = container.listen(
      quickEditorControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(() async {
      subscription.close();
      container.dispose();
      await wakelock.dispose();
    });

    final controller = container.read(quickEditorControllerProvider.notifier);
    const job = QuickEditorJob(
      type: QuickEditorJobType.export,
      operation: 'convert',
      successMessageKey: 'exportSuccess',
    );
    await controller.runJob(
      job: job,
      sourceItem: _item(id: 'source', fileName: 'clip.mp4'),
      options: const {},
    );
    expect(container.read(quickEditorControllerProvider).completedItem, first);

    final pendingRun = controller.runJob(
      job: job,
      sourceItem: _item(id: 'source', fileName: 'clip.mp4'),
      options: const {},
    );
    expect(container.read(quickEditorControllerProvider).completedItem, isNull);

    secondResult.complete(second);
    await pendingRun;
    expect(container.read(quickEditorControllerProvider).completedItem, second);
  });
}

class _FakeLocalEditorService extends LocalEditorService {
  _FakeLocalEditorService(this.results);

  final List<Future<DownloadItemModel>> results;

  @override
  Future<DownloadItemModel> runJob({
    required DownloadItemModel source,
    required QuickEditorJob job,
    required Map<String, Object?> options,
    void Function(double progress)? onProgress,
  }) {
    onProgress?.call(0.6);
    return results.removeAt(0);
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
    sizeLabel: '12 MB',
    type: DownloadType.video,
    thumbnailUrl: '',
    fileName: fileName,
    localFilePath: '/tmp/$fileName',
    quality: 'Edited',
    isEdited: true,
  );
}
