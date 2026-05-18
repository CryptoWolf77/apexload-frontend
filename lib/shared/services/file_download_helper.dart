import 'file_download_helper_io.dart'
    if (dart.library.js_interop) 'file_download_helper_web.dart';

abstract final class FileDownloadHelper {
  static Future<String?> saveOrOpen({
    required String url,
    required String fileName,
  }) {
    return saveOrOpenFile(url: url, fileName: fileName);
  }
}
