import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/features/home/home_screen.dart';
import 'package:apexload/shared/widgets/yahyaz_lab_signature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  testWidgets('Home YahyazLab logo opens the exact URL externally', (
    tester,
  ) async {
    final launches = <({Uri uri, LaunchMode mode})>[];
    await _pumpHome(
      tester,
      launcher: (uri, mode) async {
        launches.add((uri: uri, mode: mode));
        return true;
      },
    );

    tester
        .widget<GestureDetector>(find.byKey(YahyazLabSignature.linkKey))
        .onTap!();
    await tester.pump();

    expect(launches, hasLength(1));
    expect(launches.single.uri.toString(), yahyazLabWebsiteUrl);
    expect(launches.single.mode, LaunchMode.externalApplication);
  });

  testWidgets('failed external launch does not crash or leave Home', (
    tester,
  ) async {
    await _pumpHome(tester, launcher: (_, _) async => false);

    tester
        .widget<GestureDetector>(find.byKey(YahyazLabSignature.linkKey))
        .onTap!();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byKey(const Key('app_notification_card')), findsOneWidget);
    expect(
      find.text('Could not open this link. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('Home logo dimensions and transparent link layout stay intact', (
    tester,
  ) async {
    await _pumpHome(tester, launcher: (_, _) async => true);

    final signature = find.byType(YahyazLabSignature);
    final image = tester.widget<Image>(
      find.descendant(of: signature, matching: find.byType(Image)),
    );
    final logoConstraints = tester
        .widgetList<ConstrainedBox>(
          find.descendant(of: signature, matching: find.byType(ConstrainedBox)),
        )
        .map((widget) => widget.constraints)
        .firstWhere(
          (constraints) =>
              constraints.maxWidth == 170 && constraints.maxHeight == 70,
        );

    expect(image.width, 150);
    expect(image.fit, BoxFit.contain);
    expect(logoConstraints.maxWidth, 170);
    expect(logoConstraints.maxHeight, 70);
  });

  testWidgets('Arabic Home keeps RTL and localized logo semantics', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      locale: const Locale('ar'),
      launcher: (_, _) async => true,
    );

    final signature = find.byType(YahyazLabSignature);
    final semantics = tester.widgetList<Semantics>(
      find.descendant(of: signature, matching: find.byType(Semantics)),
    );
    expect(Directionality.of(tester.element(signature)), TextDirection.rtl);
    expect(
      semantics.any(
        (widget) =>
            widget.properties.label == 'زيارة موقع YahyazLab الإلكتروني',
      ),
      isTrue,
    );
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  required YahyazLabUrlLauncher launcher,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [yahyazLabUrlLauncherProvider.overrideWithValue(launcher)],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(body: HomeScreen()),
      ),
    ),
  );
  await tester.pump();
  await tester.scrollUntilVisible(
    find.byKey(YahyazLabSignature.linkKey),
    500,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
}
