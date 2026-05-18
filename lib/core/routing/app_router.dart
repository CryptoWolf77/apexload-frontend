import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/features/account/account_screen.dart';
import 'package:apexload/features/audio_extraction/audio_extraction_screen.dart';
import 'package:apexload/features/batch_download/batch_download_screen.dart';
import 'package:apexload/features/download_options/download_options_screen.dart';
import 'package:apexload/features/download_progress/download_progress_screen.dart';
import 'package:apexload/features/home/home_screen.dart';
import 'package:apexload/features/library/library_screen.dart';
import 'package:apexload/features/onboarding/onboarding_screen.dart';
import 'package:apexload/features/premium/premium_screen.dart';
import 'package:apexload/features/quick_editor/quick_editor_screen.dart';
import 'package:apexload/features/settings/settings_screen.dart';
import 'package:apexload/features/splash/splash_screen.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/models/media_info_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
import 'package:apexload/shared/widgets/premium_locked_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/downloads',
            builder: (context, state) => const LibraryScreen(),
          ),
          GoRoute(
            path: '/batch',
            builder: (context, state) => const BatchDownloadScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/download-options',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! MediaInfoModel) {
            return const RouteFallbackScreen(
              title: 'No media to show',
              message:
                  'Paste and analyze a link first to choose download options.',
            );
          }
          return DownloadOptionsScreen(media: extra);
        },
      ),
      GoRoute(
        path: '/download-progress',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! DownloadProgressArgs) {
            return const RouteFallbackScreen(
              title: 'No download in progress',
              message: 'Start a mock download from the options screen first.',
            );
          }
          return DownloadProgressScreen(args: extra);
        },
      ),
      GoRoute(
        path: '/premium',
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: '/audio',
        builder: (context, state) => const AudioExtractionScreen(),
      ),
      GoRoute(
        path: '/quick-editor',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! DownloadItemModel) {
            return const RouteFallbackScreen(
              title: 'No video selected',
              message: 'Open Quick Editor from a downloaded video first.',
            );
          }
          return Consumer(
            builder: (context, ref, child) {
              final l = AppLocalizations.of(context);
              final premium = ref
                  .watch(subscriptionControllerProvider)
                  .isPremium;
              if (!premium) {
                return GradientScaffold(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: PremiumLockedCard(
                        title: l.t('quickEditorPremiumTitle'),
                        description: l.t('quickEditorPremiumMessage'),
                        onUpgrade: () => context.push('/premium'),
                      ),
                    ),
                  ),
                );
              }
              return QuickEditorScreen(item: extra);
            },
          );
        },
      ),
    ],
  );
});

class DownloadProgressArgs {
  const DownloadProgressArgs({
    required this.media,
    required this.formats,
    required this.fileName,
    required this.saveToGallery,
    this.apiJobId,
  });

  final MediaInfoModel media;
  final List<DownloadFormatModel> formats;
  final String fileName;
  final bool saveToGallery;
  final String? apiJobId;

  DownloadFormatModel get primaryFormat => formats.first;
}

class RouteFallbackScreen extends StatelessWidget {
  const RouteFallbackScreen({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_rounded, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home_rounded),
                label: Text(AppLocalizations.of(context).t('goHome')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexFor(location);
    final l = AppLocalizations.of(context);

    return GradientScaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => context.go(_pathFor(value)),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_rounded),
            label: l.t('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.download_done_rounded),
            label: l.t('downloads'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.playlist_add_check_rounded),
            label: l.t('batch'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_rounded),
            label: l.t('settings'),
          ),
        ],
      ),
      child: child,
    );
  }

  int _indexFor(String location) {
    if (location.startsWith('/downloads')) return 1;
    if (location.startsWith('/batch')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  String _pathFor(int index) {
    return switch (index) {
      1 => '/downloads',
      2 => '/batch',
      3 => '/settings',
      _ => '/home',
    };
  }
}
