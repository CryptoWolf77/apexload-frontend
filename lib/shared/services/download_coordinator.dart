import 'dart:async';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/core/network/api_client.dart';
import 'package:apexload/core/routing/app_router.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/services/api_download_service.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/services/local_media_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-owned tasks continue when navigation removes the progress screen.
class DownloadCoordinator with WidgetsBindingObserver {
  DownloadCoordinator(this.ref) {
    WidgetsBinding.instance.addObserver(this);
  }
  final Ref ref;
  final _tasks = <String, DownloadTask>{};

  DownloadTask taskFor(DownloadProgressArgs args, AppLocalizations l) {
    return _tasks.putIfAbsent(args.apiJobId ?? '', () {
      final task = DownloadTask(ref, args, l);
      unawaited(task.start());
      return task;
    });
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final task in _tasks.values) {
      task.dispose();
    }
    _tasks.clear();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    for (final task in _tasks.values) {
      task._retryAt = null;
      unawaited(task._pollStatus());
    }
  }
}

class DownloadTask extends ChangeNotifier {
  DownloadTask(this.ref, this.args, this.l);
  final Ref ref;
  final DownloadProgressArgs args;
  final AppLocalizations l;
  bool _disposed = false;
  bool get mounted => !_disposed;
  double get progress => _progress;
  String get status => _status;
  String get statusMessage => _statusMessage;
  bool get saved => _saved;
  bool get failed => _failed;
  bool get preparing => _preparing;
  bool get savingIndeterminate => _savingIndeterminate;
  DownloadItemModel? get completedItem => _completedItem;
  String? get localSavedPath => _localSavedPath;
  List<ApiDownloadFile> get latestFiles => _latestFiles;
  DateTime? _retryAt;
  int _consecutiveErrors = 0;
  bool _completionAdClaimed = false;

  /// Multiple progress screens can observe one task; count its completion once.
  bool claimCompletionAdOpportunity() {
    if (!_saved || _failed || _completionAdClaimed) return false;
    _completionAdClaimed = true;
    return true;
  }

  void _update(VoidCallback update) {
    if (_disposed) return;
    update();
    notifyListeners();
  }

  Future<void> start() async {
    _beginOperationWakelock();
    await ref.read(backgroundDownloadServiceProvider).begin();
    if (!mounted) return;
    _startPolling();
  }

  Timer? _timer;
  double _progress = 0;
  var _status = 'Queued';
  var _statusMessage = 'Queued';
  var _saved = false;
  var _failed = false;
  var _preparing = false;
  var _savingIndeterminate = false;
  var _polling = false;
  DownloadItemModel? _completedItem;
  String? _localSavedPath;
  List<ApiDownloadFile> _latestFiles = const [];
  var _operationWakeLockStarted = false;

  void _startPolling() {
    if (args.apiJobId == null || args.apiJobId!.isEmpty) {
      _markFailed(l.t('downloadJobFailed'));
      return;
    }
    unawaited(_pollStatus());
    _timer = Timer.periodic(
      const Duration(milliseconds: 750),
      (_) => _pollStatus(),
    );
  }

  Future<void> _pollStatus() async {
    if (!mounted || _saved || _polling) return;
    if (_retryAt != null && DateTime.now().isBefore(_retryAt!)) return;
    _polling = true;
    try {
      final status = await ref
          .read(apiDownloadServiceProvider)
          .getStatus(args.apiJobId!);
      if (!mounted) return;
      _consecutiveErrors = 0;
      _retryAt = null;
      _update(() {
        _progress = (status.progress / 100).clamp(0, 1);
        _status = status.status;
        _statusMessage = status.message.isEmpty
            ? status.status
            : status.message;
        _latestFiles = status.files;
      });

      final normalizedStatus = status.status.toLowerCase();
      if (normalizedStatus == 'failed' || status.success == false) {
        _timer?.cancel();
        _markFailed(_friendlyFailureMessage(status.error ?? status.message));
        return;
      }
      if (normalizedStatus == 'completed') {
        _timer?.cancel();
        await _completeFromStatus(status);
      }
    } on ApiClientException catch (error) {
      if (!mounted) return;
      if (error.retryable) {
        _consecutiveErrors++;
        _retryAt = DateTime.now().add(
          Duration(seconds: (1 << _consecutiveErrors.clamp(0, 5)).clamp(2, 30)),
        );
        _update(() => _statusMessage = l.t('downloadReconnecting'));
        return;
      }
      _timer?.cancel();
      _markFailed(_friendlyFailureMessage(error.message));
    } on ApiDownloadException catch (error) {
      if (!mounted) return;
      _timer?.cancel();
      final message =
          error.message.toLowerCase().contains('connect') ||
              error.message.toLowerCase().contains('timed out')
          ? l.t('connectionProblem')
          : error.message;
      _markFailed(_friendlyFailureMessage(message));
    } on Object {
      if (!mounted) return;
      _timer?.cancel();
      _markFailed(l.t('connectionProblem'));
    } finally {
      _polling = false;
    }
  }

  Future<void> _completeFromStatus(ApiDownloadStatus status) async {
    if (status.files.isEmpty) {
      _markFailed(l.t('downloadFailedNoFiles'));
      return;
    }

    final saveStageWatch = Stopwatch()..start();
    _logSavePerf('Start save');
    final apiService = ref.read(apiDownloadServiceProvider);
    final localMedia = ref.read(localMediaServiceProvider);
    _update(() {
      _preparing = true;
      _savingIndeterminate = false;
      _progress = 0.95;
      _status = 'preparing';
      _statusMessage = l.t('preparingYourFileDescription');
    });
    final savedFiles = <String, String>{};
    final thumbnails = <String, String>{};
    final savedNames = <String, String>{};
    final savedSizes = <String, String>{};
    final galleryUris = <String, String>{};
    var lastSaveProgressUpdate = DateTime.fromMillisecondsSinceEpoch(0);
    for (var i = 0; i < status.files.length; i++) {
      final file = status.files[i];
      final format = _formatForBackendFile(
        file,
        i < args.formats.length ? args.formats[i] : args.primaryFormat,
      );
      try {
        if (mounted) {
          _update(() {
            _progress = (0.95 + (i / status.files.length) * 0.045).clamp(
              0,
              0.995,
            );
            _status = 'saving';
            _statusMessage = l.t('savingFileToDevice');
            _savingIndeterminate = true;
          });
        }
        final save = await localMedia.saveRemoteFile(
          url: apiService.fullFileUrl(file),
          fileName: file.fileName.isEmpty
              ? _fileNameFor(format)
              : file.fileName,
          type: format.type,
          expectedSizeBytes: file.sizeBytes,
          publishToGallery: args.saveToGallery,
          onIndeterminateProgress: () {
            final now = DateTime.now();
            if (!mounted ||
                now.difference(lastSaveProgressUpdate).inMilliseconds < 800) {
              return;
            }
            lastSaveProgressUpdate = now;
            _update(() {
              _status = 'saving';
              _savingIndeterminate = true;
              _statusMessage = l.t('savingFileToDevice');
            });
          },
          onProgress: (saveProgress) {
            final now = DateTime.now();
            if (!mounted ||
                now.difference(lastSaveProgressUpdate).inMilliseconds < 150 &&
                    saveProgress < 1) {
              return;
            }
            lastSaveProgressUpdate = now;
            _update(() {
              final totalProgress = (i + saveProgress) / status.files.length;
              _progress = (0.95 + totalProgress * 0.049).clamp(0.95, 0.999);
              _status = 'saving';
              _savingIndeterminate = false;
              _statusMessage =
                  '${l.t('savingFileToDevice')} ${(saveProgress * 100).round().clamp(0, 100)}%';
            });
          },
        );
        savedFiles[file.fileId] = save.localFilePath;
        thumbnails[file.fileId] = save.thumbnailPath;
        savedNames[file.fileId] = save.fileName;
        if (save.sizeLabel.isNotEmpty) {
          savedSizes[file.fileId] = save.sizeLabel;
        }
        if (save.galleryUri.isNotEmpty) {
          galleryUris[file.fileId] = save.galleryUri;
        }
      } on Object catch (error) {
        if (kDebugMode) {
          debugPrint('ApexLoad local save failed: $error');
        }
        if (!mounted) return;
        _markFailed(l.t('downloadSaveFailed'));
        return;
      }
    }

    final items = [
      for (var i = 0; i < status.files.length; i++)
        if ((savedFiles[status.files[i].fileId] ?? '').isNotEmpty ||
            (kIsWeb && savedNames.containsKey(status.files[i].fileId)))
          ref
              .read(downloadServiceProvider)
              .createCompletedItem(
                media: args.media,
                format: _formatForBackendFile(
                  status.files[i],
                  i < args.formats.length
                      ? args.formats[i]
                      : args.primaryFormat,
                ),
                fileName: status.files[i].fileName.isEmpty
                    ? savedNames[status.files[i].fileId] ??
                          _fileNameFor(args.primaryFormat)
                    : savedNames[status.files[i].fileId] ??
                          status.files[i].fileName,
                sizeLabel:
                    savedSizes[status.files[i].fileId] ?? status.files[i].size,
                fileId: status.files[i].fileId,
                downloadUrl: status.files[i].downloadUrl,
                localFilePath: savedFiles[status.files[i].fileId] ?? '',
                thumbnailPath: thumbnails[status.files[i].fileId] ?? '',
                galleryUri: galleryUris[status.files[i].fileId] ?? '',
                duration: args.media.duration,
              ),
    ];
    if (items.isEmpty) {
      _markFailed(l.t('downloadSaveFailed'));
      return;
    }
    final historyWatch = Stopwatch()..start();
    final library = ref.read(libraryControllerProvider.notifier);
    for (final item in items.reversed) {
      await library.addAndSave(item);
    }
    historyWatch.stop();
    _logSavePerf(
      'history save completed in: ${historyWatch.elapsedMilliseconds} ms',
    );
    final thumbnailQueueWatch = Stopwatch()..start();
    unawaited(_generateThumbnailsInBackground(items, localMedia, library));
    thumbnailQueueWatch.stop();
    _logSavePerf(
      'thumbnail queued in: ${thumbnailQueueWatch.elapsedMilliseconds} ms',
    );
    await ref
        .read(subscriptionControllerProvider.notifier)
        .recordSuccessfulDownload(count: items.length);
    if (!mounted) return;
    _update(() {
      _progress = 1;
      _status = 'completed';
      _statusMessage = status.message.isEmpty
          ? l.t('downloadCompleted')
          : status.message;
      _saved = true;
      _preparing = false;
      _savingIndeterminate = false;
      _completedItem = items.first;
      _localSavedPath = savedFiles[status.files.first.fileId];
    });
    unawaited(_endOperationWakelock());
    saveStageWatch.stop();
    _logSavePerf(
      'total save stage completed in: ${saveStageWatch.elapsedMilliseconds} ms',
    );
  }

  String _friendlyFailureMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('could not connect to the server') ||
        lower.contains('could not connect to api') ||
        lower.contains('api request timed out')) {
      return l.t('serverConnectionProblem');
    }
    if (lower.contains('facebook photo posts are not available') ||
        (lower.contains('facebook') &&
            (lower.contains('registered users') ||
                lower.contains('cookies-from-browser') ||
                lower.contains('login required')))) {
      return l.t('facebookPhotoUnavailable');
    }
    if (lower.contains('login required') ||
        lower.contains('rate-limit') ||
        lower.contains('rate limit') ||
        lower.contains('content is not available') ||
        lower.contains('instagram blocked') ||
        lower.contains('refresh instagram cookies')) {
      return l.t('instagramBlocked');
    }
    return message;
  }

  void _markFailed(String message) {
    _update(() {
      _failed = true;
      _saved = true;
      _preparing = false;
      _savingIndeterminate = false;
      _progress = _progress.clamp(0, 0.95);
      _status = l.t('downloadFailed');
      _statusMessage = message.trim().isEmpty ? l.t('downloadFailed') : message;
    });
    unawaited(_endOperationWakelock());
  }

  Future<void> _generateThumbnailsInBackground(
    List<DownloadItemModel> items,
    LocalMediaService localMedia,
    LibraryController library,
  ) async {
    for (final item in items) {
      if (item.localFilePath.trim().isEmpty || item.thumbnailPath.isNotEmpty) {
        continue;
      }
      try {
        final thumbnailWatch = Stopwatch()..start();
        final thumbnail = await localMedia.generateThumbnail(
          localFilePath: item.localFilePath,
          fileName: item.fileName,
          type: item.type,
        );
        thumbnailWatch.stop();
        _logSavePerf(
          'thumbnail completed in: ${thumbnailWatch.elapsedMilliseconds} ms',
        );
        if (thumbnail == null || thumbnail.isEmpty) continue;
        library.add(item.copyWith(thumbnailPath: thumbnail));
      } on Object catch (error) {
        if (kDebugMode) {
          debugPrint('ApexLoad thumbnail generation skipped: $error');
        }
      }
    }
  }

  String _fileNameFor(DownloadFormatModel format) {
    if (args.formats.length == 1) return args.fileName;
    final dot = args.fileName.lastIndexOf('.');
    final base = dot <= 0 ? args.fileName : args.fileName.substring(0, dot);
    final suffix = format.label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+$'), '');
    return '${base}_$suffix.${format.extension}';
  }

  DownloadFormatModel _formatForBackendFile(
    ApiDownloadFile file,
    DownloadFormatModel fallback,
  ) {
    final type = switch (file.type.toLowerCase()) {
      'audio' => DownloadType.audio,
      'image' => DownloadType.image,
      'video' => DownloadType.video,
      _ => fallback.type,
    };
    final extension = _extensionFromFileName(file.fileName, fallback.extension);
    return DownloadFormatModel(
      id: file.fileId.isEmpty ? fallback.id : file.fileId,
      label: fallback.label,
      extension: extension,
      type: type,
      isPremium: fallback.isPremium,
      sizeLabel: file.size.isEmpty ? fallback.sizeLabel : file.size,
      isAvailable: fallback.isAvailable,
      unavailableReasonKey: fallback.unavailableReasonKey,
    );
  }

  String _extensionFromFileName(String fileName, String fallback) {
    final dot = fileName.lastIndexOf('.');
    if (dot >= 0 && dot < fileName.length - 1) {
      return fileName.substring(dot + 1).toLowerCase();
    }
    return fallback;
  }

  void _logSavePerf(String message) {
    if (!kDebugMode) return;
    debugPrint('[ApexLoad Save Perf] $message');
  }

  void _beginOperationWakelock() {
    if (_operationWakeLockStarted) return;
    _operationWakeLockStarted = true;
    unawaited(
      ref
          .read(activeOperationWakelockServiceProvider)
          .begin(reason: 'download'),
    );
  }

  Future<void> _endOperationWakelock() async {
    if (!_operationWakeLockStarted) return;
    _operationWakeLockStarted = false;
    await ref
        .read(activeOperationWakelockServiceProvider)
        .end(reason: 'download');
    await ref.read(backgroundDownloadServiceProvider).end();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
