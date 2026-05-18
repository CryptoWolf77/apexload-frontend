enum QuickEditorJobType {
  trim,
  mute,
  extractAudio,
  audioSwap,
  compress,
  export,
}

class QuickEditorJob {
  const QuickEditorJob({required this.type, required this.successMessageKey});

  final QuickEditorJobType type;
  final String successMessageKey;
}
