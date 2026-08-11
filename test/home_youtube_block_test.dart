import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/features/home/home_screen.dart';
import 'package:apexload/shared/services/api_analyze_service.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/primary_gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Home blocks YouTube links before calling analyze service', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final analyzeService = _CountingAnalyzeService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyzeServiceProvider.overrideWithValue(analyzeService)],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await tester.pump();

    for (final url in [
      'https://youtube.com/watch?v=abc',
      'https://youtu.be/abc',
      'https://m.youtube.com/shorts/abc',
    ]) {
      await tester.enterText(find.byType(TextField).first, url);
      tester
          .widget<PrimaryGradientButton>(find.byType(PrimaryGradientButton))
          .onPressed!();
      await tester.pump();
    }

    expect(analyzeService.callCount, 0);
    expect(find.text('Auto detect'), findsOneWidget);
  });
}

class _CountingAnalyzeService extends ApiAnalyzeService {
  int callCount = 0;

  @override
  Future<AnalyzeResult> analyze(String url) async {
    callCount++;
    throw StateError('Blocked links must not reach ApiAnalyzeService.');
  }
}
