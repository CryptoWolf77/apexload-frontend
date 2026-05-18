import 'dart:async';

import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/core/routing/app_router.dart';
import 'package:apexload/features/quick_editor/quick_editor_gate.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
import 'package:apexload/shared/widgets/mock_ad_dialog.dart';
import 'package:apexload/shared/widgets/primary_gradient_button.dart';
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
  var _status = 'Analyzing';
  var _saved = false;
  var _failed = false;
  DownloadItemModel? _completedItem;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 280), (_) => _tick());
  }

  Future<void> _tick() async {
    if (!mounted) return;
    if (_progress >= 1) return;
    setState(() {
      _progress = (_progress + 0.045).clamp(0, 1);
      _status = _progress < 0.2
          ? 'Analyzing'
          : _progress < 0.42
          ? 'Preparing'
          : _progress < 1
          ? 'Downloading'
          : 'Completed';
    });
    if (_progress >= 1 && !_saved) {
      _timer?.cancel();
      if (widget.args.apiJobId != null) {
        try {
          final status = await ref
              .read(apiDownloadServiceProvider)
              .getStatus(widget.args.apiJobId!);
          if (status.progress < 100 ||
              status.status.toLowerCase() == 'failed') {
            throw StateError('Download job not complete.');
          }
        } on Object {
          if (mounted) {
            setState(() {
              _failed = true;
              _saved = true;
              _status = AppLocalizations.of(context).t('downloadFailed');
            });
            AppNotification.error(
              context,
              message: AppLocalizations.of(context).t('downloadFailed'),
            );
          }
          return;
        }
      }
      final items = [
        for (final format in widget.args.formats)
          ref
              .read(downloadServiceProvider)
              .createCompletedItem(
                media: widget.args.media,
                format: format,
                fileName: _fileNameFor(format),
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
        _status = 'Completed';
        _saved = true;
        _completedItem = _firstVideoItem(items);
      });
      AppNotification.success(
        context,
        message: AppLocalizations.of(context).t('downloadCompleted'),
      );
      if (showAd) {
        await showMockAdDialog(context);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = _progress >= 1;
    final failed = _failed;
    final percent = (_progress * 100).round();
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
                  : _status,
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
                  ? l.t('savedLocally')
                  : '4.8 MB/s',
            ),
            _ProgressInfo(
              label: l.t('queuePosition'),
              value: failed
                  ? l.t('done')
                  : completed
                  ? l.t('done')
                  : '#1',
            ),
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
