import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/constants/app_config.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/models/user_subscription_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/services/reviewer_access_service.dart';
import 'package:apexload/shared/services/store_subscription_service.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
import 'package:apexload/shared/widgets/primary_gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  var _selectedPlan = 'yearly';

  Future<void> _continue() async {
    await ref
        .read(subscriptionStoreControllerProvider.notifier)
        .purchase(PremiumPlan.fromKey(_selectedPlan));
  }

  Future<void> _retryStore() {
    return ref
        .read(subscriptionStoreControllerProvider.notifier)
        .refreshCatalog();
  }

  Future<void> _showReviewerAccess() async {
    final activated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ReviewerAccessSheet(),
    );
    if (!mounted || activated != true) return;
    AppNotification.success(
      context,
      message: AppLocalizations.of(context).t('reviewerAccessActivated'),
    );
  }

  void _handleStoreState(
    SubscriptionStoreState? previous,
    SubscriptionStoreState next,
  ) {
    if (!mounted || previous?.phase == next.phase) return;
    final l = AppLocalizations.of(context);
    switch (next.phase) {
      case StorePurchasePhase.purchased:
        AppNotification.success(
          context,
          message: l.t('premiumActivatedSuccess'),
        );
        _leavePremiumScreen();
      case StorePurchasePhase.restored:
        AppNotification.success(
          context,
          message: l.t('restorePurchasesSuccess'),
        );
        _leavePremiumScreen();
      case StorePurchasePhase.restoreNotFound:
        AppNotification.info(context, message: l.t('nothingToRestore'));
      case StorePurchasePhase.pending:
        AppNotification.info(context, message: l.t('purchasePending'));
      case StorePurchasePhase.canceled:
        AppNotification.info(context, message: l.t('purchaseCancelled'));
      case StorePurchasePhase.error:
        AppNotification.error(context, message: l.t('purchaseFailed'));
      case StorePurchasePhase.loading:
      case StorePurchasePhase.ready:
      case StorePurchasePhase.purchasing:
      case StorePurchasePhase.restoring:
      case StorePurchasePhase.unavailable:
        break;
    }
  }

  void _leavePremiumScreen() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(subscriptionControllerProvider).isPremium;
    final store = ref.watch(subscriptionStoreControllerProvider);
    ref.listen<SubscriptionStoreState>(
      subscriptionStoreControllerProvider,
      _handleStoreState,
    );
    final l = AppLocalizations.of(context);
    const testerPremium = AppConfig.testerPremiumEnabled;
    final showReviewerAccess =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final selectedPlan = PremiumPlan.fromKey(_selectedPlan);
    final selectedProductAvailable = store.products.containsKey(selectedPlan);
    final catalogComplete =
        store.products.containsKey(PremiumPlan.monthly) &&
        store.products.containsKey(PremiumPlan.yearly);
    const showWhatsappStatusSaver = true;
    final benefits = <_PremiumBenefit>[
      _PremiumBenefit(
        Icons.all_inclusive_rounded,
        l.t('unlimitedDownloads'),
        l.t('premiumUnlimitedDescription'),
      ),
      _PremiumBenefit(
        Icons.high_quality_rounded,
        l.t('premiumHdDownloads'),
        l.t('premiumHdDownloadsDescription'),
      ),
      _PremiumBenefit(
        Icons.auto_fix_high_rounded,
        l.t('premiumQuickEditorTools'),
        l.t('quickEditorBenefit'),
      ),
      if (showWhatsappStatusSaver)
        _PremiumBenefit(
          Icons.phone_android_rounded,
          l.t('whatsappStatusSaver'),
          l.t('whatsappStatusBenefit'),
        ),
      _PremiumBenefit(
        Icons.block_rounded,
        l.t('noAds'),
        l.t('premiumNoAdsDescription'),
      ),
    ];

    return GradientScaffold(
      appBar: AppBar(title: Text(l.t('premium'))),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryStart, AppColors.primaryEnd],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryStart.withValues(alpha: 0.26),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.premiumGold,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.t('unlockPremiumTitle'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l.t('premiumSubtitle'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (testerPremium) ...[
            const SizedBox(height: 20),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: AppColors.premiumGold,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.t('testerPremiumTitle'),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.t('testerPremiumMessage'),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTone.textSecondary(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
          ] else ...[
            const SizedBox(height: 20),
            Text(
              l.t('choosePlan'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            _PricingCard(
              title: l.t('yearly'),
              price: store.priceFor(PremiumPlan.yearly) ?? l.t('yearlyPrice'),
              selected: _selectedPlan == 'yearly',
              bestValue: true,
              onTap: active || store.isBusy
                  ? null
                  : () => setState(() => _selectedPlan = 'yearly'),
            ),
            const SizedBox(height: 10),
            _PricingCard(
              title: l.t('monthly'),
              price: store.priceFor(PremiumPlan.monthly) ?? l.t('monthlyPrice'),
              selected: _selectedPlan == 'monthly',
              bestValue: false,
              onTap: active || store.isBusy
                  ? null
                  : () => setState(() => _selectedPlan = 'monthly'),
            ),
            if (!active &&
                store.phase != StorePurchasePhase.loading &&
                (!store.storeAvailable || !catalogComplete)) ...[
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(14),
                // Tapping retries the catalog. Recovery stays available
                // without exposing a developer-style retry button.
                onTap: store.isBusy ? null : _retryStore,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppTone.textSecondary(context),
                    ),
                    const SizedBox(width: 10),
                    // Plain-language only: the diagnostic support code and the
                    // manual retry button were developer-facing. A short
                    // explanation still has to stay, otherwise a disabled
                    // Subscribe button looks like a broken screen.
                    Expanded(
                      child: Text(
                        l.t('subscriptionTemporarilyUnavailable'),
                        style: TextStyle(
                          color: AppTone.textSecondary(context),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            PrimaryGradientButton(
              label: active ? l.t('premiumActiveButton') : l.t('subscribeNow'),
              icon: active
                  ? Icons.verified_rounded
                  : Icons.workspace_premium_rounded,
              isLoading:
                  store.phase == StorePurchasePhase.loading ||
                  store.phase == StorePurchasePhase.purchasing ||
                  store.phase == StorePurchasePhase.pending,
              onPressed:
                  active ||
                      store.isBusy ||
                      !store.storeAvailable ||
                      !selectedProductAvailable
                  ? null
                  : _continue,
            ),
            // Subscription terms sit directly under the purchase control.
            // App Review guideline 3.1.2 expects the length, price and the
            // Terms of Use / Privacy Policy links to be visible at the point
            // of purchase, not buried below the feature list.
            const SizedBox(height: 12),
            Text(
              l.t('premiumLegalNotice'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTone.textSecondary(context),
                fontSize: 12,
                height: 1.4,
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
            if (showReviewerAccess)
              TextButton.icon(
                key: const Key('reviewer_access_button'),
                onPressed: _showReviewerAccess,
                icon: const Icon(Icons.verified_user_outlined, size: 18),
                label: Text(l.t('reviewerAccess')),
                style: TextButton.styleFrom(
                  foregroundColor: AppTone.textSecondary(context),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            const SizedBox(height: 16),
          ],
          Text(
            l.t('premiumDownloads'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (var index = 0; index < benefits.length; index++) ...[
                  _BenefitRow(benefit: benefits[index]),
                  if (index != benefits.length - 1)
                    Divider(height: 1, color: AppTone.border(context)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _ReviewerAccessSheet extends ConsumerStatefulWidget {
  const _ReviewerAccessSheet();

  @override
  ConsumerState<_ReviewerAccessSheet> createState() =>
      _ReviewerAccessSheetState();
}

class _ReviewerAccessSheetState extends ConsumerState<_ReviewerAccessSheet> {
  final _codeController = TextEditingController();
  var _isValidating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    if (_isValidating) return;
    final l = AppLocalizations.of(context);
    final code = _codeController.text;
    if (code.trim().isEmpty) {
      setState(() => _errorMessage = l.t('invalidReviewerAccessCode'));
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    final result = await ref.read(reviewerAccessServiceProvider).verify(code);
    if (!mounted) return;

    switch (result) {
      case ReviewerAccessValidation.verified:
        await ref
            .read(subscriptionControllerProvider.notifier)
            .activateReviewerEntitlement();
        if (!mounted) return;
        if (ref.read(subscriptionControllerProvider).isPremium) {
          Navigator.of(context).pop(true);
          return;
        }
        setState(() {
          _isValidating = false;
          _errorMessage = l.t('reviewerAccessUnavailable');
        });
      case ReviewerAccessValidation.invalid:
        setState(() {
          _isValidating = false;
          _errorMessage = l.t('invalidReviewerAccessCode');
        });
      case ReviewerAccessValidation.unavailable:
        setState(() {
          _isValidating = false;
          _errorMessage = l.t('reviewerAccessUnavailable');
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTone.card(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: AppTone.border(context))),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTone.textSecondary(
                      context,
                    ).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.premiumGold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.premiumGold,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l.t('reviewerAccess'),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  l.t('reviewerAccessExplanation'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTone.textSecondary(context),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  key: const Key('reviewer_access_code_field'),
                  controller: _codeController,
                  enabled: !_isValidating,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  enableIMEPersonalizedLearning: false,
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  maxLength: 256,
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        required maxLength,
                      }) => null,
                  decoration: InputDecoration(
                    labelText: l.t('reviewerAccessCode'),
                    prefixIcon: const Icon(Icons.key_rounded),
                    errorText: _errorMessage,
                  ),
                  onSubmitted: (_) => _activate(),
                ),
                const SizedBox(height: 18),
                PrimaryGradientButton(
                  key: const Key('activate_reviewer_access_button'),
                  label: l.t('activateReviewerAccess'),
                  icon: Icons.lock_open_rounded,
                  isLoading: _isValidating,
                  onPressed: _isValidating ? null : _activate,
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _isValidating
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(l.t('cancel')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumBenefit {
  const _PremiumBenefit(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.benefit});

  final _PremiumBenefit benefit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.premiumGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: AppColors.premiumGold.withValues(alpha: 0.28),
              ),
            ),
            child: Icon(benefit.icon, color: AppColors.premiumGold, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  benefit.subtitle,
                  style: TextStyle(
                    color: AppTone.textSecondary(context),
                    fontSize: 12,
                    height: 1.35,
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '$title, $price',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryStart.withValues(alpha: 0.12)
                  : AppTone.card(context).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? AppColors.primaryEnd
                    : AppTone.border(context),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected
                      ? AppColors.primaryEnd
                      : AppTone.textSecondary(context),
                  size: 24,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          if (bestValue)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.premiumGold.withValues(
                                  alpha: 0.16,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                l.t('bestValue'),
                                style: const TextStyle(
                                  color: AppColors.premiumGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: TextStyle(
                          color: AppTone.textSecondary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
