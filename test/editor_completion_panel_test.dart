import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/core/theme/app_theme.dart';
import 'package:apexload/features/quick_editor/editor_completion_panel.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('completion panel exposes each result action', (tester) async {
    var openCalls = 0;
    var downloadsCalls = 0;
    var dismissCalls = 0;

    await tester.pumpWidget(
      _testApp(
        locale: const Locale('en'),
        child: EditorCompletionPanel(
          item: _completedItem,
          onOpen: () => openCalls++,
          onViewDownloads: () => downloadsCalls++,
          onDismiss: () => dismissCalls++,
        ),
      ),
    );

    expect(find.text('Your edited file is ready'), findsOneWidget);
    expect(find.text('creator_clip_trimmed_final.mp4'), findsOneWidget);
    expect(find.text('18 MB  •  00:24  •  1080p'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('editor-completion-close'))),
      const Size(48, 48),
    );

    await tester.tap(find.text('Open edited file'));
    await tester.tap(find.byKey(const ValueKey('editor-completion-downloads')));
    await tester.tap(find.byKey(const ValueKey('editor-completion-continue')));

    expect(openCalls, 1);
    expect(downloadsCalls, 1);
    expect(dismissCalls, 1);
  });

  testWidgets('completion panel fits a narrow RTL phone', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        locale: const Locale('ar'),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: EditorCompletionPanel(
            item: _completedItem,
            onOpen: () {},
            onViewDownloads: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ملفك المعدّل جاهز'), findsOneWidget);
    expect(find.text('فتح الملف المعدّل'), findsOneWidget);
    expect(find.text('عرض في التنزيلات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp({required Locale locale, required Widget child}) {
  return MaterialApp(
    locale: locale,
    theme: AppTheme.dark,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}

final _completedItem = DownloadItemModel(
  id: 'edited',
  title: 'Creator clip',
  platform: 'Editor',
  date: DateTime(2026, 7, 23),
  sizeLabel: '18 MB',
  type: DownloadType.video,
  thumbnailUrl: '',
  fileName: 'creator_clip_trimmed_final.mp4',
  duration: '00:24',
  quality: '1080p',
  isEdited: true,
);
