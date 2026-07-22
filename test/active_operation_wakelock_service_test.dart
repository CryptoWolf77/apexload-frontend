import 'dart:async';

import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/services/active_operation_wakelock_service.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeWakelockAdapter implements WakelockAdapter {
  int enableCount = 0;
  int disableCount = 0;

  @override
  Future<void> enable() async {
    enableCount++;
  }

  @override
  Future<void> disable() async {
    disableCount++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'runWithWakelock enables during work and releases after success',
    () async {
      final adapter = _FakeWakelockAdapter();
      final service = ActiveOperationWakelockService(adapter: adapter);
      addTearDown(service.dispose);

      final result = await service.runWithWakelock(
        () async => 'done',
        reason: 'test success',
      );

      expect(result, 'done');
      expect(adapter.enableCount, 1);
      expect(adapter.disableCount, 1);
      expect(service.activeOperationCount, 0);
      expect(service.isWakelockActive.value, isFalse);
    },
  );

  test('runWithWakelock releases after task failure', () async {
    final adapter = _FakeWakelockAdapter();
    final service = ActiveOperationWakelockService(adapter: adapter);
    addTearDown(service.dispose);

    await expectLater(
      service.runWithWakelock(
        () async => throw StateError('boom'),
        reason: 'test failure',
      ),
      throwsStateError,
    );

    expect(adapter.enableCount, 1);
    expect(adapter.disableCount, 1);
    expect(service.activeOperationCount, 0);
    expect(service.isWakelockActive.value, isFalse);
  });

  test('overlapping operations keep wakelock until all work ends', () async {
    final adapter = _FakeWakelockAdapter();
    final service = ActiveOperationWakelockService(adapter: adapter);
    addTearDown(service.dispose);
    final hold = Completer<void>();

    final first = service.runWithWakelock(() async {
      await hold.future;
    }, reason: 'first');
    await Future<void>.delayed(Duration.zero);

    await service.runWithWakelock(() async {}, reason: 'second');
    expect(adapter.enableCount, 1);
    expect(adapter.disableCount, 0);
    expect(service.activeOperationCount, 1);
    expect(service.isWakelockActive.value, isTrue);

    hold.complete();
    await first;

    expect(adapter.enableCount, 1);
    expect(adapter.disableCount, 1);
    expect(service.activeOperationCount, 0);
    expect(service.isWakelockActive.value, isFalse);
  });

  test(
    'disabled setting prevents and releases wakelock during active work',
    () async {
      final adapter = _FakeWakelockAdapter();
      final service = ActiveOperationWakelockService(adapter: adapter);
      addTearDown(service.dispose);

      await service.setUserEnabled(false);
      await service.runWithWakelock(() async {}, reason: 'disabled');
      expect(adapter.enableCount, 0);
      expect(adapter.disableCount, 0);

      await service.setUserEnabled(true);
      await service.begin(reason: 'active');
      expect(adapter.enableCount, 1);
      expect(service.isWakelockActive.value, isTrue);

      await service.setUserEnabled(false);
      expect(adapter.disableCount, 1);
      expect(service.activeOperationCount, 1);
      expect(service.isWakelockActive.value, isFalse);

      await service.end(reason: 'active');
      expect(adapter.disableCount, 1);
    },
  );

  test('settings controller defaults to keeping the screen awake', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(keepScreenAwakeControllerProvider), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(keepScreenAwakeControllerProvider), isTrue);
  });

  test('new wakelock localization keys exist in English and Arabic', () {
    for (final locale in const [Locale('en'), Locale('ar')]) {
      final l = AppLocalizations(locale);
      expect(l.has('activeOperationWakelockNote'), isTrue);
      expect(l.has('keepScreenAwakeDuringDownloads'), isTrue);
      expect(l.has('keepScreenAwakeDuringDownloadsSubtitle'), isTrue);
    }
  });
}
