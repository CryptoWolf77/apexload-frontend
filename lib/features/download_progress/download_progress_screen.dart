import 'dart:async';

import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/core/routing/app_router.dart';
import 'package:apexload/features/quick_editor/quick_editor_gate.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/services/api_download_service.dart';
import 'package:apexload/shared/services/app_state.dart';
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
  DownloadItemModel? _completedItem;
  ApiDownloadFile? _completedFile;
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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _pollStatus());
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
    final firstFile = status.files.first;
    String? savedPath;
    if (widget.args.saveToGallery) {
      try {
        savedPath = await apiService.saveOrOpenFile(firstFile);
      } on Object catch (error) {
        if (!mounted) return;
        AppNotification.warning(
          context,
          message: '${l.t('downloadCompleted')} ${error.toString()}',
        );
      }
    }

    final items = [
      for (var i = 0; i < status.files.length; i++)
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
                  ? _fileNameFor(widget.args.primaryFormat)
                  : status.files[i].fileName,
              sizeLabel: status.files[i].size,
            ),
    ];
    for (final item in items.reversed) {
      ref.read(libraryControllerProvider.notifier).add(item);
    }
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
      _completedItem = _firstVideoItem(items);
      _completedFile = firstFile;
      _localSavedPath = savedPath;
    });
    AppNotification.success(context, message: l.t('downloadCompleted'));
    if (showAd) {
      await showMockAdDialog(context);
    }
  }

  String _friendlyFailureMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('login required') ||
        lower.contains('rate-limit') ||
        lower.contains('rate limit') ||
        lower.contains('content is not available') ||
        lower.contains('instagram blocked') ||
        lower.contains('refresh instagram cookies')) {
      return AppLocalizations.of(context).t('instagramBlocked');
    }
    return message;
  }

  void _markFailed(String message) {
    final l = AppLocalizations.of(context);
    setState(() {
      _failed = true;
      _saved = true;
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
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Spacer(),
            SizedBox(
              width: 178,
              height: 178,
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
            const SizedBox(height: 28),
            Text(
              failed
                  ? l.t('downloadFailed')
                  : completed
                  ? l.t('downloadCompleted')
                  : _statusLabel(l),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              widget.args.fileName,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTone.textSecondary(context)),
            ),
            const SizedBox(height: 20),
            _ProgressInfo(
              label: l.t('platform'),
              value: l.platformName(widget.args.media.platform),
            ),
            _ProgressInfo(
              label: l.t('speed'),
              value: failed
                  ? l.t('downloadFailed')
                  : completed
                  ? (_localSavedPath == null
                        ? l.t('readyToOpen')
                        : l.t('savedLocally'))
                  : _statusMessage,
            ),
            _ProgressInfo(
              label: l.t('queuePosition'),
              value: failed
                  ? l.t('done')
                  : completed
                  ? l.t('done')
                  : '#1',
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              _DebugDownloadInfo(
                requestedFormats: widget.args.formats,
                returnedFiles: _latestFiles,
              ),
            ],
            const Spacer(),
            if (completed && !failed) ...[
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
              if (_completedItem != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _completedItem == null
                      ? null
                      : () => _openQuickEditor(_completedItem!),
                  icon: const Icon(Icons.auto_fix_high_rounded),
                  label: Text(l.t('editVideo')),
                ),
              ],
              if (_completedFile != null) ...[
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
  }

  void _openQuickEditor(DownloadItemModel item) {
    final premium = ref.read(subscriptionControllerProvider).isPremium;
    if (!premium) {
      showQuickEditorPremiumSheet(context);
      return;
    }
    context.push('/quick-editor', extra: item);
  }

  Future<void> _openCompletedFile() async {
    final file = _completedFile;
    if (file == null) return;
    try {
      await ref.read(apiDownloadServiceProvider).saveOrOpenFile(file);
    } on Object {
      if (!mounted) return;
      AppNotification.error(
        context,
        message: AppLocalizations.of(context).t('connectionProblem'),
      );
    }
  }

  String _statusLabel(AppLocalizations l) {
    return switch (_status.toLowerCase()) {
      'queued' => l.t('queued'),
      'processing' => l.t('downloading'),
      'completed' => l.t('downloadCompleted'),
      'failed' => l.t('downloadFailed'),
      _ => _statusMessage,
    };
  }

  DownloadItemModel? _firstVideoItem(List<DownloadItemModel> items) {
    for (final item in items) {
      if (item.type == DownloadType.video) return item;
    }
    return null;
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

class _ProgressInfo extends StatelessWidget {
  const _ProgressInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTone.textSecondary(context))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
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
