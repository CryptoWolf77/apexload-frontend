import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/models/media_info_model.dart';

class MockDownloadService {
  DownloadItemModel createCompletedItem({
    required MediaInfoModel media,
    required DownloadFormatModel format,
    required String fileName,
    String? sizeLabel,
    String? fileId,
    String? downloadUrl,
    String? localFilePath,
    String? thumbnailPath,
    String? duration,
    String? quality,
    String? galleryUri,
    bool isEdited = false,
  }) {
    return DownloadItemModel(
      id: '${media.id}_${format.id}_${DateTime.now().millisecondsSinceEpoch}',
      title: media.title,
      platform: media.platform,
      date: DateTime.now(),
      sizeLabel: sizeLabel ?? format.sizeLabel,
      type: format.type,
      thumbnailUrl: media.thumbnailUrl,
      fileName: fileName,
      fileId: fileId ?? '',
      downloadUrl: downloadUrl ?? '',
      localFilePath: localFilePath ?? '',
      thumbnailPath: thumbnailPath ?? '',
      duration: duration ?? media.duration,
      quality: quality ?? format.label,
      galleryUri: galleryUri ?? '',
      isEdited: isEdited,
    );
  }
}
