import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/models/media_info_model.dart';

class MockDownloadService {
  DownloadItemModel createCompletedItem({
    required MediaInfoModel media,
    required DownloadFormatModel format,
    required String fileName,
    String? sizeLabel,
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
    );
  }
}
