import 'package:apexload/shared/models/download_format_model.dart';

class DownloadItemModel {
  const DownloadItemModel({
    required this.id,
    required this.title,
    required this.platform,
    required this.date,
    required this.sizeLabel,
    required this.type,
    required this.thumbnailUrl,
    required this.fileName,
    this.fileId = '',
    this.downloadUrl = '',
  });

  final String id;
  final String title;
  final String platform;
  final DateTime date;
  final String sizeLabel;
  final DownloadType type;
  final String thumbnailUrl;
  final String fileName;
  final String fileId;
  final String downloadUrl;

  DownloadItemModel copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? sizeLabel,
    String? fileName,
    String? fileId,
    String? downloadUrl,
  }) {
    return DownloadItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      platform: platform,
      date: date ?? this.date,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      type: type,
      thumbnailUrl: thumbnailUrl,
      fileName: fileName ?? this.fileName,
      fileId: fileId ?? this.fileId,
      downloadUrl: downloadUrl ?? this.downloadUrl,
    );
  }
}
