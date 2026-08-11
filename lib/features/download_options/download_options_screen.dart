import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/core/routing/app_router.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/media_info_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/active_operation_note.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:apexload/shared/widgets/download_rights_confirmation_dialog.dart';
import 'package:apexload/shared/widgets/format_option_card.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
import 'package:apexload/shared/widgets/legal_notice_card.dart';
import 'package:apexload/shared/widgets/premium_badge.dart';
import 'package:apexload/shared/widgets/premium_lock_sheet.dart';
import 'package:apexload/shared/widgets/primary_gradient_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DownloadOptionsScreen extends ConsumerStatefulWidget {
  const DownloadOptionsScreen({super.key, required this.media});

  final MediaInfoModel media;

  @override
  ConsumerState<DownloadOptionsScreen> createState() =>
      _DownloadOptionsScreenState();
}

class _DownloadOptionsScreenState extends ConsumerState<DownloadOptionsScreen> {
  static const _instagramPlatform = 'Instagram';
  static const _thumbnailFormatId = 'thumbnail';

  late final TextEditingController _fileController;
  DownloadFormatModel? _selectedFormat;
  var _creatingDownloadJob = false;

  bool get _isVideo => widget.media.mediaType == MediaType.video;
  bool get _isImage => widget.media.mediaType == MediaType.image;
  bool get _isInstagram => widget.media.platform == _instagramPlatform;
  List<DownloadFormatModel> get _visibleFormats => widget.media.formats
      .where((format) => !_isInstagram || format.id != _thumbnailFormatId)
      .toList(growable: false);
  bool get _allFormatsUnavailable =>
      _visibleFormats.isNotEmpty &&
      _visibleFormats.every((format) => !format.isAvailable);

  List<DownloadFormatModel> get _selectedFormats {
    final selected = _selectedFormat;
    return selected == null ? <DownloadFormatModel>[] : [selected];
  }

  @override
  void initState() {
    super.initState();
    final availableFormats = _visibleFormats.where(
      (format) => format.isAvailable && !format.isPremium,
    );
    _selectedFormat = availableFormats.isNotEmpty
        ? availableFormats.first
        : null;
    _fileController = TextEditingController(text: _defaultFileName);
  }

  String get _defaultFileName {
    final selected = _selectedFormats.isNotEmpty
        ? _selectedFormats.first
        : (_visibleFormats.isNotEmpty ? _visibleFormats.first : null);
    if (selected == null) return 'apexload_download';
    final safe = widget.media.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+$'), '');
    return '$safe.${selected.extension}';
  }

  void _select(DownloadFormatModel format, bool premiumActive) {
    final l = AppLocalizations.of(context);
    if (!format.isAvailable) return;
    if (format.isPremium && !premiumActive) {
      showPremiumLockSheet(
        context: context,
        title: _premiumLockTitle(l, format),
        message: _premiumLockMessage(l, format),
      );
      return;
    }

    setState(() {
      _selectedFormat = format;
      _fileController.text = _defaultFileName;
    });
  }

  Future<void> _download(bool premiumActive) async {
    final l = AppLocalizations.of(context);
    final selected = _selectedFormats;
    if (selected.isEmpty) {
      AppNotification.warning(context, message: l.t('selectDownloadOption'));
      return;
    }
    if (widget.media.sourceUrl.trim().isEmpty) {
      AppNotification.error(context, message: l.t('downloadJobFailed'));
      return;
    }
    final legalConsent = ref.read(legalConsentServiceProvider);
    final acceptedResponsibleUse = await legalConsent
        .hasAcceptedResponsibleUse();
    if (!mounted) return;
    if (!acceptedResponsibleUse) {
      context.push('/responsible-use');
      return;
    }

    final premiumLocked = selected.where((format) => format.isPremium).toList();
    if (premiumLocked.isNotEmpty && !premiumActive) {
      showPremiumLockSheet(
        context: context,
        title: _premiumLockTitle(l, premiumLocked.first),
        message: _premiumLockMessage(l, premiumLocked.first),
      );
      return;
    }

    final allowance = await ref
        .read(subscriptionControllerProvider.notifier)
        .checkDownloadAllowance(requestedCount: selected.length);
    if (!mounted) return;
    if (!allowance.allowed) {
      showPremiumLockSheet(
        context: context,
        title: l.t('dailyLimitReachedTitle'),
        message: l.t('dailyLimitReachedMessage'),
        icon: Icons.all_inclusive_rounded,
      );
      return;
    }
    final hasConfirmedRights = await legalConsent.hasConfirmedDownloadRights();
    if (!mounted) return;
    if (!hasConfirmedRights) {
      final confirmed = await showDownloadRightsConfirmationDialog(context);
      if (!mounted) return;
      if (!confirmed) return;
      await legalConsent.confirmDownloadRights();
      if (!mounted) return;
    }
    String? apiJobId;
    setState(() => _creatingDownloadJob = true);
    try {
      final job = await ref
          .read(activeOperationWakelockServiceProvider)
          .runWithWakelock(
            () => ref
                .read(apiDownloadServiceProvider)
                .startDownload(
                  url: widget.media.sourceUrl,
                  selectedFormats: selected,
                  premium: false,
                  noWatermark: false,
                ),
            reason: 'create download job',
          );
      apiJobId = job.jobId.isEmpty ? null : job.jobId;
      if (!mounted) return;
      setState(() => _creatingDownloadJob = false);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _creatingDownloadJob = false);
      AppNotification.error(
        context,
        message: _friendlyDownloadError(l, error.toString()),
      );
      return;
    }
    context.push(
      '/download-progress',
      extra: DownloadProgressArgs(
        media: widget.media,
        formats: selected,
        fileName: _fileController.text.trim().isEmpty
            ? _defaultFileName
            : _fileController.text.trim(),
        saveToGallery:
            !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS) &&
            ref.read(autoSaveToGalleryControllerProvider),
        apiJobId: apiJobId,
      ),
    );
  }

  String _premiumLockTitle(AppLocalizations l, DownloadFormatModel format) {
    if (_isImage) return l.t('imagePremiumTitle');
    if (format.type == DownloadType.audio) {
      return l.t('audioExtractionPremiumTitle');
    }
    return l.t('fhd4kPremiumTitle');
  }

  String _premiumLockMessage(AppLocalizations l, DownloadFormatModel format) {
    if (_isImage) return l.t('imagePremiumMessage');
    if (format.type == DownloadType.audio) {
      return l.t('audioExtractionPremiumMessage');
    }
    return l.t('fhd4kPremiumMessage');
  }

  String _friendlyDownloadError(AppLocalizations l, String message) {
    final lower = message.toLowerCase();
    if (lower.contains('could not connect to the server') ||
        lower.contains('could not connect to api') ||
        lower.contains('api request timed out')) {
      return l.t('serverConnectionProblem');
    }
    if (lower.contains('facebook photo posts are not available') ||
        (lower.contains('facebook') &&
            (lower.contains('registered users') ||
                lower.contains('cookies-from-browser') ||
                lower.contains('login required')))) {
      return l.t('facebookPhotoUnavailable');
    }
    if (lower.contains('login required') ||
        lower.contains('rate-limit') ||
        lower.contains('rate limit') ||
        lower.contains('content is not available') ||
        lower.contains('instagram blocked') ||
        lower.contains('refresh instagram cookies')) {
      return l.t('instagramBlocked');
    }
    return l.t('downloadJobFailed');
  }

  @override
  void dispose() {
    _fileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionControllerProvider);
    final autoSaveToGallery = ref.watch(autoSaveToGalleryControllerProvider);
    final galleryPublishingSupported =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final premiumActive = subscription.isPremium;
    final l = AppLocalizations.of(context);
    final remainingText = l
        .t('freeDownloadsLeft')
        .replaceFirst(
          '{count}',
          subscription.remainingDownloadsToday.toString(),
        );
    final selected = _selectedFormats;
    final sectionTitle = _isImage
        ? l.t('chooseImageFormat')
        : l.t('chooseFormat');

    return GradientScaffold(
      appBar: AppBar(
        title: Text(l.t('downloadOptions')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _PreviewCard(media: widget.media),
          const SizedBox(height: 18),
          if (!subscription.isPremium) ...[
            PremiumBadge(label: remainingText),
            const SizedBox(height: 12),
          ],
          Text(
            widget.media.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            _isImage
                ? l.platformName(widget.media.platform)
                : '${l.platformName(widget.media.platform)} - ${widget.media.duration}',
            style: TextStyle(color: AppTone.textSecondary(context)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  sectionTitle,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          // Watermark removal was withdrawn. Stripping a platform's
          // attribution mark is exactly what App Review guideline 5.2.3
          // treats as facilitating infringement, and it was being sold as a
          // Premium feature. Media is now always saved as the source
          // provides it.
          const SizedBox(height: 10),
          if (_isImage &&
              (_isInstagram || widget.media.platform == 'Facebook') &&
              _allFormatsUnavailable) ...[
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_rounded,
                    color: AppColors.primaryEnd,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _allUnavailableReason(l),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          for (final format in _visibleFormats) ...[
            FormatOptionCard(
              format: format,
              selected: _selectedFormat?.id == format.id,
              isPremiumActive: premiumActive,
              onTap: () => _select(format, premiumActive),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          Text(
            l.t('saveOptions'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    value: galleryPublishingSupported && autoSaveToGallery,
                    onChanged: galleryPublishingSupported
                        ? (value) => ref
                              .read(
                                autoSaveToGalleryControllerProvider.notifier,
                              )
                              .setEnabled(value)
                        : null,
                    title: Text(l.t('saveToGallery')),
                    subtitle: Text(
                      galleryPublishingSupported
                          ? l.t('autoSaveAndroidDescription')
                          : l.t('autoSaveIosDescription'),
                      style: TextStyle(
                        color: AppTone.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Divider(color: AppTone.border(context)),
                const SizedBox(height: 8),
                TextField(
                  controller: _fileController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.drive_file_rename_outline_rounded,
                    ),
                    labelText: l.t('customFilename'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const LegalNoticeCard(),
          const SizedBox(height: 18),
          PrimaryGradientButton(
            label: l.t('download'),
            icon: Icons.download_rounded,
            isLoading: _creatingDownloadJob,
            onPressed: selected.isEmpty || _creatingDownloadJob
                ? null
                : () => _download(premiumActive),
          ),
          const ActiveOperationNote(),
          if (_isVideo)
            TextButton.icon(
              onPressed: () => context.push('/audio'),
              icon: const Icon(Icons.graphic_eq_rounded),
              label: Text(l.t('openAudioTool')),
            ),
        ],
      ),
    );
  }

  String _allUnavailableReason(AppLocalizations l) {
    for (final format in _visibleFormats) {
      final reason = format.unavailableReasonKey;
      if (reason != null && reason.trim().isNotEmpty) {
        return l.t(reason);
      }
    }
    return l.t('selectDownloadOption');
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.media});

  final MediaInfoModel media;

  @override
  Widget build(BuildContext context) {
    final isImage = media.mediaType == MediaType.image;
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.primaryStart, AppColors.primaryEnd],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              isImage ? Icons.image_rounded : Icons.play_circle_fill_rounded,
              size: 70,
              color: Colors.white,
            ),
          ),
          if (!isImage)
            Positioned(
              right: 14,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(media.duration),
              ),
            ),
        ],
      ),
    );
  }
}
