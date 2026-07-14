import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/constants/app_file_type_groups.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
import 'package:apexload/shared/widgets/local_thumbnail_view.dart';
import 'package:file_selector/file_selector.dart' show openFile;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuickEditorLandingScreen extends ConsumerWidget {
  const QuickEditorLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final premium = ref.watch(subscriptionControllerProvider).isPremium;
    final downloads = ref
        .watch(libraryControllerProvider)
        .where((item) => item.type == DownloadType.video)
        .toList();

    return GradientScaffold(
      appBar: AppBar(
        title: Text(l.t('quickEditor')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Text(
            l.t('quickEditor'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            l.t('quickEditorLandingSubtitle'),
            style: TextStyle(color: AppTone.textSecondary(context)),
          ),
          const SizedBox(height: 16),
          _SourcePickerCard(downloads: downloads, premium: premium),
          const SizedBox(height: 14),
          _ToolsGrid(premium: premium),
        ],
      ),
    );
  }
}

class _SourcePickerCard extends ConsumerWidget {
  const _SourcePickerCard({required this.downloads, required this.premium});

  final List<DownloadItemModel> downloads;
  final bool premium;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.video_library_rounded,
                color: AppColors.primaryEnd,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.t('chooseVideoSource'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l.t('chooseVideoSourceDescription'),
            style: TextStyle(color: AppTone.textSecondary(context)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Semantics(
                button: true,
                label: premium
                    ? l.t('chooseLocalVideo')
                    : '${l.t('chooseLocalVideo')}. ${l.t('premiumRequired')}',
                hint: premium ? null : l.t('localVideoPremiumMessage'),
                child: FilledButton.icon(
                  onPressed: () => premium
                      ? _pickLocalVideo(context)
                      : _showLocalVideoPremiumDialog(context),
                  style: premium
                      ? null
                      : FilledButton.styleFrom(
                          backgroundColor: AppTone.cardSecondary(
                            context,
                          ).withValues(alpha: 0.88),
                          foregroundColor: AppTone.textSecondary(context),
                        ),
                  icon: Icon(
                    premium ? Icons.folder_open_rounded : Icons.lock_rounded,
                  ),
                  label: Text(l.t('chooseLocalVideo')),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/downloads'),
                icon: const Icon(Icons.download_done_rounded),
                label: Text(l.t('chooseFromDownloads')),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (downloads.isEmpty)
            Text(
              l.t('noEditableVideosYet'),
              style: TextStyle(color: AppTone.textSecondary(context)),
            )
          else
            ...downloads.take(4).map((item) => _DownloadSourceTile(item: item)),
        ],
      ),
    );
  }

  Future<void> _pickLocalVideo(BuildContext context) async {
    final l = AppLocalizations.of(context);
    try {
      final file = await openFile(
        acceptedTypeGroups: [AppFileTypeGroups.video],
      );
      final path = file?.path;
      if (file == null || path == null || path.trim().isEmpty) return;
      final sizeLabel = _formatBytes(await file.length());
      if (!context.mounted) return;
      context.push(
        '/quick-editor/edit',
        extra: DownloadItemModel(
          id: 'local_video_${DateTime.now().millisecondsSinceEpoch}',
          title: file.name,
          platform: l.t('localFile'),
          date: DateTime.now(),
          sizeLabel: sizeLabel,
          type: DownloadType.video,
          thumbnailUrl: '',
          fileName: file.name,
          localFilePath: path,
          quality: l.t('localFile'),
        ),
      );
    } on Object catch (error, stackTrace) {
      if (isFilePickerCancellation(error)) return;
      if (kDebugMode) {
        debugPrint('Quick Editor local video picker failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (!context.mounted) return;
      AppNotification.error(context, message: l.t('somethingWentWrong'));
    }
  }

  Future<void> _showLocalVideoPremiumDialog(BuildContext context) async {
    final l = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.t('localVideoPremiumTitle')),
        content: Text(l.t('localVideoPremiumMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.t('notNow')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.push('/premium');
            },
            child: Text(l.t('viewPremium')),
          ),
        ],
      ),
    );
  }
}

class _DownloadSourceTile extends ConsumerStatefulWidget {
  const _DownloadSourceTile({required this.item});

  final DownloadItemModel item;

  @override
  ConsumerState<_DownloadSourceTile> createState() =>
      _DownloadSourceTileState();
}

class _DownloadSourceTileState extends ConsumerState<_DownloadSourceTile> {
  late DownloadItemModel _item;
  var _generatingThumbnail = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _generateThumbnailIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _DownloadSourceTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.item.thumbnailPath != widget.item.thumbnailPath) {
      _item = widget.item;
      _generateThumbnailIfNeeded();
    }
  }

  Future<void> _generateThumbnailIfNeeded() async {
    if (_generatingThumbnail ||
        _item.thumbnailPath.trim().isNotEmpty ||
        _item.localFilePath.trim().isEmpty ||
        _item.type == DownloadType.audio) {
      return;
    }
    _generatingThumbnail = true;
    try {
      final thumbnail = await ref
          .read(localMediaServiceProvider)
          .generateThumbnail(
            localFilePath: _item.localFilePath,
            fileName: _item.fileName,
            type: _item.type,
          );
      if (!mounted || thumbnail == null || thumbnail.isEmpty) return;
      final updated = _item.copyWith(thumbnailPath: thumbnail);
      setState(() => _item = updated);
      ref.read(libraryControllerProvider.notifier).add(updated);
    } on Object {
      // Thumbnail generation is a visual enhancement only.
    } finally {
      _generatingThumbnail = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/quick-editor/edit', extra: _item),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTone.cardSecondary(context).withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTone.border(context)),
          ),
          child: Row(
            children: [
              _EditorSourceThumbnail(item: _item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_platformLabel(l, _item.platform)} - ${_item.fileName}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTone.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTone.textSecondary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _platformLabel(AppLocalizations l, String platform) {
    final trimmed = platform.trim();
    if (trimmed == 'Editor') return l.t('editor');
    if (trimmed == 'Local' || trimmed == 'Local file') return l.t('localFile');
    if (trimmed == 'WhatsApp Status') return l.t('whatsappStatusSaver');
    if (trimmed == 'ApexLoad') return trimmed;
    return l.platformName(trimmed);
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
  final gb = mb / 1024;
  return '${gb.toStringAsFixed(gb < 10 ? 1 : 0)} GB';
}

class _EditorSourceThumbnail extends StatelessWidget {
  const _EditorSourceThumbnail({required this.item});

  final DownloadItemModel item;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(14);
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        children: [
          Positioned.fill(
            child: LocalThumbnailView(
              path: item.thumbnailPath,
              borderRadius: borderRadius,
              fallback: _EditorSourceFallback(type: item.type),
            ),
          ),
          if (item.type == DownloadType.video)
            PositionedDirectional(
              bottom: 5,
              end: 5,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EditorSourceFallback extends StatelessWidget {
  const _EditorSourceFallback({required this.type});

  final DownloadType type;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      DownloadType.audio => Icons.graphic_eq_rounded,
      DownloadType.image => Icons.image_rounded,
      DownloadType.video => Icons.movie_rounded,
    };
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryStart.withValues(alpha: 0.74),
            AppColors.primaryEnd.withValues(alpha: 0.74),
          ],
        ),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class _ToolsGrid extends ConsumerWidget {
  const _ToolsGrid({required this.premium});

  final bool premium;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final tools = [
      (Icons.content_cut_rounded, 'trimVideo'),
      (Icons.swap_horizontal_circle_rounded, 'audioSwap'),
      (Icons.volume_off_rounded, 'muteVideo'),
      (Icons.graphic_eq_rounded, 'extractAudio'),
      (Icons.movie_creation_rounded, 'convertVideoToMp4'),
      (Icons.tune_rounded, 'videoOptimizer'),
      (Icons.gif_box_rounded, 'videoToGif'),
      (Icons.stay_current_portrait_rounded, 'reelsShortsCreator'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final tool in tools)
          SizedBox(
            width: 160,
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(tool.$1, color: AppColors.primaryEnd),
                  const SizedBox(height: 10),
                  Text(
                    l.t(tool.$2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        premium ? Icons.lock_open_rounded : Icons.lock_rounded,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          premium ? l.t('unlocked') : l.t('premium'),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTone.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
