import 'dart:async';

import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/core/routing/app_router.dart';
import 'package:apexload/features/quick_editor/quick_editor_gate.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/services/api_download_service.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/services/local_media_service.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
import 'package:apexload/shared/widgets/mock_ad_dialog.dart';
import 'package:apexload/shared/widgets/primary_gradient_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DownloadProgressScreen extends ConsumerStatefulWidget {
  const DownloadProgressScreen({super.key, required this.args});

  final DownloadProgressArgs args;

  @override
  ConsumerState<DownloadProgressScreen> createState() =>
      _DownloadProgressScreenState();
}

class _DownloadProgressScreenState
    extends ConsumerState<DownloadProgressScreen> {
  Timer? _timer;
  double _progress = 0;
  var _status = 'Queued';
  var _statusMessage = 'Queued';
  var _saved = false;
  var _failed = false;
  var _preparing = false;
  DownloadItemModel? _completedItem;
  String? _localSavedPath;
  List<ApiDownloadFile> _latestFiles = const [];

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    if (widget.args.apiJobId == null || widget.args.apiJobId!.isEmpty) {
      _markFailed(AppLocalizations.of(context).t('downloadJobFailed'));
      return;
    }
    unawaited(_pollStatus());
    _timer = Timer.periodic(
      const Duration(milliseconds: 1500),
      (_) => _pollStatus(),
    );
  }

  Future<void> _pollStatus() async {
    if (!mounted || _saved) return;
    try {
      final status = await ref
          .read(apiDownloadServiceProvider)
          .getStatus(widget.args.apiJobId!);
      if (!mounted) return;
      setState(() {
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
    } on ApiDownloadException catch (error) {
      if (!mounted) return;
      _timer?.cancel();
      final message =
          error.message.toLowerCase().contains('connect') ||
              error.message.toLowerCase().contains('timed out')
          ? AppLocalizations.of(context).t('connectionProblem')
          : error.message;
      _markFailed(_friendlyFailureMessage(message));
    } on Object {
      if (!mounted) return;
      _timer?.cancel();
      _markFailed(AppLocalizations.of(context).t('connectionProblem'));
    }
  }

  Future<void> _completeFromStatus(ApiDownloadStatus status) async {
    final l = AppLocalizations.of(context);
    if (status.files.isEmpty) {
      _markFailed(l.t('downloadFailedNoFiles'));
      return;
    }

    final apiService = ref.read(apiDownloadServiceProvider);
    final localMedia = ref.read(localMediaServiceProvider);
    setState(() {
      _preparing = true;
      _progress = 0.96;
      _status = 'preparing';
      _statusMessage = l.t('preparingYourFileDescription');
    });
    final savedFiles = <String, String>{};
    final thumbnails = <String, String>{};
    final savedNames = <String, String>{};
    final savedSizes = <String, String>{};
    final galleryUris = <String, String>{};
    var galleryPublishFailed = false;
    var lastSaveProgressUpdate = DateTime.fromMillisecondsSinceEpoch(0);
    for (var i = 0; i < status.files.length; i++) {
      final file = status.files[i];
      final format = _formatForBackendFile(
        file,
        i < widget.args.formats.length
            ? widget.args.formats[i]
            : widget.args.primaryFormat,
      );
      try {
        if (mounted) {
          setState(() {
            _progress = (0.96 + (i / status.files.length) * 0.035).clamp(
              0,
              0.995,
            );
            _status = 'saving';
            _statusMessage = l.t('savingFileToDevice');
          });
        }
        final save = await localMedia.saveRemoteFile(
          url: apiService.fullFileUrl(file),
          fileName: file.fileName.isEmpty
              ? _fileNameFor(format)
              : file.fileName,
          type: format.type,
          onProgress: (saveProgress) {
            final now = DateTime.now();
            if (!mounted ||
                now.difference(lastSaveProgressUpdate).inMilliseconds < 150 &&
                    saveProgress < 1) {
              return;
            }
            lastSaveProgressUpdate = now;
            setState(() {
              final totalProgress = (i + saveProgress) / status.files.length;
              _progress = (0.96 + totalProgress * 0.035).clamp(0.96, 0.995);
              _status = 'saving';
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
        } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          galleryPublishFailed = true;
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
                media: widget.args.media,
                format: _formatForBackendFile(
                  status.files[i],
                  i < widget.args.formats.length
                      ? widget.args.formats[i]
                      : widget.args.primaryFormat,
                ),
                fileName: status.files[i].fileName.isEmpty
                    ? savedNames[status.files[i].fileId] ??
                          _fileNameFor(widget.args.primaryFormat)
                    : savedNames[status.files[i].fileId] ??
                          status.files[i].fileName,
                sizeLabel:
                    savedSizes[status.files[i].fileId] ?? status.files[i].size,
                fileId: status.files[i].fileId,
                downloadUrl: status.files[i].downloadUrl,
                localFilePath: savedFiles[status.files[i].fileId] ?? '',
                thumbnailPath: thumbnails[status.files[i].fileId] ?? '',
                galleryUri: galleryUris[status.files[i].fileId] ?? '',
                duration: widget.args.media.duration,
              ),
    ];
    if (items.isEmpty) {
      _markFailed(l.t('downloadSaveFailed'));
      return;
    }
    for (final item in items.reversed) {
      ref.read(libraryControllerProvider.notifier).add(item);
    }
    unawaited(
      _generateThumbnailsInBackground(
        items,
        localMedia,
        ref.read(libraryControllerProvider.notifier),
      ),
    );
    final showAd = await ref
        .read(subscriptionControllerProvider.notifier)
        .recordSuccessfulDownload(count: items.length);
    if (!mounted) return;
    setState(() {
      _progress = 1;
      _status = 'completed';
      _statusMessage = status.message.isEmpty
          ? l.t('downloadCompleted')
          : status.message;
      _saved = true;
      _preparing = false;
      _completedItem = items.first;
      _localSavedPath = savedFiles[status.files.first.fileId];
    });
    AppNotification.success(context, message: l.t('downloadSavedToLibrary'));
    if (galleryPublishFailed) {
      AppNotification.warning(context, message: l.t('galleryPublishFailed'));
    }
    if (showAd) {
      await showMockAdDialog(context);
    }
  }

  String _friendlyFailureMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('could not connect to the server') ||
        lower.contains('could not connect to api') ||
        lower.contains('api request timed out')) {
      return AppLocalizations.of(context).t('serverConnectionProblem');
    }
    if (lower.contains('facebook photo posts are not available') ||
        (lower.contains('facebook') &&
            (lower.contains('registered users') ||
                lower.contains('cookies-from-browser') ||
                lower.contains('login required')))) {
      return AppLocalizations.of(context).t('facebookPhotoUnavailable');
    }
    if (lower.contains('login required') ||
        lower.contains('rate-limit') ||
        lower.contains('rate limit') ||
        lower.contains('content is not available') ||
        lower.contains('instagram blocked') ||
        lower.contains('refresh instagram cookies')) {
      return AppLocalizations.of(context).t('instagramBlocked');
    }
    if (lower.contains('youtube requires sign-in') ||
        lower.contains('youtube requested sign-in') ||
        lower.contains('not a bot') ||
        lower.contains('refresh youtube cookies')) {
      return AppLocalizations.of(context).t('youtubeRequiresAuth');
    }
    if (lower.contains('youtube format is not available') ||
        lower.contains('requested format is not available')) {
      return AppLocalizations.of(context).t('youtubeFormatUnavailable');
    }
    if (lower.contains('youtube video formats are temporarily unavailable') ||
        lower.contains('only images are available') ||
        lower.contains('challenge solver') ||
        lower.contains('javascript runtime')) {
      return AppLocalizations.of(
        context,
      ).t('youtubeFormatsTemporarilyUnavailable');
    }
    return message;
  }

  void _markFailed(String message) {
    final l = AppLocalizations.of(context);
    setState(() {
      _failed = true;
      _saved = true;
      _preparing = false;
      _progress = _progress.clamp(0, 0.95);
      _status = l.t('downloadFailed');
      _statusMessage = message.trim().isEmpty ? l.t('downloadFailed') : message;
    });
    AppNotification.error(
      context,
      message: message.trim().isEmpty ? l.t('downloadFailed') : message,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = _saved && !_failed;
    final failed = _failed;
    final percent = failed
        ? (_progress * 100).round().clamp(0, 99)
        : (_progress * 100).round();
    final l = AppLocalizations.of(context);

    return GradientScaffold(
      appBar: AppBar(
        title: Text(l.t('downloadProgress')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 38).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 172,
                      height: 172,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 14,
                            backgroundColor: AppTone.cardSecondary(context),
                            color: failed
                                ? AppColors.error
                                : completed
                                ? AppColors.success
                                : AppColors.primaryEnd,
                          ),
                          Center(
                            child: Text(
                              completed ? '100%' : '$percent%',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      failed
                          ? l.t('downloadFailed')
                          : completed
                          ? l.t('downloadCompleted')
                          : _statusLabel(l),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _displayStatusMessage(l, completed: completed),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTone.textSecondary(context),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ProgressMetadataCard(
                      rows: [
                        _ProgressMetadataRowData(
                          l.t('platform'),
                          l.platformName(widget.args.media.platform),
                        ),
                        _ProgressMetadataRowData(
                          l.t('filename'),
                          widget.args.fileName,
                        ),
                        _ProgressMetadataRowData(
                          l.t('format'),
                          widget.args.primaryFormat.label,
                        ),
                        if (_metadataSizeLabel(l) != null)
                          _ProgressMetadataRowData(
                            l.t('size'),
                            _metadataSizeLabel(l)!,
                          ),
                        _ProgressMetadataRowData(
                          l.t('queuePosition'),
                          completed || failed ? l.t('done') : '#1',
                        ),
                      ],
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 12),
                      _DebugDownloadInfo(
                        requestedFormats: widget.args.formats,
                        returnedFiles: _latestFiles,
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (_preparing) ...[
                      LinearProgressIndicator(value: _progress),
                    ] else if (completed && !failed) ...[
                      PrimaryGradientButton(
                        label: l.t('openLibrary'),
                        icon: Icons.folder_rounded,
                        onPressed: () => context.go('/downloads'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.add_link_rounded),
                        label: Text(l.t('downloadAnother')),
                      ),
                      if (_completedItem != null &&
                          _completedItem!.type == DownloadType.video) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _completedItem == null
                              ? null
                              : () => _openQuickEditor(_completedItem!),
                          icon: const Icon(Icons.auto_fix_high_rounded),
                          label: Text(l.t('editVideo')),
                        ),
                      ],
                      if (_completedItem != null) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _openCompletedFile,
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: Text(l.t('open')),
                        ),
                      ],
                    ] else if (!completed)
                      OutlinedButton.icon(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                        icon: const Icon(Icons.close_rounded),
                        label: Text(l.t('cancel')),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.add_link_rounded),
                        label: Text(l.t('downloadAnother')),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openQuickEditor(DownloadItemModel item) {
    final premium = ref.read(subscriptionControllerProvider).isPremium;
    if (!premium) {
      showQuickEditorPremiumSheet(context);
      return;
    }
    context.push('/quick-editor/edit', extra: item);
  }

  Future<void> _openCompletedFile() async {
    final item = _completedItem;
    if (item == null) return;
    try {
      await ref.read(localMediaServiceProvider).openItem(item);
    } on Object {
      if (!mounted) return;
      AppNotification.error(
        context,
        message: AppLocalizations.of(context).t('couldNotOpenFile'),
      );
    }
  }

  String _statusLabel(AppLocalizations l) {
    return switch (_status.toLowerCase()) {
      'queued' => l.t('queued'),
      'processing' => l.t('downloading'),
      'preparing' => l.t('preparingYourFile'),
      'saving' => l.t('savingToDevice'),
      'completed' => l.t('downloadCompleted'),
      'failed' => l.t('downloadFailed'),
      _ => _statusMessage,
    };
  }

  String _displayStatusMessage(AppLocalizations l, {required bool completed}) {
    if (_failed) return _statusMessage;
    if (_status.toLowerCase() == 'saving') return _statusMessage;
    if (_preparing) return l.t('preparingYourFileDescription');
    if (completed) {
      return _localSavedPath == null ? l.t('readyToOpen') : l.t('savedLocally');
    }
    return _statusMessage.trim().isEmpty ? _statusLabel(l) : _statusMessage;
  }

  String? _metadataSizeLabel(AppLocalizations l) {
    final label = widget.args.primaryFormat.sizeLabel.trim();
    if (label.isEmpty) return null;
    if (label.toLowerCase() == 'unknown') return l.t('calculating');
    return label;
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
        final thumbnail = await localMedia.generateThumbnail(
          localFilePath: item.localFilePath,
          fileName: item.fileName,
          type: item.type,
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
    if (widget.args.formats.length == 1) return widget.args.fileName;
    final dot = widget.args.fileName.lastIndexOf('.');
    final base = dot <= 0
        ? widget.args.fileName
        : widget.args.fileName.substring(0, dot);
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
}

class _ProgressMetadataRowData {
  const _ProgressMetadataRowData(this.label, this.value);

  final String label;
  final String value;
}

class _ProgressMetadataCard extends StatelessWidget {
  const _ProgressMetadataCard({required this.rows});

  final List<_ProgressMetadataRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTone.card(context).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTone.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _ProgressMetadataRow(row: rows[i]),
            if (i < rows.length - 1)
              Divider(height: 18, color: AppTone.border(context)),
          ],
        ],
      ),
    );
  }
}

class _ProgressMetadataRow extends StatelessWidget {
  const _ProgressMetadataRow({required this.row});

  final _ProgressMetadataRowData row;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            row.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppTone.textSecondary(context)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            row.value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _DebugDownloadInfo extends StatelessWidget {
  const _DebugDownloadInfo({
    required this.requestedFormats,
    required this.returnedFiles,
  });

  final List<DownloadFormatModel> requestedFormats;
  final List<ApiDownloadFile> returnedFiles;

  @override
  Widget build(BuildContext context) {
    final requested = [
      for (final format in requestedFormats)
        DownloadSelectedItem.fromFormat(format),
    ];
    final returned = returnedFiles.isEmpty ? null : returnedFiles.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTone.cardSecondary(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTone.border(context)),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: AppTone.textSecondary(context),
          fontSize: 11,
          height: 1.35,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected type: ${requested.map((item) => item.type).join(', ')}',
            ),
            Text(
              'Requested format: ${requested.map((item) => item.formatId).join(', ')}',
            ),
            Text('Returned file type: ${returned?.type ?? '-'}'),
            Text('Returned filename: ${returned?.fileName ?? '-'}'),
          ],
        ),
      ),
    );
  }
}
