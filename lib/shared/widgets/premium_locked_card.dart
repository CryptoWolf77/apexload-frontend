import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/primary_gradient_button.dart';
import 'package:flutter/material.dart';

class PremiumLockedCard extends StatelessWidget {
  const PremiumLockedCard({
    super.key,
    required this.title,
    required this.description,
    required this.onUpgrade,
  });

  final String title;
  final String description;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_rounded,
            size: 48,
            color: AppTone.isLight(context)
                ? AppColors.lightPremiumGold
                : AppColors.premiumGold,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTone.textSecondary(context)),
          ),
          const SizedBox(height: 18),
          PrimaryGradientButton(
            label: AppLocalizations.of(context).t('upgradeNow'),
            icon: Icons.workspace_premium_rounded,
            onPressed: onUpgrade,
          ),
        ],
      ),
    );
  }
}
