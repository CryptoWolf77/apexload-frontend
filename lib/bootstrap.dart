import 'dart:async';

import 'package:apexload/app.dart';
import 'package:apexload/shared/services/local_media_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Starts the app as soon as the engine is ready.
///
/// Nothing may be awaited before [runApp]: until it runs there is no Flutter
/// app, so a stalled platform channel would leave the native launch screen on
/// screen with no way to report the failure. The splash route decides where to
/// go next while its animation plays.
Future<void> bootstrapApexLoad() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('ApexLoad startup: bindings initialized');
  runApp(const ProviderScope(child: ApexLoadApp()));
  unawaited(_initializeLocalMediaSafely());
}

Future<void> _initializeLocalMediaSafely() async {
  try {
    debugPrint('ApexLoad startup: local media initialization started');
    await LocalMediaService().ensureFolders();
    debugPrint('ApexLoad startup: local media initialization succeeded');
  } on Object catch (error, stackTrace) {
    debugPrint('ApexLoad startup: local media initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
