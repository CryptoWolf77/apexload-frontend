import 'dart:async';

import 'package:apexload/core/utils/platform_detector.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/media_info_model.dart';

class MockAnalyzeService {
  Future<MediaInfoModel> analyze(String url) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final platform = detectPlatformName(url);
    final lowerUrl = url.toLowerCase();
    final mediaType = _detectMockMediaType(lowerUrl, platform);
    final isImage = mediaType == MediaType.image;
    final title = switch (platform) {
      'Pinterest' when isImage => 'Pinterest design inspiration',
      'Instagram' when isImage => 'Creative Instagram photo post',
      'Snapchat' when isImage => 'Snapchat image story',
      'Instagram' => 'Creative reel with city lights',
      'Snapchat' => 'Behind-the-scenes snap story',
      _ => 'Amazing travel sunset video',
    };

    return MediaInfoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      mediaType: mediaType,
      platform: platform == 'Auto detect' ? 'TikTok' : platform,
      duration: isImage ? 'Image' : '00:32',
      thumbnailUrl: '',
      sourceUrl: url,
      formats: isImage ? _imageFormats : _videoFormats,
    );
  }

  MediaType _detectMockMediaType(String lowerUrl, String platform) {
    // TODO: Replace this local/demo media type guessing with the real VPS
    // analyze API response. Backend analysis should determine whether a social
    // URL points to video, image, carousel, audio, and which formats exist.
    final imageSignals = [
      'image',
      'photo',
      'photos',
      'picture',
      'pic',
      'jpg',
      'jpeg',
      'png',
      'webp',
      'pin',
      'pinterest',
      'instagram.com/p/',
      '/p/',
      '/photo/',
      '/photos/',
      '/image/',
    ];
    final videoSignals = [
      'video',
      'reel',
      'reels',
      'tiktok',
      'instagram.com/reel/',
      '/reel/',
      '/reels/',
    ];

    if (videoSignals.any(lowerUrl.contains)) {
      return MediaType.video;
    }
    if (imageSignals.any(lowerUrl.contains) || platform == 'Pinterest') {
      return MediaType.image;
    }

    // TODO: Defaulting unknown links to video is temporary mock behavior. The
    // VPS backend analyze endpoint will provide authoritative mediaType later.
    return MediaType.video;
  }

  static const _videoFormats = [
    DownloadFormatModel(
      id: 'mp4_480',
      label: 'MP4 480p',
      extension: 'mp4',
      type: DownloadType.video,
      isPremium: false,
      sizeLabel: '12 MB',
    ),
    DownloadFormatModel(
      id: 'mp4_720',
      label: 'MP4 720p',
      extension: 'mp4',
      type: DownloadType.video,
      isPremium: false,
      sizeLabel: '24 MB',
    ),
    DownloadFormatModel(
      id: 'mp4_1080',
      label: 'MP4 1080p',
      extension: 'mp4',
      type: DownloadType.video,
      isPremium: true,
      sizeLabel: '48 MB',
    ),
    DownloadFormatModel(
      id: 'mp4_2160',
      label: 'MP4 2160p / 4K',
      extension: 'mp4',
      type: DownloadType.video,
      isPremium: true,
      sizeLabel: 'Not available',
      isAvailable: false,
      unavailableReasonKey: 'notAvailableOnClip',
    ),
    DownloadFormatModel(
      id: 'mp3_audio',
      label: 'MP3 Audio',
      extension: 'mp3',
      type: DownloadType.audio,
      isPremium: true,
      sizeLabel: '4 MB',
    ),
    DownloadFormatModel(
      id: 'thumbnail',
      label: 'Thumbnail JPG',
      extension: 'jpg',
      type: DownloadType.image,
      isPremium: false,
      sizeLabel: '860 KB',
    ),
  ];

  static const _imageFormats = [
    DownloadFormatModel(
      id: 'original_image',
      label: 'Original Image',
      extension: 'jpg',
      type: DownloadType.image,
      isPremium: false,
      sizeLabel: 'Best available quality',
    ),
    DownloadFormatModel(
      id: 'jpg_image',
      label: 'JPG Image',
      extension: 'jpg',
      type: DownloadType.image,
      isPremium: false,
      sizeLabel: 'Standard format',
    ),
    DownloadFormatModel(
      id: 'png_image',
      label: 'PNG Image',
      extension: 'png',
      type: DownloadType.image,
      isPremium: false,
      sizeLabel: 'When available',
      isAvailable: false,
      unavailableReasonKey: 'notAvailableForImage',
    ),
    DownloadFormatModel(
      id: 'high_quality_image',
      label: 'High Quality Image',
      extension: 'jpg',
      type: DownloadType.image,
      isPremium: true,
      sizeLabel: 'Premium quality when available',
    ),
    DownloadFormatModel(
      id: 'compressed_image',
      label: 'Compressed Image',
      extension: 'jpg',
      type: DownloadType.image,
      isPremium: false,
      sizeLabel: 'Smaller file size',
    ),
  ];
}
