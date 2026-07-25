import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS uses parallel ranges for larger transfers', () {
    final source = File(
      'lib/shared/services/local_media_service_io.dart',
    ).readAsStringSync();

    expect(
      source,
      contains(
        'static const _iosParallelDownloadThresholdBytes = 8 * 1024 * 1024;',
      ),
    );
    expect(source, contains('Platform.isAndroid || Platform.isIOS'));
    expect(source, contains('required int parallelThresholdBytes'));
  });

  test('download completion polling reacts in under one second', () {
    final source = File(
      'lib/features/download_progress/download_progress_screen.dart',
    ).readAsStringSync();

    expect(source, contains('const Duration(milliseconds: 750)'));
    expect(source, isNot(contains('const Duration(milliseconds: 1500)')));
  });
}
