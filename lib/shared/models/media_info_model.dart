import 'package:apexload/shared/models/download_format_model.dart';

enum MediaType { video, image, audio }

class MediaInfoModel {
  const MediaInfoModel({
    required this.id,
    required this.title,
    required this.mediaType,
    required this.platform,
    required this.duration,
    required this.thumbnailUrl,
    required this.sourceUrl,
    required this.formats,
  });

  final String id;
  final String title;
  final MediaType mediaType;
  final String platform;
  final String duration;
  final String thumbnailUrl;
  final String sourceUrl;
  final List<DownloadFormatModel> formats;
}
