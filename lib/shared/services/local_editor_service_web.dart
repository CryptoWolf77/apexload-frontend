import 'package:apexload/features/quick_editor/quick_editor_models.dart';
import 'package:apexload/shared/models/download_item_model.dart';

class LocalEditorService {
  LocalEditorService({Object? mediaService});

  Future<DownloadItemModel> runJob({
    required DownloadItemModel source,
    required QuickEditorJob job,
    required Map<String, Object?> options,
  }) {
    throw const LocalEditorException('local_editor_unavailable');
  }

  Future<String> createAudioSwapPreview({
    required DownloadItemModel source,
    required String audioPath,
    required double audioStartTime,
    required double previewDuration,
  }) {
    throw const LocalEditorException('local_editor_unavailable');
  }

  Future<double?> mediaDuration(String path) async => null;

  Future<String> createGifPreview({
    required DownloadItemModel source,
    required double startTime,
    required double endTime,
    required int fps,
    required String size,
  }) {
    throw const LocalEditorException('local_editor_unavailable');
  }
}

class LocalEditorException implements Exception {
  const LocalEditorException(this.message);

  final String message;

  @override
  String toString() => message;
}
