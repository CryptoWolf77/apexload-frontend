import 'dart:async';

import 'package:apexload/app.dart';
import 'package:apexload/shared/services/local_media_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
