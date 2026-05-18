import 'package:apexload/app.dart';
import 'package:apexload/shared/widgets/premium_badge.dart';
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

  testWidgets('Home premium badge opens Premium screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: ApexLoadApp()));
    await tester.pump();

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.byType(PremiumBadge), findsOneWidget);
    await tester.tap(find.byType(PremiumBadge));
    await tester.pumpAndSettle();

    expect(find.text('Unlock ApexLoad Premium'), findsOneWidget);
  });
}
