import 'dart:ui' show PointerDeviceKind;

import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/widgets/platform_chip.dart';
import 'package:apexload/shared/widgets/supported_platforms_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const autoScrollKey = ValueKey('supported-platforms-auto-scroll-view');
  const staticListKey = ValueKey('supported-platforms-static-list');

  testWidgets('renders the authoritative platforms in logical order', (
    tester,
  ) async {
    await _pumpCarousel(tester);

    expect(
      find.byType(PlatformChip),
      findsNWidgets(9 * AppConstants.availablePlatforms.length),
    );
    expect(find.text('YouTube'), findsNothing);
    for (final platform in AppConstants.availablePlatforms) {
      expect(
        find.byKey(ValueKey('supported-platform-4-$platform')),
        findsOneWidget,
      );
    }

    final horizontalPositions = [
      for (final platform in AppConstants.availablePlatforms)
        tester
            .getTopLeft(find.byKey(ValueKey('supported-platform-4-$platform')))
            .dx,
    ];
    expect(
      horizontalPositions,
      orderedEquals([...horizontalPositions]..sort()),
    );
  });

  testWidgets('moves automatically without waiting for perpetual settlement', (
    tester,
  ) async {
    await _pumpCarousel(tester, pixelsPerSecond: 80);
    final controller = _controllerFor(tester, autoScrollKey);
    final start = controller.offset;

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.offset, greaterThan(start + 30));
  });

  testWidgets('pauses on touch and resumes after the idle delay', (
    tester,
  ) async {
    await _pumpCarousel(
      tester,
      pixelsPerSecond: 100,
      resumeDelay: const Duration(milliseconds: 200),
    );
    final controller = _controllerFor(tester, autoScrollKey);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(autoScrollKey)),
    );
    await tester.pump();
    final pausedOffset = controller.offset;
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset, closeTo(pausedOffset, 0.01));

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 150));
    expect(controller.offset, closeTo(pausedOffset, 0.01));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.offset, greaterThan(pausedOffset + 20));
  });

  testWidgets('supports primary mouse dragging on desktop', (tester) async {
    await _pumpCarousel(tester, pixelsPerSecond: 0);
    final controller = _controllerFor(tester, autoScrollKey);
    final start = controller.offset;

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(autoScrollKey)),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(-120, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(controller.offset, greaterThan(start + 80));
  });

  testWidgets('reduced motion uses one ordinary list and stays still', (
    tester,
  ) async {
    await _pumpCarousel(tester, disableAnimations: true);

    expect(find.byKey(staticListKey), findsOneWidget);
    expect(find.byKey(autoScrollKey), findsNothing);
    expect(
      tester.widget<ListView>(find.byKey(staticListKey)).semanticChildCount,
      AppConstants.availablePlatforms.length,
    );
    final position = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(staticListKey),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    final start = position.pixels;
    await tester.pump(const Duration(seconds: 2));
    expect(position.pixels, start);
  });

  testWidgets('accessible navigation also disables repeated motion', (
    tester,
  ) async {
    await _pumpCarousel(tester, accessibleNavigation: true);

    expect(find.byKey(staticListKey), findsOneWidget);
    expect(
      tester.widget<ListView>(find.byKey(staticListKey)).semanticChildCount,
      AppConstants.availablePlatforms.length,
    );
  });

  testWidgets('announces only one logical copy of every platform', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpCarousel(tester);

      for (final platform in AppConstants.availablePlatforms) {
        expect(find.bySemanticsLabel(platform), findsOneWidget);
      }
      expect(find.bySemanticsLabel('YouTube'), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('pauses while inactive and resumes safely', (tester) async {
    await _pumpCarousel(tester, pixelsPerSecond: 80);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    final controller = _controllerFor(tester, autoScrollKey);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    final inactiveOffset = controller.offset;
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset, closeTo(inactiveOffset, 0.01));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.offset, greaterThan(inactiveOffset + 15));
  });

  testWidgets('adapts to text scale, RTL locale, and viewport changes', (
    tester,
  ) async {
    await _pumpCarousel(tester, pixelsPerSecond: 80, carouselWidth: 320);
    final controller = _controllerFor(tester, autoScrollKey);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));

    await _pumpCarousel(
      tester,
      pixelsPerSecond: 80,
      locale: const Locale('ar'),
      textScaler: const TextScaler.linear(2),
      carouselWidth: 560,
    );

    expect(
      tester.getSize(find.byType(SupportedPlatformsCarousel)).height,
      greaterThan(42),
    );
    final horizontalPositions = [
      for (final platform in AppConstants.availablePlatforms)
        tester
            .getTopLeft(find.byKey(ValueKey('supported-platform-4-$platform')))
            .dx,
    ];
    expect(
      horizontalPositions,
      orderedEquals([...horizontalPositions]..sort((a, b) => b.compareTo(a))),
    );
    for (final platform in AppConstants.availablePlatforms) {
      final localized = AppLocalizations(
        const Locale('ar'),
      ).platformName(platform);
      expect(find.text(localized), findsWidgets);
    }

    final changedOffset = controller.offset;
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.offset, greaterThan(changedOffset + 15));
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposes safely while auto-scroll and resume timer are active', (
    tester,
  ) async {
    await _pumpCarousel(tester, pixelsPerSecond: 100);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(autoScrollKey)),
    );
    await tester.pump();
    await gesture.up();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpCarousel(
  WidgetTester tester, {
  double pixelsPerSecond = 24,
  Duration resumeDelay = const Duration(milliseconds: 900),
  bool disableAnimations = false,
  bool accessibleNavigation = false,
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
  double carouselWidth = 360,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          accessibleNavigation: accessibleNavigation,
          textScaler: textScaler,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: carouselWidth,
            child: SupportedPlatformsCarousel(
              pixelsPerSecond: pixelsPerSecond,
              resumeDelay: resumeDelay,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

ScrollController _controllerFor(WidgetTester tester, Key key) {
  return tester.widget<SingleChildScrollView>(find.byKey(key)).controller!;
}
