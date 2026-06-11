import 'package:apexload/shared/models/download_format_model.dart';

class WhatsAppStatusItem {
  const WhatsAppStatusItem({
    required this.id,
    required this.title,
    required this.sourcePath,
    required this.fileName,
    required this.type,
    required this.sizeLabel,
    required this.modifiedAt,
    required this.duplicateKey,
    this.thumbnailPath = '',
    this.duration = '',
    this.isSaved = false,
  });

  final String id;
  final String title;
  final String sourcePath;
  final String fileName;
  final DownloadType type;
  final String sizeLabel;
  final DateTime modifiedAt;
  final String duplicateKey;
  final String thumbnailPath;
  final String duration;
  final bool isSaved;

  WhatsAppStatusItem copyWith({String? thumbnailPath, bool? isSaved}) {
    return WhatsAppStatusItem(
      id: id,
      title: title,
      sourcePath: sourcePath,
      fileName: fileName,
      type: type,
      sizeLabel: sizeLabel,
      modifiedAt: modifiedAt,
      duplicateKey: duplicateKey,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      duration: duration,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

enum WhatsAppStatusConnectionState {
  detecting,
  connectedAutomatic,
  setupRequired,
  validating,
  connectedNoStatuses,
  wrongFolder,
  permissionRequired,
  permissionRevoked,
  folderNotFound,
  noStatusesFound,
}

class WhatsAppStatusSource {
  const WhatsAppStatusSource({
    required this.id,
    required this.label,
    required this.business,
    required this.state,
    this.folderPath,
    this.installed = false,
  });

  final String id;
  final String label;
  final bool business;
  final WhatsAppStatusConnectionState state;
  final String? folderPath;
  final bool installed;

  bool get connected =>
      (state == WhatsAppStatusConnectionState.connectedAutomatic ||
          state == WhatsAppStatusConnectionState.connectedNoStatuses) &&
      folderPath != null;

  WhatsAppStatusSource copyWith({
    WhatsAppStatusConnectionState? state,
    String? folderPath,
    bool? installed,
  }) {
    return WhatsAppStatusSource(
      id: id,
      label: label,
      business: business,
      state: state ?? this.state,
      folderPath: folderPath ?? this.folderPath,
      installed: installed ?? this.installed,
    );
  }
}
