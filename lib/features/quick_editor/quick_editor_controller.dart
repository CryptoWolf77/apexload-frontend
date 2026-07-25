import 'dart:async';

import 'package:apexload/features/quick_editor/quick_editor_models.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final quickEditorControllerProvider =
    NotifierProvider.autoDispose<QuickEditorController, QuickEditorState>(
      QuickEditorController.new,
    );

class QuickEditorState {
  const QuickEditorState({
    this.activeJob,
    this.progress = 0,
    this.successMessageKey,
    this.errorMessage,
    this.completedItem,
  });

  final QuickEditorJobType? activeJob;
  final double progress;
  final String? successMessageKey;
  final String? errorMessage;
  final DownloadItemModel? completedItem;

  bool get isProcessing => activeJob != null;

  QuickEditorState copyWith({
    QuickEditorJobType? activeJob,
    double? progress,
    String? successMessageKey,
    String? errorMessage,
    DownloadItemModel? completedItem,
    bool clearJob = false,
    bool clearMessage = false,
    bool clearCompletedFile = false,
  }) {
    return QuickEditorState(
      activeJob: clearJob ? null : activeJob ?? this.activeJob,
      progress: progress ?? this.progress,
      successMessageKey: clearMessage
          ? null
          : successMessageKey ?? this.successMessageKey,
      errorMessage: clearMessage ? null : errorMessage ?? this.errorMessage,
      completedItem: clearCompletedFile
          ? null
          : completedItem ?? this.completedItem,
    );
  }
}

class QuickEditorController extends Notifier<QuickEditorState> {
  var _cancelled = false;

  @override
  QuickEditorState build() {
    ref.onDispose(() => _cancelled = true);
    return const QuickEditorState();
  }

  Future<void> runJob({
    required QuickEditorJob job,
    required DownloadItemModel sourceItem,
    required Map<String, Object?> options,
  }) async {
    _cancelled = false;
    state = QuickEditorState(activeJob: job.type);

    try {
      state = state.copyWith(progress: 0.12, clearMessage: true);
      final service = ref.read(localEditorServiceProvider);
      final completed = await ref
          .read(activeOperationWakelockServiceProvider)
          .runWithWakelock(
            () => service.runJob(
              source: sourceItem,
              job: job,
              options: options,
              onProgress: (progress) {
                if (_cancelled) return;
                state = state.copyWith(progress: progress.clamp(0.04, 0.98));
              },
            ),
            reason: 'quick editor ${job.operation}',
          );
      if (_cancelled) return;
      state = QuickEditorState(
        progress: 1,
        successMessageKey: job.successMessageKey,
        completedItem: completed,
      );
    } on Object catch (error) {
      state = QuickEditorState(errorMessage: error.toString());
    }
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true, progress: 0);
  }

  void dismissResult() {
    state = state.copyWith(
      clearMessage: true,
      clearCompletedFile: true,
      progress: 0,
    );
  }
}
