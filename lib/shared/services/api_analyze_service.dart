import 'package:apexload/core/network/api_client.dart';
import 'package:apexload/core/network/api_config.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/media_info_model.dart';
import 'package:apexload/shared/services/mock_analyze_service.dart';
import 'package:flutter/foundation.dart';

class ApiAnalyzeService {
  ApiAnalyzeService({ApiClient? client, MockAnalyzeService? mockAnalyzeService})
    : _client = client ?? ApiClient(),
      _mockAnalyzeService = mockAnalyzeService ?? MockAnalyzeService();

  final ApiClient _client;
  final MockAnalyzeService _mockAnalyzeService;

  Future<AnalyzeResult> analyze(String url) async {
    try {
      if (kDebugMode) {
        debugPrint('ApexLoad analyze request URL: $url');
      }
      final data = await _client.post(
        ApiConfig.analyzePath,
        data: {'url': url},
      );
      if (kDebugMode) {
        debugPrint(
          'ApexLoad analyze response: success=${data['success']} '
          'source=${data['source']} platform=${data['platform']}',
        );
      }
      final media = _mediaFromApi(url, data);
      return AnalyzeResult(media: media, usedMockFallback: false);
    } on Object catch (error) {
      if (!ApiConfig.enableMockAnalyzeFallback) {
        throw AnalyzeException(error.toString());
      }
      final fallback = await _mockAnalyzeService.analyze(url);
      return AnalyzeResult(
        media: fallback,
        usedMockFallback: true,
        fallbackReason: error.toString(),
      );
    }
  }

  MediaInfoModel _mediaFromApi(String sourceUrl, Map<String, dynamic> data) {
    if (data['success'] != true) {
      final message =
          (data['message'] as String?) ?? (data['error'] as String?);
      throw AnalyzeException(
        message?.trim().isNotEmpty == true
            ? message!
            : 'Could not analyze this link. Please try again.',
      );
    }
    final mediaType = _mediaType(data['mediaType'] as String?);
    final formatsData = data['formats'];
    final formats = formatsData is List
        ? formatsData
              .whereType<Map>()
              .map((item) => _formatFromApi(Map<String, dynamic>.from(item)))
              .toList()
        : <DownloadFormatModel>[];
    if (formats.isEmpty) {
      throw const AnalyzeException('Backend analyze returned no formats.');
    }

    return MediaInfoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? data['title'] as String
          : 'ApexLoad media',
      mediaType: mediaType,
      platform: (data['platform'] as String?)?.trim().isNotEmpty == true
          ? data['platform'] as String
          : 'Unknown',
      duration: data['duration'] as String? ?? '',
      thumbnailUrl: data['thumbnail'] as String? ?? '',
      sourceUrl: sourceUrl,
      formats: formats,
    );
  }

  DownloadFormatModel _formatFromApi(Map<String, dynamic> data) {
    final type = _downloadType(data['type'] as String?);
    final id = data['id'] as String? ?? data['quality'] as String? ?? 'format';
    final label = data['label'] as String? ?? id;
    final size = data['size'] as String?;
    final unavailableReason = data['unavailableReason'] as String?;

    return DownloadFormatModel(
      id: _normalizedFormatId(id, label, type),
      label: label,
      extension: _extensionFor(data, label, type),
      type: type,
      isPremium: data['premium'] == true,
      sizeLabel: size ?? 'Not available',
      isAvailable: data['available'] != false,
      unavailableReasonKey: unavailableReason,
    );
  }

  String _normalizedFormatId(String id, String label, DownloadType type) {
    return switch (id) {
      'original' => 'original_image',
      'jpg' => 'jpg_image',
      'png' => 'png_image',
      'high_quality' => 'high_quality_image',
      'compressed' => 'compressed_image',
      'mp3' => 'mp3_audio',
      'thumbnail' => 'thumbnail',
      _ when type == DownloadType.video && id.startsWith(RegExp(r'\d')) =>
        'mp4_${id.replaceAll('p', '')}',
      _ => id,
    };
  }

  MediaType _mediaType(String? value) {
    return switch (value?.toLowerCase()) {
      'image' => MediaType.image,
      'audio' => MediaType.audio,
      _ => MediaType.video,
    };
  }

  DownloadType _downloadType(String? value) {
    return switch (value?.toLowerCase()) {
      'audio' => DownloadType.audio,
      'image' => DownloadType.image,
      _ => DownloadType.video,
    };
  }

  String _extensionFor(
    Map<String, dynamic> data,
    String label,
    DownloadType type,
  ) {
    final quality = (data['quality'] as String?)?.toLowerCase() ?? '';
    final lowerLabel = label.toLowerCase();
    if (type == DownloadType.audio) return 'mp3';
    if (type == DownloadType.video) return 'mp4';
    if (quality.contains('png') || lowerLabel.contains('png')) return 'png';
    if (quality.contains('webp') || lowerLabel.contains('webp')) return 'webp';
    return 'jpg';
  }
}

class AnalyzeResult {
  const AnalyzeResult({
    required this.media,
    required this.usedMockFallback,
    this.fallbackReason,
  });

  final MediaInfoModel media;
  final bool usedMockFallback;
  final String? fallbackReason;
}

class AnalyzeException implements Exception {
  const AnalyzeException(this.message);

  final String message;

  @override
  String toString() => message;
}
