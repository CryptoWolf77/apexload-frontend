import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DownloadItemCard extends StatelessWidget {
  const DownloadItemCard({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onRename,
    this.onEdit,
  });

  final DownloadItemModel item;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final isLight = AppTone.isLight(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTone.card(context).withValues(alpha: isLight ? 0.96 : 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTone.border(context)),
        boxShadow: [
          if (isLight)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [AppColors.primaryStart, AppColors.primaryEnd],
              ),
            ),
            child: Icon(_typeIcon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  '${item.platform} - ${DateFormat.MMMd().format(item.date)} - ${item.sizeLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTone.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTone.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'delete') onDelete();
              if (value == 'rename') onRename();
              if (value == 'edit') onEdit?.call();
              if (value != 'delete' && value != 'rename' && value != 'edit') {
                final l = AppLocalizations.of(context);
                final message = switch (value) {
                  'share' => l.t('shareDemoAction'),
                  'open' => l.t('openDemoAction'),
                  'save_gallery' => l.t('saveGalleryDemoAction'),
                  _ => l.t('demoActionForNow').replaceFirst('{action}', value),
                };
                AppNotification.info(context, message: message);
              }
            },
            itemBuilder: (context) {
              final l = AppLocalizations.of(context);
              return [
                PopupMenuItem(value: 'open', child: Text(l.t('open'))),
                PopupMenuItem(value: 'share', child: Text(l.t('share'))),
                if (item.type == DownloadType.video && onEdit != null)
                  PopupMenuItem(value: 'edit', child: Text(l.t('edit'))),
                PopupMenuItem(value: 'rename', child: Text(l.t('rename'))),
                PopupMenuItem(
                  value: 'save_gallery',
                  child: Text(l.t('saveToGallery')),
                ),
                PopupMenuItem(value: 'delete', child: Text(l.t('delete'))),
              ];
            },
          ),
        ],
      ),
    );
  }

  IconData get _typeIcon {
    return switch (item.type) {
      DownloadType.video => Icons.play_arrow_rounded,
      DownloadType.audio => Icons.music_note_rounded,
      DownloadType.image => Icons.image_rounded,
    };
  }
}
