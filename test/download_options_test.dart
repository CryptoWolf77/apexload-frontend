import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/core/theme/app_theme.dart';
import 'package:apexload/features/download_options/download_options_screen.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/media_info_model.dart';
import 'package:apexload/shared/services/api_download_service.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'Instagram video hides thumbnail and preserves video and audio options',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final media = _videoMedia();

      await _pumpDownloadOptions(tester, media: media);

      expect(find.text('MP4 480p'), findsOneWidget);
      expect(find.text('MP4 720p'), findsOneWidget);
      expect(find.text('MP4 1080p'), findsOneWidget);
      expect(find.text('MP4 2160p / 4K'), findsOneWidget);
      expect(find.text('Not available on this clip'), findsOneWidget);
      expect(find.text('MP3 Audio'), findsOneWidget);
      expect(find.text('Thumbnail JPG'), findsNothing);
      // Watermark removal was withdrawn for App Review guideline 5.2.3.
      expect(find.text('No watermark when available'), findsNothing);
      expect(find.text('No watermark applied when available'), findsNothing);
    },
  );

  for (final platform in [
    'YouTube Shorts',
    'Facebook',
    'TikTok',
    'X/Twitter',
    'Snapchat',
  ]) {
    testWidgets('$platform keeps its Thumbnail JPG option', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await _pumpDownloadOptions(
        tester,
        media: _videoMedia(platform: platform),
      );

      expect(find.text('Thumbnail JPG'), findsOneWidget);
      expect(find.text('MP4 720p'), findsOneWidget);
      expect(find.text('MP3 Audio'), findsOneWidget);
    });
  }

  testWidgets(
    'Instagram image formats remain while only the separate thumbnail is hidden',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      await _pumpDownloadOptions(tester, media: _instagramImageMedia());

      expect(find.text('Choose image format'), findsOneWidget);
      expect(find.text('Original Image'), findsOneWidget);
      expect(find.text('JPG Image'), findsOneWidget);
      expect(find.text('Carousel Image'), findsOneWidget);
      expect(find.text('Thumbnail JPG'), findsNothing);
    },
  );

  testWidgets('image options do not show video or audio formats', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final media = _imageMedia();

    await _pumpDownloadOptions(tester, media: media);

    expect(find.text('Choose image format'), findsOneWidget);
    expect(find.text('Original Image'), findsOneWidget);
    expect(find.text('JPG Image'), findsOneWidget);
    expect(find.text('PNG Image'), findsOneWidget);
    expect(find.text('High Quality Image'), findsOneWidget);
    expect(find.text('Compressed Image'), findsOneWidget);
    expect(find.text('Not available for this image'), findsOneWidget);
    expect(find.text('MP4 480p'), findsNothing);
    expect(find.text('MP3 Audio'), findsNothing);
  });

  testWidgets('watermark removal is not offered to anyone, premium included', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'subscription_is_premium': true,
      'subscription_plan_name': 'Yearly',
      'subscription_downloads_used_today': 0,
      'subscription_last_reset_date': DateTime.now().toIso8601String(),
      'subscription_premium_mock': true,
    });
    final media = _videoMedia();

    await _pumpDownloadOptions(tester, media: media);
    await tester.pumpAndSettle();

    expect(find.text('No watermark applied when available'), findsNothing);
    expect(find.text('No watermark when available'), findsNothing);
  });

  testWidgets('first download rights confirmation can cancel download', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'responsible_use_agreement_v1': true,
    });
    final fakeDownloadService = _FakeApiDownloadService();

    await _pumpDownloadOptions(
      tester,
      media: _videoMedia(),
      apiDownloadService: fakeDownloadService,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('MP4 480p'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Download'),
      500,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm your right to download'), findsOneWidget);
    final continueButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(fakeDownloadService.called, isFalse);
  });
}

MediaInfoModel _videoMedia({String platform = 'Instagram'}) {
  return MediaInfoModel(
    id: 'video_test',
    title: 'Creative reel with city lights',
    mediaType: MediaType.video,
    platform: platform,
    duration: '00:32',
    thumbnailUrl: '',
    sourceUrl: 'https://www.instagram.com/reel/demo',
    formats: [
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
    ],
  );
}

MediaInfoModel _instagramImageMedia() {
  return const MediaInfoModel(
    id: 'instagram_image_test',
    title: 'Instagram image post',
    mediaType: MediaType.image,
    platform: 'Instagram',
    duration: 'Image',
    thumbnailUrl: '',
    sourceUrl: 'https://www.instagram.com/p/demo-image',
    formats: [
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
        id: 'carousel_image',
        label: 'Carousel Image',
        extension: 'jpg',
        type: DownloadType.image,
        isPremium: false,
        sizeLabel: 'Carousel item',
      ),
      DownloadFormatModel(
        id: 'thumbnail',
        label: 'Thumbnail JPG',
        extension: 'jpg',
        type: DownloadType.image,
        isPremium: false,
        sizeLabel: '860 KB',
      ),
    ],
  );
}

MediaInfoModel _imageMedia() {
  return const MediaInfoModel(
    id: 'image_test',
    title: 'Minimal workspace inspiration image',
    mediaType: MediaType.image,
    platform: 'Pinterest',
    duration: 'Image',
    thumbnailUrl: '',
    sourceUrl: 'https://www.pinterest.com/pin/demo-image',
    formats: [
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
    ],
  );
}

Future<void> _pumpDownloadOptions(
  WidgetTester tester, {
  required MediaInfoModel media,
  ApiDownloadService? apiDownloadService,
}) {
  tester.view.physicalSize = const Size(430, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (apiDownloadService != null)
          apiDownloadServiceProvider.overrideWithValue(apiDownloadService),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: DownloadOptionsScreen(media: media),
      ),
    ),
  );
}

class _FakeApiDownloadService extends ApiDownloadService {
  bool called = false;

  @override
  Future<ApiDownloadJob> startDownload({
    required String url,
    required List<DownloadFormatModel> selectedFormats,
    required bool premium,
    required bool noWatermark,
  }) async {
    called = true;
    return const ApiDownloadJob(
      jobId: 'job_test',
      status: 'queued',
      message: 'queued',
    );
  }
}
