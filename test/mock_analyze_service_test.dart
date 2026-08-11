import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/media_info_model.dart';
import 'package:apexload/shared/services/mock_analyze_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('video mock data has separate 1080p and 4K options', () async {
    final media = await MockAnalyzeService().analyze(
      'https://www.instagram.com/reel/demo',
    );

    expect(media.mediaType, MediaType.video);
    expect(media.formats.any((format) => format.label == 'MP4 1080p'), isTrue);
    expect(
      media.formats.any((format) => format.label == 'MP4 2160p / 4K'),
      isTrue,
    );
    expect(media.formats.any((format) => format.id == 'no_watermark'), isFalse);
  });

  test('image mock data only returns image download formats', () async {
    final media = await MockAnalyzeService().analyze(
      'https://www.pinterest.com/pin/demo-image',
    );

    expect(media.mediaType, MediaType.image);
    expect(
      media.formats.every((format) => format.type == DownloadType.image),
      isTrue,
    );
    expect(media.formats.any((format) => format.extension == 'mp4'), isFalse);
    expect(media.formats.any((format) => format.extension == 'mp3'), isFalse);
  });

  test('Instagram post links are treated as image mock data', () async {
    final media = await MockAnalyzeService().analyze(
      'https://www.instagram.com/p/demo-photo-post',
    );

    expect(media.mediaType, MediaType.image);
    expect(media.title, 'Creative Instagram photo post');
    expect(
      media.formats.every((format) => format.type == DownloadType.image),
      isTrue,
    );
  });

  test('Instagram reel links are treated as video mock data', () async {
    final media = await MockAnalyzeService().analyze(
      'https://www.instagram.com/reel/demo-video',
    );

    expect(media.mediaType, MediaType.video);
    expect(media.formats.any((format) => format.extension == 'mp4'), isTrue);
    expect(media.formats.any((format) => format.extension == 'mp3'), isTrue);
  });

  test('Snapchat image-looking links are treated as image mock data', () async {
    final media = await MockAnalyzeService().analyze(
      'https://www.snapchat.com/add/demo/photo/story',
    );

    expect(media.mediaType, MediaType.image);
    expect(media.title, 'Snapchat image story');
  });

  test('common image keywords are treated as image mock data', () async {
    final urls = [
      'https://example.com/photo/story.webp',
      'https://example.com/picture/demo.jpg',
      'https://www.pinterest.com/pin/design-inspiration',
    ];

    for (final url in urls) {
      final media = await MockAnalyzeService().analyze(url);
      expect(media.mediaType, MediaType.image, reason: url);
      expect(
        media.formats.every((format) => format.type == DownloadType.image),
        isTrue,
        reason: url,
      );
    }
  });

  test('common video keywords are treated as video mock data', () async {
    final urls = [
      'https://www.tiktok.com/@creator/video/123',
      'https://example.com/watch/demo-video',
    ];

    for (final url in urls) {
      final media = await MockAnalyzeService().analyze(url);
      expect(media.mediaType, MediaType.video, reason: url);
      expect(
        media.formats.any((format) => format.type == DownloadType.video),
        isTrue,
        reason: url,
      );
    }
  });
}
