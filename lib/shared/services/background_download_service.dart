import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps Android's download process alive and gives iOS time to schedule its
/// native background URLSession transfers. Independent of the screen setting.
class BackgroundDownloadService {
  BackgroundDownloadService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('apexload/background');

  final MethodChannel _channel;
  int _operations = 0;
  Future<void> _pending = Future<void>.value();

  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> begin() {
    _operations++;
    return _sync();
  }

  Future<void> end() {
    if (_operations > 0) _operations--;
    return _sync();
  }

  Future<T> run<T>(Future<T> Function() task) async {
    await begin();
    try {
      return await task();
    } finally {
      await end();
    }
  }

  Future<void> _sync() {
    return _pending = _pending.then((_) async {
      if (!supported) return;
      try {
        await _channel.invokeMethod<void>(_operations > 0 ? 'begin' : 'end');
      } on MissingPluginException {
        // Desktop, tests, or an older native host.
      } on PlatformException catch (error) {
        debugPrint('ApexLoad background protection: ${error.code}');
      }
    });
  }

  Future<void> dispose() {
    _operations = 0;
    return _sync();
  }
}
