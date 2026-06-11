import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/widgets/local_thumbnail_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DownloadItemCard extends StatelessWidget {
  const DownloadItemCard({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onShare,
    required this.onDelete,
    required this.onRename,
    this.onEdit,
  });

  final DownloadItemModel item;
  final VoidCallback onOpen;
  final VoidCallback onShare;
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
        onTap: onOpen,
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
              SizedBox(
                width: 64,
                height: 64,
                child: LocalThumbnailView(
                  path: item.thumbnailPath,
                  borderRadius: BorderRadius.circular(16),
                  fallback: _FallbackThumb(type: item.type),
                ),
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          item.platform,
                          style: TextStyle(
                            color: AppTone.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          item.type.name.toUpperCase(),
                          style: TextStyle(
                            color: AppTone.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                        if (item.quality.isNotEmpty)
                          Text(
                            item.quality,
                            style: TextStyle(
                              color: AppTone.textSecondary(context),
                              fontSize: 12,
                            ),
                          ),
                        Text(
                          item.sizeLabel,
                          style: TextStyle(
                            color: AppTone.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          DateFormat.MMMd().format(item.date),
                          style: TextStyle(
                            color: AppTone.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                        if (item.isEdited)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryEnd.withValues(
                                alpha: 0.16,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.primaryEnd),
                            ),
                            child: Text(
                              AppLocalizations.of(context).t('edited'),
                              style: const TextStyle(
                                color: AppColors.primaryEnd,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
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
                    onOpen();
                    return;
                  }
                  if (value == 'share') {
                    onShare();
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
}

class _FallbackThumb extends StatelessWidget {
  const _FallbackThumb({required this.type});

  final DownloadType type;

  @override
  Widget build(BuildContext context) {
    final colors = switch (type) {
      DownloadType.audio => const [Color(0xFF6C63FF), Color(0xFFEF3E88)],
      DownloadType.image => const [Color(0xFF00B8D9), Color(0xFF16A34A)],
      DownloadType.video => const [
        AppColors.primaryStart,
        AppColors.primaryEnd,
      ],
    };
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: colors),
      ),
      child: Icon(_icon, color: Colors.white),
    );
  }

  IconData get _icon {
    return switch (type) {
      DownloadType.video => Icons.play_arrow_rounded,
      DownloadType.audio => Icons.music_note_rounded,
      DownloadType.image => Icons.image_rounded,
    };
  }
}
