import 'dart:async';

import 'package:apexload/core/utils/platform_detector.dart';
import 'package:apexload/core/network/api_config.dart';
import 'package:apexload/shared/services/legal_consent_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Extracts a web URL from the captions supplied by social apps.
String? extractSharedVideoUrl(String text) {
  final urls = <String>[];
  for (final match in RegExp(
    r'''https?://[^\s<>"\u0000-\u001f]+''',
    caseSensitive: false,
  ).allMatches(text)) {
    var value = match.group(0)!.replaceAll('&amp;', '&');
    value = value.replaceFirst(RegExp(r'''[.,;:!?\)\]\}'”»،。]+$'''), '');
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      continue;
    }
    urls.add(value);
  }
  if (urls.isEmpty) return null;
  return urls.firstWhere(
    (url) => detectPlatformName(url) != 'Auto detect',
    orElse: () => urls.first,
  );
}

class IncomingShareService with WidgetsBindingObserver {
  IncomingShareService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('apexload/share');
  final MethodChannel _channel;
  final pendingText = ValueNotifier<String?>(null);
  bool _started = false;
  bool _disposed = false;
  bool _reading = false;
  bool _readAgain = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'sharedTextAvailable') await _read();
    });
    await _read();
  }

  Future<void> _read() async {
    if (_disposed) return;
    if (_reading) {
      _readAgain = true;
      return;
    }
    _reading = true;
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _channel.invokeMethod<void>('setShareConsent', {
          'accepted': await const LegalConsentService()
              .hasAcceptedResponsibleUse(),
          'analyzeUrl': '${ApiConfig.baseUrl}${ApiConfig.analyzePath}',
        });
      }
      final text = await _channel.invokeMethod<String>('takeSharedText');
      if (!_disposed && text != null && text.trim().isNotEmpty) {
        // A repeated intentional share should trigger analysis again.
        pendingText.value = null;
        pendingText.value = text;
      }
    } on MissingPluginException {
      // Web/desktop hosts do not receive native shares.
    } on PlatformException catch (error) {
      debugPrint('ApexLoad incoming share: ${error.code}');
    } finally {
      _reading = false;
      if (_readAgain) {
        _readAgain = false;
        unawaited(_read());
      }
    }
  }

  void clear() => pendingText.value = null;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_read());
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _channel.setMethodCallHandler(null);
    pendingText.dispose();
  }
}
