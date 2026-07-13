import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/models/user_subscription_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
import 'package:apexload/shared/widgets/primary_gradient_button.dart';
import 'package:flutter/foundation.dart';
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
    final showWhatsappStatusSaver =
        (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS);
    return GradientScaffold(
      appBar: AppBar(
        title: Text(l.t('premium')),
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
            childAspectRatio: 1.34,
            children: [
              _Benefit(
                icon: Icons.all_inclusive_rounded,
                label: l.t('unlimitedDownloads'),
                subtitle: l.t('premiumUnlimitedDescription'),
              ),
              _Benefit(
                icon: Icons.high_quality_rounded,
                label: l.t('premiumHdDownloads'),
                subtitle: l.t('premiumHdDownloadsDescription'),
              ),
              _Benefit(
                icon: Icons.playlist_add_check_rounded,
                label: l.t('batchDownloads'),
                subtitle: l.t('premiumBatchDescription'),
              ),
              _Benefit(
                icon: Icons.graphic_eq_rounded,
                label: l.t('premiumMp3Extraction'),
                subtitle: l.t('premiumMp3Description'),
              ),
              _Benefit(
                icon: Icons.verified_rounded,
                label: l.t('premiumNoWatermark'),
                subtitle: l.t('premiumNoWatermarkDescription'),
              ),
              if (showWhatsappStatusSaver)
                _Benefit(
                  icon: Icons.phone_android_rounded,
                  label: l.t('whatsappStatusSaver'),
                  subtitle: l.t('whatsappStatusBenefit'),
                ),
              _Benefit(
                icon: Icons.auto_fix_high_rounded,
                label: l.t('premiumQuickEditorTools'),
                subtitle: l.t('quickEditorBenefit'),
              ),
              _Benefit(
                icon: Icons.speed_rounded,
                label: l.t('premiumFasterQueue'),
                subtitle: l.t('premiumFasterQueueDescription'),
              ),
              _Benefit(
                icon: Icons.block_rounded,
                label: l.t('noAds'),
                subtitle: l.t('premiumNoAdsDescription'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _FeatureSection(
            title: l.t('premiumDownloads'),
            features: [
              _PremiumFeature(
                icon: Icons.high_quality_rounded,
                title: l.t('fhd4kDownloads'),
                body: l.t('fhd4kDownloadsWhenAvailable'),
              ),
              _PremiumFeature(
                icon: Icons.graphic_eq_rounded,
                title: l.t('audioExtraction'),
                body: l.t('audioExtractionPremiumMessage'),
              ),
              _PremiumFeature(
                icon: Icons.block_rounded,
                title: l.t('noAds'),
                body: l.t('premiumSubtitle'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FeatureSection(
            title: l.t('premiumCreatorTools'),
            features: [
              _PremiumFeature(
                icon: Icons.gif_box_rounded,
                title: l.t('videoToGif'),
                body: l.t('videoToGifBenefit'),
              ),
              _PremiumFeature(
                icon: Icons.stay_current_portrait_rounded,
                title: l.t('reelsShortsCreator'),
                body: l.t('reelsShortsBenefit'),
              ),
              if (showWhatsappStatusSaver)
                _PremiumFeature(
                  icon: Icons.message_rounded,
                  title: l.t('whatsappStatusSaver'),
                  body: l.t('whatsappStatusBenefit'),
                ),
              _PremiumFeature(
                icon: Icons.tune_rounded,
                title: l.t('videoOptimizer'),
                body: l.t('videoOptimizerBenefit'),
              ),
              _PremiumFeature(
                icon: Icons.swap_horizontal_circle_rounded,
                title: l.t('advancedAudioSwap'),
                body: l.t('advancedAudioSwapBenefit'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FeatureSection(
            title: l.t('premiumEditorTools'),
            features: [
              _PremiumFeature(
                icon: Icons.content_cut_rounded,
                title: l.t('professionalTrimPreview'),
                body: l.t('trimVideo'),
              ),
              _PremiumFeature(
                icon: Icons.timeline_rounded,
                title: l.t('audioStartSelector'),
                body: l.t('advancedAudioSwapBenefit'),
              ),
              _PremiumFeature(
                icon: Icons.movie_creation_rounded,
                title: l.t('localVideoConversion'),
                body: l.t('convertVideoToMp4'),
              ),
              _PremiumFeature(
                icon: Icons.speed_rounded,
                title: l.t('localOptimization'),
                body: l.t('videoOptimizerBenefit'),
              ),
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
            child: Column(
              children: [
                Text(
                  l.t('premiumLegalNotice'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTone.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => context.push('/terms'),
                      child: Text(l.t('termsOfUse')),
                    ),
                    TextButton(
                      onPressed: () => context.push('/privacy'),
                      child: Text(l.t('privacyPolicy')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection({required this.title, required this.features});

  final String title;
  final List<_PremiumFeature> features;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        for (final feature in features) ...[
          _PremiumFeatureCard(feature: feature),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PremiumFeature {
  const _PremiumFeature({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _PremiumFeatureCard extends StatelessWidget {
  const _PremiumFeatureCard({required this.feature});

  final _PremiumFeature feature;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [AppColors.primaryStart, AppColors.primaryEnd],
              ),
            ),
            child: Icon(feature.icon, color: Colors.white),
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
                      feature.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.premiumGold.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l.t('premium'),
                        style: const TextStyle(
                          color: AppColors.premiumGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  feature.body,
                  style: TextStyle(
                    color: AppTone.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
              ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.premiumGold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: AppColors.premiumGold.withValues(alpha: 0.32),
              ),
            ),
            child: Icon(icon, color: AppColors.premiumGold, size: 20),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Expanded(
              child: Text(
                subtitle!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTone.textSecondary(context),
                  fontSize: 11,
                  height: 1.25,
                ),
              ),
            ),
          ] else
            const Spacer(),
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
