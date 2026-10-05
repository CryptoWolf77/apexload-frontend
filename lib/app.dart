import 'dart:async';

import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/core/routing/app_router.dart';
import 'package:apexload/core/theme/app_theme.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/services/incoming_share_service.dart';
import 'package:apexload/shared/services/store_subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ApexLoadApp extends ConsumerStatefulWidget {
  const ApexLoadApp({super.key});

  @override
  ConsumerState<ApexLoadApp> createState() => _ApexLoadAppState();
}

class _ApexLoadAppState extends ConsumerState<ApexLoadApp> {
  late IncomingShareService _shares;
  late GoRouter _router;
  @override
  void initState() {
    super.initState();
    _shares = ref.read(incomingShareServiceProvider);
    _router = ref.read(appRouterProvider);
    _shares.pendingText.addListener(_routeSharedLink);
    _router.routerDelegate.addListener(_routeSharedLink);
    unawaited(_shares.start());
  }

  void _routeSharedLink() {
    if (!mounted ||
        ref.read(incomingShareServiceProvider).pendingText.value == null) {
      return;
    }
    final router = ref.read(appRouterProvider);
    final path = router.routeInformationProvider.value.uri.path;
    if (path == '/splash' ||
        path == '/onboarding' ||
        path == '/responsible-use' ||
        path == '/home') {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          ref.read(incomingShareServiceProvider).pendingText.value != null) {
        router.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _shares.pendingText.removeListener(_routeSharedLink);
    _router.routerDelegate.removeListener(_routeSharedLink);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final router = ref.watch(appRouterProvider);
    ref.watch(subscriptionControllerProvider);
    ref.watch(subscriptionStoreControllerProvider);
    ref.watch(adMobInitializationProvider);
    ref.listen(subscriptionControllerProvider, (_, next) {
      unawaited(
        ref.read(adMobServiceProvider).updatePremiumStatus(next.isPremium),
      );
    });

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ApexLoad',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
