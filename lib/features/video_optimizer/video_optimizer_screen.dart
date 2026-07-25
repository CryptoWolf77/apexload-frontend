import 'dart:async';

import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/features/quick_editor/editor_completion_panel.dart';
import 'package:apexload/features/quick_editor/quick_editor_controller.dart';
import 'package:apexload/features/quick_editor/quick_editor_models.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
import 'package:apexload/shared/widgets/primary_gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VideoOptimizerScreen extends ConsumerStatefulWidget {
  const VideoOptimizerScreen({super.key, required this.item});

  final DownloadItemModel item;

  @override
  ConsumerState<VideoOptimizerScreen> createState() =>
      _VideoOptimizerScreenState();
}

class _VideoOptimizerScreenState extends ConsumerState<VideoOptimizerScreen> {
  final ScrollController _scrollController = ScrollController();
  var _preset = 'balanced';
  var _format = 'mp4';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(quickEditorControllerProvider);
    ref.listen<QuickEditorState>(quickEditorControllerProvider, (
      previous,
      next,
    ) {
      if (next.errorMessage != null &&
          previous?.errorMessage != next.errorMessage) {
        AppNotification.error(context, message: l.t('couldNotEditFile'));
        ref.read(quickEditorControllerProvider.notifier).clearMessage();
      }
      if (next.successMessageKey != null &&
          previous?.successMessageKey != next.successMessageKey) {
        final item = next.completedItem;
        if (item != null) {
          ref.read(libraryControllerProvider.notifier).add(item);
        }
        AppNotification.success(context, message: l.t(next.successMessageKey!));
        ref.read(quickEditorControllerProvider.notifier).clearMessage();
        _revealCompletion();
      }
    });

    return GradientScaffold(
      appBar: AppBar(
        title: Text(l.t('videoOptimizer')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
        children: [
          Text(
            l.t('videoOptimizer'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            l.t('videoOptimizerSubtitle'),
            style: TextStyle(color: AppTone.textSecondary(context)),
          ),
          const SizedBox(height: 16),
          if (state.completedItem != null) ...[
            EditorCompletionPanel(
              item: state.completedItem!,
              onOpen: () => _openCompletedItem(state.completedItem!),
              onViewDownloads: _viewCompletedItemInDownloads,
              onDismiss: _dismissCompletedItem,
            ),
            const SizedBox(height: 16),
          ],
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.item.platform}  ${widget.item.fileName}',
                  style: TextStyle(color: AppTone.textSecondary(context)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.t('optimizerPreset'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    selected: {_preset},
                    segments: [
                      ButtonSegment(
                        value: 'low',
                        label: Text(l.t('smallFile')),
                      ),
                      ButtonSegment(
                        value: 'balanced',
                        label: Text(l.t('balanced')),
                      ),
                      ButtonSegment(
                        value: 'high',
                        label: Text(l.t('highestQuality')),
                      ),
                    ],
                    onSelectionChanged: (value) =>
                        setState(() => _preset = value.first),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.t('chooseOutputFormat'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  selected: {_format},
                  segments: const [
                    ButtonSegment(value: 'mp4', label: Text('MP4')),
                  ],
                  onSelectionChanged: (value) =>
                      setState(() => _format = value.first),
                ),
                const SizedBox(height: 14),
                Text(
                  l.t('optimizerLocalOnly'),
                  style: TextStyle(color: AppTone.textSecondary(context)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PrimaryGradientButton(
            label: l.t('optimizeVideo'),
            icon: Icons.tune_rounded,
            isLoading: state.isProcessing,
            onPressed: state.isProcessing ? null : _runOptimizer,
          ),
          if (state.isProcessing) ...[
            const SizedBox(height: 18),
            LinearProgressIndicator(value: state.progress.clamp(0, 1)),
          ],
        ],
      ),
    );
  }

  void _revealCompletion() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      unawaited(
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        ),
      );
    });
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

  void _runOptimizer() {
    final job = _format == 'mp4'
        ? const QuickEditorJob(
            type: QuickEditorJobType.compress,
            operation: 'optimize',
            successMessageKey: 'optimizerSuccess',
          )
        : const QuickEditorJob(
            type: QuickEditorJobType.export,
            operation: 'convert',
            successMessageKey: 'exportSuccess',
          );
    unawaited(
      ref
          .read(quickEditorControllerProvider.notifier)
          .runJob(
            job: job,
            sourceItem: widget.item,
            options: {'quality': _preset, 'format': _format},
          ),
    );
  }
}
