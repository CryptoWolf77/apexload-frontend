import 'dart:async';

import 'package:apexload/core/constants/app_file_type_groups.dart';
import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/features/quick_editor/editor_completion_panel.dart';
import 'package:apexload/features/quick_editor/quick_editor_controller.dart';
import 'package:apexload/features/quick_editor/quick_editor_models.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/active_operation_note.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
import 'package:apexload/shared/widgets/primary_gradient_button.dart';
import 'package:apexload/shared/widgets/video_preview_panel.dart';
import 'package:apexload/shared/widgets/media_source_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

String _formatEditorTime(num seconds) {
  final totalSeconds = seconds.isFinite
      ? seconds.round().clamp(0, 2147483647).toInt()
      : 0;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final secs = totalSeconds % 60;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = secs.toString().padLeft(2, '0');
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:$mm:$ss';
  }
  return '$mm:$ss';
}

String _formatEditorBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
  final gb = mb / 1024;
  return '${gb.toStringAsFixed(gb < 10 ? 1 : 0)} GB';
}

bool _hasLargeEditorVideoSignal(Iterable<String> labels) {
  for (final label in labels) {
    final normalized = label.toLowerCase().replaceAll(' ', '');
    if (normalized.isEmpty) continue;
    if (normalized.contains('1080') ||
        normalized.contains('1440') ||
        normalized.contains('2160') ||
        normalized.contains('1920x1080') ||
        normalized.contains('2k') ||
        normalized.contains('4k') ||
        normalized.contains('fhd') ||
        normalized.contains('uhd') ||
        normalized.contains('highbitrate')) {
      return true;
    }
    final mb = _editorSizeLabelToMb(label);
    if (mb != null && mb >= 100) return true;
  }
  return false;
}

double? _editorSizeLabelToMb(String value) {
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

class QuickEditorScreen extends ConsumerStatefulWidget {
  const QuickEditorScreen({super.key, required this.item});

  final DownloadItemModel item;

  @override
  ConsumerState<QuickEditorScreen> createState() => _QuickEditorScreenState();
}

class _QuickEditorScreenState extends ConsumerState<QuickEditorScreen> {
  final ScrollController _scrollController = ScrollController();
  RangeValues _trimRange = const RangeValues(0, 10);
  var _trimMax = 32.0;
  var _removeAudio = true;
  var _audioFormat = 'MP3';
  var _audioQuality = 'Standard';
  String? _selectedAudioFile;
  String? _selectedAudioPath;
  double? _selectedAudioDuration;
  var _loadingAudioDuration = false;
  var _audioSwapMode = 'replace';
  var _shortAudioBehavior = 'silent';
  var _audioStartPosition = 0.0;
  var _audioVolume = 0.82;
  String? _selectedVideoFile;
  String? _selectedVideoPath;
  RangeValues _gifRange = const RangeValues(0, 6);
  var _gifQuality = 'Standard';
  var _gifSize = 'Medium';
  var _gifFps = 15;
  var _gifLoop = true;
  var _gifSpeed = 1.0;
  var _reelsPreset = 'instagram';
  var _reelsResizeMode = 'smart_crop';
  var _reelsQuality = 'medium';
  var _reelsMute = false;
  String? _selectedVideoSizeLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showIosCompatibilityRecommendationIfNeeded();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showIosCompatibilityRecommendationIfNeeded() async {
    final extension = _sourceExtension(widget.item);
    if (!mounted ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.iOS ||
        extension.isEmpty ||
        extension == 'mp4') {
      return;
    }
    final l = AppLocalizations.of(context);
    final goToConvert = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.t('editingCompatibilityTitle')),
        content: Text(l.t('editingCompatibilityMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.t('continueEditing')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.t('convertToMp4')),
          ),
        ],
      ),
    );
    if (goToConvert != true || !mounted) return;
    _run(
      const QuickEditorJob(
        type: QuickEditorJobType.export,
        operation: 'convert',
        successMessageKey: 'exportSuccess',
      ),
    );
  }

  String _sourceExtension(DownloadItemModel item) {
    final source = item.fileName.trim().isNotEmpty
        ? item.fileName.trim()
        : item.localFilePath.trim();
    final clean = source.split('?').first;
    final dot = clean.lastIndexOf('.');
    if (dot < 0 || dot == clean.length - 1) return '';
    return clean.substring(dot + 1).toLowerCase();
  }

  void _showCompletionDialog(DownloadItemModel item, AppLocalizations l) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.background.withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primaryEnd,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  l.t('editingComplete'),
                  style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l.t('editingCompleteMessage'),
                  style: TextStyle(
                    color: AppTone.textSecondary(dialogContext),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      context.go('/downloads');
                    },
                    child: Text(l.t('viewInDownloads')),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: Text(l.t('continueEditing')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(quickEditorControllerProvider);
    ref.listen<QuickEditorState>(quickEditorControllerProvider, (
      previous,
      next,
    ) {
      final error = next.errorMessage;
      if (error != null && previous?.errorMessage != error) {
        AppNotification.error(context, message: _friendlyEditorError(l, error));
        ref.read(quickEditorControllerProvider.notifier).clearMessage();
        return;
      }
      final completedItem = next.completedItem;
      final messageKey = next.successMessageKey;
      if (messageKey != null && previous?.successMessageKey != messageKey) {
        if (completedItem != null) {
          ref.read(libraryControllerProvider.notifier).add(completedItem);
        }
        AppNotification.success(context, message: l.t(messageKey));
        ref.read(quickEditorControllerProvider.notifier).clearMessage();
        
        if (completedItem != null && mounted) {
          _showCompletionDialog(completedItem, l);
        }
      }
    });

    return GradientScaffold(
      appBar: AppBar(
        title: Text(l.t('quickEditor')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: Theme(
        data: _editorButtonTheme(context),
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 104),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Text(
                  l.t('quickEditor'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  l.t('quickEditorSubtitle'),
                  style: TextStyle(color: AppTone.textSecondary(context)),
                ),
                const SizedBox(height: 16),
                _VideoInfoCard(item: widget.item),
                if (state.completedItem != null) ...[
                  const SizedBox(height: 14),
                  EditorCompletionPanel(
                    item: state.completedItem!,
                    onOpen: () => _openCompletedItem(state.completedItem!),
                    onViewDownloads: _viewCompletedItemInDownloads,
                    onDismiss: _dismissCompletedItem,
                  ),
                ],
                const SizedBox(height: 14),
                _TrimCard(
                  localFilePath: widget.item.localFilePath,
                  range: _trimRange,
                  maxDuration: _trimMax,
                  onDurationChanged: _updateTrimDuration,
                  onChanged: (value) => setState(() => _trimRange = value),
                  onApply: () => _run(
                    const QuickEditorJob(
                      type: QuickEditorJobType.trim,
                      operation: 'trim',
                      successMessageKey: 'trimSuccess',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _MuteCard(
                  value: _removeAudio,
                  onChanged: (value) => setState(() => _removeAudio = value),
                  onApply: () => _run(
                    const QuickEditorJob(
                      type: QuickEditorJobType.mute,
                      operation: 'mute',
                      successMessageKey: 'muteSuccess',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _ExtractAudioCard(
                  format: _audioFormat,
                  quality: _audioQuality,
                  onFormatChanged: (value) =>
                      setState(() => _audioFormat = value),
                  onQualityChanged: (value) =>
                      setState(() => _audioQuality = value),
                  onApply: () => _run(
                    const QuickEditorJob(
                      type: QuickEditorJobType.extractAudio,
                      operation: 'extract-audio',
                      successMessageKey: 'audioExtractedSuccess',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _AudioSwapCard(
                  videoPath: widget.item.localFilePath,
                  selectedFile: _selectedAudioFile,
                  mode: _audioSwapMode,
                  shortAudioBehavior: _shortAudioBehavior,
                  videoDuration: _trimMax,
                  audioDuration: _selectedAudioDuration,
                  loadingAudioDuration: _loadingAudioDuration,
                  startPosition: _audioStartPosition,
                  volume: _audioVolume,
                  onPickAudio: _pickAudioFile,
                  onClearAudio: () => setState(() {
                    _selectedAudioFile = null;
                    _selectedAudioPath = null;
                    _selectedAudioDuration = null;
                    _loadingAudioDuration = false;
                    _audioStartPosition = 0;
                  }),
                  onModeChanged: (value) => setState(() {
                    _audioSwapMode = value;
                    if (value == 'remove') {
                      _selectedAudioFile = null;
                      _selectedAudioPath = null;
                    }
                  }),
                  onShortBehaviorChanged: (value) =>
                      setState(() => _shortAudioBehavior = value),
                  onStartPositionChanged: (value) =>
                      setState(() => _audioStartPosition = value),
                  onVolumeChanged: (value) =>
                      setState(() => _audioVolume = value),
                  onPreview: _previewAudioSwap,
                  onApply: () {
                    if (_audioSwapMode == 'remove') {
                      _run(
                        const QuickEditorJob(
                          type: QuickEditorJobType.mute,
                          operation: 'mute',
                          successMessageKey: 'muteSuccess',
                        ),
                      );
                      return;
                    }
                    if (_selectedAudioPath == null) {
                      AppNotification.warning(
                        context,
                        message: l.t('noAudioSelected'),
                      );
                      return;
                    }
                    _run(
                      const QuickEditorJob(
                        type: QuickEditorJobType.audioSwap,
                        operation: 'audio-swap',
                        successMessageKey: 'audioReplacedSuccess',
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _VideoToGifCard(
                  sourceName: _selectedVideoFile ?? widget.item.fileName,
                  localFilePath:
                      _selectedVideoPath ?? widget.item.localFilePath,
                  range: _gifRange,
                  maxDuration: _trimMax,
                  quality: _gifQuality,
                  size: _gifSize,
                  fps: _gifFps,
                  loop: _gifLoop,
                  speed: _gifSpeed,
                  onPickVideo: _pickVideoFile,
                  onRangeChanged: (value) => setState(() => _gifRange = value),
                  onQualityChanged: (value) =>
                      setState(() => _gifQuality = value),
                  onSizeChanged: (value) => setState(() => _gifSize = value),
                  onFpsChanged: (value) => setState(() => _gifFps = value),
                  onLoopChanged: (value) => setState(() => _gifLoop = value),
                  onSpeedChanged: (value) => setState(() => _gifSpeed = value),
                  onPreview: _previewGifRange,
                  onCreate: () => _run(
                    const QuickEditorJob(
                      type: QuickEditorJobType.videoToGif,
                      operation: 'video-to-gif',
                      successMessageKey: 'gifCreatedSuccess',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _ReelsShortsCard(
                  sourceName: _selectedVideoFile ?? widget.item.fileName,
                  localFilePath:
                      _selectedVideoPath ?? widget.item.localFilePath,
                  preset: _reelsPreset,
                  resizeMode: _reelsResizeMode,
                  quality: _reelsQuality,
                  mute: _reelsMute,
                  onPickVideo: _pickVideoFile,
                  onPresetChanged: (value) => setState(() {
                    _reelsPreset = value;
                    if (value == 'snapchat') _reelsResizeMode = 'smart_crop';
                  }),
                  onResizeModeChanged: (value) =>
                      setState(() => _reelsResizeMode = value),
                  onQualityChanged: (value) =>
                      setState(() => _reelsQuality = value),
                  onMuteChanged: (value) => setState(() => _reelsMute = value),
                  onCreate: () => _run(
                    const QuickEditorJob(
                      type: QuickEditorJobType.reelsShorts,
                      operation: 'reels-shorts',
                      successMessageKey: 'reelShortCreatedSuccess',
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryGradientButton(
                  label: l.t('convertVideoToMp4'),
                  icon: Icons.ios_share_rounded,
                  isLoading: state.activeJob == QuickEditorJobType.export,
                  onPressed: state.isProcessing
                      ? null
                      : () => _run(
                          const QuickEditorJob(
                            type: QuickEditorJobType.export,
                            operation: 'convert',
                            successMessageKey: 'exportSuccess',
                          ),
                        ),
                ),
              ],
            ),
          ),
            if (state.isProcessing)
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: _ProgressPanel(
                  progress: state.progress,
                  showLargeFileHint: _showLargeProcessingHint(state.activeJob),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCompletedItem(DownloadItemModel item) async {
    try {
      await ref.read(localMediaServiceProvider).openItem(item);
      if (!mounted) return;
      _dismissCompletedItem();
    } on Object {
      if (!mounted) return;
      AppNotification.error(
        context,
        message: AppLocalizations.of(context).t('couldNotOpenFile'),
      );
    }
  }

  void _viewCompletedItemInDownloads() {
    _dismissCompletedItem();
    context.go('/downloads');
  }

  void _dismissCompletedItem() {
    ref.read(quickEditorControllerProvider.notifier).dismissResult();
  }

  ThemeData _editorButtonTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryEnd,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTone.cardSecondary(
            context,
          ).withValues(alpha: 0.88),
          disabledForegroundColor: AppTone.textSecondary(
            context,
          ).withValues(alpha: 0.82),
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryEnd,
          disabledForegroundColor: AppTone.textSecondary(
            context,
          ).withValues(alpha: 0.72),
          side: BorderSide(color: AppColors.primaryEnd.withValues(alpha: 0.56)),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  void _run(QuickEditorJob job) {
    if (ref.read(quickEditorControllerProvider).isProcessing) return;
    final sourceItem = _sourceItemFor(job);
    if (sourceItem.localFilePath.trim().isEmpty) {
      AppNotification.error(
        context,
        message: AppLocalizations.of(context).t('fileMustBeSavedBeforeEdit'),
      );
      return;
    }
    if ((job.type == QuickEditorJobType.trim ||
            job.type == QuickEditorJobType.videoToGif) &&
        !_validTrimRangeFor(job)) {
      AppNotification.warning(
        context,
        message: AppLocalizations.of(context).t('validTrimRange'),
      );
      return;
    }
    if (job.type == QuickEditorJobType.audioSwap &&
        _audioSwapMode == 'replace' &&
        _selectedAudioPath == null) {
      AppNotification.warning(
        context,
        message: AppLocalizations.of(context).t('noAudioSelected'),
      );
      return;
    }
    final controller = ref.read(quickEditorControllerProvider.notifier);
    if (kDebugMode) {
      debugPrint(
        'ApexLoad editor source: fileId=${widget.item.fileId} '
        'downloadUrl=${widget.item.downloadUrl} '
        'localFilePath=${widget.item.localFilePath} '
        'filename=${widget.item.fileName} type=${widget.item.type.name} '
        'platform=${widget.item.platform}',
      );
      if (job.type == QuickEditorJobType.audioSwap) {
        final audioEnd = ((_audioStartPosition + _trimMax).clamp(
          0,
          _selectedAudioDuration ?? _audioStartPosition + _trimMax,
        )).toDouble();
        debugPrint(
          'ApexLoad audio swap: videoDuration=$_trimMax '
          'audioDuration=$_selectedAudioDuration '
          'audioStart=$_audioStartPosition audioEnd=$audioEnd '
          'shortAudioBehavior=$_shortAudioBehavior',
        );
      }
    }
    unawaited(
      controller.runJob(
        job: job,
        sourceItem: sourceItem,
        options: _optionsFor(job),
      ),
    );
  }

  Map<String, Object?> _optionsFor(QuickEditorJob job) {
    return switch (job.type) {
      QuickEditorJobType.trim => {
        'startTime': _trimRange.start,
        'endTime': _trimRange.end,
        'sourceDuration': _trimMax,
      },
      QuickEditorJobType.extractAudio => {
        'format': _audioFormat.toLowerCase(),
        'sourceDuration': _trimMax,
      },
      QuickEditorJobType.compress => {
        'quality': 'medium',
        'sourceDuration': _trimMax,
      },
      QuickEditorJobType.export => {
        'format': 'mp4',
        'quality': AppLocalizations.of(context).t('highestQuality'),
        'sourceDuration': _trimMax,
      },
      QuickEditorJobType.mute => {
        'mute': _removeAudio,
        'sourceDuration': _trimMax,
      },
      QuickEditorJobType.audioSwap => {
        'audioPath': _selectedAudioPath,
        'audioStart': _audioStartPosition,
        'audioEnd': ((_audioStartPosition + _trimMax).clamp(
          0,
          _selectedAudioDuration ?? _audioStartPosition + _trimMax,
        )).toDouble(),
        'videoDuration': _trimMax,
        'audioRangeMode': 'single_start',
        'shortAudioBehavior': _shortAudioBehavior,
        'loopAudio': _shortAudioBehavior == 'loop',
        'audioVolume': _audioVolume,
        'audioStartPosition': _audioStartPosition,
        'removeOriginal': true,
        'keepOriginalSoftly': false,
      },
      QuickEditorJobType.videoToGif => {
        'startTime': _gifRange.start,
        'endTime': _gifRange.end,
        'quality': _gifQuality.toLowerCase(),
        'size': _gifSize.toLowerCase(),
        'fps': _gifFps,
        'loop': _gifLoop,
        'speed': _gifSpeed,
        'sourceDuration': _trimMax,
      },
      QuickEditorJobType.reelsShorts => {
        'preset': _reelsPreset,
        'resizeMode': _reelsResizeMode,
        'quality': _reelsQuality,
        'mute': _reelsMute,
        'sourceDuration': _trimMax,
      },
    };
  }

  DownloadItemModel _sourceItemFor(QuickEditorJob job) {
    if ((job.type == QuickEditorJobType.videoToGif ||
            job.type == QuickEditorJobType.reelsShorts) &&
        _selectedVideoPath != null) {
      return widget.item.copyWith(
        id: '${widget.item.id}_external_source',
        title: _selectedVideoFile ?? widget.item.title,
        fileName: _selectedVideoFile ?? widget.item.fileName,
        localFilePath: _selectedVideoPath,
      );
    }
    return widget.item;
  }

  bool _validTrimRange() {
    return _trimRange.start >= 0 &&
        _trimRange.end > _trimRange.start &&
        (_trimRange.end - _trimRange.start) >= 1 &&
        _trimRange.end <= _trimMax + 0.05;
  }

  bool _validTrimRangeFor(QuickEditorJob job) {
    if (job.type == QuickEditorJobType.videoToGif) {
      return _gifRange.start >= 0 &&
          _gifRange.end > _gifRange.start &&
          (_gifRange.end - _gifRange.start) >= 1 &&
          _gifRange.end <= _trimMax + 0.05;
    }
    return _validTrimRange();
  }

  void _updateTrimDuration(double seconds) {
    if (seconds <= 0 || !mounted) return;
    setState(() {
      _trimMax = seconds;
      final end = _trimRange.end.clamp(1, seconds).toDouble();
      final start = _trimRange.start.clamp(0, end - 1).toDouble();
      _trimRange = RangeValues(start, end);
    });
  }

  Future<void> _pickAudioFile() async {
    try {
      final file = await pickLocalMedia(context, kind: LocalMediaKind.audio);
      final path = file?.path;
      if (file == null || path == null || path.trim().isEmpty) return;
      setState(() {
        _selectedAudioFile = file.name;
        _selectedAudioPath = path;
        _selectedAudioDuration = null;
        _loadingAudioDuration = true;
        _audioStartPosition = 0;
      });
      final duration = await ref
          .read(localEditorServiceProvider)
          .mediaDuration(path);
      if (!mounted) return;
      setState(() {
        _selectedAudioDuration = duration;
        _loadingAudioDuration = false;
      });
    } on Object catch (error, stackTrace) {
      if (isFilePickerCancellation(error)) return;
      if (kDebugMode) {
        debugPrint('Quick Editor audio picker failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (!mounted) return;
      setState(() => _loadingAudioDuration = false);
      AppNotification.error(
        context,
        message: AppLocalizations.of(context).t('couldNotReplaceAudio'),
      );
    }
  }

  Future<void> _pickVideoFile() async {
    try {
      final file = await pickLocalMedia(context, kind: LocalMediaKind.video);
      final path = file?.path;
      if (file == null || path == null || path.trim().isEmpty) return;
      setState(() {
        _selectedVideoFile = file.name;
        _selectedVideoPath = path;
        _selectedVideoSizeLabel = null;
      });
      final sizeLabel = _formatEditorBytes(await file.length());
      if (!mounted) return;
      setState(() => _selectedVideoSizeLabel = sizeLabel);
    } on Object catch (error, stackTrace) {
      if (isFilePickerCancellation(error)) return;
      if (kDebugMode) {
        debugPrint('Quick Editor video picker failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (!mounted) return;
      AppNotification.error(
        context,
        message: AppLocalizations.of(context).t('somethingWentWrong'),
      );
    }
  }

  Future<void> _previewGifRange() async {
    final l = AppLocalizations.of(context);
    if (_gifRange.end - _gifRange.start < 1) {
      AppNotification.warning(context, message: l.t('validTrimRange'));
      return;
    }
    final source = _sourceItemFor(
      const QuickEditorJob(
        type: QuickEditorJobType.videoToGif,
        operation: 'video-to-gif-preview',
        successMessageKey: 'gifCreatedSuccess',
      ),
    );
    try {
      final path = await ref
          .read(activeOperationWakelockServiceProvider)
          .runWithWakelock(
            () => ref
                .read(localEditorServiceProvider)
                .createGifPreview(
                  source: source,
                  startTime: _gifRange.start,
                  endTime: _gifRange.end,
                  fps: _gifFps,
                  size: _gifSize.toLowerCase(),
                ),
            reason: 'quick editor gif preview',
          );
      await ref
          .read(localMediaServiceProvider)
          .openItem(
            source.copyWith(
              id: '${source.id}_gif_preview',
              platform: 'Editor',
              type: DownloadType.image,
              fileName: path.split(RegExp(r'[/\\]')).last,
              localFilePath: path,
            ),
          );
    } on Object {
      if (!mounted) return;
      AppNotification.error(context, message: l.t('couldNotCreateGif'));
    }
  }

  Future<void> _previewAudioSwap() async {
    final l = AppLocalizations.of(context);
    if (_audioSwapMode == 'remove') {
      AppNotification.info(context, message: l.t('removeOriginalAudioOnly'));
      return;
    }
    final audioPath = _selectedAudioPath;
    if (audioPath == null || audioPath.trim().isEmpty) {
      AppNotification.warning(context, message: l.t('noAudioSelected'));
      return;
    }
    if (widget.item.localFilePath.trim().isEmpty) {
      AppNotification.error(context, message: l.t('fileMustBeSavedBeforeEdit'));
      return;
    }
    try {
      final previewPath = await ref
          .read(activeOperationWakelockServiceProvider)
          .runWithWakelock(
            () => ref
                .read(localEditorServiceProvider)
                .createAudioSwapPreview(
                  source: widget.item,
                  audioPath: audioPath,
                  audioStartTime: _audioStartPosition,
                  previewDuration: _previewDurationForAudioSwap,
                ),
            reason: 'quick editor audio swap preview',
          );
      final previewItem = widget.item.copyWith(
        id: '${widget.item.id}_audio_swap_preview',
        title: '${l.t('preview')} ${widget.item.title}',
        platform: 'Editor',
        localFilePath: previewPath,
        fileName: previewPath.split(RegExp(r'[/\\]')).last,
      );
      await ref.read(localMediaServiceProvider).openItem(previewItem);
    } on Object {
      if (!mounted) return;
      AppNotification.error(context, message: l.t('couldNotReplaceAudio'));
    }
  }

  String _friendlyEditorError(AppLocalizations l, String message) {
    final lower = message.toLowerCase();
    if (lower.contains('missing fileid') ||
        lower.contains('original_file_missing') ||
        lower.contains('local_editor_unavailable') ||
        lower.contains('editor_tool_soon') ||
        lower.contains('could_not_replace_audio') ||
        lower.contains('could_not_create_gif') ||
        lower.contains('could_not_create_reel') ||
        lower.contains('invalid_trim_range') ||
        lower.contains('original file could not be found') ||
        lower.contains('source file does not exist') ||
        lower.contains('unsupported') ||
        lower.contains('invalid trim') ||
        lower.contains('api returned') ||
        lower.contains('could_not_edit') ||
        lower.contains('could not edit')) {
      if (lower.contains('original_file_missing') ||
          lower.contains('original file') ||
          lower.contains('source file')) {
        return l.t('originalFileMissing');
      }
      if (lower.contains('local_editor_unavailable') ||
          lower.contains('editor_tool_soon')) {
        return l.t('editorToolSoon');
      }
      if (lower.contains('could_not_replace_audio')) {
        return l.t('couldNotReplaceAudio');
      }
      if (lower.contains('could_not_create_gif')) {
        return l.t('couldNotCreateGif');
      }
      if (lower.contains('could_not_create_reel')) {
        return l.t('couldNotCreateReelShort');
      }
      if (lower.contains('invalid_trim_range')) {
        return l.t('validTrimRange');
      }
      return l.t('couldNotEditFile');
    }
    return message.trim().isEmpty ? l.t('couldNotEditFile') : message;
  }

  double get _previewDurationForAudioSwap {
    final remaining =
        (_selectedAudioDuration ?? _trimMax) - _audioStartPosition;
    return remaining.clamp(1, _trimMax < 12 ? _trimMax : 12).toDouble();
  }

  bool _showLargeProcessingHint(QuickEditorJobType? activeJob) {
    if (activeJob == null) return false;
    final heavyJob = switch (activeJob) {
      QuickEditorJobType.export ||
      QuickEditorJobType.compress ||
      QuickEditorJobType.videoToGif ||
      QuickEditorJobType.reelsShorts ||
      QuickEditorJobType.audioSwap ||
      QuickEditorJobType.trim => true,
      QuickEditorJobType.mute || QuickEditorJobType.extractAudio => false,
    };
    if (!heavyJob) return false;
    final source =
        activeJob == QuickEditorJobType.videoToGif ||
            activeJob == QuickEditorJobType.reelsShorts
        ? _sourceItemFor(
            QuickEditorJob(
              type: activeJob,
              operation: '',
              successMessageKey: '',
            ),
          )
        : widget.item;
    return _hasLargeEditorVideoSignal([
      source.title,
      source.fileName,
      source.sizeLabel,
      source.quality,
      _selectedVideoSizeLabel ?? '',
      _reelsQuality,
    ]);
  }
}

class _VideoInfoCard extends StatelessWidget {
  const _VideoInfoCard({required this.item});

  final DownloadItemModel item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [AppColors.primaryStart, AppColors.primaryEnd],
              ),
            ),
            child: const Icon(
              Icons.movie_filter_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.platform} - 00:32 - ${item.sizeLabel}',
                  style: TextStyle(
                    color: AppTone.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${l.t('format')}: ${_formatLabel(item)}',
                  style: TextStyle(
                    color: AppTone.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLabel(DownloadItemModel item) {
    return switch (item.type) {
      DownloadType.video => 'MP4',
      DownloadType.audio => 'MP3',
      DownloadType.image => 'JPG',
    };
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryEnd.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primaryEnd),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TrimCard extends StatelessWidget {
  const _TrimCard({
    required this.localFilePath,
    required this.range,
    required this.maxDuration,
    required this.onDurationChanged,
    required this.onChanged,
    required this.onApply,
  });

  final String localFilePath;
  final RangeValues range;
  final double maxDuration;
  final ValueChanged<double> onDurationChanged;
  final ValueChanged<RangeValues> onChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final duration = (range.end - range.start).round();
    return _ToolCard(
      icon: Icons.content_cut_rounded,
      title: l.t('trimVideo'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VideoPreviewPanel(
            localFilePath: localFilePath,
            range: range,
            onDurationChanged: onDurationChanged,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${l.t('startTime')}: ${_formatEditorTime(range.start)}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${l.t('endTime')}: ${_formatEditorTime(range.end)}',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: range,
            min: 0,
            max: maxDuration <= 1 ? 1 : maxDuration,
            divisions: maxDuration.round().clamp(1, 600),
            onChanged: (value) {
              if (value.end - value.start < 1) return;
              onChanged(value);
            },
          ),
          Text(
            '${l.t('trimDuration')}: ${_formatEditorTime(duration)}',
            style: TextStyle(color: AppTone.textSecondary(context)),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onApply,
            icon: const Icon(Icons.check_rounded),
            label: Text(l.t('applyTrim')),
          ),
        ],
      ),
    );
  }
}

class _MuteCard extends StatelessWidget {
  const _MuteCard({
    required this.value,
    required this.onChanged,
    required this.onApply,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _ToolCard(
      icon: Icons.volume_off_rounded,
      title: l.t('muteVideo'),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              value: value,
              onChanged: onChanged,
              title: Text(l.t('removeOriginalAudio')),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          FilledButton.icon(
            onPressed: onApply,
            icon: const Icon(Icons.volume_off_rounded),
            label: Text(l.t('applyMute')),
          ),
        ],
      ),
    );
  }
}

class _ExtractAudioCard extends StatelessWidget {
  const _ExtractAudioCard({
    required this.format,
    required this.quality,
    required this.onFormatChanged,
    required this.onQualityChanged,
    required this.onApply,
  });

  final String format;
  final String quality;
  final ValueChanged<String> onFormatChanged;
  final ValueChanged<String> onQualityChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _ToolCard(
      icon: Icons.graphic_eq_rounded,
      title: l.t('extractAudio'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'MP3', label: Text('MP3')),
                ButtonSegment(value: 'M4A', label: Text('M4A')),
              ],
              selected: {format},
              onSelectionChanged: (value) => onFormatChanged(value.first),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'Standard', label: Text(l.t('standard'))),
                ButtonSegment(value: 'High', label: Text(l.t('high'))),
              ],
              selected: {quality},
              onSelectionChanged: (value) => onQualityChanged(value.first),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onApply,
            icon: const Icon(Icons.music_note_rounded),
            label: Text(l.t('extractAudio')),
          ),
        ],
      ),
    );
  }
}

class _AudioSwapCard extends StatelessWidget {
  const _AudioSwapCard({
    required this.videoPath,
    required this.selectedFile,
    required this.mode,
    required this.shortAudioBehavior,
    required this.videoDuration,
    required this.audioDuration,
    required this.loadingAudioDuration,
    required this.startPosition,
    required this.volume,
    required this.onPickAudio,
    required this.onClearAudio,
    required this.onModeChanged,
    required this.onShortBehaviorChanged,
    required this.onStartPositionChanged,
    required this.onVolumeChanged,
    required this.onPreview,
    required this.onApply,
  });

  final String videoPath;
  final String? selectedFile;
  final String mode;
  final String shortAudioBehavior;
  final double videoDuration;
  final double? audioDuration;
  final bool loadingAudioDuration;
  final double startPosition;
  final double volume;
  final VoidCallback onPickAudio;
  final VoidCallback onClearAudio;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<String> onShortBehaviorChanged;
  final ValueChanged<double> onStartPositionChanged;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onPreview;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return _ToolCard(
      icon: Icons.swap_horizontal_circle_rounded,
      title: l.t('audioSwap'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.t('audioSwapDescription'),
            style: TextStyle(color: AppTone.textSecondary(context)),
          ),
          const SizedBox(height: 12),
          Text(
            l.t('videoStep'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          VideoPreviewPanel(
            localFilePath: videoPath,
            range: RangeValues(0, videoDuration <= 1 ? 1 : videoDuration),
            onDurationChanged: (_) {},
          ),
          const SizedBox(height: 8),
          Text(
            '${l.t('videoAudioSwapHelp')} ${l.t('trimDuration')}: ${_formatSeconds(videoDuration)}',
            style: TextStyle(color: AppTone.textSecondary(context)),
          ),
          const SizedBox(height: 12),
          _EditorStepTile(
            number: '1',
            title: l.t('originalAudio'),
            subtitle: mode == 'replace'
                ? l.t('replaceOriginalAudio')
                : l.t('removeOriginalAudioOnly'),
            icon: Icons.movie_filter_rounded,
          ),
          const SizedBox(height: 8),
          _SegmentedString(
            values: const ['replace', 'remove'],
            selected: mode,
            labels: [
              l.t('replaceOriginalAudio'),
              l.t('removeOriginalAudioOnly'),
            ],
            onChanged: onModeChanged,
          ),
          const SizedBox(height: 8),
          if (mode == 'replace') ...[
            _EditorStepTile(
              number: '2',
              title: l.t('chooseNewAudio'),
              subtitle: selectedFile ?? l.t('pickAudioFile'),
              icon: Icons.library_music_rounded,
              trailing: OutlinedButton.icon(
                onPressed: onPickAudio,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(l.t('chooseAudioFile')),
              ),
            ),
            if (selectedFile != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l.t('selectedAudio')}: $selectedFile',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: l.t('delete'),
                    onPressed: onClearAudio,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ],
          ] else
            _EditorStepTile(
              number: '2',
              title: l.t('chooseNewAudio'),
              subtitle: l.t('noNewAudioNeeded'),
              icon: Icons.volume_off_rounded,
            ),
          const SizedBox(height: 8),
          _EditorStepTile(
            number: '3',
            title: l.t('previewAndApply'),
            subtitle: mode == 'replace'
                ? l.t('audioTrimmedToVideoLength')
                : l.t('removeOriginalAudioOnly'),
            icon: Icons.play_circle_fill_rounded,
          ),
          if (mode == 'replace') ...[
            const SizedBox(height: 12),
            Text(
              l.t('audioFormatSupport'),
              style: TextStyle(
                color: AppTone.textSecondary(context),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.t('audioStartPoint'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              l.t('audioStartPointHelp'),
              style: TextStyle(color: AppTone.textSecondary(context)),
            ),
            const SizedBox(height: 10),
            if (loadingAudioDuration)
              const LinearProgressIndicator()
            else
              _AudioStartTimeline(
                audioDuration: audioDuration ?? videoDuration,
                videoDuration: videoDuration,
                startPosition: startPosition,
                onChanged: onStartPositionChanged,
              ),
            Text(
              l.t('audioStartsAtVideoPoint'),
              style: TextStyle(color: AppTone.textSecondary(context)),
            ),
            const SizedBox(height: 10),
            _SegmentedString(
              values: const ['silent', 'loop', 'original'],
              selected: shortAudioBehavior,
              labels: [
                l.t('leaveRemainingVideoSilent'),
                l.t('loopAudioUntilVideoEnds'),
                l.t('keepOriginalAfterAudioEnds'),
              ],
              onChanged: onShortBehaviorChanged,
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(l.t('advancedOptions')),
                children: [
                  Text(
                    '${l.t('audioVolume')}: ${(volume * 100).round()}%',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Slider(value: volume, onChanged: onVolumeChanged),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: mode == 'replace' ? onPreview : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l.t('previewWithNewAudio')),
              ),
              FilledButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.swap_horizontal_circle_rounded),
                label: Text(
                  mode == 'replace' ? l.t('applyAudioSwap') : l.t('applyMute'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSeconds(double value) {
    final total = value.round().clamp(0, 86400);
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _AudioStartTimeline extends StatelessWidget {
  const _AudioStartTimeline({
    required this.audioDuration,
    required this.videoDuration,
    required this.startPosition,
    required this.onChanged,
  });

  final double audioDuration;
  final double videoDuration;
  final double startPosition;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final max = audioDuration <= 1 ? 1.0 : audioDuration;
    final start = startPosition.clamp(0, max).toDouble();
    final end = (start + videoDuration).clamp(0, max).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _MiniInfo(label: l.t('selectedAudio'), value: _formatSeconds(max)),
            _MiniInfo(
              label: l.t('video'),
              value: _formatSeconds(videoDuration),
            ),
            _MiniInfo(label: l.t('audioStart'), value: _formatSeconds(start)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppTone.card(context).withValues(alpha: 0.34),
            border: Border.all(color: AppTone.border(context)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final startX = width * (start / max);
              final endX = width * (end / max);
              return Stack(
                children: [
                  for (var i = 0; i < 32; i++)
                    Positioned(
                      left: (width / 32) * i,
                      top: 10 + (i % 5) * 2,
                      bottom: 10 + ((i + 2) % 5) * 2,
                      child: Container(
                        width: 3,
                        decoration: BoxDecoration(
                          color: AppTone.textSecondary(
                            context,
                          ).withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  Positioned(
                    left: startX,
                    width: (endX - startX).clamp(4, width).toDouble(),
                    top: 8,
                    bottom: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryStart,
                            AppColors.primaryEnd,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (startX - 2).clamp(0, width - 4).toDouble(),
                    top: 4,
                    bottom: 4,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: AppColors.premiumGold,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Slider(
          value: start,
          min: 0,
          max: max,
          divisions: max.round().clamp(1, 1200),
          onChanged: onChanged,
        ),
        Text(
          '${l.t('audioSectionUsed')}: ${_formatSeconds(start)} - ${_formatSeconds(end)}',
          style: TextStyle(color: AppTone.textSecondary(context)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final delta in [-5.0, -1.0, 1.0, 5.0])
              OutlinedButton(
                onPressed: () => onChanged((start + delta).clamp(0, max)),
                child: Text(
                  delta > 0 ? '+${delta.round()}s' : '${delta.round()}s',
                ),
              ),
            TextButton.icon(
              onPressed: () => onChanged(0),
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(l.t('resetSelection')),
            ),
          ],
        ),
      ],
    );
  }

  String _formatSeconds(double value) {
    final total = value.round().clamp(0, 86400);
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.primaryEnd.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.primaryEnd.withValues(alpha: 0.32)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _VideoToGifCard extends StatelessWidget {
  const _VideoToGifCard({
    required this.sourceName,
    required this.localFilePath,
    required this.range,
    required this.maxDuration,
    required this.quality,
    required this.size,
    required this.fps,
    required this.loop,
    required this.speed,
    required this.onPickVideo,
    required this.onRangeChanged,
    required this.onQualityChanged,
    required this.onSizeChanged,
    required this.onFpsChanged,
    required this.onLoopChanged,
    required this.onSpeedChanged,
    required this.onPreview,
    required this.onCreate,
  });

  final String sourceName;
  final String localFilePath;
  final RangeValues range;
  final double maxDuration;
  final String quality;
  final String size;
  final int fps;
  final bool loop;
  final double speed;
  final VoidCallback onPickVideo;
  final ValueChanged<RangeValues> onRangeChanged;
  final ValueChanged<String> onQualityChanged;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<int> onFpsChanged;
  final ValueChanged<bool> onLoopChanged;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onPreview;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final max = maxDuration <= 1 ? 1.0 : maxDuration;

    return _ToolCard(
      icon: Icons.gif_box_rounded,
      title: l.t('videoToGif'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SourcePickerRow(
            title: l.t('chooseVideo'),
            sourceName: sourceName,
            localFilePath: localFilePath,
            onPickVideo: onPickVideo,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l.t('startTime')}: ${_formatEditorTime(range.start)}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${l.t('endTime')}: ${_formatEditorTime(range.end)}',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: range,
            min: 0,
            max: max,
            divisions: max.round().clamp(1, 600),
            onChanged: (value) {
              if (value.end - value.start < 1) return;
              onRangeChanged(value);
            },
          ),
          Text(
            '${l.t('trimDuration')}: ${_formatEditorTime(range.end - range.start)}',
            style: TextStyle(color: AppTone.textSecondary(context)),
          ),
          const SizedBox(height: 12),
          Text(
            l.t('gifSettings'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _SegmentedString(
            values: const ['Standard', 'High'],
            selected: quality,
            labels: [l.t('standard'), l.t('high')],
            onChanged: onQualityChanged,
          ),
          const SizedBox(height: 8),
          _SegmentedString(
            values: const ['Small', 'Medium', 'Original'],
            selected: size,
            labels: [l.t('small'), l.t('medium'), l.t('original')],
            onChanged: onSizeChanged,
          ),
          const SizedBox(height: 10),
          Text(
            '${l.t('fps')}: $fps',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Slider(
            value: fps.toDouble(),
            min: 10,
            max: 20,
            divisions: 10,
            onChanged: (value) => onFpsChanged(value.round()),
          ),
          Text(
            '${l.t('speed')}: ${speed.toStringAsFixed(1)}x',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Slider(
            value: speed,
            min: 0.5,
            max: 2,
            divisions: 6,
            onChanged: onSpeedChanged,
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              value: loop,
              onChanged: onLoopChanged,
              title: Text(l.t('loop')),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onPreview,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l.t('previewGifRange')),
              ),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.gif_rounded),
                label: Text(l.t('createGif')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReelsShortsCard extends StatelessWidget {
  const _ReelsShortsCard({
    required this.sourceName,
    required this.localFilePath,
    required this.preset,
    required this.resizeMode,
    required this.quality,
    required this.mute,
    required this.onPickVideo,
    required this.onPresetChanged,
    required this.onResizeModeChanged,
    required this.onQualityChanged,
    required this.onMuteChanged,
    required this.onCreate,
  });

  final String sourceName;
  final String localFilePath;
  final String preset;
  final String resizeMode;
  final String quality;
  final bool mute;
  final VoidCallback onPickVideo;
  final ValueChanged<String> onPresetChanged;
  final ValueChanged<String> onResizeModeChanged;
  final ValueChanged<String> onQualityChanged;
  final ValueChanged<bool> onMuteChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _ToolCard(
      icon: Icons.smart_display_rounded,
      title: l.t('reelsShortsCreator'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SourcePickerRow(
            title: l.t('chooseVideo'),
            sourceName: sourceName,
            localFilePath: localFilePath,
            onPickVideo: onPickVideo,
          ),
          const SizedBox(height: 12),
          Text(
            l.t('choosePlatform'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            l.t('platformPresetHelp'),
            style: TextStyle(color: AppTone.textSecondary(context)),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width < 430 ? 2 : 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.92,
            children: [
              _PlatformPresetCard(
                selected: preset == 'instagram',
                icon: Icons.camera_alt_rounded,
                title: l.t('instagramReel'),
                badge: l
                    .t('readyForPlatform')
                    .replaceFirst('{platform}', 'Instagram'),
                onTap: () => onPresetChanged('instagram'),
              ),
              _PlatformPresetCard(
                selected: preset == 'youtube',
                icon: Icons.play_circle_fill_rounded,
                title: l.t('youtubeShort'),
                badge: l
                    .t('readyForPlatform')
                    .replaceFirst('{platform}', 'YouTube'),
                onTap: () => onPresetChanged('youtube'),
              ),
              _PlatformPresetCard(
                selected: preset == 'tiktok',
                icon: Icons.music_video_rounded,
                title: l.t('tiktokVideo'),
                badge: l
                    .t('readyForPlatform')
                    .replaceFirst('{platform}', 'TikTok'),
                onTap: () => onPresetChanged('tiktok'),
              ),
              _PlatformPresetCard(
                selected: preset == 'snapchat',
                icon: Icons.flash_on_rounded,
                title: l.t('snapchatSpotlight'),
                badge: l
                    .t('readyForPlatform')
                    .replaceFirst('{platform}', 'Snapchat'),
                onTap: () => onPresetChanged('snapchat'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SafeZonePreview(preset: preset),
          const SizedBox(height: 8),
          Text(
            l.t('safeZoneHelp'),
            style: TextStyle(
              color: AppTone.textSecondary(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l.t('resizeMode'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _SegmentedString(
            values: const ['smart_crop', 'fit_blur', 'fit_solid'],
            selected: resizeMode,
            labels: [
              l.t('smartCrop'),
              l.t('fitWithBlurredBackground'),
              l.t('fitWithSolidBackground'),
            ],
            onChanged: onResizeModeChanged,
          ),
          const SizedBox(height: 6),
          Text(
            resizeMode == 'smart_crop'
                ? l.t('smartCropHelp')
                : l.t('blurredBackgroundHelp'),
            style: TextStyle(
              color: AppTone.textSecondary(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          _SegmentedString(
            values: const ['low', 'medium', 'high'],
            selected: quality,
            labels: [l.t('smallFile'), l.t('balanced'), l.t('highQuality')],
            onChanged: onQualityChanged,
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              value: mute,
              onChanged: onMuteChanged,
              title: Text(l.t('removeOriginalAudio')),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          Text(
            l.t('reelsShortsOutputNote'),
            style: TextStyle(
              color: AppTone.textSecondary(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.auto_awesome_motion_rounded),
            label: Text(_createLabel(l, preset)),
          ),
        ],
      ),
    );
  }

  String _createLabel(AppLocalizations l, String preset) {
    return switch (preset) {
      'youtube' => l.t('createYouTubeShort'),
      'tiktok' => l.t('createTikTokVideo'),
      'snapchat' => l.t('createSnapchatSpotlight'),
      _ => l.t('createInstagramReel'),
    };
  }
}

class _PlatformPresetCard extends StatelessWidget {
  const _PlatformPresetCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.badge,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primaryEnd : AppTone.border(context),
            width: selected ? 1.8 : 1,
          ),
          color: selected
              ? AppColors.primaryEnd.withValues(alpha: 0.14)
              : AppTone.card(context).withValues(alpha: 0.32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected
                  ? AppColors.primaryEnd
                  : AppTone.textSecondary(context),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text('9:16 · 1080x1920', style: TextStyle(fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              badge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTone.textSecondary(context),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafeZonePreview extends StatelessWidget {
  const _SafeZonePreview({required this.preset});

  final String preset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 260,
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF18213A), Color(0xFF0B1020)],
              ),
              border: Border.all(color: AppTone.border(context)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 110,
                      height: 170,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryEnd,
                          width: 2,
                        ),
                        color: AppColors.primaryEnd.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  top: 22,
                  left: 18,
                  right: 18,
                  child: _SafeZoneBar(),
                ),
                Positioned(
                  right: preset == 'tiktok' ? 14 : 18,
                  top: 92,
                  child: Column(
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        const CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.white54,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
                const Positioned(
                  left: 18,
                  right: 18,
                  bottom: 24,
                  child: _SafeZoneBar(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SafeZoneBar extends StatelessWidget {
  const _SafeZoneBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white24),
      ),
    );
  }
}

class _SourcePickerRow extends StatelessWidget {
  const _SourcePickerRow({
    required this.title,
    required this.sourceName,
    required this.localFilePath,
    required this.onPickVideo,
  });

  final String title;
  final String sourceName;
  final String localFilePath;
  final VoidCallback onPickVideo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTone.border(context)),
        color: AppTone.card(context).withValues(alpha: 0.36),
      ),
      child: Row(
        children: [
          const Icon(Icons.video_file_rounded, color: AppColors.primaryEnd),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  localFilePath.trim().isEmpty
                      ? l.t('fileMustBeSavedBeforeEdit')
                      : sourceName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTone.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onPickVideo,
            icon: const Icon(Icons.folder_open_rounded),
            label: Text(l.t('chooseVideo')),
          ),
        ],
      ),
    );
  }
}

class _EditorStepTile extends StatelessWidget {
  const _EditorStepTile({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
  });

  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stackAction =
            trailing != null &&
            (constraints.maxWidth < 500 || textScale > 1.15);

        Widget buildHeader() => Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryEnd.withValues(alpha: 0.18),
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.primaryEnd,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: AppColors.primaryEnd),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTone.textSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTone.border(context)),
            color: AppTone.card(context).withValues(alpha: 0.36),
          ),
          child: stackAction
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildHeader(),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: trailing),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: buildHeader()),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _SegmentedString extends StatelessWidget {
  const _SegmentedString({
    required this.values,
    required this.selected,
    required this.labels,
    required this.onChanged,
  });

  final List<String> values;
  final String selected;
  final List<String> labels;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<String>(
        segments: [
          for (var i = 0; i < values.length; i++)
            ButtonSegment(value: values[i], label: Text(labels[i])),
        ],
        selected: {selected},
        onSelectionChanged: (value) => onChanged(value.first),
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({
    required this.progress,
    required this.showLargeFileHint,
  });

  final double progress;
  final bool showLargeFileHint;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(l.t('processingEditor'))),
              Text('${(progress * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress),
          const ActiveOperationNote(),
          if (showLargeFileHint) ...[
            const SizedBox(height: 10),
            _EditorLargeFileInfoCard(
              title: l.t('processingLargeVideo'),
              message: l.t('largeVideoProcessingMessage'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditorLargeFileInfoCard extends StatelessWidget {
  const _EditorLargeFileInfoCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryEnd.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryEnd.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_rounded, color: AppColors.primaryEnd, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: AppTone.textSecondary(context),
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
