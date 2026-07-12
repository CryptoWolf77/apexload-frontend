import 'package:apexload/core/network/api_client.dart';
import 'package:apexload/core/network/api_config.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/media_info_model.dart';
import 'package:apexload/shared/services/api_analyze_service.dart';
import 'package:apexload/shared/services/api_download_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'ApiAnalyzeService maps backend video response into app models',
    () async {
      final service = ApiAnalyzeService(
        client: _FakeApiClient(postData: _videoAnalyzeResponse),
      );

      final result = await service.analyze(
        'https://www.instagram.com/reel/demo',
      );

      expect(result.usedMockFallback, isFalse);
      expect(result.media.mediaType, MediaType.video);
      expect(result.media.platform, 'Instagram');
      expect(result.media.formats.length, 2);
      expect(result.media.formats.first.id, 'mp4_1080');
      expect(result.media.formats.first.type, DownloadType.video);
      expect(result.media.formats.first.isPremium, isTrue);
      expect(result.media.formats.last.id, 'thumbnail');
      expect(result.media.formats.last.extension, 'jpg');
    },
  );

  test(
    'ApiAnalyzeService maps backend image response into app models',
    () async {
      final service = ApiAnalyzeService(
        client: _FakeApiClient(postData: _imageAnalyzeResponse),
      );

      final result = await service.analyze('https://www.instagram.com/p/demo');

      expect(result.media.mediaType, MediaType.image);
      expect(result.media.duration, isEmpty);
      expect(
        result.media.formats.every(
          (format) => format.type == DownloadType.image,
        ),
        isTrue,
      );
      expect(result.media.formats.first.id, 'original_image');
      expect(result.media.formats.last.id, 'png_image');
      expect(result.media.formats.last.isAvailable, isFalse);
      expect(
        result.media.formats.last.unavailableReasonKey,
        'Not available for this image',
      );
    },
  );

  test('ApiAnalyzeService reports unusable backend responses', () async {
    final service = ApiAnalyzeService(
      client: _FakeApiClient(postData: {'success': false}),
    );

    expect(
      () => service.analyze('https://www.instagram.com/p/demo'),
      throwsA(isA<AnalyzeException>()),
    );
  });

  test(
    'ApiDownloadService sends backend skeleton payload and reads status',
    () async {
      final client = _FakeApiClient(
        postData: {
          'success': true,
          'jobId': 'job_demo_test',
          'status': 'queued',
          'message': 'Demo download job created',
        },
        getData: {
          'success': true,
          'jobId': 'job_demo_test',
          'status': 'completed',
          'progress': 100,
          'message': 'Demo files are ready',
          'files': [
            {
              'fileId': 'demo_video_1',
              'fileName': 'apexload_demo_video.mp4',
              'type': 'video',
              'size': '24 MB',
              'downloadUrl': '/api/file/demo_video_1',
            },
          ],
        },
      );
      final service = ApiDownloadService(client: client);

      final job = await service.startDownload(
        url: 'https://www.instagram.com/reel/demo',
        selectedFormats: const [
          DownloadFormatModel(
            id: 'mp4_1080',
            label: 'MP4 1080p',
            extension: 'mp4',
            type: DownloadType.video,
            isPremium: true,
            sizeLabel: '42 MB',
          ),
        ],
        premium: true,
        noWatermark: true,
      );
      final status = await service.getStatus(job.jobId);

      expect(client.lastPostPath, ApiConfig.downloadPath);
      expect(client.lastPostData?.keys.toList(), [
        'url',
        'selectedItems',
        'premium',
        'noWatermark',
      ]);
      expect(
        client.lastPostData?['url'],
        'https://www.instagram.com/reel/demo',
      );
      expect(client.lastPostData?['premium'], true);
      expect(client.lastPostData?['noWatermark'], true);
      expect(client.lastPostData?['selectedItems'], [
        {'formatId': '1080p', 'type': 'video'},
      ]);
      expect(job.jobId, 'job_demo_test');
      expect(status.progress, 100);
      expect(status.files.single.fileId, 'demo_video_1');
    },
  );

  test('ApiDownloadService rejects missing job id', () async {
    final service = ApiDownloadService(
      client: _FakeApiClient(postData: {'success': true}),
    );

    expect(
      () => service.startDownload(
        url: 'https://www.instagram.com/reel/demo',
        selectedFormats: const [
          DownloadFormatModel(
            id: 'mp4_720',
            label: 'MP4 720p',
            extension: 'mp4',
            type: DownloadType.video,
            isPremium: false,
            sizeLabel: '24 MB',
          ),
        ],
        premium: false,
        noWatermark: false,
      ),
      throwsA(isA<ApiDownloadException>()),
    );
  });

  test(
    'ApiDownloadService rejects empty selected items before posting',
    () async {
      final client = _FakeApiClient(
        postData: {'success': true, 'jobId': 'job_demo_test'},
      );
      final service = ApiDownloadService(client: client);

      expect(
        () => service.startDownload(
          url: 'https://www.instagram.com/reel/demo',
          selectedFormats: const [],
          premium: false,
          noWatermark: false,
        ),
        throwsA(isA<ApiDownloadException>()),
      );
      expect(client.lastPostPath, isNull);
    },
  );

  test('ApiDownloadService rejects empty URL before posting', () async {
    final client = _FakeApiClient(
      postData: {'success': true, 'jobId': 'job_demo_test'},
    );
    final service = ApiDownloadService(client: client);

    expect(
      () => service.startDownload(
        url: ' ',
        selectedFormats: const [
          DownloadFormatModel(
            id: 'mp4_720',
            label: 'MP4 720p',
            extension: 'mp4',
            type: DownloadType.video,
            isPremium: false,
            sizeLabel: '24 MB',
          ),
        ],
        premium: false,
        noWatermark: false,
      ),
      throwsA(isA<ApiDownloadException>()),
    );
    expect(client.lastPostPath, isNull);
  });
}

const _videoAnalyzeResponse = {
  'success': true,
  'platform': 'Instagram',
  'mediaType': 'video',
  'title': 'Amazing travel sunset video',
  'thumbnail': 'https://picsum.photos/600/400',
  'duration': '00:32',
  'formats': [
    {
      'id': '1080p',
      'label': 'MP4 1080p',
      'type': 'video',
      'quality': '1080p',
      'size': '42 MB',
      'premium': true,
      'available': true,
    },
    {
      'id': 'thumbnail',
      'label': 'Thumbnail JPG',
      'type': 'image',
      'quality': 'thumbnail',
      'size': '860 KB',
      'premium': false,
      'available': true,
    },
  ],
};

const _imageAnalyzeResponse = {
  'success': true,
  'platform': 'Instagram',
  'mediaType': 'image',
  'title': 'Creative Instagram photo post',
  'thumbnail': 'https://picsum.photos/600/600',
  'duration': null,
  'formats': [
    {
      'id': 'original',
      'label': 'Original Image',
      'type': 'image',
      'quality': 'original',
      'size': '2.4 MB',
      'premium': false,
      'available': true,
    },
    {
      'id': 'png',
      'label': 'PNG Image',
      'type': 'image',
      'quality': 'png',
      'size': null,
      'premium': true,
      'available': false,
      'unavailableReason': 'Not available for this image',
    },
  ],
};

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.postData = const {}, this.getData = const {}});

  final Map<String, dynamic> postData;
  final Map<String, dynamic> getData;
  String? lastPostPath;
  Map<String, dynamic>? lastPostData;

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    return postData;
  }

  @override
  Future<Map<String, dynamic>> get(String path) async => getData;
}
