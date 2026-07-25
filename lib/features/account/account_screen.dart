import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
import 'package:apexload/shared/widgets/premium_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final subscription = ref.watch(subscriptionControllerProvider);
    final downloads = ref.watch(libraryControllerProvider).length;

    return GradientScaffold(
      appBar: AppBar(
        title: Text(l.t('appStatus')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.primaryEnd,
                      size: 32,
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
                const SizedBox(height: 16),
                _InfoRow(
                  label: l.t('plan'),
                  value: subscription.isPremium
                      ? l.t('premiumActive')
                      : l.t('freePlan'),
                ),
                _InfoRow(
                  label: l.t('downloads'),
                  value: '$downloads ${l.t('downloads').toLowerCase()}',
                ),
                _InfoRow(label: l.t('storageUsed'), value: '128 MB'),
                _InfoRow(
                  label: l.t('quickEditor'),
                  value: subscription.isPremium
                      ? l.t('unlocked')
                      : l.t('locked'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
