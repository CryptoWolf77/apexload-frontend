import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class VideoPreviewPanel extends StatelessWidget {
  const VideoPreviewPanel({
    super.key,
    required this.localFilePath,
    required this.range,
    required this.onDurationChanged,
  });

  final String localFilePath;
  final RangeValues range;
  final ValueChanged<double> onDurationChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        color: AppTone.cardSecondary(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTone.border(context)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            AppLocalizations.of(context).t('videoPreviewUnavailable'),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTone.textSecondary(context)),
          ),
        ),
      ),
    );
  }
}
