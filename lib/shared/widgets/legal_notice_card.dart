import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class LegalNoticeCard extends StatelessWidget {
  const LegalNoticeCard({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textKey = compact ? 'legalShort' : 'legalFull';
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.primaryStart.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryEnd.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            size: 18,
            color: AppColors.primaryEnd,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l.t(textKey),
              style: TextStyle(
                color: AppTone.textSecondary(context),
                fontSize: compact ? 12 : 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
