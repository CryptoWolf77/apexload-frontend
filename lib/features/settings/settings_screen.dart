import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/premium_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final subscription = ref.watch(subscriptionControllerProvider);
    final downloads = ref.watch(libraryControllerProvider).length;
    final locale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
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
          value: true,
          onChanged: (_) {},
          title: Text(l.t('autoSaveToGallery')),
          contentPadding: EdgeInsets.zero,
        ),
        _SettingsTile(
          icon: Icons.folder_rounded,
          title: l.t('downloadLocation'),
          subtitle: l.t('deviceDownloadsFolder'),
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.cleaning_services_rounded,
          title: l.t('clearCache'),
          subtitle: l.t('demoCacheOnly'),
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.privacy_tip_rounded,
          title: l.t('privacyPolicy'),
          subtitle: l.t('placeholder'),
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.article_rounded,
          title: l.t('termsOfUse'),
          subtitle: l.t('placeholder'),
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.support_agent_rounded,
          title: l.t('contactSupport'),
          subtitle: 'support@example.com',
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.star_rate_rounded,
          title: l.t('rateApp'),
          subtitle: l.t('comingSoon'),
          onTap: () {},
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
