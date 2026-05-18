import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/core/theme/app_theme.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('notification is width-limited on large screens', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpNotificationDemo(tester, theme: AppTheme.dark);
    await tester.tap(find.text('Show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Share is a demo action for now.'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('app_notification_card'))).width,
      lessThanOrEqualTo(520),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification renders in light theme and RTL', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpNotificationDemo(
      tester,
      theme: AppTheme.light,
      locale: const Locale('ar'),
      message: 'المشاركة حالياً مجرد تجربة',
    );
    await tester.tap(find.text('Show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('المشاركة حالياً مجرد تجربة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpNotificationDemo(
  WidgetTester tester, {
  required ThemeData theme,
  Locale locale = const Locale('en'),
  String message = 'Share is a demo action for now.',
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        bottomNavigationBar: NavigationBar(
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => AppNotification.info(context, message: message),
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    ),
  );
}
