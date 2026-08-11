import 'dart:io';

import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/features/quick_editor/quick_editor_models.dart';
import 'package:apexload/shared/services/local_editor_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = LocalEditorService();

  List<String> arguments(
    QuickEditorJobType type, {
    Map<String, Object?> options = const {},
  }) {
    return service.buildArgumentsForTest(
      inputPath: 'input.mp4',
      outputPath: 'output.mp4',
      job: QuickEditorJob(
        type: type,
        operation: type.name,
        successMessageKey: 'done',
      ),
      options: options,
    );
  }

  test('trim uses fast input seeking and a mobile-optimized encoder', () {
    final args = arguments(
      QuickEditorJobType.trim,
      options: const {'startTime': 12.0, 'endTime': 42.0},
    );

    expect(args.indexOf('-ss'), lessThan(args.indexOf('-i')));
    expect(args, containsAllInOrder(['-t', '00:00:30']));
    expect(args, containsAllInOrder(['-preset', 'superfast']));
    expect(args, containsAllInOrder(['-threads', '0']));
    expect(args, isNot(contains('+faststart')));
  });

  test('MP4 conversion uses the fastest safe software preset', () {
    final args = arguments(QuickEditorJobType.export);

    expect(args, containsAllInOrder(['-preset', 'ultrafast']));
    expect(args, containsAllInOrder(['-crf', '20']));
    expect(args, isNot(contains('+faststart')));
  });

  test('mute and audio replacement keep the original video stream', () async {
    final mute = arguments(QuickEditorJobType.mute);
    expect(mute, containsAllInOrder(['-c:v', 'copy']));

    final audio = File(
      '${Directory.systemTemp.path}/apexload_editor_args_audio.mp3',
    );
    await audio.writeAsBytes(const [0]);
    addTearDown(() async {
      if (await audio.exists()) await audio.delete();
    });
    final audioSwap = arguments(
      QuickEditorJobType.audioSwap,
      options: {'audioPath': audio.path, 'videoDuration': 30.0},
    );
    expect(audioSwap, containsAllInOrder(['-c:v', 'copy']));
  });

  test('reel export uses faster scaling and encoding', () {
    final args = arguments(
      QuickEditorJobType.reelsShorts,
      options: const {
        'preset': 'instagram',
        'resizeMode': 'smart_crop',
        'quality': 'medium',
      },
    );

    expect(args, containsAllInOrder(['-preset', 'superfast']));
    expect(args.join(' '), contains('flags=bilinear'));
  });

  test('vertical short preset keeps the existing vertical export settings', () {
    final args = arguments(
      QuickEditorJobType.reelsShorts,
      options: const {
        'preset': 'vertical',
        'resizeMode': 'smart_crop',
        'quality': 'medium',
      },
    );

    expect(args.join(' '), contains('scale=1080:1920'));
    expect(args, containsAllInOrder(['-c:v', 'libx264']));
    expect(args, containsAllInOrder(['-preset', 'superfast']));
  });

  test('vertical short branding is available in English and Arabic', () {
    final english = AppLocalizations(const Locale('en'));
    final arabic = AppLocalizations(const Locale('ar'));

    expect(english.t('verticalShort'), 'Vertical Short');
    expect(english.t('createVerticalShort'), 'Create Vertical Short');
    expect(arabic.t('verticalShort'), 'Vertical Short');
    expect(arabic.t('createVerticalShort'), 'إنشاء Vertical Short');
  });
}
