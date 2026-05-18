import 'package:apexload/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:apexload/shared/widgets/premium_lock_sheet.dart';

Future<void> showQuickEditorPremiumSheet(BuildContext context) {
  final l = AppLocalizations.of(context);
  return showPremiumLockSheet(
    context: context,
    title: l.t('quickEditorPremiumTitle'),
    message: l.t('quickEditorPremiumMessage'),
    icon: Icons.auto_fix_high_rounded,
  );
}
