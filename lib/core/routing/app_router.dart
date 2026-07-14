import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/core/constants/legal_documents.dart';
import 'package:apexload/features/account/account_screen.dart';
import 'package:apexload/features/audio_extraction/audio_extraction_screen.dart';
import 'package:apexload/features/download_options/download_options_screen.dart';
import 'package:apexload/features/download_progress/download_progress_screen.dart';
import 'package:apexload/features/home/home_screen.dart';
import 'package:apexload/features/library/library_screen.dart';
import 'package:apexload/features/legal/legal_document_screen.dart';
import 'package:apexload/features/legal/responsible_use_agreement_screen.dart';
import 'package:apexload/features/onboarding/onboarding_screen.dart';
import 'package:apexload/features/premium/premium_screen.dart';
import 'package:apexload/features/quick_editor/quick_editor_landing_screen.dart';
import 'package:apexload/features/quick_editor/quick_editor_screen.dart';
import 'package:apexload/features/settings/settings_screen.dart';
import 'package:apexload/features/splash/splash_screen.dart';
import 'package:apexload/features/video_optimizer/video_optimizer_screen.dart';
import 'package:apexload/features/whatsapp_status/whatsapp_status_screen.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/models/media_info_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
import 'package:apexload/shared/widgets/premium_locked_card.dart';
import 'package:flutter/foundation.dart';
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
            path: '/quick-editor',
            builder: (context, state) => const QuickEditorLandingScreen(),
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
              title: 'noMediaToShow',
              message: 'analyzeFirstForOptions',
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
              title: 'noDownloadInProgress',
              message: 'startDownloadFirst',
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
        path: '/privacy',
        builder: (context, state) =>
            const LegalDocumentScreen(document: ApexLoadLegalDocuments.privacy),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) =>
            const LegalDocumentScreen(document: ApexLoadLegalDocuments.terms),
      ),
      GoRoute(
        path: '/responsible-use',
        builder: (context, state) => ResponsibleUseAgreementScreen(
          reviewOnly: state.uri.queryParameters['review'] == 'true',
        ),
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
        path: '/whatsapp-status',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final l = AppLocalizations.of(context);
              if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
                return const WhatsAppStatusAndroidOnlyScreen();
              }
              final premium = ref
                  .watch(subscriptionControllerProvider)
                  .isPremium;
              if (!premium) {
                return GradientScaffold(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: PremiumLockedCard(
                        title: l.t('whatsappStatusPremiumTitle'),
                        description: l.t('whatsappStatusPremiumMessage'),
                        onUpgrade: () => context.push('/premium'),
                      ),
                    ),
                  ),
                );
              }
              return const WhatsAppStatusScreen();
            },
          );
        },
      ),
      GoRoute(
        path: '/quick-editor/edit',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! DownloadItemModel) {
            return const RouteFallbackScreen(
              title: 'noVideoSelected',
              message: 'openQuickEditorFirst',
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
      GoRoute(
        path: '/video-optimizer',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! DownloadItemModel) {
            return const RouteFallbackScreen(
              title: 'noVideoSelected',
              message: 'openQuickEditorFirst',
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
                        title: l.t('videoOptimizerPremiumTitle'),
                        description: l.t('videoOptimizerPremiumMessage'),
                        onUpgrade: () => context.push('/premium'),
                      ),
                    ),
                  ),
                );
              }
              return VideoOptimizerScreen(item: extra);
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

class WhatsAppStatusAndroidOnlyScreen extends StatelessWidget {
  const WhatsAppStatusAndroidOnlyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GradientScaffold(
      appBar: AppBar(
        title: Text(l.t('whatsappStatusSaver')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_rounded),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.t('whatsappStatusSaver'),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Chip(label: Text(l.t('androidOnly'))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l.t('whatsappStatusAndroidOnlyTitle'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.t('whatsappStatusAndroidOnlyMessage'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.home_rounded),
                      label: Text(l.t('goHome')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    final l = AppLocalizations.of(context);
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
                l.t(title),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(l.t(message), textAlign: TextAlign.center),
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
            icon: const Icon(Icons.auto_fix_high_rounded),
            label: l.t('quickEditor'),
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
    if (location.startsWith('/quick-editor')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  String _pathFor(int index) {
    return switch (index) {
      1 => '/downloads',
      2 => '/quick-editor',
      3 => '/settings',
      _ => '/home',
    };
  }
}
