import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/utils/platform_detector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('supported platforms use the required YouTube-free order', () {
    expect(AppConstants.supportedPlatforms, const [
      'TikTok',
      'Instagram',
      'Snapchat',
      'X/Twitter',
      'Facebook',
      'Pinterest',
      'Reddit',
    ]);
    expect(
      AppConstants.supportedPlatforms.any(
        (platform) => platform.toLowerCase().contains('youtube'),
      ),
      isFalse,
    );
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    test('$platform exposes the same YouTube-free platform list', () {
      debugDefaultTargetPlatformOverride = platform;
      expect(AppConstants.availablePlatforms, AppConstants.supportedPlatforms);
      expect(AppConstants.availablePlatforms.length, 7);
    });
  }

  test('YouTube hosts are blocked on every Flutter target', () {
    const urls = [
      'https://www.youtube.com/shorts/abc',
      'https://youtube.com/watch?v=abc',
      'https://m.youtube.com/watch?v=abc',
      'https://music.youtube.com/watch?v=abc',
      'https://youtu.be/abc',
      'HTTPS://YOUTUBE.COM/SHORTS/ABC',
    ];

    for (final platform in [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.windows,
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      for (final url in urls) {
        expect(
          AppConstants.isBlockedSource(url),
          isTrue,
          reason: '$platform $url',
        );
        expect(detectPlatformName(url), 'Auto detect', reason: url);
      }
    }
  });

  test('supported and lookalike hosts are not blocked', () {
    expect(
      AppConstants.isBlockedSource('https://tiktok.com/@a/video/1'),
      isFalse,
    );
    expect(
      AppConstants.isBlockedSource('https://instagram.com/reel/x'),
      isFalse,
    );
    expect(
      AppConstants.isBlockedSource('https://youtube.com.example/video'),
      isFalse,
    );
  });

  test('remaining supported platform detection is unchanged', () {
    const expected = {
      'https://www.tiktok.com/@creator/video/1': 'TikTok',
      'https://www.instagram.com/reel/example/': 'Instagram',
      'https://www.snapchat.com/spotlight/example': 'Snapchat',
      'https://x.com/creator/status/1': 'X/Twitter',
      'https://www.facebook.com/watch/?v=1': 'Facebook',
      'https://www.pinterest.com/pin/1/': 'Pinterest',
      'https://www.reddit.com/r/videos/comments/example/': 'Reddit',
    };

    for (final entry in expected.entries) {
      expect(detectPlatformName(entry.key), entry.value, reason: entry.key);
    }
  });
}
