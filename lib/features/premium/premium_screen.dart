import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/models/user_subscription_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
import 'package:apexload/shared/widgets/primary_gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  var _selectedPlan = 'yearly';
  var _loading = false;

  Future<void> _continue() async {
    setState(() => _loading = true);
    await ref
        .read(subscriptionControllerProvider.notifier)
        .activatePremium(PremiumPlan.fromKey(_selectedPlan));
    if (!mounted) return;
    setState(() => _loading = false);
    AppNotification.success(
      context,
      message: AppLocalizations.of(context).t('premiumActivatedSuccess'),
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(subscriptionControllerProvider).isPremium;
    final l = AppLocalizations.of(context);
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [AppColors.primaryStart, AppColors.primaryEnd],
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.premiumGold,
                  size: 60,
                ),
                const SizedBox(height: 14),
                Text(
                  l.t('unlockPremiumTitle'),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  l.t('premiumSubtitle'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              _Benefit(icon: Icons.block_rounded, label: l.t('noAds')),
              _Benefit(
                icon: Icons.all_inclusive_rounded,
                label: l.t('unlimitedDownloads'),
              ),
              _Benefit(
                icon: Icons.high_quality_rounded,
                label: l.t('fhd4kDownloads'),
              ),
              _Benefit(
                icon: Icons.verified_rounded,
                label: l.t('noWatermarkWhenAvailable'),
              ),
              _Benefit(
                icon: Icons.auto_fix_high_rounded,
                label: l.t('quickEditor'),
                subtitle: l.t('quickEditorBenefit'),
              ),
              _Benefit(
                icon: Icons.swap_horizontal_circle_rounded,
                label: l.t('audioSwapReplaceAudio'),
                subtitle: l.t('audioSwapSubtitle'),
              ),
              _Benefit(
                icon: Icons.playlist_add_check_rounded,
                label: l.t('batchDownloads'),
              ),
              _Benefit(
                icon: Icons.graphic_eq_rounded,
                label: l.t('audioExtraction'),
              ),
              _Benefit(icon: Icons.speed_rounded, label: l.t('fasterQueue')),
              _Benefit(icon: Icons.cloud_done_rounded, label: l.t('cloudSave')),
            ],
          ),
          const SizedBox(height: 18),
          for (final plan in [
            ('monthly', l.t('monthly'), l.t('monthlyPrice')),
            ('yearly', l.t('yearly'), l.t('yearlyPrice')),
            ('lifetime', l.t('lifetime'), l.t('lifetimePrice')),
          ]) ...[
            _PricingCard(
              title: plan.$2,
              price: plan.$3,
              selected: _selectedPlan == plan.$1,
              bestValue: plan.$1 == 'yearly',
              onTap: () => setState(() => _selectedPlan = plan.$1),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          PrimaryGradientButton(
            label: active ? l.t('premiumActiveButton') : l.t('continue'),
            icon: Icons.workspace_premium_rounded,
            isLoading: _loading,
            onPressed: active ? null : _continue,
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              l.t('termsPrivacyPlaceholder'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTone.textSecondary(context),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.label, this.subtitle});

  final IconData icon;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryEnd),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTone.textSecondary(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.title,
    required this.price,
    required this.selected,
    required this.bestValue,
    required this.onTap,
  });

  final String title;
  final String price;
  final bool selected;
  final bool bestValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected
                ? AppColors.primaryEnd
                : AppTone.textSecondary(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if (bestValue)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.premiumGold.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          l.t('bestValue'),
                          style: const TextStyle(
                            color: AppColors.premiumGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: TextStyle(color: AppTone.textSecondary(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
