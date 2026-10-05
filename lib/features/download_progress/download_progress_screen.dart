import 'dart:async';

import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/core/routing/app_router.dart';
import 'package:apexload/features/quick_editor/quick_editor_gate.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/services/api_download_service.dart';
import 'package:apexload/shared/services/admob_service.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/services/download_coordinator.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:apexload/shared/widgets/active_operation_note.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
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
  late DownloadTask _task;
  bool _attached = false;
  double get _progress => _task.progress;
  String get _status => _task.status;
  String get _statusMessage => _task.statusMessage;
  bool get _saved => _task.saved;
  bool get _failed => _task.failed;
  bool get _preparing => _task.preparing;
  bool get _savingIndeterminate => _task.savingIndeterminate;
  DownloadItemModel? get _completedItem => _task.completedItem;
  String? get _localSavedPath => _task.localSavedPath;
  List<ApiDownloadFile> get _latestFiles => _task.latestFiles;
  bool _notified = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_attached) return;
    _attached = true;
    _task = ref
        .read(downloadCoordinatorProvider)
        .taskFor(widget.args, AppLocalizations.of(context));
    _task.addListener(_onChanged);
    if (_saved) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onChanged());
    }
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    if (_saved && !_notified) {
      _notified = true;
      if (_failed) {
        AppNotification.error(context, message: _statusMessage);
      } else {
        AppNotification.success(
          context,
          message: AppLocalizations.of(context).t('downloadSavedToLibrary'),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final lifecycle = WidgetsBinding.instance.lifecycleState;
          if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
            return;
          }
          unawaited(
            ref
                .read(adMobServiceProvider)
                .handleDownloadOperation(DownloadAdOutcome.successful),
          );
        });
      }
    }
  }

  @override
  void dispose() {
    if (_attached) _task.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = _saved && !_failed;
    final failed = _failed;
    final progressIsIndeterminate =
        _status.toLowerCase() == 'saving' &&
        _savingIndeterminate &&
        !completed &&
        !failed;
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
                            value: progressIsIndeterminate ? null : _progress,
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
                              progressIsIndeterminate
                                  ? '...'
                                  : completed
                                  ? '100%'
                                  : '$percent%',
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
                    if (!completed && !failed) ...[
                      const SizedBox(height: 12),
                      Text(
                        l.t('backgroundDownloadNote'),
                        textAlign: TextAlign.center,
                      ),
                      const ActiveOperationNote(),
                    ],
                    if (_showLargeSavingHint) ...[
                      const SizedBox(height: 12),
                      _LargeFileInfoCard(
                        title: l.t('preparingLargeVideo'),
                        message: l.t('largeVideoSavingMessage'),
                        subtitle: l.t('largeVideoSavingSubtitle'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (_preparing) ...[
                      LinearProgressIndicator(
                        value: progressIsIndeterminate ? null : _progress,
                      ),
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
                        icon: const Icon(Icons.home_rounded),
                        label: Text(l.t('goHome')),
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

  bool get _showLargeSavingHint {
    if (_status.toLowerCase() != 'saving') return false;
    if (widget.args.primaryFormat.type != DownloadType.video) return false;
    final labels = [
      widget.args.primaryFormat.label,
      widget.args.primaryFormat.id,
      widget.args.primaryFormat.sizeLabel,
      widget.args.fileName,
      widget.args.media.title,
      for (final file in _latestFiles) ...[file.fileName, file.size, file.type],
    ];
    return _hasLargeVideoSignal(labels);
  }

  bool _hasLargeVideoSignal(Iterable<String> labels) {
    for (final label in labels) {
      final normalized = label.toLowerCase().replaceAll(' ', '');
      if (normalized.isEmpty) continue;
      if (normalized.contains('1080') ||
          normalized.contains('1440') ||
          normalized.contains('2160') ||
          normalized.contains('2k') ||
          normalized.contains('4k') ||
          normalized.contains('fhd') ||
          normalized.contains('uhd') ||
          normalized.contains('highbitrate')) {
        return true;
      }
      final mb = _sizeLabelToMb(label);
      if (mb != null && mb >= 100) return true;
    }
    return false;
  }

  double? _sizeLabelToMb(String value) {
    final match = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(gb|gib|mb|mib|kb|kib)\b',
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) return null;
    final amount = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (amount == null) return null;
    final unit = match.group(2)!.toLowerCase();
    if (unit.startsWith('g')) return amount * 1024;
    if (unit.startsWith('m')) return amount;
    return amount / 1024;
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

class _LargeFileInfoCard extends StatelessWidget {
  const _LargeFileInfoCard({
    required this.title,
    required this.message,
    this.subtitle,
  });

  final String title;
  final String message;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryEnd.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryEnd.withValues(alpha: 0.26)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: TextStyle(
                    color: AppTone.textSecondary(context),
                    height: 1.35,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: AppTone.textSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
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
    final l = AppLocalizations.of(context);
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
              '${l.t('selectedType')}: ${requested.map((item) => item.type).join(', ')}',
            ),
            Text(
              '${l.t('requestedFormat')}: ${requested.map((item) => item.formatId).join(', ')}',
            ),
            Text('${l.t('returnedFileType')}: ${returned?.type ?? '-'}'),
            Text('${l.t('returnedFilename')}: ${returned?.fileName ?? '-'}'),
          ],
        ),
      ),
    );
  }
}
