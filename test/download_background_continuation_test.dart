import 'dart:async';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/core/network/api_client.dart';
import 'package:apexload/core/routing/app_router.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/models/media_info_model.dart';
import 'package:apexload/shared/models/user_subscription_model.dart';
import 'package:apexload/shared/services/api_download_service.dart';
import 'package:apexload/shared/services/background_download_service.dart';
import 'package:apexload/shared/services/active_operation_wakelock_service.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/services/local_media_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _format = DownloadFormatModel(
  id: '720p',
  label: 'MP4 720p',
  extension: 'mp4',
  type: DownloadType.video,
  isPremium: false,
  sizeLabel: '1 MB',
);
const _args = DownloadProgressArgs(
  media: MediaInfoModel(
    id: 'media',
    title: 'Video',
    mediaType: MediaType.video,
    platform: 'Instagram',
    duration: '',
    thumbnailUrl: '',
    sourceUrl: 'https://www.instagram.com/reel/test/',
    formats: [_format],
  ),
  formats: [_format],
  fileName: 'video.mp4',
  saveToGallery: false,
  apiJobId: 'job',
);

class _Api extends ApiDownloadService {
  int polls = 0;
  bool failPermanently = false;
  @override
  Future<ApiDownloadStatus> getStatus(String jobId) async {
    polls++;
    if (polls == 1 && !failPermanently) {
      throw const ApiClientException('API request timed out', retryable: true);
    }
    return ApiDownloadStatus(
      jobId: jobId,
      status: failPermanently ? 'failed' : 'completed',
      progress: 100,
      message: 'done',
      success: !failPermanently,
      files: const [
        ApiDownloadFile(
          fileId: 'file',
          fileName: 'video.mp4',
          type: 'video',
          size: '1 MB',
          downloadUrl: '/api/file/file',
        ),
      ],
    );
  }
}

class _Media extends LocalMediaService {
  final save = Completer<LocalMediaSaveResult>();
  int saves = 0;
  @override
  Future<LocalMediaSaveResult> saveRemoteFile({
    required String url,
    required String fileName,
    required DownloadType type,
    int? expectedSizeBytes,
    void Function(double)? onProgress,
    VoidCallback? onIndeterminateProgress,
    bool publishToGallery = true,
  }) {
    saves++;
    return save.future;
  }

  @override
  Future<String?> generateThumbnail({
    required String localFilePath,
    required String fileName,
    required DownloadType type,
  }) async => null;
}

class _Library extends LibraryController {
  @override
  List<DownloadItemModel> build() => [];
  @override
  Future<void> addAndSave(DownloadItemModel item) async {
    state = [item, ...state];
  }
}

class _Subscription extends SubscriptionController {
  @override
  UserSubscriptionModel build() => UserSubscriptionModel.free();
  @override
  Future<bool> recordSuccessfulDownload({int count = 1}) async => false;
}

class _Background extends BackgroundDownloadService {
  @override
  Future<void> begin() async {}
  @override
  Future<void> end() async {}
}

class _Wakelock implements WakelockAdapter {
  @override
  Future<void> enable() async {}
  @override
  Future<void> disable() async {}
}

void main() {
  testWidgets(
    'resume retries the same job and a detached UI still saves exactly once',
    (tester) async {
      final api = _Api();
      final media = _Media();
      final wakelock = ActiveOperationWakelockService(adapter: _Wakelock());
      addTearDown(wakelock.dispose);
      final container = ProviderContainer(
        overrides: [
          backgroundDownloadServiceProvider.overrideWithValue(_Background()),
          activeOperationWakelockServiceProvider.overrideWithValue(wakelock),
          apiDownloadServiceProvider.overrideWithValue(api),
          localMediaServiceProvider.overrideWithValue(media),
          libraryControllerProvider.overrideWith(_Library.new),
          subscriptionControllerProvider.overrideWith(_Subscription.new),
        ],
      );
      addTearDown(container.dispose);
      final coordinator = container.read(downloadCoordinatorProvider);
      final task = coordinator.taskFor(
        _args,
        AppLocalizations(const Locale('en')),
      );
      void listener() {}
      task.addListener(listener);
      await tester.pump();
      expect(task.failed, isFalse);
      expect(task.statusMessage, contains('Reconnecting'));
      // Switch away, then return. The backend job must be reused.
      coordinator.didChangeAppLifecycleState(AppLifecycleState.paused);
      coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(media.saves, 1);
      task.removeListener(listener);
      // Represents navigation away while the native file transfer is still active.
      await tester.pumpWidget(const SizedBox());
      media.save.complete(
        const LocalMediaSaveResult(
          localFilePath: '/downloads/video.mp4',
          thumbnailPath: '',
          fileName: 'video.mp4',
          sizeLabel: '1 MB',
        ),
      );
      await tester.pump();
      expect(task.saved, isTrue);
      expect(task.failed, isFalse);
      expect(container.read(libraryControllerProvider), hasLength(1));
      expect(
        coordinator.taskFor(_args, AppLocalizations(const Locale('en'))),
        same(task),
      );
      coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 1));
      expect(media.saves, 1);
      expect(api.polls, 2);
    },
  );

  testWidgets('a terminal backend failure still fails without trying to save', (
    tester,
  ) async {
    final api = _Api()..failPermanently = true;
    final media = _Media();
    final wakelock = ActiveOperationWakelockService(adapter: _Wakelock());
    addTearDown(wakelock.dispose);
    final container = ProviderContainer(
      overrides: [
        backgroundDownloadServiceProvider.overrideWithValue(_Background()),
        activeOperationWakelockServiceProvider.overrideWithValue(wakelock),
        apiDownloadServiceProvider.overrideWithValue(api),
        localMediaServiceProvider.overrideWithValue(media),
      ],
    );
    addTearDown(container.dispose);
    final task = container
        .read(downloadCoordinatorProvider)
        .taskFor(_args, AppLocalizations(const Locale('en')));
    await tester.pump();
    expect(task.failed, isTrue);
    expect(media.saves, 0);
  });
}
