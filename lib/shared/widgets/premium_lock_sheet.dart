import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/widgets/primary_gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<void> showPremiumLockSheet({
  required BuildContext context,
  required String title,
  required String message,
  IconData icon = Icons.workspace_premium_rounded,
}) {
  final parentContext = context;
  final l = AppLocalizations.of(context);

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTone.card(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.premiumGold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: AppColors.premiumGold, size: 32),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTone.textSecondary(context)),
          ),
          const SizedBox(height: 18),
          PrimaryGradientButton(
            label: l.t('upgradeToPremium'),
            icon: Icons.workspace_premium_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              parentContext.push('/premium');
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.t('maybeLater')),
          ),
        ],
      ),
    ),
  );
}
