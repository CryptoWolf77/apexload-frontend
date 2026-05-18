import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';

class MockLibraryService {
  List<DownloadItemModel> initialItems() {
    return [
      DownloadItemModel(
        id: 'demo_tiktok',
        title: 'Amazing travel sunset video',
        platform: 'TikTok',
        date: DateTime.now().subtract(const Duration(days: 1)),
        sizeLabel: '24 MB',
        type: DownloadType.video,
        thumbnailUrl: '',
        fileName: 'travel_sunset.mp4',
      ),
      DownloadItemModel(
        id: 'demo_instagram',
        title: 'Creative reel with city lights',
        platform: 'Instagram',
        date: DateTime.now().subtract(const Duration(days: 3)),
        sizeLabel: '18 MB',
        type: DownloadType.video,
        thumbnailUrl: '',
        fileName: 'city_lights.mp4',
      ),
      DownloadItemModel(
        id: 'demo_snapchat',
        title: 'Behind-the-scenes snap story',
        platform: 'Snapchat',
        date: DateTime.now().subtract(const Duration(days: 5)),
        sizeLabel: '15 MB',
        type: DownloadType.video,
        thumbnailUrl: '',
        fileName: 'snap_story.mp4',
      ),
    ];
  }
}
