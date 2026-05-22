import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:flutter/material.dart';

class FormatOptionCard extends StatelessWidget {
  const FormatOptionCard({
    super.key,
    required this.format,
    required this.selected,
    required this.onTap,
    required this.isPremiumActive,
  });

  final DownloadFormatModel format;
  final bool selected;
  final bool isPremiumActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLight = AppTone.isLight(context);
    final locked = format.isPremium && !isPremiumActive;
    final unavailable = !format.isAvailable;
    final l = AppLocalizations.of(context);
    final label = _localizedLabel(l);
    final subtitle = unavailable && format.unavailableReasonKey != null
        ? l.t(format.unavailableReasonKey!)
        : _localizedSize(l);
    return InkWell(
      onTap: unavailable ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: unavailable
              ? AppTone.cardSecondary(
                  context,
                ).withValues(alpha: isLight ? 0.48 : 0.36)
              : selected
              ? AppColors.primaryStart.withValues(alpha: 0.22)
              : AppTone.cardSecondary(
                  context,
                ).withValues(alpha: isLight ? 0.88 : 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primaryEnd : AppTone.border(context),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _icon,
              color: unavailable
                  ? AppTone.textSecondary(context).withValues(alpha: 0.55)
                  : locked
                  ? AppColors.premiumGold
                  : AppColors.primaryEnd,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: unavailable
                          ? AppTone.textSecondary(
                              context,
                            ).withValues(alpha: 0.65)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: unavailable
                          ? AppTone.textSecondary(
                              context,
                            ).withValues(alpha: 0.72)
                          : AppTone.textSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (unavailable)
              Icon(
                Icons.block_rounded,
                color: AppTone.textSecondary(context).withValues(alpha: 0.55),
                size: 20,
              )
            else if (locked)
              const Icon(
                Icons.lock_rounded,
                color: AppColors.premiumGold,
                size: 20,
              )
            else if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 22,
              )
            else
              Icon(
                Icons.radio_button_unchecked_rounded,
                color: AppTone.textSecondary(context),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  IconData get _icon {
    return switch (format.type) {
      DownloadType.video => Icons.videocam_rounded,
      DownloadType.audio => Icons.graphic_eq_rounded,
      DownloadType.image => Icons.image_rounded,
    };
  }

  String _localizedLabel(AppLocalizations l) {
    return switch (format.id) {
      'original_image' => l.t('originalImage'),
      'high_quality_image' => l.t('highQualityImage'),
      'compressed_image' => l.t('compressedImage'),
      'jpg_image' => l.t('jpgImage'),
      'png_image' => l.t('pngImage'),
      _ => format.label,
    };
  }

  String _localizedSize(AppLocalizations l) {
    return switch (format.id) {
      'original_image' => l.t('bestAvailableQuality'),
      'high_quality_image' => l.t('premiumQualityWhenAvailable'),
      'compressed_image' => l.t('smallerFileSize'),
      'jpg_image' => l.t('standardFormat'),
      'png_image' => l.t('whenAvailable'),
      _ => format.sizeLabel,
    };
  }
}
