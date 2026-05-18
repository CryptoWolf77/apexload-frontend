import 'dart:async';

import 'package:apexload/features/quick_editor/quick_editor_models.dart';
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
  });

  final QuickEditorJobType? activeJob;
  final double progress;
  final String? successMessageKey;

  bool get isProcessing => activeJob != null;

  QuickEditorState copyWith({
    QuickEditorJobType? activeJob,
    double? progress,
    String? successMessageKey,
    bool clearJob = false,
    bool clearMessage = false,
  }) {
    return QuickEditorState(
      activeJob: clearJob ? null : activeJob ?? this.activeJob,
      progress: progress ?? this.progress,
      successMessageKey: clearMessage
          ? null
          : successMessageKey ?? this.successMessageKey,
    );
  }
}

class QuickEditorController extends Notifier<QuickEditorState> {
  Timer? _timer;

  @override
  QuickEditorState build() {
    ref.onDispose(() => _timer?.cancel());
    return const QuickEditorState();
  }

  void runMockJob(QuickEditorJob job) {
    _timer?.cancel();
    state = QuickEditorState(activeJob: job.type);

    _timer = Timer.periodic(const Duration(milliseconds: 180), (timer) {
      final next = (state.progress + 0.08).clamp(0, 1).toDouble();
      if (next >= 1) {
        timer.cancel();
        state = QuickEditorState(
          progress: 1,
          successMessageKey: job.successMessageKey,
        );
        return;
      }
      state = state.copyWith(progress: next, clearMessage: true);
    });
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true, progress: 0);
  }
}
