import 'dart:async';

import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/core/routing/app_router.dart';
import 'package:apexload/core/theme/app_theme.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/services/store_subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApexLoadApp extends ConsumerWidget {
  const ApexLoadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
