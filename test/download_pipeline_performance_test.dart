import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS delegates file transfers to the native background session', () {
    final source = File(
      'lib/shared/services/local_media_service_io.dart',
    ).readAsStringSync();

    expect(source, contains("if (Platform.isIOS)"));
    expect(source, contains("'apexload/background'"));
    expect(source, contains("'downloadFile',"));
    final native = File(
      'ios/Runner/BackgroundTransfers.swift',
    ).readAsStringSync();
    expect(native, contains('URLSessionConfiguration.background'));
    expect(native, contains('session.downloadTask'));
  });

  test('download completion polling reacts in under one second', () {
    final source = File(
      'lib/shared/services/download_coordinator.dart',
    ).readAsStringSync();

    expect(source, contains('const Duration(milliseconds: 750)'));
    expect(source, isNot(contains('const Duration(milliseconds: 1500)')));
  });
}
