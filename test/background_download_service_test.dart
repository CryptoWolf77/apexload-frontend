import 'dart:async';
import 'package:apexload/shared/services/background_download_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'overlapping downloads release native protection only after all finish',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      const channel = MethodChannel('apexload/background-test');
      final calls = <String>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return null;
      });
      final service = BackgroundDownloadService(channel: channel);
      addTearDown(() async {
        await service.dispose();
        messenger.setMockMethodCallHandler(channel, null);
        debugDefaultTargetPlatformOverride = null;
      });
      final hold = Completer<void>();
      final first = service.run(() => hold.future);
      await Future<void>.delayed(Duration.zero);
      await service.run(() async {});
      expect(calls, isNot(contains('end')));
      hold.complete();
      await first;
      expect(calls.last, 'end');
      expect(calls.where((call) => call == 'end'), hasLength(1));
      await expectLater(
        service.run(() async => throw StateError('failed')),
        throwsStateError,
      );
      expect(calls.last, 'end');
    },
  );
}
