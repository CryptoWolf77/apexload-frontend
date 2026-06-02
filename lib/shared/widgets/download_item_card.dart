import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/core/network/api_config.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openFile(context),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTone.card(
              context,
            ).withValues(alpha: isLight ? 0.96 : 0.82),
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
                  if (value == 'open') {
                    _openFile(context);
                    return;
                  }
                  if (value == 'save_gallery') {
                    _openFile(context);
                    return;
                  }
                  if (value == 'share') {
                    AppNotification.info(
                      context,
                      message: AppLocalizations.of(context).t('sharingSoon'),
                    );
                    return;
                  }
                  if (value == 'delete') onDelete();
                  if (value == 'rename') onRename();
                  if (value == 'edit') onEdit?.call();
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
        ),
      ),
    );
  }

  Future<void> _openFile(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final url = _fileUrl;
    if (url == null) {
      AppNotification.error(context, message: l.t('couldNotOpenFile'));
      return;
    }
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      AppNotification.error(context, message: l.t('couldNotOpenFile'));
    }
  }

  String? get _fileUrl {
    final value = item.downloadUrl.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) return '${ApiConfig.baseUrl}$value';
    if (value.isNotEmpty) return '${ApiConfig.baseUrl}/$value';
    final fileId = item.fileId.trim();
    if (fileId.isNotEmpty) {
      return '${ApiConfig.baseUrl}${ApiConfig.filePath(fileId)}';
    }
    return null;
  }

  IconData get _typeIcon {
    return switch (item.type) {
      DownloadType.video => Icons.play_arrow_rounded,
      DownloadType.audio => Icons.music_note_rounded,
      DownloadType.image => Icons.image_rounded,
    };
  }
}
