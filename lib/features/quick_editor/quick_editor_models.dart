enum QuickEditorJobType {
  trim,
  mute,
  extractAudio,
  audioSwap,
  videoToGif,
  reelsShorts,
  compress,
  export,
}

class QuickEditorJob {
  const QuickEditorJob({
    required this.type,
    required this.operation,
    required this.successMessageKey,
  });

  final QuickEditorJobType type;
  final String operation;
  final String successMessageKey;
}
