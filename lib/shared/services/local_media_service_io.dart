import 'dart:async';
import 'dart:io';

import 'package:apexload/core/network/api_config.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/services/active_operation_wakelock_service.dart';
import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
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

class CacheClearResult {
  const CacheClearResult({
    required this.bytesCleared,
    required this.filesCleared,
  });

  final int bytesCleared;
  final int filesCleared;
}

class LocalMediaService {
  LocalMediaService({Dio? dio, ActiveOperationWakelockService? wakelockService})
    : _dio = dio ?? _sharedDio,
      _wakelockService = wakelockService;

  static final Dio _sharedDio = Dio();
  static Future<void>? _folderSetupFuture;
  static Future<Directory>? _rootDirectoryFuture;
  static const _androidParallelDownloadThresholdBytes = 32 * 1024 * 1024;
  static const _androidFourPartDownloadThresholdBytes = 96 * 1024 * 1024;
  static const _iosParallelDownloadThresholdBytes = 8 * 1024 * 1024;
  static const _iosFourPartDownloadThresholdBytes = 32 * 1024 * 1024;
  final Dio _dio;
  final ActiveOperationWakelockService? _wakelockService;
  static const _androidChannel = MethodChannel('apexload/android');
  static const _iosChannel = MethodChannel('apexload/ios');

  Future<void> ensureFolders() async {
    final setup = _folderSetupFuture ??= _createFolders();
    try {
      await setup;
    } on Object {
      if (identical(_folderSetupFuture, setup)) {
        _folderSetupFuture = null;
      }
      rethrow;
    }
  }

  Future<void> _createFolders() async {
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
    int? expectedSizeBytes,
    void Function(double progress)? onProgress,
    VoidCallback? onIndeterminateProgress,
    bool publishToGallery = true,
  }) async {
    return _runWithWakelock(
      () => _saveRemoteFile(
        url: url,
        fileName: fileName,
        type: type,
        expectedSizeBytes: expectedSizeBytes,
        onProgress: onProgress,
        onIndeterminateProgress: onIndeterminateProgress,
        publishToGallery: publishToGallery,
      ),
      reason: 'save remote file',
    );
  }

  Future<LocalMediaSaveResult> _saveRemoteFile({
    required String url,
    required String fileName,
    required DownloadType type,
    int? expectedSizeBytes,
    void Function(double progress)? onProgress,
    VoidCallback? onIndeterminateProgress,
    bool publishToGallery = true,
  }) async {
    final totalWatch = Stopwatch()..start();
    _logSavePerf('Start save');
    await ensureFolders();
    final folder = await _folderFor(type);
    final safeName = _safeFileName(fileName, fallback: _defaultFileName(type));
    final file = await _uniqueFile(folder, safeName);
    var savedFile = file;
    final prepareForIosPlayback = Platform.isIOS && type == DownloadType.video;
    _logSavePerf('downloadUrl: $url');
    _logSavePerf('targetPath: ${file.path}');
    _logIosSave('Starting save');
    _logIosSave('Platform: ${Platform.operatingSystem}');
    _logIosSave('Source: $url');
    _logIosSave('Expected filename: $safeName');
    _logIosSave('Target: ${file.path}');
    _logIosSave('Directory exists: ${folder.existsSync()}');
    final downloadWatch = Stopwatch()..start();
    try {
      await _downloadToFile(
        url: url,
        file: file,
        expectedSizeBytes: expectedSizeBytes,
        onProgress: prepareForIosPlayback
            ? (progress) => onProgress?.call(progress * 0.82)
            : onProgress,
        onIndeterminateProgress: onIndeterminateProgress,
      );
    } on Object catch (error, stackTrace) {
      _logIosSave('Failed: ${error.runtimeType}: $error');
      if (kDebugMode && Platform.isIOS) {
        debugPrintStack(stackTrace: stackTrace);
      }
      if (file.existsSync()) {
        await file.delete();
      }
      rethrow;
    }
    downloadWatch.stop();
    _logSavePerf(
      'stream download completed in: ${downloadWatch.elapsedMilliseconds} ms',
    );
    final verifyWatch = Stopwatch()..start();
    final exists = file.existsSync();
    var size = exists ? await file.length() : 0;
    _logIosSave('File exists: $exists');
    _logIosSave('File size: $size');
    if (!exists || size == 0) {
      _logIosSave('Failed: saved file missing or empty');
      throw StateError('Downloaded file could not be saved.');
    }
    if (prepareForIosPlayback) {
      try {
        savedFile = await _prepareVideoForIosPlayback(
          file,
          onProgress: onProgress,
        );
      } on Object {
        if (file.existsSync()) await file.delete();
        rethrow;
      }
      size = await savedFile.length();
    }
    verifyWatch.stop();
    _logSavePerf(
      'file verification completed in: ${verifyWatch.elapsedMilliseconds} ms',
    );
    if (publishToGallery) {
      final galleryQueueWatch = Stopwatch()..start();
      unawaited(
        _publishToGalleryAfterSave(
          localFilePath: savedFile.path,
          fileName: savedFile.uri.pathSegments.last,
          type: type,
        ),
      );
      galleryQueueWatch.stop();
      _logSavePerf(
        'gallery scan queued in: ${galleryQueueWatch.elapsedMilliseconds} ms',
      );
    } else {
      _logSavePerf('gallery publishing skipped by user setting');
    }
    totalWatch.stop();
    _logSavePerf(
      'total save stage completed in: ${totalWatch.elapsedMilliseconds} ms',
    );
    _logIosSave('Completed');
    return LocalMediaSaveResult(
      localFilePath: savedFile.path,
      thumbnailPath: '',
      fileName: savedFile.uri.pathSegments.last,
      sizeLabel: _formatBytes(size),
      galleryUri: '',
    );
  }

  Future<File> _prepareVideoForIosPlayback(
    File source, {
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.84);
    final probeSession = await FFprobeKit.getMediaInformation(source.path);
    final media = probeSession.getMediaInformation();
    if (media == null) {
      throw StateError('Downloaded video could not be inspected.');
    }

    final videoStreams = media
        .getStreams()
        .where((stream) => stream.getType()?.toLowerCase() == 'video')
        .toList(growable: false);
    if (videoStreams.isEmpty) {
      throw StateError('Downloaded video does not contain a video track.');
    }

    final codecs = videoStreams
        .map((stream) => stream.getCodec()?.toLowerCase().trim() ?? '')
        .where((codec) => codec.isNotEmpty)
        .toSet();
    final extension = _extension(source.uri.pathSegments.last);
    final compatibleContainer = {'mp4', 'm4v', 'mov'}.contains(extension);
    final compatibleVideo =
        codecs.isNotEmpty &&
        codecs.every((codec) => codec == 'h264' || codec == 'hevc');
    if (compatibleContainer && compatibleVideo) {
      _logIosSave('Native video codec detected: ${codecs.join(', ')}');
      onProgress?.call(1);
      return source;
    }

    _logIosSave(
      'Converting video for iOS playback: '
      'container=$extension codec=${codecs.join(', ')}',
    );
    final sourceName = source.uri.pathSegments.last;
    final finalFile = extension == 'mp4'
        ? source
        : await _uniqueFile(source.parent, '${_baseName(sourceName)}.mp4');
    final workingFile = File(
      '${finalFile.path}.apexload_ios_compat_${DateTime.now().microsecondsSinceEpoch}.mp4',
    );
    final durationMs = (double.tryParse(media.getDuration() ?? '') ?? 0) * 1000;
    final completion = Completer<FFmpegSession>();
    await FFmpegKit.executeWithArgumentsAsync(
      [
        '-y',
        '-i',
        source.path,
        '-map',
        '0:v:0',
        '-map',
        '0:a?',
        '-c:v',
        'libx264',
        '-preset',
        'veryfast',
        '-crf',
        '18',
        '-pix_fmt',
        'yuv420p',
        '-c:a',
        'aac',
        '-b:a',
        '192k',
        '-movflags',
        '+faststart',
        workingFile.path,
      ],
      (session) {
        if (!completion.isCompleted) completion.complete(session);
      },
      null,
      (statistics) {
        if (durationMs <= 0) return;
        final converted = (statistics.getTime() / durationMs).clamp(0.0, 1.0);
        onProgress?.call(0.84 + converted * 0.15);
      },
    );
    final session = await completion.future;
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code) ||
        !workingFile.existsSync() ||
        workingFile.lengthSync() == 0) {
      if (workingFile.existsSync()) await workingFile.delete();
      throw StateError('Downloaded video could not be made iPhone-compatible.');
    }

    if (finalFile.existsSync()) await finalFile.delete();
    final convertedFile = await workingFile.rename(finalFile.path);
    if (source.path != convertedFile.path && source.existsSync()) {
      await source.delete();
    }
    onProgress?.call(1);
    _logIosSave('iOS-compatible H.264 MP4 created');
    return convertedFile;
  }

  Future<void> _downloadToFile({
    required String url,
    required File file,
    int? expectedSizeBytes,
    void Function(double progress)? onProgress,
    VoidCallback? onIndeterminateProgress,
  }) async {
    final supportsParallelDownload = Platform.isAndroid || Platform.isIOS;
    final parallelThreshold = Platform.isIOS
        ? _iosParallelDownloadThresholdBytes
        : _androidParallelDownloadThresholdBytes;
    final shouldProbeForParallelDownload = Platform.isIOS
        ? expectedSizeBytes != null && expectedSizeBytes >= parallelThreshold
        : expectedSizeBytes == null || expectedSizeBytes >= parallelThreshold;
    if (supportsParallelDownload && shouldProbeForParallelDownload) {
      try {
        final downloadedInParallel = await _tryParallelDownload(
          url: url,
          file: file,
          parallelThresholdBytes: parallelThreshold,
          fourPartThresholdBytes: Platform.isIOS
              ? _iosFourPartDownloadThresholdBytes
              : _androidFourPartDownloadThresholdBytes,
          onProgress: onProgress,
        );
        if (downloadedInParallel) return;
      } on Object catch (error) {
        _logSavePerf('parallel download unavailable; using one stream: $error');
        if (await file.exists()) {
          await file.delete();
        }
      }
    } else if (supportsParallelDownload) {
      _logSavePerf(
        'known small file: $expectedSizeBytes bytes; starting direct transfer',
      );
    }

    var loggedContentLength = false;
    await _dio.download(
      url,
      file.path,
      deleteOnError: true,
      options: Options(responseType: ResponseType.stream),
      onReceiveProgress: (received, total) {
        if (!loggedContentLength) {
          loggedContentLength = true;
          _logSavePerf('contentLength: ${total > 0 ? total : 'unknown'}');
        }
        if (total <= 0) {
          onIndeterminateProgress?.call();
          return;
        }
        onProgress?.call((received / total).clamp(0, 1));
      },
    );
  }

  Future<bool> _tryParallelDownload({
    required String url,
    required File file,
    required int parallelThresholdBytes,
    required int fourPartThresholdBytes,
    void Function(double progress)? onProgress,
  }) async {
    final probe = await _dio.get<ResponseBody>(
      url,
      options: Options(
        responseType: ResponseType.stream,
        headers: const {'Range': 'bytes=0-0', 'Accept-Encoding': 'identity'},
        validateStatus: (status) => status == 200 || status == 206,
      ),
    );
    final probeBody = probe.data;
    if (probeBody == null) return false;
    if (probe.statusCode != 206) {
      await _cancelResponseBody(probeBody);
      _logSavePerf(
        'range requests unsupported; canceled probe before downloading file',
      );
      return false;
    }
    await probeBody.stream.drain<void>();

    final totalBytes = _contentRangeTotal(probe.headers.value('content-range'));
    if (totalBytes == null || totalBytes < parallelThresholdBytes) {
      return false;
    }

    var receivedBytes = 0;
    final partCount = totalBytes >= fourPartThresholdBytes ? 4 : 2;
    final partSize = (totalBytes / partCount).ceil();
    final ranges = <(int, int)>[];
    for (var index = 0; index < partCount; index++) {
      final start = index * partSize;
      if (start >= totalBytes) break;
      final proposedEnd = start + partSize - 1;
      final end = proposedEnd < totalBytes ? proposedEnd : totalBytes - 1;
      ranges.add((start, end));
    }

    _logSavePerf(
      'large file detected: $totalBytes bytes; using ${ranges.length} streams',
    );
    final handles = <RandomAccessFile>[];
    try {
      for (var index = 0; index < ranges.length; index++) {
        handles.add(await file.open(mode: FileMode.writeOnly));
      }
      await handles.first.truncate(totalBytes);
      await Future.wait([
        for (var index = 0; index < ranges.length; index++)
          _downloadRange(
            url: url,
            start: ranges[index].$1,
            end: ranges[index].$2,
            handle: handles[index],
            onBytes: (count) {
              receivedBytes += count;
              onProgress?.call((receivedBytes / totalBytes).clamp(0, 1));
            },
          ),
      ]);
    } finally {
      for (final handle in handles) {
        await handle.close();
      }
    }
    if (await file.length() != totalBytes) {
      throw StateError('Parallel download size verification failed.');
    }
    onProgress?.call(1);
    return true;
  }

  Future<void> _downloadRange({
    required String url,
    required int start,
    required int end,
    required RandomAccessFile handle,
    required ValueChanged<int> onBytes,
  }) async {
    final response = await _dio.get<ResponseBody>(
      url,
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Range': 'bytes=$start-$end', 'Accept-Encoding': 'identity'},
        validateStatus: (status) => status == 206,
      ),
    );
    final body = response.data;
    if (response.statusCode != 206 || body == null) {
      throw StateError('The server did not return the requested file range.');
    }

    final expectedBytes = end - start + 1;
    var writtenBytes = 0;
    await handle.setPosition(start);
    await for (final chunk in body.stream) {
      final remaining = expectedBytes - writtenBytes;
      if (remaining <= 0) break;
      final count = chunk.length < remaining ? chunk.length : remaining;
      await handle.writeFrom(chunk, 0, count);
      writtenBytes += count;
      onBytes(count);
    }
    if (writtenBytes != expectedBytes) {
      throw StateError(
        'File range was incomplete ($writtenBytes of $expectedBytes bytes).',
      );
    }
  }

  Future<void> _cancelResponseBody(ResponseBody body) async {
    final subscription = body.stream.listen((_) {});
    await subscription.cancel();
  }

  int? _contentRangeTotal(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^bytes\s+\d+-\d+\/(\d+)$').firstMatch(value.trim());
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  Future<void> _publishToGalleryAfterSave({
    required String localFilePath,
    required String fileName,
    required DownloadType type,
  }) async {
    await _runWithWakelock(() async {
      final watch = Stopwatch()..start();
      final uri = await publishToGallery(
        localFilePath: localFilePath,
        fileName: fileName,
        type: type,
      );
      watch.stop();
      _logSavePerf(
        uri == null
            ? 'gallery scan finished without uri in: ${watch.elapsedMilliseconds} ms'
            : 'gallery scan finished in: ${watch.elapsedMilliseconds} ms',
      );
    }, reason: 'publish to gallery');
  }

  Future<LocalMediaSaveResult> saveLocalFile({
    required String sourcePath,
    required String fileName,
    required DownloadType type,
    bool statusFile = false,
  }) async {
    return _runWithWakelock(
      () => _saveLocalFile(
        sourcePath: sourcePath,
        fileName: fileName,
        type: type,
        statusFile: statusFile,
      ),
      reason: 'save local file',
    );
  }

  Future<LocalMediaSaveResult> _saveLocalFile({
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
    if (!Platform.isAndroid && !Platform.isIOS) return null;
    if (Platform.isIOS && type == DownloadType.audio) return null;
    final file = File(localFilePath);
    if (!file.existsSync()) return null;
    try {
      final channel = Platform.isIOS ? _iosChannel : _androidChannel;
      return await channel.invokeMethod<String>('publishToGallery', {
        'sourcePath': localFilePath,
        'fileName': fileName,
        'type': type.name,
        'category': category ?? '',
      });
    } on Object {
      return null;
    }
  }

  void publishToGalleryInBackground({
    required String localFilePath,
    required String fileName,
    required DownloadType type,
    String? category,
  }) {
    unawaited(
      _runWithWakelock(() async {
        final watch = Stopwatch()..start();
        await publishToGallery(
          localFilePath: localFilePath,
          fileName: fileName,
          type: type,
          category: category,
        );
        watch.stop();
        _logSavePerf(
          'background editor gallery publish finished in: '
          '${watch.elapsedMilliseconds} ms',
        );
      }, reason: 'publish editor output'),
    );
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
      var playablePath = localPath;
      if (Platform.isIOS &&
          item.type == DownloadType.video &&
          _extension(item.fileName) == 'mp4') {
        playablePath = (await _prepareVideoForIosPlayback(
          File(localPath),
        )).path;
      }
      final result = await OpenFilex.open(playablePath, type: _mimeType(item));
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

  Future<CacheClearResult> clearSafeCache() async {
    await ensureFolders();
    var bytesCleared = 0;
    var filesCleared = 0;

    final thumbnailResult = await _deleteDirectoryContents(
      await thumbnailsDirectory(),
    );
    bytesCleared += thumbnailResult.bytesCleared;
    filesCleared += thumbnailResult.filesCleared;

    final temp = await getTemporaryDirectory();
    if (temp.existsSync()) {
      await for (final entity in temp.list(followLinks: false)) {
        final name = entity.uri.pathSegments.isEmpty
            ? ''
            : entity.uri.pathSegments.last;
        if (!name.startsWith('apexload_audio_swap_preview_') &&
            !name.startsWith('apexload_gif_preview_')) {
          continue;
        }
        final result = await _deleteCacheEntity(entity);
        bytesCleared += result.bytesCleared;
        filesCleared += result.filesCleared;
      }
    }

    return CacheClearResult(
      bytesCleared: bytesCleared,
      filesCleared: filesCleared,
    );
  }

  Future<String?> visibleDownloadRootPath() async {
    if (!Platform.isAndroid) return null;
    return (await _rootDirectory()).path;
  }

  Future<bool> openDownloadsFolder() async {
    if (!Platform.isAndroid) return false;
    final root = await _rootDirectory();
    final result = await OpenFilex.open(root.path);
    return result.type == ResultType.done;
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
            thumbnailPath: '',
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

  Future<Directory> _rootDirectory() {
    return _rootDirectoryFuture ??= _resolveRootDirectory();
  }

  Future<Directory> _resolveRootDirectory() async {
    final base = Platform.isAndroid
        ? (await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory())
        : await getApplicationDocumentsDirectory();
    return Directory('${base.path}/ApexLoad');
  }

  Future<CacheClearResult> _deleteDirectoryContents(Directory directory) async {
    if (!directory.existsSync()) {
      return const CacheClearResult(bytesCleared: 0, filesCleared: 0);
    }
    var bytes = 0;
    var files = 0;
    await for (final entity in directory.list(followLinks: false)) {
      final result = await _deleteCacheEntity(entity);
      bytes += result.bytesCleared;
      files += result.filesCleared;
    }
    return CacheClearResult(bytesCleared: bytes, filesCleared: files);
  }

  Future<CacheClearResult> _deleteCacheEntity(FileSystemEntity entity) async {
    var bytes = 0;
    var files = 0;
    if (entity is File) {
      bytes = await entity.length();
      files = 1;
    } else if (entity is Directory) {
      await for (final child in entity.list(
        recursive: true,
        followLinks: false,
      )) {
        if (child is File) {
          bytes += await child.length();
          files++;
        }
      }
    }
    await entity.delete(recursive: true);
    return CacheClearResult(bytesCleared: bytes, filesCleared: files);
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

  void _logIosSave(String message) {
    if (!Platform.isIOS) return;
    debugPrint('[ApexLoad iOS Save] $message');
  }

  void _logSavePerf(String message) {
    if (!kDebugMode) return;
    debugPrint('[ApexLoad Save Perf] $message');
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

  Future<T> _runWithWakelock<T>(
    Future<T> Function() task, {
    required String reason,
  }) {
    final service = _wakelockService;
    if (service == null) return task();
    return service.runWithWakelock(task, reason: reason);
  }
}
