import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

abstract class WakelockAdapter {
  Future<void> enable();
  Future<void> disable();
}

class WakelockPlusAdapter implements WakelockAdapter {
  const WakelockPlusAdapter();

  @override
  Future<void> enable() => WakelockPlus.enable();

  @override
  Future<void> disable() => WakelockPlus.disable();
}

class ActiveOperationWakelockService with WidgetsBindingObserver {
  ActiveOperationWakelockService({
    WakelockAdapter adapter = const WakelockPlusAdapter(),
    bool initiallyEnabled = true,
  }) : _adapter = adapter,
       _userEnabled = initiallyEnabled {
    WidgetsBinding.instance.addObserver(this);
  }

  final WakelockAdapter _adapter;
  final ValueNotifier<bool> isWakelockActive = ValueNotifier<bool>(false);

  var _activeOperationCount = 0;
  var _userEnabled = true;
  var _wakeLockHeld = false;
  var _disposed = false;

  int get activeOperationCount => _activeOperationCount;
  bool get userEnabled => _userEnabled;

  Future<T> runWithWakelock<T>(
    Future<T> Function() task, {
    String reason = 'active operation',
  }) async {
    await begin(reason: reason);
    try {
      return await task();
    } finally {
      await end(reason: reason);
    }
  }

  Future<void> begin({String reason = 'active operation'}) async {
    if (_disposed) return;
    _activeOperationCount++;
    _log('begin "$reason", count=$_activeOperationCount');
    await _syncWakelock(reason: reason);
  }

  Future<void> end({String reason = 'active operation'}) async {
    if (_activeOperationCount > 0) {
      _activeOperationCount--;
    }
    _log('end "$reason", count=$_activeOperationCount');
    await _syncWakelock(reason: reason);
  }

  Future<void> setUserEnabled(bool enabled) async {
    _userEnabled = enabled;
    _log('setting changed, enabled=$_userEnabled');
    await _syncWakelock(reason: 'settings change');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncWakelock(reason: 'app resumed'));
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(_release(reason: 'app lifecycle $state'));
    }
  }

  Future<void> releaseAll({String reason = 'release all'}) async {
    _activeOperationCount = 0;
    await _release(reason: reason);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    await _release(reason: 'dispose');
    isWakelockActive.dispose();
  }

  Future<void> _syncWakelock({required String reason}) async {
    if (_disposed) return;
    final shouldHold = _userEnabled && _activeOperationCount > 0;
    if (shouldHold) {
      await _acquire(reason: reason);
    } else {
      await _release(reason: reason);
    }
  }

  Future<void> _acquire({required String reason}) async {
    if (_wakeLockHeld) {
      _setActive(true);
      return;
    }
    try {
      await _adapter.enable();
      _wakeLockHeld = true;
      _setActive(true);
      _log('enabled for $reason');
    } on Object catch (error, stackTrace) {
      _setActive(false);
      _log('enable failed: $error');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  Future<void> _release({required String reason}) async {
    if (!_wakeLockHeld) {
      _setActive(false);
      return;
    }
    try {
      await _adapter.disable();
      _log('disabled for $reason');
    } on Object catch (error, stackTrace) {
      _log('disable failed: $error');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
    } finally {
      _wakeLockHeld = false;
      _setActive(false);
    }
  }

  void _setActive(bool active) {
    if (isWakelockActive.value != active) {
      isWakelockActive.value = active;
    }
  }

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[ApexLoad Wakelock] $message');
  }
}
