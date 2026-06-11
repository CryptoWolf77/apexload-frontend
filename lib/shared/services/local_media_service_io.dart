import 'dart:io';

import 'package:apexload/core/network/api_config.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
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
  LocalMediaService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static const _androidChannel = MethodChannel('apexload/android');

  Future<void> ensureFolders() async {
    for (final directory in [
      await _rootDirectory(),
      await videosDirectory(),
      await audioDirectory(),
      await imagesDirectory(),
      await editedDirectory(),
      await gifsDirectory(),
      await statusImagesDirectory(),
      await statusVideosDirectory(),
      await thumbnailsDirectory(),
    ]) {
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }
    }
  }

  Future<LocalMediaSaveResult> saveRemoteFile({
    required String url,
    required String fileName,
    required DownloadType type,
    void Function(double progress)? onProgress,
  }) async {
    await ensureFolders();
    final folder = await _folderFor(type);
    final safeName = _safeFileName(fileName, fallback: _defaultFileName(type));
    final file = await _uniqueFile(folder, safeName);
    try {
      await _dio.download(
        url,
        file.path,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          onProgress?.call((received / total).clamp(0, 1));
        },
      );
    } on Object {
      if (file.existsSync()) {
        await file.delete();
      }
      rethrow;
    }
    if (!file.existsSync() || await file.length() == 0) {
      throw StateError('Downloaded file could not be saved.');
    }
    final galleryUri = await publishToGallery(
      localFilePath: file.path,
      fileName: file.uri.pathSegments.last,
      type: type,
    );
    return LocalMediaSaveResult(
      localFilePath: file.path,
      thumbnailPath: '',
      fileName: file.uri.pathSegments.last,
      sizeLabel: _formatBytes(await file.length()),
      galleryUri: galleryUri ?? '',
    );
  }

  Future<LocalMediaSaveResult> saveLocalFile({
    required String sourcePath,
    required String fileName,
    required DownloadType type,
    bool statusFile = false,
  }) async {
    await ensureFolders();
    final source = File(sourcePath);
    if (!source.existsSync()) {
      throw StateError('Source file does not exist.');
    }
    final folder = statusFile
        ? await _statusFolderFor(type)
        : await _folderFor(type);
    final safeName = _safeFileName(fileName, fallback: _defaultFileName(type));
    final file = await _uniqueFile(folder, safeName);
    await source.copy(file.path);
    final thumbnail = await generateThumbnail(
      localFilePath: file.path,
      fileName: file.uri.pathSegments.last,
      type: type,
    );
    final galleryUri = await publishToGallery(
      localFilePath: file.path,
      fileName: file.uri.pathSegments.last,
      type: type,
      category: statusFile ? 'status' : null,
    );
    return LocalMediaSaveResult(
      localFilePath: file.path,
      thumbnailPath: thumbnail ?? '',
      fileName: file.uri.pathSegments.last,
      sizeLabel: _formatBytes(await file.length()),
      galleryUri: galleryUri ?? '',
    );
  }

  Future<String?> publishToGallery({
    required String localFilePath,
    required String fileName,
    required DownloadType type,
    String? category,
  }) async {
    final file = File(localFilePath);
    if (!file.existsSync()) return null;
    try {
      return await _androidChannel.invokeMethod<String>('publishToGallery', {
        'sourcePath': localFilePath,
        'fileName': fileName,
        'type': type.name,
        'category': category ?? '',
      });
    } on Object {
      return null;
    }
  }

  Future<String?> generateThumbnail({
    required String localFilePath,
    required String fileName,
    required DownloadType type,
  }) async {
    final source = File(localFilePath);
    if (!source.existsSync()) return null;
    final thumbnails = await thumbnailsDirectory();
    final base = _baseName(fileName);

    if (type == DownloadType.image) {
      final ext = _extension(fileName).isEmpty ? 'jpg' : _extension(fileName);
      final target = await _uniqueFile(thumbnails, '${base}_thumb.$ext');
      await source.copy(target.path);
      return target.path;
    }

    if (type == DownloadType.audio) {
      return null;
    }

    final target = await _uniqueFile(thumbnails, '${base}_thumb.jpg');
    final session = await FFmpegKit.executeWithArguments([
      '-y',
      '-ss',
      '00:00:01',
      '-i',
      localFilePath,
      '-frames:v',
      '1',
      '-q:v',
      '3',
      target.path,
    ]);
    final code = await session.getReturnCode();
    if (ReturnCode.isSuccess(code) &&
        target.existsSync() &&
        target.lengthSync() > 0) {
      return target.path;
    }
    if (target.existsSync()) {
      await target.delete();
    }
    return null;
  }

  Future<void> openItem(DownloadItemModel item) async {
    final localPath = item.localFilePath.trim();
    if (localPath.isNotEmpty && File(localPath).existsSync()) {
      final result = await OpenFilex.open(localPath, type: _mimeType(item));
      if (result.type == ResultType.done) return;
      throw StateError(result.message);
    }

    final url = remoteUrlFor(item);
    if (url == null) {
      throw StateError('localFileMissing');
    }
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      throw StateError('Could not open downloaded file.');
    }
  }

  Future<void> shareItem(DownloadItemModel item) async {
    final localPath = item.localFilePath.trim();
    if (localPath.isNotEmpty && File(localPath).existsSync()) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(localPath)],
          text: item.title,
          fileNameOverrides: [item.fileName],
        ),
      );
      return;
    }
    final url = remoteUrlFor(item);
    if (url == null) {
      throw StateError('localFileMissing');
    }
    await SharePlus.instance.share(ShareParams(uri: Uri.parse(url)));
  }

  Future<void> deleteItemFiles(DownloadItemModel item) async {
    for (final path in [item.localFilePath, item.thumbnailPath]) {
      final trimmed = path.trim();
      if (trimmed.isEmpty) continue;
      final file = File(trimmed);
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }

  Future<List<DownloadItemModel>> discoverExistingDownloads({
    List<DownloadItemModel> existing = const [],
  }) async {
    await ensureFolders();
    final existingPaths = existing
        .map((item) => item.localFilePath.trim())
        .where((path) => path.isNotEmpty)
        .toSet();
    final discovered = <DownloadItemModel>[];
    for (final entry in [
      (await videosDirectory(), DownloadType.video, 'ApexLoad', false),
      (await audioDirectory(), DownloadType.audio, 'ApexLoad', false),
      (await imagesDirectory(), DownloadType.image, 'ApexLoad', false),
      (await editedDirectory(), DownloadType.video, 'Editor', true),
      (await gifsDirectory(), DownloadType.video, 'Editor', true),
      (
        await statusVideosDirectory(),
        DownloadType.video,
        'WhatsApp Status',
        true,
      ),
      (
        await statusImagesDirectory(),
        DownloadType.image,
        'WhatsApp Status',
        true,
      ),
    ]) {
      final directory = entry.$1;
      if (!directory.existsSync()) continue;
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is! File) continue;
        final path = entity.path;
        if (existingPaths.contains(path)) continue;
        final fileName = entity.uri.pathSegments.last;
        final type = _typeForFileName(fileName) ?? entry.$2;
        final stat = await entity.stat();
        final thumbnail = await generateThumbnail(
          localFilePath: path,
          fileName: fileName,
          type: type,
        );
        discovered.add(
          DownloadItemModel(
            id: _libraryIdForPath(path),
            title: _titleFromFileName(fileName),
            platform: entry.$3,
            date: stat.modified,
            sizeLabel: _formatBytes(stat.size),
            type: type,
            thumbnailUrl: '',
            fileName: fileName,
            localFilePath: path,
            thumbnailPath: thumbnail ?? '',
            quality: entry.$4 ? 'Edited' : '',
            isEdited: entry.$4,
          ),
        );
        existingPaths.add(path);
      }
    }
    discovered.sort((a, b) => b.date.compareTo(a.date));
    return discovered;
  }

  Future<Directory> videosDirectory() async =>
      Directory('${(await _rootDirectory()).path}/Videos');

  Future<Directory> audioDirectory() async =>
      Directory('${(await _rootDirectory()).path}/Audio');

  Future<Directory> imagesDirectory() async =>
      Directory('${(await _rootDirectory()).path}/Images');

  Future<Directory> editedDirectory() async =>
      Directory('${(await _rootDirectory()).path}/Edited');

  Future<Directory> gifsDirectory() async =>
      Directory('${(await _rootDirectory()).path}/GIFs');

  Future<Directory> statusImagesDirectory() async =>
      Directory('${(await _rootDirectory()).path}/Statuses/Images');

  Future<Directory> statusVideosDirectory() async =>
      Directory('${(await _rootDirectory()).path}/Statuses/Videos');

  Future<Directory> thumbnailsDirectory() async =>
      Directory('${(await _rootDirectory()).path}/Thumbnails');

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

  Future<File> editedOutputFile({
    required String sourceFileName,
    required String suffix,
    required String extension,
  }) async {
    await ensureFolders();
    final folder = await editedDirectory();
    final base = _baseName(sourceFileName);
    return _uniqueFile(folder, '${base}_$suffix.$extension');
  }

  Future<File> gifOutputFile({
    required String sourceFileName,
    required String suffix,
  }) async {
    await ensureFolders();
    final folder = await gifsDirectory();
    final base = _baseName(sourceFileName);
    return _uniqueFile(folder, '${base}_$suffix.gif');
  }

  Future<Directory> _folderFor(DownloadType type) {
    return switch (type) {
      DownloadType.video => videosDirectory(),
      DownloadType.audio => audioDirectory(),
      DownloadType.image => imagesDirectory(),
    };
  }

  Future<Directory> _statusFolderFor(DownloadType type) {
    return switch (type) {
      DownloadType.video => statusVideosDirectory(),
      DownloadType.audio => audioDirectory(),
      DownloadType.image => statusImagesDirectory(),
    };
  }

  Future<Directory> _rootDirectory() async {
    final external = await getExternalStorageDirectory();
    final base = external ?? await getApplicationDocumentsDirectory();
    return Directory('${base.path}/ApexLoad');
  }

  Future<File> _uniqueFile(Directory directory, String fileName) async {
    final base = _baseName(fileName);
    final ext = _extension(fileName);
    var candidate = File('${directory.path}/$fileName');
    var index = 1;
    while (candidate.existsSync()) {
      final suffix = ext.isEmpty ? '_$index' : '_$index.$ext';
      candidate = File('${directory.path}/$base$suffix');
      index++;
    }
    return candidate;
  }

  String _defaultFileName(DownloadType type) {
    return switch (type) {
      DownloadType.video => 'apexload_video.mp4',
      DownloadType.audio => 'apexload_audio.mp3',
      DownloadType.image => 'apexload_image.jpg',
    };
  }

  DownloadType? _typeForFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.3gp') ||
        lower.endsWith('.gif')) {
      return DownloadType.video;
    }
    if (lower.endsWith('.mp3') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.webm')) {
      return DownloadType.audio;
    }
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp')) {
      return DownloadType.image;
    }
    return null;
  }

  String _titleFromFileName(String fileName) {
    final base = _baseName(fileName).replaceAll('_', ' ').trim();
    if (base.isEmpty) return 'ApexLoad download';
    return base[0].toUpperCase() + base.substring(1);
  }

  String _libraryIdForPath(String path) {
    final encoded = path.codeUnits
        .map((unit) => unit.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'local_$encoded';
  }

  String _safeFileName(String value, {required String fallback}) {
    final sanitized = value
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_')
        .replaceAll(RegExp(r'^\.+'), '')
        .trim();
    return sanitized.isEmpty ? fallback : sanitized;
  }

  String _baseName(String fileName) {
    final safe = _safeFileName(fileName, fallback: 'apexload_file');
    final dot = safe.lastIndexOf('.');
    return dot <= 0 ? safe : safe.substring(0, dot);
  }

  String _extension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
  }

  String? _mimeType(DownloadItemModel item) {
    return switch (item.type) {
      DownloadType.video => 'video/mp4',
      DownloadType.audio =>
        item.fileName.toLowerCase().endsWith('.m4a')
            ? 'audio/mp4'
            : 'audio/mpeg',
      DownloadType.image => 'image/*',
    };
  }
}
