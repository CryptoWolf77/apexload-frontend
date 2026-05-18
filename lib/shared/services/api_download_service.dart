import 'package:apexload/core/network/api_client.dart';
import 'package:apexload/core/network/api_config.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/services/file_download_helper.dart';
import 'package:flutter/foundation.dart';

class ApiDownloadService {
  ApiDownloadService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<ApiDownloadJob> startDownload({
    required String url,
    required List<DownloadFormatModel> selectedFormats,
    required bool premium,
    required bool noWatermark,
  }) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      throw const ApiDownloadException('Download request URL is empty.');
    }
    if (selectedFormats.isEmpty) {
      throw const ApiDownloadException('No download options selected.');
    }
    final selectedItems = [
      for (final format in selectedFormats)
        {'formatId': _apiFormatId(format), 'type': _apiType(format.type)},
    ];
    if (selectedItems.any((item) => (item['formatId'] ?? '').isEmpty)) {
      throw const ApiDownloadException('Download request has empty formatId.');
    }
    final requestBody = {
      'url': trimmedUrl,
      'selectedItems': selectedItems,
      'premium': premium,
      'noWatermark': noWatermark,
    };
    if (kDebugMode) {
      debugPrint('ApexLoad download request: $requestBody');
    }
    final data = await _client.post(ApiConfig.downloadPath, data: requestBody);
    if (kDebugMode) {
      debugPrint('ApexLoad download response: $data');
    }
    if (data['success'] != true) {
      throw ApiDownloadException(
        data['message'] as String? ??
            data['error'] as String? ??
            'Backend download returned success=false.',
      );
    }
    final jobId = data['jobId'] as String? ?? '';
    if (jobId.isEmpty) {
      throw const ApiDownloadException('Backend download returned no jobId.');
    }
    return ApiDownloadJob(
      jobId: jobId,
      status: data['status'] as String? ?? 'queued',
      message: data['message'] as String? ?? '',
    );
  }

  Future<ApiDownloadStatus> getStatus(String jobId) async {
    if (kDebugMode) {
      debugPrint('ApexLoad download status request: $jobId');
    }
    final data = await _client.get(ApiConfig.downloadStatusPath(jobId));
    if (kDebugMode) {
      debugPrint('ApexLoad download status response: $data');
    }
    final files = data['files'] is List
        ? (data['files'] as List)
              .whereType<Map>()
              .map(
                (item) =>
                    ApiDownloadFile.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <ApiDownloadFile>[];
    return ApiDownloadStatus(
      jobId: data['jobId'] as String? ?? jobId,
      status: data['status'] as String? ?? 'processing',
      progress: _intValue(data['progress']),
      platform: data['platform'] as String?,
      message: data['message'] as String? ?? '',
      files: files,
      error: data['error'] as String?,
      success: data['success'] == true,
    );
  }

  String fullFileUrl(ApiDownloadFile file) {
    final value = file.downloadUrl.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) return '${ApiConfig.baseUrl}$value';
    return '${ApiConfig.baseUrl}/$value';
  }

  Future<String?> saveOrOpenFile(ApiDownloadFile file) async {
    final url = fullFileUrl(file);
    if (kDebugMode) {
      debugPrint('ApexLoad completed file URL: $url');
    }
    final fileName = _safeFileName(
      file.fileName.isEmpty ? file.fileId : file.fileName,
    );
    return FileDownloadHelper.saveOrOpen(url: url, fileName: fileName);
  }

  String _apiFormatId(DownloadFormatModel format) {
    return switch (format.id) {
      'mp4_480' => '480p',
      'mp4_720' => '720p',
      'mp4_1080' => '1080p',
      'mp4_2160' => '2160p',
      'mp3_audio' => 'mp3',
      'original_image' => 'original',
      'jpg_image' => 'jpg',
      'png_image' => 'png',
      'high_quality_image' => 'high_quality',
      'compressed_image' => 'compressed',
      _ => format.id,
    };
  }

  String _apiType(DownloadType type) {
    return switch (type) {
      DownloadType.audio => 'audio',
      DownloadType.image => 'image',
      DownloadType.video => 'video',
    };
  }

  int _intValue(Object? value) {
    if (value is int) return value.clamp(0, 100);
    if (value is num) return value.round().clamp(0, 100);
    return 0;
  }

  String _safeFileName(String value) {
    final sanitized = value
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_')
        .replaceAll(RegExp(r'^\.+'), '')
        .trim();
    return sanitized.isEmpty ? 'apexload_download' : sanitized;
  }
}

class ApiDownloadException implements Exception {
  const ApiDownloadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiDownloadJob {
  const ApiDownloadJob({
    required this.jobId,
    required this.status,
    required this.message,
  });

  final String jobId;
  final String status;
  final String message;
}

class ApiDownloadStatus {
  const ApiDownloadStatus({
    required this.jobId,
    required this.status,
    required this.progress,
    required this.message,
    required this.files,
    required this.success,
    this.platform,
    this.error,
  });

  final String jobId;
  final String status;
  final int progress;
  final String? platform;
  final String message;
  final List<ApiDownloadFile> files;
  final bool success;
  final String? error;
}

class ApiDownloadFile {
  const ApiDownloadFile({
    required this.fileId,
    required this.fileName,
    required this.type,
    required this.size,
    required this.downloadUrl,
  });

  factory ApiDownloadFile.fromJson(Map<String, dynamic> json) {
    final fileName =
        json['fileName'] as String? ?? json['filename'] as String? ?? '';
    return ApiDownloadFile(
      fileId: json['fileId'] as String? ?? '',
      fileName: fileName,
      type: json['type'] as String? ?? '',
      size: json['size'] as String? ?? '',
      downloadUrl: json['downloadUrl'] as String? ?? '',
    );
  }

  final String fileId;
  final String fileName;
  final String type;
  final String size;
  final String downloadUrl;
}
