import 'package:apexload/core/constants/app_config.dart';
import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/services/platform_info_service.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/premium_badge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final subscription = ref.watch(subscriptionControllerProvider);
    final downloads = ref.watch(libraryControllerProvider).length;
    final locale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final autoSaveToGallery = ref.watch(autoSaveToGalleryControllerProvider);
    final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final galleryPublishingSupported =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final planLabel = subscription.isPremium
        ? _premiumPlanLabel(l, subscription.planName)
        : l.t('freePlan');

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 104),
      children: [
        Text(l.t('settings'), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryStart, AppColors.primaryEnd],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.t('yourApexLoad'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  PremiumBadge(
                    label: subscription.isPremium
                        ? l.t('premium')
                        : l.t('free'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _StatusRow(label: l.t('plan'), value: planLabel),
              _StatusRow(
                label: l.t('downloadsToday'),
                value: subscription.isPremium
                    ? l.t('unlimitedDownloads')
                    : '${subscription.downloadsUsedToday}/${subscription.dailyDownloadLimit}',
              ),
              _StatusRow(label: l.t('storageUsed'), value: '128 MB'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FeaturePill(
                    label: l.t('quickEditor'),
                    unlocked: subscription.isPremium,
                  ),
                  _FeaturePill(
                    label: l.t('batchDownloads'),
                    unlocked: subscription.isPremium,
                  ),
                  _FeaturePill(
                    label: l.t('audioSwap'),
                    unlocked: subscription.isPremium,
                  ),
                  _FeaturePill(
                    label: l.t('downloads'),
                    unlocked: downloads >= 0,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          onTap: () => context.push('/premium'),
          child: Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.premiumGold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  planLabel,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (subscription.isPremium)
                PremiumBadge(label: l.t('active'))
              else
                Text(
                  l.t('upgradeToPremium'),
                  style: const TextStyle(color: AppColors.primaryEnd),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionTitle(l.t('language')),
        DropdownButtonFormField<String>(
          initialValue: locale?.languageCode ?? 'system',
          items: [
            DropdownMenuItem(
              value: 'system',
              child: Text(l.t('systemDefault')),
            ),
            DropdownMenuItem(value: 'en', child: Text(l.t('english'))),
            DropdownMenuItem(value: 'ar', child: Text(l.t('arabic'))),
          ],
          onChanged: (value) {
            final controller = ref.read(localeControllerProvider.notifier);
            if (value == 'ar') controller.setArabic();
            if (value == 'en') controller.setEnglish();
            if (value == 'system') controller.setSystem();
          },
        ),
        const SizedBox(height: 14),
        _SectionTitle(l.t('theme')),
        DropdownButtonFormField<ThemeMode>(
          initialValue: themeMode,
          items: [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text(l.t('system')),
            ),
            DropdownMenuItem(value: ThemeMode.dark, child: Text(l.t('dark'))),
            DropdownMenuItem(value: ThemeMode.light, child: Text(l.t('light'))),
          ],
          onChanged: (value) {
            if (value != null) {
              ref.read(themeModeControllerProvider.notifier).setMode(value);
            }
          },
        ),
        const SizedBox(height: 14),
        SwitchListTile(
          value: galleryPublishingSupported && autoSaveToGallery,
          onChanged: galleryPublishingSupported
              ? (value) => ref
                    .read(autoSaveToGalleryControllerProvider.notifier)
                    .setEnabled(value)
              : null,
          title: Text(l.t('autoSaveToGallery')),
          subtitle: Text(
            isIos
                ? l.t('autoSaveIosDescription')
                : l.t('autoSaveAndroidDescription'),
            style: TextStyle(color: AppTone.textSecondary(context)),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        _SettingsTile(
          icon: Icons.folder_rounded,
          title: l.t('downloadLocation'),
          subtitle: isIos
              ? l.t('downloadLocationIosSubtitle')
              : l.t('downloadLocationAndroidSubtitle'),
          onTap: () => _showDownloadLocation(context, ref),
        ),
        _SettingsTile(
          icon: Icons.cleaning_services_rounded,
          title: l.t('clearCache'),
          subtitle: l.t('clearCacheSubtitle'),
          onTap: () => _clearCache(context, ref),
        ),
        _SettingsTile(
          icon: Icons.privacy_tip_rounded,
          title: l.t('privacyPolicy'),
          subtitle: l.t('privacyPolicySubtitle'),
          onTap: () => context.push('/privacy'),
        ),
        _SettingsTile(
          icon: Icons.article_rounded,
          title: l.t('termsOfUse'),
          subtitle: l.t('termsOfUseSubtitle'),
          onTap: () => context.push('/terms'),
        ),
        _SettingsTile(
          icon: Icons.support_agent_rounded,
          title: l.t('contactSupport'),
          subtitle: 'support@apexload.org',
          onTap: () => _contactSupport(context),
        ),
        _SettingsTile(
          icon: Icons.star_rate_rounded,
          title: l.t('rateApp'),
          subtitle: l.t('rateAppSubtitle'),
          onTap: () => _rateApp(context),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'ApexLoad v${AppConstants.version}',
            style: TextStyle(color: AppTone.textSecondary(context)),
          ),
        ),
      ],
    );
  }

  Future<void> _showDownloadLocation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l = AppLocalizations.of(context);
    final media = ref.read(localMediaServiceProvider);
    final rootPath = await media.visibleDownloadRootPath();
    if (!context.mounted) return;
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppTone.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTone.textSecondary(
                      context,
                    ).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.folder_copy_rounded,
                    color: AppColors.primaryEnd,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.t('downloadLocation'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                isIos
                    ? l.t('downloadLocationIosDescription')
                    : l.t('downloadLocationAndroidDescription'),
                style: TextStyle(
                  color: AppTone.textSecondary(context),
                  height: 1.45,
                ),
              ),
              if (isAndroid && rootPath != null) ...[
                const SizedBox(height: 10),
                SelectableText(
                  rootPath,
                  style: TextStyle(
                    color: AppTone.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _LocationFolderRow(
                icon: Icons.movie_rounded,
                label: l.t('videosFolder'),
              ),
              _LocationFolderRow(
                icon: Icons.audiotrack_rounded,
                label: l.t('audioFolder'),
              ),
              _LocationFolderRow(
                icon: Icons.image_rounded,
                label: l.t('imagesFolder'),
              ),
              _LocationFolderRow(
                icon: Icons.auto_fix_high_rounded,
                label: l.t('editedFolder'),
              ),
              _LocationFolderRow(
                icon: Icons.gif_box_rounded,
                label: l.t('gifsFolder'),
              ),
              _LocationFolderRow(
                icon: Icons.photo_size_select_small_rounded,
                label: l.t('thumbnailsFolder'),
              ),
              const SizedBox(height: 18),
              if (isAndroid)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final opened = await media.openDownloadsFolder();
                      if (!sheetContext.mounted) return;
                      if (!opened) {
                        AppNotification.info(
                          sheetContext,
                          message: l.t('folderOpenUnavailable'),
                        );
                      }
                    },
                    icon: const Icon(Icons.folder_open_rounded),
                    label: Text(l.t('openFolder')),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(l.t('close')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.t('clearCacheConfirmTitle')),
        content: Text(l.t('clearCacheConfirmMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.t('clearCache')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final result = await ref.read(localMediaServiceProvider).clearSafeCache();
      if (!context.mounted) return;
      ref.read(libraryControllerProvider.notifier).clearCachedThumbnails();
      final message = l
          .t('cacheClearedSuccess')
          .replaceFirst('{size}', _formatBytes(result.bytesCleared));
      AppNotification.success(context, message: message);
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('ApexLoad cache clear failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (!context.mounted) return;
      AppNotification.error(context, message: l.t('cacheClearFailed'));
    }
  }

  Future<void> _contactSupport(BuildContext context) async {
    final l = AppLocalizations.of(context);
    const email = 'support@apexload.org';
    final body = l
        .t('supportEmailBody')
        .replaceFirst('{version}', AppConstants.version)
        .replaceFirst('{platform}', PlatformInfoService.platformName)
        .replaceFirst(
          '{osVersion}',
          PlatformInfoService.operatingSystemVersion,
        );
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'ApexLoad Support', 'body': body},
    );
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('ApexLoad support email launch failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
    if (opened || !context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.t('emailAppUnavailableTitle')),
        content: SelectableText(
          '${l.t('emailAppUnavailableMessage')}\n\n$email',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.t('close')),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: email));
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              AppNotification.success(context, message: l.t('emailCopied'));
            },
            icon: const Icon(Icons.copy_rounded),
            label: Text(l.t('copyEmail')),
          ),
        ],
      ),
    );
  }

  Future<void> _rateApp(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final storeUrl = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => AppConfig.iosStoreUrl,
      TargetPlatform.android => AppConfig.androidStoreUrl,
      _ => '',
    };
    if (storeUrl.trim().isEmpty) {
      AppNotification.info(
        context,
        message: l.t('ratingAvailableAfterRelease'),
      );
      return;
    }
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(storeUrl),
        mode: LaunchMode.externalApplication,
      );
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('ApexLoad store launch failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
    if (!opened && context.mounted) {
      AppNotification.error(context, message: l.t('couldNotOpenStore'));
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
  }

  String _premiumPlanLabel(AppLocalizations l, String planName) {
    return switch (planName) {
      'Monthly' => l.t('premiumMonthly'),
      'Yearly' => l.t('premiumYearly'),
      'Lifetime' => l.t('premiumLifetime'),
      _ => l.t('premiumActive'),
    };
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppTone.textSecondary(context)),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.label, required this.unlocked});

  final String label;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? AppColors.success : AppColors.premiumGold;
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ${unlocked ? l.t('unlocked') : l.t('locked')}',
            style: TextStyle(
              color: AppTone.textPrimary(context),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
  );
}

class _LocationFolderRow extends StatelessWidget {
  const _LocationFolderRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryEnd),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primaryEnd),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppTone.textSecondary(context)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
