import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class PlatformChip extends StatelessWidget {
  const PlatformChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final platformColor = _colorFor(label);
    final displayLabel = AppLocalizations.of(context).platformName(label);
    final borderColor = selected
        ? platformColor.withValues(alpha: 0.86)
        : platformColor.withValues(alpha: 0.36);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? platformColor.withValues(alpha: 0.16)
                : isLight
                ? AppColors.lightSurface.withValues(alpha: 0.96)
                : AppColors.card.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: platformColor.withValues(alpha: selected ? 0.18 : 0.08),
                blurRadius: selected ? 14 : 9,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconFor(label), size: 17, color: platformColor),
              const SizedBox(width: 7),
              Text(
                displayLabel,
                style: TextStyle(
                  color: isLight
                      ? AppColors.lightTextPrimary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('audio')) {
      return Icons.music_note_rounded;
    }
    if (lower.contains('youtube')) {
      return Icons.play_circle_fill_rounded;
    }
    if (lower.contains('instagram')) {
      return Icons.camera_alt_rounded;
    }
    if (lower.contains('facebook')) {
      return Icons.facebook_rounded;
    }
    if (lower.contains('reddit')) {
      return Icons.forum_rounded;
    }
    if (lower.contains('snapchat')) {
      return Icons.photo_camera_front_rounded;
    }
    if (lower.contains('pinterest')) {
      return Icons.push_pin_rounded;
    }
    if (lower.contains('x/') || lower.contains('twitter')) {
      return Icons.alternate_email_rounded;
    }
    return Icons.movie_filter_rounded;
  }

  Color _colorFor(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('tiktok')) {
      return const Color(0xFF00F2EA);
    }
    if (lower.contains('instagram')) {
      return const Color(0xFFE4408F);
    }
    if (lower.contains('facebook')) {
      return const Color(0xFF1877F2);
    }
    if (lower.contains('x/') || lower.contains('twitter')) {
      return const Color(0xFF38BDF8);
    }
    if (lower.contains('youtube')) {
      return const Color(0xFFFF3B30);
    }
    if (lower.contains('pinterest')) {
      return const Color(0xFFE60023);
    }
    if (lower.contains('reddit')) {
      return const Color(0xFFFF6A3D);
    }
    if (lower.contains('snapchat')) {
      return const Color(0xFFFFFC00);
    }
    if (lower == 'all') {
      return AppColors.primaryEnd;
    }
    return AppColors.primaryEnd;
  }
}
