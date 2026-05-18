import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/features/quick_editor/quick_editor_controller.dart';
import 'package:apexload/features/quick_editor/quick_editor_models.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
import 'package:apexload/shared/widgets/primary_gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuickEditorScreen extends ConsumerStatefulWidget {
  const QuickEditorScreen({super.key, required this.item});

  final DownloadItemModel item;

  @override
  ConsumerState<QuickEditorScreen> createState() => _QuickEditorScreenState();
}

class _QuickEditorScreenState extends ConsumerState<QuickEditorScreen> {
  RangeValues _trimRange = const RangeValues(4, 24);
  var _removeAudio = true;
  var _audioFormat = 'MP3';
  var _audioQuality = 'Standard';
  String? _selectedAudioFile;
  RangeValues _audioSwapRange = const RangeValues(0, 20);
  var _audioStartPosition = 0.0;
  var _removeOriginalForSwap = true;
  var _keepOriginalSoftly = false;
  var _audioVolume = 0.82;
  var _compression = 'Balanced';
  var _exportQuality = 'Highest quality';
  var _saveToGallery = true;
  var _noWatermark = true;
  var _exportAdded = false;

  // TODO: Real Quick Editor processing should be implemented locally on the
  // device, not through the VPS. Future local processing tasks: trim video
  // locally, mute video locally, extract audio locally, compress video locally,
  // export edited video locally, and save edited files to the phone gallery or
  // local library. Do not send user videos to the VPS for Quick Editor work.
  // TODO: Real Audio Swap should be processed locally on the phone/device.
  // TODO: Do not upload user video or selected audio to the VPS for editing.
  // TODO: Future implementation can use local/native video processing packages.

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(quickEditorControllerProvider);
    ref.listen<QuickEditorState>(quickEditorControllerProvider, (
      previous,
      next,
    ) {
      final messageKey = next.successMessageKey;
      if (messageKey != null && previous?.successMessageKey != messageKey) {
        if (messageKey == 'exportSuccess' && !_exportAdded) {
          final edited = widget.item.copyWith(
            id: '${widget.item.id}_edited_${DateTime.now().millisecondsSinceEpoch}',
            title: '${widget.item.title} (Edited)',
            date: DateTime.now(),
            fileName: _editedFileName(widget.item.fileName),
          );
          ref.read(libraryControllerProvider.notifier).add(edited);
          _exportAdded = true;
        }
        AppNotification.success(context, message: l.t(messageKey));
        ref.read(quickEditorControllerProvider.notifier).clearMessage();
      }
    });

    return GradientScaffold(
      appBar: AppBar(
        title: Text(l.t('quickEditor')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 104),
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
              const SizedBox(height: 14),
              _TrimCard(
                range: _trimRange,
                onChanged: (value) => setState(() => _trimRange = value),
                onApply: () => _run(
                  const QuickEditorJob(
                    type: QuickEditorJobType.trim,
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
                    successMessageKey: 'audioExtractedSuccess',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _AudioSwapCard(
                selectedFile: _selectedAudioFile,
                range: _audioSwapRange,
                startPosition: _audioStartPosition,
                removeOriginal: _removeOriginalForSwap,
                keepOriginalSoftly: _keepOriginalSoftly,
                volume: _audioVolume,
                onPickAudio: () =>
                    setState(() => _selectedAudioFile = 'my_audio_track.mp3'),
                onRangeChanged: (value) =>
                    setState(() => _audioSwapRange = value),
                onStartPositionChanged: (value) =>
                    setState(() => _audioStartPosition = value),
                onRemoveOriginalChanged: (value) =>
                    setState(() => _removeOriginalForSwap = value),
                onKeepOriginalChanged: (value) =>
                    setState(() => _keepOriginalSoftly = value),
                onVolumeChanged: (value) =>
                    setState(() => _audioVolume = value),
                onPreview: () => AppNotification.info(
                  context,
                  message: l.t('demoPreviewReady'),
                ),
                onApply: () {
                  if (_selectedAudioFile == null) {
                    AppNotification.warning(
                      context,
                      message: l.t('noAudioSelected'),
                    );
                    return;
                  }
                  _run(
                    const QuickEditorJob(
                      type: QuickEditorJobType.audioSwap,
                      successMessageKey: 'audioReplacedSuccess',
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _CompressCard(
                value: _compression,
                onChanged: (value) => setState(() => _compression = value),
                onApply: () => _run(
                  const QuickEditorJob(
                    type: QuickEditorJobType.compress,
                    successMessageKey: 'compressSuccess',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ExportSettingsCard(
                quality: _exportQuality,
                saveToGallery: _saveToGallery,
                noWatermark: _noWatermark,
                onQualityChanged: (value) =>
                    setState(() => _exportQuality = value),
                onSaveChanged: (value) =>
                    setState(() => _saveToGallery = value),
                onWatermarkChanged: (value) =>
                    setState(() => _noWatermark = value),
              ),
              const SizedBox(height: 18),
              PrimaryGradientButton(
                label: l.t('exportEditedVideo'),
                icon: Icons.ios_share_rounded,
                isLoading: state.activeJob == QuickEditorJobType.export,
                onPressed: state.isProcessing
                    ? null
                    : () => _run(
                        const QuickEditorJob(
                          type: QuickEditorJobType.export,
                          successMessageKey: 'exportSuccess',
                        ),
                      ),
              ),
            ],
          ),
          if (state.isProcessing)
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: _ProgressPanel(progress: state.progress),
            ),
        ],
      ),
    );
  }

  void _run(QuickEditorJob job) {
    if (job.type == QuickEditorJobType.export) {
      _exportAdded = false;
    }
    final controller = ref.read(quickEditorControllerProvider.notifier);
    controller.runMockJob(job);
  }

  String _editedFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0) {
      return '${fileName}_edited.mp4';
    }
    return '${fileName.substring(0, dot)}_edited${fileName.substring(dot)}';
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
    required this.range,
    required this.onChanged,
    required this.onApply,
  });

  final RangeValues range;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${l.t('startTime')}: 00:${range.start.round().toString().padLeft(2, '0')}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${l.t('endTime')}: 00:${range.end.round().toString().padLeft(2, '0')}',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: range,
            min: 0,
            max: 32,
            divisions: 32,
            onChanged: onChanged,
          ),
          Text(
            '${l.t('trimDuration')}: $duration ${l.t('seconds')}',
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
          SwitchListTile(
            value: value,
            onChanged: onChanged,
            title: Text(l.t('removeOriginalAudio')),
            contentPadding: EdgeInsets.zero,
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

class _CompressCard extends StatelessWidget {
  const _CompressCard({
    required this.value,
    required this.onChanged,
    required this.onApply,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _ToolCard(
      icon: Icons.compress_rounded,
      title: l.t('compressVideo'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'Small file',
                  label: Text(l.t('smallFile')),
                ),
                ButtonSegment(value: 'Balanced', label: Text(l.t('balanced'))),
                ButtonSegment(
                  value: 'High quality',
                  label: Text(l.t('highQuality')),
                ),
              ],
              selected: {value},
              onSelectionChanged: (value) => onChanged(value.first),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l.t('estimatedReduction'),
            style: TextStyle(color: AppTone.textSecondary(context)),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onApply,
            icon: const Icon(Icons.compress_rounded),
            label: Text(l.t('compress')),
          ),
        ],
      ),
    );
  }
}

class _AudioSwapCard extends StatelessWidget {
  const _AudioSwapCard({
    required this.selectedFile,
    required this.range,
    required this.startPosition,
    required this.removeOriginal,
    required this.keepOriginalSoftly,
    required this.volume,
    required this.onPickAudio,
    required this.onRangeChanged,
    required this.onStartPositionChanged,
    required this.onRemoveOriginalChanged,
    required this.onKeepOriginalChanged,
    required this.onVolumeChanged,
    required this.onPreview,
    required this.onApply,
  });

  final String? selectedFile;
  final RangeValues range;
  final double startPosition;
  final bool removeOriginal;
  final bool keepOriginalSoftly;
  final double volume;
  final VoidCallback onPickAudio;
  final ValueChanged<RangeValues> onRangeChanged;
  final ValueChanged<double> onStartPositionChanged;
  final ValueChanged<bool> onRemoveOriginalChanged;
  final ValueChanged<bool> onKeepOriginalChanged;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onPreview;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final trimDuration = (range.end - range.start).round();

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
          OutlinedButton.icon(
            onPressed: onPickAudio,
            icon: const Icon(Icons.library_music_rounded),
            label: Text(l.t('pickAudioFile')),
          ),
          const SizedBox(height: 8),
          Text(
            '${l.t('selectedAudio')}: ${selectedFile ?? '-'}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            l.t('audioFormatSupport'),
            style: TextStyle(
              color: AppTone.textSecondary(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l.t('startTime')}: 00:${range.start.round().toString().padLeft(2, '0')}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${l.t('endTime')}: 00:${range.end.round().toString().padLeft(2, '0')}',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: range,
            min: 0,
            max: 32,
            divisions: 32,
            onChanged: onRangeChanged,
          ),
          Text(
            '${l.t('trimDuration')}: $trimDuration ${l.t('seconds')}',
            style: TextStyle(color: AppTone.textSecondary(context)),
          ),
          const SizedBox(height: 12),
          Text(
            '${l.t('audioStartPosition')}: 00:${startPosition.round().toString().padLeft(2, '0')}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Slider(
            value: startPosition,
            min: 0,
            max: 32,
            divisions: 32,
            onChanged: onStartPositionChanged,
          ),
          SwitchListTile(
            value: removeOriginal,
            onChanged: onRemoveOriginalChanged,
            title: Text(l.t('removeOriginalSound')),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: keepOriginalSoftly,
            onChanged: onKeepOriginalChanged,
            title: Text(l.t('keepOriginalSoundSoftly')),
            contentPadding: EdgeInsets.zero,
          ),
          Text(
            '${l.t('audioVolume')}: ${(volume * 100).round()}%',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Slider(value: volume, onChanged: onVolumeChanged),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onPreview,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l.t('preview')),
              ),
              FilledButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.swap_horizontal_circle_rounded),
                label: Text(l.t('applyAudioSwap')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExportSettingsCard extends StatelessWidget {
  const _ExportSettingsCard({
    required this.quality,
    required this.saveToGallery,
    required this.noWatermark,
    required this.onQualityChanged,
    required this.onSaveChanged,
    required this.onWatermarkChanged,
  });

  final String quality;
  final bool saveToGallery;
  final bool noWatermark;
  final ValueChanged<String> onQualityChanged;
  final ValueChanged<bool> onSaveChanged;
  final ValueChanged<bool> onWatermarkChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _ToolCard(
      icon: Icons.tune_rounded,
      title: l.t('exportSettings'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'Standard', label: Text(l.t('standard'))),
                ButtonSegment(
                  value: 'Highest quality',
                  label: Text(l.t('highestQuality')),
                ),
              ],
              selected: {quality},
              onSelectionChanged: (value) => onQualityChanged(value.first),
            ),
          ),
          SwitchListTile(
            value: saveToGallery,
            onChanged: onSaveChanged,
            title: Text(l.t('saveToGallery')),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: noWatermark,
            onChanged: onWatermarkChanged,
            title: Text(l.t('noWatermarkWhenAvailable')),
            subtitle: Text(
              l.t('noWatermarkNote'),
              style: TextStyle(color: AppTone.textSecondary(context)),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.progress});

  final double progress;

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
              Expanded(child: Text(l.t('processingLocally'))),
              Text('${(progress * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }
}
