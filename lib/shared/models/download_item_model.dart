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
    this.localFilePath = '',
    this.thumbnailPath = '',
    this.duration = '',
    this.quality = '',
    this.isEdited = false,
    this.galleryUri = '',
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
  final String localFilePath;
  final String thumbnailPath;
  final String duration;
  final String quality;
  final bool isEdited;
  final String galleryUri;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'platform': platform,
      'type': type.name,
      'filename': fileName,
      'fileName': fileName,
      'fileId': fileId,
      'downloadUrl': downloadUrl,
      'localFilePath': localFilePath,
      'thumbnailPath': thumbnailPath,
      'size': sizeLabel,
      'sizeLabel': sizeLabel,
      'duration': duration,
      'quality': quality,
      'createdAt': date.toIso8601String(),
      'date': date.toIso8601String(),
      'thumbnailUrl': thumbnailUrl,
      'isEdited': isEdited,
      'galleryUri': galleryUri,
    };
  }

  factory DownloadItemModel.fromJson(Map<String, Object?> json) {
    final rawType = '${json['type'] ?? ''}'.toLowerCase();
    final type = DownloadType.values.firstWhere(
      (value) => value.name == rawType,
      orElse: () => DownloadType.video,
    );
    final createdAt = DateTime.tryParse(
      '${json['createdAt'] ?? json['date'] ?? ''}',
    );
    return DownloadItemModel(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? json['fileName'] ?? json['filename'] ?? ''}',
      platform: '${json['platform'] ?? ''}',
      date: createdAt ?? DateTime.now(),
      sizeLabel: '${json['sizeLabel'] ?? json['size'] ?? ''}',
      type: type,
      thumbnailUrl: '${json['thumbnailUrl'] ?? ''}',
      fileName: '${json['fileName'] ?? json['filename'] ?? ''}',
      fileId: '${json['fileId'] ?? ''}',
      downloadUrl: '${json['downloadUrl'] ?? ''}',
      localFilePath: '${json['localFilePath'] ?? ''}',
      thumbnailPath: '${json['thumbnailPath'] ?? ''}',
      duration: '${json['duration'] ?? ''}',
      quality: '${json['quality'] ?? ''}',
      isEdited: json['isEdited'] == true,
      galleryUri: '${json['galleryUri'] ?? ''}',
    );
  }

  DownloadItemModel copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? sizeLabel,
    String? fileName,
    DownloadType? type,
    String? fileId,
    String? downloadUrl,
    String? localFilePath,
    String? thumbnailPath,
    String? duration,
    String? quality,
    bool? isEdited,
    String? platform,
    String? thumbnailUrl,
    String? galleryUri,
  }) {
    return DownloadItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      platform: platform ?? this.platform,
      date: date ?? this.date,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      type: type ?? this.type,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      fileId: fileId ?? this.fileId,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      duration: duration ?? this.duration,
      quality: quality ?? this.quality,
      isEdited: isEdited ?? this.isEdited,
      galleryUri: galleryUri ?? this.galleryUri,
    );
  }
}
