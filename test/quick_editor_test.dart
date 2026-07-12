import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/core/theme/app_theme.dart';
import 'package:apexload/features/quick_editor/quick_editor_screen.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Quick Editor renders on a phone-sized viewport', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: QuickEditorScreen(
            item: DownloadItemModel(
              id: 'test_video',
              title: 'Test travel video',
              platform: 'TikTok',
              date: DateTime(2026, 5, 15),
              sizeLabel: '24 MB',
              type: DownloadType.video,
              thumbnailUrl: '',
              fileName: 'test_video.mp4',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Quick Editor'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Choose new audio'), findsOneWidget);
    expect(find.text('Choose audio file'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final english = AppLocalizations(const Locale('en'));
    expect(english.t('highestQuality'), 'Highest quality');
    expect(english.t('highestQuality'), isNot('FHD & 4K'));
  });

  testWidgets('Quick Editor renders in light mode on a phone-sized viewport', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: QuickEditorScreen(
            item: DownloadItemModel(
              id: 'test_video_light',
              title: 'Test travel video',
              platform: 'Snapchat',
              date: DateTime(2026, 5, 15),
              sizeLabel: '24 MB',
              type: DownloadType.video,
              thumbnailUrl: '',
              fileName: 'test_video.mp4',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Quick Editor'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'iOS recommends MP4 for a selected MOV without blocking editing',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: QuickEditorScreen(
              item: DownloadItemModel(
                id: 'ios_mov',
                title: 'iPhone clip',
                platform: 'Local file',
                date: DateTime(2026, 7, 11),
                sizeLabel: '8 MB',
                type: DownloadType.video,
                thumbnailUrl: '',
                fileName: 'iphone_clip.mov',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('For the best editing compatibility'), findsOneWidget);
      expect(find.text('Continue editing'), findsOneWidget);
      expect(find.text('Go to Convert to MP4'), findsOneWidget);

      await tester.tap(find.text('Continue editing'));
      await tester.pumpAndSettle();
      expect(find.text('Quick Editor'), findsWidgets);
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
