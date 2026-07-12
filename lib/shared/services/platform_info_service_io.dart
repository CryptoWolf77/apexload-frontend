import 'dart:io';

class PlatformInfoService {
  const PlatformInfoService._();

  static String get platformName {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return Platform.operatingSystem;
  }

  static String get operatingSystemVersion => Platform.operatingSystemVersion;
}
