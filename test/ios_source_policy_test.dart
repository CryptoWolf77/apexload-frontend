import 'package:apexload/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS platform list excludes YouTube', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(AppConstants.availablePlatforms, isNot(contains('YouTube Shorts')));
    expect(AppConstants.availablePlatforms.length, 7);
    debugDefaultTargetPlatformOverride = null;
  });

  test('Android keeps every platform', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(AppConstants.availablePlatforms, contains('YouTube Shorts'));
    expect(AppConstants.availablePlatforms.length, 8);
    debugDefaultTargetPlatformOverride = null;
  });

  test('iOS refuses YouTube URLs, Android does not', () {
    const urls = [
      'https://www.youtube.com/shorts/abc',
      'https://youtu.be/abc',
      'https://m.youtube.com/watch?v=abc',
      'HTTPS://YOUTUBE.COM/SHORTS/ABC',
    ];
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    for (final u in urls) {
      expect(AppConstants.isBlockedSource(u), isTrue, reason: u);
    }
    expect(AppConstants.isBlockedSource('https://tiktok.com/@a/video/1'), isFalse);
    expect(AppConstants.isBlockedSource('https://instagram.com/reel/x'), isFalse);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    for (final u in urls) {
      expect(AppConstants.isBlockedSource(u), isFalse, reason: u);
    }
    debugDefaultTargetPlatformOverride = null;
  });
}
