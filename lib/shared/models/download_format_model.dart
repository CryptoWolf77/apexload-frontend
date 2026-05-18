enum DownloadType { video, audio, image }

class DownloadFormatModel {
  const DownloadFormatModel({
    required this.id,
    required this.label,
    required this.extension,
    required this.type,
    required this.isPremium,
    required this.sizeLabel,
    this.isAvailable = true,
    this.unavailableReasonKey,
  });

  final String id;
  final String label;
  final String extension;
  final DownloadType type;
  final bool isPremium;
  final String sizeLabel;
  final bool isAvailable;
  final String? unavailableReasonKey;
}
