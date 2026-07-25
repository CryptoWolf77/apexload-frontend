import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/services/local_media_service.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';

class IosWhatsAppMediaBridge {
  IosWhatsAppMediaBridge({required LocalMediaService mediaService})
    : _mediaService = mediaService;

  final LocalMediaService _mediaService;
  final Map<String, _PendingCapture> _captures = {};

  Future<DownloadItemModel> captureCurrentStatus(
    InAppWebViewController controller, {
    void Function(double progress)? onProgress,
  }) async {
    final captureId =
        'ios_whatsapp_${DateTime.now().microsecondsSinceEpoch.toString()}';
    final pending = _PendingCapture(onProgress: onProgress);
    _captures[captureId] = pending;

    try {
      final asyncResult = await controller.callAsyncJavaScript(
        functionBody: '''
          if (!window.__apexloadExportCurrentStatus) {
            return {
              ok: false,
              error: 'The status capture tool is not ready yet.',
            };
          }
          return await window.__apexloadExportCurrentStatus(captureId);
        ''',
        arguments: {'captureId': captureId},
      );
      if (pending.completer.isCompleted) {
        return await pending.completer.future;
      }
      if (asyncResult?.error != null) {
        throw StateError('${asyncResult!.error}');
      }
      final result = asyncResult?.value;
      final resultMap = result is Map
          ? result.map((key, value) => MapEntry('$key', value))
          : const <String, dynamic>{};
      if (resultMap['ok'] != true) {
        throw StateError(
          '${resultMap['error'] ?? 'The current status could not be captured.'}',
        );
      }
      return await pending.completer.future;
    } on Object {
      await _discardCapture(captureId);
      rethrow;
    }
  }

  Future<Map<String, Object?>> handleMediaChunk(List<dynamic> arguments) async {
    if (arguments.isEmpty || arguments.first is! Map) {
      throw const FormatException('Invalid media chunk.');
    }
    final payload = (arguments.first as Map).map(
      (key, value) => MapEntry('$key', value),
    );
    final captureId = '${payload['captureId'] ?? ''}';
    final pending = _captures[captureId];
    if (captureId.isEmpty || pending == null) {
      throw StateError('Unknown media capture.');
    }

    final mime = '${payload['mime'] ?? ''}'.toLowerCase();
    final totalBytes = (payload['totalBytes'] as num?)?.toInt() ?? 0;
    final index = (payload['index'] as num?)?.toInt() ?? 0;
    pending.mime = mime;
    pending.totalBytes = totalBytes;

    pending.file ??= await _newTemporaryFile(captureId, mime);
    pending.writer ??= await pending.file!.open(mode: FileMode.writeOnly);

    final encoded = '${payload['data'] ?? ''}';
    if (encoded.isNotEmpty) {
      final bytes = base64Decode(encoded);
      await pending.writer!.writeFrom(bytes);
      pending.receivedBytes += bytes.length;
      if (totalBytes > 0) {
        pending.onProgress?.call(
          (pending.receivedBytes / totalBytes).clamp(0, 1),
        );
      }
    }

    if (payload['done'] == true) {
      await pending.writer?.close();
      pending.writer = null;
      try {
        final item = await _saveCompletedCapture(pending);
        pending.onProgress?.call(1);
        if (!pending.completer.isCompleted) pending.completer.complete(item);
      } on Object catch (error, stackTrace) {
        if (!pending.completer.isCompleted) {
          pending.completer.completeError(error, stackTrace);
        }
        rethrow;
      } finally {
        _captures.remove(captureId);
        await _deleteIfPresent(pending.file);
      }
    }

    return {'accepted': true, 'index': index};
  }

  Future<void> dispose() async {
    final ids = _captures.keys.toList(growable: false);
    for (final id in ids) {
      await _discardCapture(id);
    }
  }

  Future<File> _newTemporaryFile(String captureId, String mime) async {
    final temporary = await getTemporaryDirectory();
    return File('${temporary.path}/$captureId.${statusExtensionForMime(mime)}');
  }

  Future<DownloadItemModel> _saveCompletedCapture(
    _PendingCapture pending,
  ) async {
    final source = pending.file;
    if (source == null ||
        !await source.exists() ||
        await source.length() == 0) {
      throw StateError('WhatsApp returned an empty status file.');
    }
    final type = statusTypeForMime(pending.mime);
    if (type == DownloadType.image) {
      await _validateCapturedImage(source);
    }
    final extension = statusExtensionForMime(pending.mime);
    final now = DateTime.now();
    final fileName =
        'whatsapp_status_${_two(now.year % 100)}'
        '${_two(now.month)}${_two(now.day)}_'
        '${_two(now.hour)}${_two(now.minute)}${_two(now.second)}.$extension';
    final saved = await _mediaService.saveLocalFile(
      sourcePath: source.path,
      fileName: fileName,
      type: type,
      statusFile: true,
    );
    return DownloadItemModel(
      id: 'ios_whatsapp_status_${now.microsecondsSinceEpoch}',
      title: type == DownloadType.video
          ? 'WhatsApp status video'
          : 'WhatsApp status photo',
      platform: 'WhatsApp Status',
      date: now,
      sizeLabel: saved.sizeLabel,
      type: type,
      thumbnailUrl: '',
      fileName: saved.fileName,
      localFilePath: saved.localFilePath,
      thumbnailPath: saved.thumbnailPath,
      galleryUri: saved.galleryUri,
      quality: 'Status',
      isEdited: true,
    );
  }

  Future<void> _discardCapture(String id) async {
    final pending = _captures.remove(id);
    if (pending == null) return;
    await pending.writer?.close();
    pending.writer = null;
    await _deleteIfPresent(pending.file);
  }

  Future<void> _validateCapturedImage(File source) async {
    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(await source.readAsBytes());
      final frame = await codec.getNextFrame();
      image = frame.image;
      if (image.width < 96 || image.height < 96) {
        throw StateError('WhatsApp returned a placeholder image.');
      }
    } on StateError {
      rethrow;
    } on Object {
      throw StateError('WhatsApp returned an invalid image.');
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  Future<void> _deleteIfPresent(File? file) async {
    if (file != null && await file.exists()) await file.delete();
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

DownloadType statusTypeForMime(String mime) =>
    mime.toLowerCase().startsWith('video/')
    ? DownloadType.video
    : DownloadType.image;

String statusExtensionForMime(String mime) {
  final normalized = mime.toLowerCase().split(';').first.trim();
  return switch (normalized) {
    'video/quicktime' => 'mov',
    'video/webm' => 'webm',
    'video/mp4' => 'mp4',
    'image/png' => 'png',
    'image/jpeg' || 'image/jpg' => 'jpg',
    'image/webp' || 'image/gif' => 'png',
    _ when normalized.startsWith('video/') => 'mp4',
    _ => 'jpg',
  };
}

class _PendingCapture {
  _PendingCapture({required this.onProgress});

  final Completer<DownloadItemModel> completer = Completer<DownloadItemModel>();
  final void Function(double progress)? onProgress;
  File? file;
  RandomAccessFile? writer;
  String mime = '';
  int totalBytes = 0;
  int receivedBytes = 0;
}
