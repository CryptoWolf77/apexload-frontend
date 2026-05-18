import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/widgets/primary_gradient_button.dart';
import 'package:flutter/material.dart';

// TODO: Replace mock ad placeholder with real Google AdMob / mediation
// integration in Version 1.3.
Future<void> showMockAdDialog(BuildContext context) {
  final l = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: AppTone.card(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryStart, AppColors.primaryEnd],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.campaign_rounded, color: Colors.white),
      ),
      title: Text(l.t('adPlaceholderTitle'), textAlign: TextAlign.center),
      content: Text(
        l.t('adPlaceholderMessage'),
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTone.textSecondary(context)),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        SizedBox(
          width: 180,
          child: PrimaryGradientButton(
            label: l.t('continue'),
            icon: Icons.arrow_forward_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    ),
  );
}
