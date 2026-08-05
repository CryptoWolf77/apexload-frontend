import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConstants {
  const AppConstants._();

  static const appName = 'ApexLoad';
  static const storeName = 'ApexLoad: Video Saver & Editor';
  static const subtitle = 'Video Saver & Editor';
  static const tagline = 'Save smarter. Edit faster.';
  static const version = '1.0.0';

  static const legalNotice =
      'This app is intended only for downloading content you own, have permission to use, or content that is publicly allowed to be downloaded. Users are responsible for respecting copyright and platform terms.';

  static const supportedPlatforms = [
    'TikTok',
    'Instagram',
    'Facebook',
    'X/Twitter',
    'YouTube Shorts',
    'Pinterest',
    'Reddit',
    'Snapchat',
  ];

  /// YouTube's Terms of Service prohibit saving its media, and App Review
  /// guideline 5.2.3 names YouTube explicitly. The iOS build therefore offers
  /// no YouTube support at all — it is not listed, not detected, and URLs are
  /// refused before any request leaves the device.
  static const iosSupportedPlatforms = [
    'TikTok',
    'Instagram',
    'Facebook',
    'X/Twitter',
    'Pinterest',
    'Reddit',
    'Snapchat',
  ];

  static const unsupportedOnIosPlatform = 'YouTube Shorts';

  static bool get isIosBuild =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Platforms this build is allowed to offer.
  static List<String> get availablePlatforms =>
      isIosBuild ? iosSupportedPlatforms : supportedPlatforms;

  /// True when the link points at a source this build must not handle.
  static bool isBlockedSource(String url) {
    if (!isIosBuild) return false;
    final value = url.toLowerCase();
    return value.contains('youtube.') ||
        value.contains('youtu.be') ||
        value.contains('//youtube') ||
        value.contains('m.youtube');
  }
}

class AppColors {
  const AppColors._();

  static const background = Color(0xFF0B1020);
  static const card = Color(0xFF151B2E);
  static const cardLight = Color(0xFF202842);
  static const primaryStart = Color(0xFF6C63FF);
  static const primaryEnd = Color(0xFF00D4FF);
  static const lightPrimaryEnd = Color(0xFF00B8D9);
  static const premiumGold = Color(0xFFFFD166);
  static const lightPremiumGold = Color(0xFFD99A00);
  static const success = Color(0xFF22C55E);
  static const lightSuccess = Color(0xFF16A34A);
  static const error = Color(0xFFEF4444);
  static const lightError = Color(0xFFDC2626);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFAAB3C5);
  static const lightBackground = Color(0xFFF7F8FC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceSecondary = Color(0xFFEEF1F8);
  static const lightTextPrimary = Color(0xFF101828);
  static const lightTextSecondary = Color(0xFF667085);
  static const lightBorder = Color(0xFFD9E0EC);
}

class AppTone {
  const AppTone._();

  static bool isLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  static Color textPrimary(BuildContext context) =>
      isLight(context) ? AppColors.lightTextPrimary : AppColors.textPrimary;

  static Color textSecondary(BuildContext context) =>
      isLight(context) ? AppColors.lightTextSecondary : AppColors.textSecondary;

  static Color card(BuildContext context) =>
      isLight(context) ? AppColors.lightSurface : AppColors.card;

  static Color cardSecondary(BuildContext context) =>
      isLight(context) ? AppColors.lightSurfaceSecondary : AppColors.cardLight;

  static Color border(BuildContext context) => isLight(context)
      ? AppColors.lightBorder
      : Colors.white.withValues(alpha: 0.08);
}
