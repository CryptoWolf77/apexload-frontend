import 'dart:async';
import 'dart:io';

import 'package:apexload/features/quick_editor/quick_editor_models.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/services/local_media_service.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LocalEditorService {
  LocalEditorService({LocalMediaService? mediaService})
    : _mediaService = mediaService ?? LocalMediaService();

  final LocalMediaService _mediaService;

  Future<DownloadItemModel> runJob({
    required DownloadItemModel source,
    required QuickEditorJob job,
    required Map<String, Object?> options,
    void Function(double progress)? onProgress,
  }) async {
    final inputPath = source.localFilePath.trim();
    if (inputPath.isEmpty || !File(inputPath).existsSync()) {
      throw const LocalEditorException('original_file_missing');
    }

    final output = await _outputFile(
      source: source,
      job: job,
      options: options,
    );
    if (job.type == QuickEditorJobType.trim) {
      final start = _doubleOption(options, 'startTime', 0);
      final end = _doubleOption(options, 'endTime', 0);
      if (start < 0 || end <= start || end - start < 1) {
        throw const LocalEditorException('invalid_trim_range');
      }
    }
    onProgress?.call(0.04);
    final args = _argumentsFor(
      inputPath: inputPath,
      outputPath: output.path,
      job: job,
      options: options,
    );

    // TODO: Real Audio Swap should be processed locally on the phone/device.
    // TODO: Do not upload user video or selected audio to the VPS for editing.
    // TODO: Future implementation can use local/native video processing packages.
    debugPrint(
      'ApexLoad editor lazy initialization: operation=${job.operation}',
    );
    if (kDebugMode) {
      debugPrint(
        'ApexLoad local editor input=$inputPath output=${output.path}',
      );
    }
    final expectedDuration = await _expectedOutputDuration(
      inputPath: inputPath,
      job: job,
      options: options,
    );
    final session = await _executeWithProgress(
      args,
      expectedDuration: expectedDuration,
      onProgress: onProgress,
    );
    var code = await session.getReturnCode();
    debugPrint(
      'ApexLoad editor lazy initialization result: returnCode=${code?.getValue()}',
    );

    if (!ReturnCode.isSuccess(code) &&
        (job.type == QuickEditorJobType.mute ||
            job.type == QuickEditorJobType.audioSwap)) {
      final fallbackArgs = _fallbackArgumentsFor(
        inputPath: inputPath,
        outputPath: output.path,
        job: job,
        options: options,
      );
      final fallback = await _executeWithProgress(
        fallbackArgs,
        expectedDuration: expectedDuration,
        onProgress: onProgress,
      );
      code = await fallback.getReturnCode();
    }

    if (!ReturnCode.isSuccess(code) ||
        !output.existsSync() ||
        output.lengthSync() == 0) {
      debugPrint('ApexLoad editor lazy initialization failed');
      throw LocalEditorException(_failureKeyFor(job));
    }
    debugPrint('ApexLoad editor lazy initialization succeeded');
    onProgress?.call(0.93);

    final type = job.type == QuickEditorJobType.extractAudio
        ? DownloadType.audio
        : job.type == QuickEditorJobType.videoToGif
        ? DownloadType.image
        : DownloadType.video;
    final thumbnail = await _mediaService.generateThumbnail(
      localFilePath: output.path,
      fileName: output.uri.pathSegments.last,
      type: type,
    );
    onProgress?.call(0.98);
    _mediaService.publishToGalleryInBackground(
      localFilePath: output.path,
      fileName: output.uri.pathSegments.last,
      type: type,
      category: type == DownloadType.video ? 'edited' : null,
    );

    return source.copyWith(
      id: '${source.id}_edited_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleFor(job, source.title, options),
      platform: _platformFor(job, options),
      date: DateTime.now(),
      type: type,
      fileName: output.uri.pathSegments.last,
      localFilePath: output.path,
      thumbnailPath: thumbnail ?? '',
      galleryUri: '',
      fileId: '',
      downloadUrl: '',
      sizeLabel: _formatBytes(output.lengthSync()),
      quality: _qualityLabel(job, options),
      isEdited: true,
    );
  }

  Future<String> createAudioSwapPreview({
    required DownloadItemModel source,
    required String audioPath,
    required double audioStartTime,
    required double previewDuration,
  }) async {
    final inputPath = source.localFilePath.trim();
    if (inputPath.isEmpty || !File(inputPath).existsSync()) {
      throw const LocalEditorException('original_file_missing');
    }
    if (audioPath.trim().isEmpty || !File(audioPath).existsSync()) {
      throw const LocalEditorException('could_not_replace_audio');
    }
    final temp = await getTemporaryDirectory();
    final output = File(
      '${temp.path}/apexload_audio_swap_preview_'
      '${DateTime.now().millisecondsSinceEpoch}.mp4',
    );
    final duration = previewDuration.clamp(1, 12).toDouble();
    final args = [
      ..._commandPreamble,
      '-t',
      _secondsToTimestamp(duration),
      '-i',
      inputPath,
      '-ss',
      _secondsToTimestamp(audioStartTime),
      '-i',
      audioPath,
      '-map',
      '0:v:0',
      '-map',
      '1:a:0',
      '-c:v',
      'copy',
      '-c:a',
      'aac',
      '-shortest',
      output.path,
    ];
    final session = await FFmpegKit.executeWithArguments(args);
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code) ||
        !output.existsSync() ||
        output.lengthSync() == 0) {
      throw const LocalEditorException('could_not_replace_audio');
    }
    return output.path;
  }

  Future<double?> mediaDuration(String path) async {
    if (path.trim().isEmpty || !File(path).existsSync()) return null;
    final session = await FFprobeKit.getMediaInformation(path);
    final info = session.getMediaInformation();
    final duration = double.tryParse(info?.getDuration() ?? '');
    if (duration == null || duration <= 0) return null;
    return duration;
  }

  Future<String> createGifPreview({
    required DownloadItemModel source,
    required double startTime,
    required double endTime,
    required int fps,
    required String size,
  }) async {
    final inputPath = source.localFilePath.trim();
    if (inputPath.isEmpty || !File(inputPath).existsSync()) {
      throw const LocalEditorException('original_file_missing');
    }
    final temp = await getTemporaryDirectory();
    final output = File(
      '${temp.path}/apexload_gif_preview_'
      '${DateTime.now().millisecondsSinceEpoch}.gif',
    );
    final args = _argumentsFor(
      inputPath: inputPath,
      outputPath: output.path,
      job: const QuickEditorJob(
        type: QuickEditorJobType.videoToGif,
        operation: 'video-to-gif-preview',
        successMessageKey: 'gifCreatedSuccess',
      ),
      options: {
        'startTime': startTime,
        'endTime': endTime,
        'fps': fps,
        'size': size,
        'loop': true,
      },
    );
    final session = await FFmpegKit.executeWithArguments(args);
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code) ||
        !output.existsSync() ||
        output.lengthSync() == 0) {
      throw const LocalEditorException('could_not_create_gif');
    }
    return output.path;
  }

  Future<File> _outputFile({
    required DownloadItemModel source,
    required QuickEditorJob job,
    required Map<String, Object?> options,
  }) {
    if (job.type == QuickEditorJobType.videoToGif) {
      return _mediaService.gifOutputFile(
        sourceFileName: source.fileName,
        suffix: 'gif',
      );
    }
    final extension = switch (job.type) {
      QuickEditorJobType.extractAudio =>
        (options['format'] as String? ?? 'mp3').toLowerCase() == 'm4a'
            ? 'm4a'
            : 'mp3',
      _ => 'mp4',
    };
    final suffix = switch (job.type) {
      QuickEditorJobType.trim => 'trimmed',
      QuickEditorJobType.mute => 'muted',
      QuickEditorJobType.extractAudio => 'audio',
      QuickEditorJobType.compress => 'compressed',
      QuickEditorJobType.export => 'converted',
      QuickEditorJobType.audioSwap => 'audio_swap',
      QuickEditorJobType.videoToGif => 'gif',
      QuickEditorJobType.reelsShorts =>
        '${options['preset'] as String? ?? 'instagram'}_reel_short',
    };
    return _mediaService.editedOutputFile(
      sourceFileName: source.fileName,
      suffix: suffix,
      extension: extension,
    );
  }

  List<String> _argumentsFor({
    required String inputPath,
    required String outputPath,
    required QuickEditorJob job,
    required Map<String, Object?> options,
  }) {
    return switch (job.type) {
      QuickEditorJobType.trim => [
        ..._commandPreamble,
        '-ss',
        _secondsToTimestamp(_doubleOption(options, 'startTime', 0)),
        '-i',
        inputPath,
        '-t',
        _secondsToTimestamp(
          _doubleOption(options, 'endTime', 10) -
              _doubleOption(options, 'startTime', 0),
        ),
        '-c:v',
        'libx264',
        '-preset',
        'superfast',
        '-crf',
        '20',
        '-threads',
        '0',
        '-c:a',
        'aac',
        outputPath,
      ],
      QuickEditorJobType.mute => [
        ..._commandPreamble,
        '-i',
        inputPath,
        '-an',
        '-c:v',
        'copy',
        outputPath,
      ],
      QuickEditorJobType.extractAudio => [
        ..._commandPreamble,
        '-i',
        inputPath,
        '-vn',
        '-codec:a',
        (options['format'] as String? ?? 'mp3').toLowerCase() == 'm4a'
            ? 'aac'
            : 'libmp3lame',
        if ((options['format'] as String? ?? 'mp3').toLowerCase() == 'mp3')
          '-q:a',
        if ((options['format'] as String? ?? 'mp3').toLowerCase() == 'mp3') '2',
        '-threads',
        '0',
        outputPath,
      ],
      QuickEditorJobType.compress => [
        ..._commandPreamble,
        '-i',
        inputPath,
        '-vcodec',
        'libx264',
        '-crf',
        _crfFor(options['quality'] as String?),
        '-preset',
        'superfast',
        '-threads',
        '0',
        '-acodec',
        'aac',
        outputPath,
      ],
      QuickEditorJobType.export => [
        ..._commandPreamble,
        '-i',
        inputPath,
        '-vcodec',
        'libx264',
        '-preset',
        'ultrafast',
        '-crf',
        '20',
        '-threads',
        '0',
        '-acodec',
        'aac',
        outputPath,
      ],
      QuickEditorJobType.audioSwap => [
        ..._commandPreamble,
        '-i',
        inputPath,
        if (_boolOption(options, 'loopAudio', false)) '-stream_loop',
        if (_boolOption(options, 'loopAudio', false)) '-1',
        '-ss',
        _secondsToTimestamp(_doubleOption(options, 'audioStart', 0)),
        '-to',
        _secondsToTimestamp(_doubleOption(options, 'audioEnd', 20)),
        '-i',
        _audioPath(options),
        '-map',
        '0:v:0',
        '-map',
        '1:a:0',
        '-c:v',
        'copy',
        '-c:a',
        'aac',
        if (!_boolOption(options, 'loopAudio', false)) '-af',
        if (!_boolOption(options, 'loopAudio', false)) 'apad',
        '-t',
        _secondsToTimestamp(_doubleOption(options, 'videoDuration', 20)),
        outputPath,
      ],
      QuickEditorJobType.videoToGif => [
        ..._commandPreamble,
        '-ss',
        _secondsToTimestamp(_doubleOption(options, 'startTime', 0)),
        '-i',
        inputPath,
        '-t',
        _secondsToTimestamp(
          _doubleOption(options, 'endTime', 6) -
              _doubleOption(options, 'startTime', 0),
        ),
        '-vf',
        _gifFilter(options),
        '-loop',
        _boolOption(options, 'loop', true) ? '0' : '-1',
        outputPath,
      ],
      QuickEditorJobType.reelsShorts => [
        ..._commandPreamble,
        '-i',
        inputPath,
        '-vf',
        _reelsFilter(options),
        if (_boolOption(options, 'mute', false)) '-an',
        if (!_boolOption(options, 'mute', false)) '-c:a',
        if (!_boolOption(options, 'mute', false)) 'aac',
        '-c:v',
        'libx264',
        '-preset',
        'superfast',
        '-crf',
        _crfFor(options['quality'] as String?),
        '-threads',
        '0',
        outputPath,
      ],
    };
  }

  List<String> _fallbackArgumentsFor({
    required String inputPath,
    required String outputPath,
    required QuickEditorJob job,
    required Map<String, Object?> options,
  }) {
    if (job.type == QuickEditorJobType.audioSwap) {
      return [
        ..._commandPreamble,
        '-i',
        inputPath,
        if (_boolOption(options, 'loopAudio', false)) '-stream_loop',
        if (_boolOption(options, 'loopAudio', false)) '-1',
        '-ss',
        _secondsToTimestamp(_doubleOption(options, 'audioStart', 0)),
        '-to',
        _secondsToTimestamp(_doubleOption(options, 'audioEnd', 20)),
        '-i',
        _audioPath(options),
        '-map',
        '0:v:0',
        '-map',
        '1:a:0',
        '-c:v',
        'libx264',
        '-preset',
        'ultrafast',
        '-crf',
        '20',
        '-threads',
        '0',
        '-c:a',
        'aac',
        if (!_boolOption(options, 'loopAudio', false)) '-af',
        if (!_boolOption(options, 'loopAudio', false)) 'apad',
        '-t',
        _secondsToTimestamp(_doubleOption(options, 'videoDuration', 20)),
        outputPath,
      ];
    }
    return [
      ..._commandPreamble,
      '-i',
      inputPath,
      '-an',
      '-c:v',
      'libx264',
      '-preset',
      'ultrafast',
      '-crf',
      '20',
      '-threads',
      '0',
      outputPath,
    ];
  }

  Future<FFmpegSession> _executeWithProgress(
    List<String> arguments, {
    required double expectedDuration,
    void Function(double progress)? onProgress,
  }) async {
    final completer = Completer<FFmpegSession>();
    await FFmpegKit.executeWithArgumentsAsync(
      arguments,
      (session) {
        if (!completer.isCompleted) completer.complete(session);
      },
      null,
      (statistics) {
        if (expectedDuration <= 0) return;
        final processedSeconds = statistics.getTime() / 1000;
        final ratio = (processedSeconds / expectedDuration).clamp(0.0, 1.0);
        onProgress?.call(0.08 + ratio * 0.82);
      },
    );
    return completer.future;
  }

  Future<double> _expectedOutputDuration({
    required String inputPath,
    required QuickEditorJob job,
    required Map<String, Object?> options,
  }) async {
    if (job.type == QuickEditorJobType.trim ||
        job.type == QuickEditorJobType.videoToGif) {
      final selectedDuration =
          (_doubleOption(options, 'endTime', 0) -
                  _doubleOption(options, 'startTime', 0))
              .clamp(0.0, 86400.0);
      if (job.type == QuickEditorJobType.videoToGif) {
        final speed = _doubleOption(options, 'speed', 1).clamp(0.5, 2.0);
        return selectedDuration / speed;
      }
      return selectedDuration;
    }
    if (job.type == QuickEditorJobType.audioSwap) {
      return _doubleOption(options, 'videoDuration', 0);
    }
    final supplied = _doubleOption(options, 'sourceDuration', 0);
    if (supplied > 0) return supplied;
    return await mediaDuration(inputPath) ?? 0;
  }

  @visibleForTesting
  List<String> buildArgumentsForTest({
    required String inputPath,
    required String outputPath,
    required QuickEditorJob job,
    required Map<String, Object?> options,
  }) => _argumentsFor(
    inputPath: inputPath,
    outputPath: outputPath,
    job: job,
    options: options,
  );

  String _audioPath(Map<String, Object?> options) {
    final path = (options['audioPath'] as String? ?? '').trim();
    if (path.isEmpty || !File(path).existsSync()) {
      throw const LocalEditorException('could_not_replace_audio');
    }
    return path;
  }

  String _gifFilter(Map<String, Object?> options) {
    final fps = (options['fps'] as int? ?? 15).clamp(10, 20);
    final width = switch (options['size'] as String? ?? 'medium') {
      'small' => 320,
      'original' => -1,
      _ => 480,
    };
    final speed = _doubleOption(options, 'speed', 1).clamp(0.5, 2.0);
    final scale = width == -1
        ? 'scale=iw:ih:flags=bilinear'
        : 'scale=$width:-1:flags=bilinear';
    return 'fps=$fps,$scale,setpts=PTS/$speed';
  }

  String _reelsFilter(Map<String, Object?> options) {
    final preset = options['preset'] as String? ?? 'reels';
    final mode = options['resizeMode'] as String? ?? 'smart_crop';
    final size = switch (preset) {
      'square' => (w: 1080, h: 1080),
      'landscape' => (w: 1920, h: 1080),
      _ => (w: 1080, h: 1920),
    };
    if (mode == 'fit_blur') {
      // Keep this single-input filter reliable on mobile FFmpeg builds.
      return 'scale=${size.w}:${size.h}:force_original_aspect_ratio=decrease:flags=bilinear,'
          'pad=${size.w}:${size.h}:(ow-iw)/2:(oh-ih)/2:#101828';
    }
    if (mode == 'fit_solid') {
      return 'scale=${size.w}:${size.h}:force_original_aspect_ratio=decrease:flags=bilinear,'
          'pad=${size.w}:${size.h}:(ow-iw)/2:(oh-ih)/2:black';
    }
    return 'scale=${size.w}:${size.h}:force_original_aspect_ratio=increase:flags=bilinear,'
        'crop=${size.w}:${size.h}';
  }

  static const _commandPreamble = [
    '-y',
    '-hide_banner',
    '-loglevel',
    'error',
    '-nostdin',
  ];

  bool _boolOption(Map<String, Object?> options, String key, bool fallback) {
    final value = options[key];
    return value is bool ? value : fallback;
  }

  double _doubleOption(
    Map<String, Object?> options,
    String key,
    double fallback,
  ) {
    final value = options[key];
    if (value is num) return value.toDouble();
    return fallback;
  }

  String _secondsToTimestamp(double seconds) {
    final total = seconds.round().clamp(0, 86400);
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final secs = total % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  String _crfFor(String? quality) {
    return switch (quality) {
      'low' => '32',
      'high' => '23',
      _ => '28',
    };
  }

  String _qualityLabel(QuickEditorJob job, Map<String, Object?> options) {
    return switch (job.type) {
      QuickEditorJobType.extractAudio =>
        (options['format'] as String? ?? 'mp3').toUpperCase(),
      QuickEditorJobType.compress => 'Compressed',
      QuickEditorJobType.trim => 'Trimmed',
      QuickEditorJobType.mute => 'Muted',
      QuickEditorJobType.export => 'MP4',
      QuickEditorJobType.audioSwap => 'Audio Swap',
      QuickEditorJobType.videoToGif => 'GIF',
      QuickEditorJobType.reelsShorts => 'Reel/Short',
    };
  }

  String _titleFor(
    QuickEditorJob job,
    String originalTitle,
    Map<String, Object?> options,
  ) {
    return switch (job.type) {
      QuickEditorJobType.audioSwap => 'Audio swapped $originalTitle',
      QuickEditorJobType.videoToGif => 'GIF $originalTitle',
      QuickEditorJobType.reelsShorts =>
        '${_reelsTitlePrefix(options['preset'] as String?)} $originalTitle',
      _ => 'Edited $originalTitle',
    };
  }

  String _platformFor(QuickEditorJob job, Map<String, Object?> options) {
    if (job.type != QuickEditorJobType.reelsShorts) return 'Editor';
    return switch (options['preset'] as String? ?? 'instagram') {
      'vertical' => 'Vertical Short Creator',
      'tiktok' => 'TikTok Creator',
      'snapchat' => 'Snapchat Spotlight Creator',
      _ => 'Instagram Reel Creator',
    };
  }

  String _reelsTitlePrefix(String? preset) {
    return switch (preset ?? 'instagram') {
      'vertical' => 'Vertical Short',
      'tiktok' => 'TikTok Video',
      'snapchat' => 'Snapchat Spotlight',
      _ => 'Instagram Reel',
    };
  }

  String _failureKeyFor(QuickEditorJob job) {
    return switch (job.type) {
      QuickEditorJobType.audioSwap => 'could_not_replace_audio',
      QuickEditorJobType.videoToGif => 'could_not_create_gif',
      QuickEditorJobType.reelsShorts => 'could_not_create_reel',
      _ => 'could_not_edit',
    };
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
  }
}

class LocalEditorException implements Exception {
  const LocalEditorException(this.message);

  final String message;

  @override
  String toString() => message;
}
