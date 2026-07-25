import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/primary_gradient_button.dart';
import 'package:flutter/material.dart';

class EditorCompletionPanel extends StatelessWidget {
  const EditorCompletionPanel({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onViewDownloads,
    required this.onDismiss,
  });

  final DownloadItemModel item;
  final VoidCallback onOpen;
  final VoidCallback onViewDownloads;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final metadata = [
      item.sizeLabel.trim(),
      item.duration.trim(),
      item.quality.trim(),
    ].where((value) => value.isNotEmpty).toList();
    final successColor = AppTone.isLight(context)
        ? AppColors.lightSuccess
        : AppColors.success;

    return Semantics(
      container: true,
      liveRegion: true,
      label: l.t('editedFileReady'),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: successColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: successColor.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: successColor,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      l.t('editedFileReady'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    key: const ValueKey('editor-completion-close'),
                    tooltip: l.t('continueEditing'),
                    onPressed: onDismiss,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close_rounded, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTone.cardSecondary(context).withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTone.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  if (metadata.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      metadata.join('  •  '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTone.textSecondary(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            PrimaryGradientButton(
              label: l.t('openEditedFile'),
              icon: Icons.open_in_new_rounded,
              onPressed: onOpen,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const ValueKey('editor-completion-downloads'),
              onPressed: onViewDownloads,
              icon: const Icon(Icons.download_done_rounded, size: 20),
              label: Text(l.t('viewInDownloads'), textAlign: TextAlign.center),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            TextButton(
              key: const ValueKey('editor-completion-continue'),
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: AppTone.textSecondary(context),
              ),
              child: Text(l.t('continueEditing')),
            ),
          ],
        ),
      ),
    );
  }
}
