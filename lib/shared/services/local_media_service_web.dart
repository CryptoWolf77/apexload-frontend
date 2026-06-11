import 'package:apexload/core/network/api_config.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class LocalMediaSaveResult {
  const LocalMediaSaveResult({
    required this.localFilePath,
    required this.thumbnailPath,
    required this.fileName,
    required this.sizeLabel,
    this.galleryUri = '',
  });

  final String localFilePath;
  final String thumbnailPath;
  final String fileName;
  final String sizeLabel;
  final String galleryUri;
}

class LocalMediaService {
  Future<void> ensureFolders() async {}

  Future<LocalMediaSaveResult> saveRemoteFile({
    required String url,
    required String fileName,
    required DownloadType type,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(1);
    return LocalMediaSaveResult(
      localFilePath: '',
      thumbnailPath: '',
      fileName: fileName,
      sizeLabel: '',
      galleryUri: '',
    );
  }

  Future<LocalMediaSaveResult> saveLocalFile({
    required String sourcePath,
    required String fileName,
    required DownloadType type,
    bool statusFile = false,
  }) async {
    return LocalMediaSaveResult(
      localFilePath: '',
      thumbnailPath: '',
      fileName: fileName,
      sizeLabel: '',
      galleryUri: '',
    );
  }

  Future<String?> publishToGallery({
    required String localFilePath,
    required String fileName,
    required DownloadType type,
    String? category,
  }) async {
    return null;
  }

  Future<String?> generateThumbnail({
    required String localFilePath,
    required String fileName,
    required DownloadType type,
  }) async {
    return null;
  }

  Future<void> openItem(DownloadItemModel item) async {
    final url = remoteUrlFor(item);
    if (url == null) throw StateError('localFileMissing');
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) throw StateError('Could not open downloaded file.');
  }

  Future<void> shareItem(DownloadItemModel item) async {
    final url = remoteUrlFor(item);
    if (url == null) throw StateError('localFileMissing');
    await SharePlus.instance.share(ShareParams(uri: Uri.parse(url)));
  }

  Future<void> deleteItemFiles(DownloadItemModel item) async {}

  Future<List<DownloadItemModel>> discoverExistingDownloads({
    List<DownloadItemModel> existing = const [],
  }) async {
    return const [];
  }

  String? remoteUrlFor(DownloadItemModel item) {
    final value = item.downloadUrl.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) return '${ApiConfig.baseUrl}$value';
    if (value.isNotEmpty) return '${ApiConfig.baseUrl}/$value';
    final fileId = item.fileId.trim();
    if (fileId.isNotEmpty) {
      return '${ApiConfig.baseUrl}${ApiConfig.filePath(fileId)}';
    }
    return null;
  }

  Future<Object> editedOutputFile({
    required String sourceFileName,
    required String suffix,
    required String extension,
  }) {
    throw UnsupportedError('Local editing is not available on web.');
  }

  Future<Object> gifOutputFile({
    required String sourceFileName,
    required String suffix,
  }) {
    throw UnsupportedError('Local editing is not available on web.');
  }
}
