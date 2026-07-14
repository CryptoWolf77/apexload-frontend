import 'package:apexload/app.dart';
import 'package:apexload/shared/widgets/premium_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ApexLoad starts at splash', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: ApexLoadApp()));
    await tester.pump();

    expect(find.text('ApexLoad'), findsOneWidget);
    expect(find.text('Social Downloader'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Paste any supported media link'), findsOneWidget);
  });

  testWidgets('agreement appears after onboarding and requires checkbox', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: ApexLoadApp()));
    await tester.pump();

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Responsible Use Agreement'), findsWidgets);
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Agree and Continue'),
      400,
    );
    final agreeButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Agree and Continue'),
    );
    expect(agreeButton.onPressed, isNull);

    await tester.scrollUntilVisible(find.byType(CheckboxListTile), -400);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    final enabledAgreeButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Agree and Continue'),
    );
    expect(enabledAgreeButton.onPressed, isNotNull);
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Agree and Continue'),
      400,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Agree and Continue'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('responsible_use_agreement_v1'), isTrue);
    expect(find.text('Paste your video link'), findsOneWidget);
  });

  testWidgets('declining agreement opens local Quick Editor entry point', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: ApexLoadApp()));
    await tester.pump();

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Decline'), 400);
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();

    expect(find.text('Quick Editor'), findsWidgets);
    expect(find.text('Choose local video'), findsOneWidget);
  });

  testWidgets('Home premium badge opens Premium screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'responsible_use_agreement_v1': true,
      'has_seen_onboarding': true,
    });
    await tester.pumpWidget(const ProviderScope(child: ApexLoadApp()));
    await tester.pump();

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(PremiumBadge), findsOneWidget);
    await tester.tap(find.byType(PremiumBadge));
    await tester.pumpAndSettle();

    expect(find.text('Unlock ApexLoad Premium'), findsOneWidget);
  });
}
