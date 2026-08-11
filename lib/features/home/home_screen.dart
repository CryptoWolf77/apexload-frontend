import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/core/utils/platform_detector.dart';
import 'package:apexload/features/quick_editor/quick_editor_gate.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/services/api_analyze_service.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:apexload/shared/widgets/download_item_card.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/legal_notice_card.dart';
import 'package:apexload/shared/widgets/platform_chip.dart';
import 'package:apexload/shared/widgets/premium_badge.dart';
import 'package:apexload/shared/widgets/primary_gradient_button.dart';
import 'package:apexload/shared/widgets/supported_platforms_carousel.dart';
import 'package:apexload/shared/widgets/yahyaz_lab_signature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _urlController = TextEditingController();
  var _platform = 'Auto detect';
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(() {
      final text = _urlController.text;
      // Never surface a platform this build does not support.
      final detected = AppConstants.isBlockedSource(text)
          ? 'Auto detect'
          : detectPlatformName(text);
      setState(() => _platform = detected);
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final text = await ref.read(clipboardServiceProvider).readText();
    if (!mounted) return;
    if (text.isEmpty) {
      AppNotification.warning(
        context,
        message: AppLocalizations.of(context).t('clipboardEmpty'),
      );
      return;
    }
    _urlController.text = text;
  }

  Future<void> _analyze() async {
    final l = AppLocalizations.of(context);
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      AppNotification.info(context, message: l.t('pasteFirst'));
      return;
    }
    // Refuse unsupported sources before anything leaves the device.
    if (AppConstants.isBlockedSource(url)) {
      AppNotification.info(context, message: l.t('sourceNotSupported'));
      return;
    }
    final accepted = await ref
        .read(legalConsentServiceProvider)
        .hasAcceptedResponsibleUse();
    if (!mounted) return;
    if (!accepted) {
      context.push('/responsible-use');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ref
          .read(activeOperationWakelockServiceProvider)
          .runWithWakelock(
            () => ref.read(analyzeServiceProvider).analyze(url),
            reason: 'analyze link',
          );
      if (!mounted) return;
      setState(() => _loading = false);
      if (result.usedMockFallback) {
        AppNotification.info(
          context,
          message: AppLocalizations.of(context).t('backendUnavailableDemo'),
        );
      }
      context.push('/download-options', extra: result.media);
    } on AnalyzeException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppNotification.error(
        context,
        message: _friendlyAnalyzeError(
          AppLocalizations.of(context),
          error.message,
        ),
      );
    } on Object {
      if (!mounted) return;
      setState(() => _loading = false);
      AppNotification.error(
        context,
        message: AppLocalizations.of(context).t('connectionProblem'),
      );
    }
  }

  String _friendlyAnalyzeError(AppLocalizations l, String message) {
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
    return message.isEmpty ? l.t('analyzeFailed') : message;
  }

  void _showPasteLinkHelp() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PasteLinkTutorialSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final recent = ref.watch(libraryControllerProvider).take(2).toList();
    final subscription = ref.watch(subscriptionControllerProvider);
    const showWhatsappStatusSaver = true;
    final remainingText = l
        .t('freeDownloadsLeft')
        .replaceFirst(
          '{count}',
          subscription.remainingDownloadsToday.toString(),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 104),
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryStart, AppColors.primaryEnd],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                  ),
                  Text(
                    AppConstants.subtitle,
                    style: TextStyle(color: AppTone.textSecondary(context)),
                  ),
                ],
              ),
            ),
            PremiumBadge(onTap: () => context.push('/premium')),
          ],
        ),
        const SizedBox(height: 20),
        GlassCard(
          child: Row(
            children: [
              Icon(
                subscription.isPremium
                    ? Icons.verified_rounded
                    : Icons.download_done_rounded,
                color: subscription.isPremium
                    ? AppColors.premiumGold
                    : AppColors.primaryEnd,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  subscription.isPremium ? l.t('premiumActive') : remainingText,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (!subscription.isPremium)
                TextButton(
                  onPressed: () => context.push('/premium'),
                  child: Text(l.t('upgradeToPremium')),
                )
              else
                PremiumBadge(label: l.t('active')),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.t('pasteYourVideoLink'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _showPasteLinkHelp,
                    icon: const Icon(Icons.help_outline_rounded, size: 18),
                    label: Text(l.t('howToUse')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppColors.primaryEnd,
                      side: BorderSide(
                        color: AppColors.primaryEnd.withValues(alpha: 0.48),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                minLines: 1,
                maxLines: 3,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: 'https://www.tiktok.com/@creator/video/...',
                  prefixIcon: const Icon(Icons.link_rounded),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _urlController,
                    builder: (_, value, _) {
                      final hasLink = value.text.trim().isNotEmpty;
                      return IconButton(
                        tooltip: hasLink
                            ? l.t('clearLink')
                            : l.t('pasteFromClipboard'),
                        onPressed: hasLink
                            ? () => _urlController.clear()
                            : _paste,
                        icon: Icon(
                          hasLink
                              ? Icons.close_rounded
                              : Icons.content_paste_rounded,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PlatformChip(
                label: _platform,
                selected: _platform != 'Auto detect',
              ),
              const SizedBox(height: 14),
              PrimaryGradientButton(
                label: l.t('analyzeLink'),
                icon: Icons.auto_awesome_rounded,
                isLoading: _loading,
                onPressed: _analyze,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l.t('supportedPlatforms'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const SupportedPlatformsCarousel(),
        const SizedBox(height: 10),
        // Non-affiliation and ownership notice, matching the disclaimer
        // pattern used by comparable apps that pass App Review.
        Text(
          l.t('contentOwnershipNotice'),
          style: TextStyle(
            color: AppTone.textSecondary(context),
            fontSize: 12,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        if (showWhatsappStatusSaver) ...[
          GlassCard(
            onTap: () => context.push('/whatsapp-status'),
            child: Row(
              children: [
                const _WhatsAppStatusMark(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.t('whatsappStatusSaver'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.t('whatsappStatusHomeCopy'),
                        style: TextStyle(color: AppTone.textSecondary(context)),
                      ),
                    ],
                  ),
                ),
                if (!subscription.isPremium)
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.premiumGold,
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppTone.textSecondary(context),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l.t('recentDownloads'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            TextButton(
              onPressed: () => context.go('/downloads'),
              child: Text(l.t('viewAll')),
            ),
          ],
        ),
        ...recent.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DownloadItemCard(
              item: item,
              onOpen: () => _openItem(item),
              onShare: () => _shareItem(item),
              onDelete: () => _deleteItem(item),
              onRename: () {},
              onEdit: () {
                final premium = ref
                    .read(subscriptionControllerProvider)
                    .isPremium;
                if (!premium) {
                  showQuickEditorPremiumSheet(context);
                  return;
                }
                context.push('/quick-editor/edit', extra: item);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        const LegalNoticeCard(compact: true),
        const SizedBox(height: 22),
        const YahyazLabSignature(compact: true),
      ],
    );
  }

  Future<void> _openItem(DownloadItemModel item) async {
    try {
      await ref.read(localMediaServiceProvider).openItem(item);
    } on Object catch (error) {
      if (!mounted) return;
      AppNotification.error(
        context,
        message: AppLocalizations.of(context).t(
          _isMissingFileError(error)
              ? 'fileNoLongerAvailable'
              : 'couldNotOpenFile',
        ),
      );
    }
  }

  Future<void> _shareItem(DownloadItemModel item) async {
    try {
      await ref.read(localMediaServiceProvider).shareItem(item);
    } on Object catch (error) {
      if (!mounted) return;
      AppNotification.error(
        context,
        message: AppLocalizations.of(context).t(
          _isMissingFileError(error)
              ? 'fileNoLongerAvailable'
              : 'sharingFailed',
        ),
      );
    }
  }

  bool _isMissingFileError(Object error) {
    return error.toString().contains('localFileMissing');
  }

  Future<void> _deleteItem(DownloadItemModel item) async {
    await ref.read(localMediaServiceProvider).deleteItemFiles(item);
    ref.read(libraryControllerProvider.notifier).delete(item.id);
  }
}

class _WhatsAppStatusMark extends StatelessWidget {
  const _WhatsAppStatusMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF33E17A), Color(0xFF0DA955)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25D366).withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.4),
            ),
          ),
          const Icon(Icons.phone_rounded, color: Colors.white, size: 19),
          PositionedDirectional(
            bottom: 9,
            start: 10,
            child: Transform.rotate(
              angle: -0.7,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(7),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasteLinkStepData {
  const _PasteLinkStepData({
    required this.assetPath,
    required this.titleKey,
    required this.descriptionKey,
  });

  final String assetPath;
  final String titleKey;
  final String descriptionKey;
}

class _PasteLinkTutorialSheet extends StatefulWidget {
  const _PasteLinkTutorialSheet();

  @override
  State<_PasteLinkTutorialSheet> createState() =>
      _PasteLinkTutorialSheetState();
}

class _PasteLinkTutorialSheetState extends State<_PasteLinkTutorialSheet> {
  static const _steps = [
    _PasteLinkStepData(
      assetPath: 'assets/tutorials/paste_link/instagram_step_1_share.png',
      titleKey: 'pasteLinkInstagramShareTitle',
      descriptionKey: 'pasteLinkInstagramShareDescription',
    ),
    _PasteLinkStepData(
      assetPath: 'assets/tutorials/paste_link/instagram_step_2_copy_link.png',
      titleKey: 'pasteLinkInstagramCopyTitle',
      descriptionKey: 'pasteLinkCopyDescription',
    ),
    _PasteLinkStepData(
      assetPath: 'assets/tutorials/paste_link/tiktok_step_1_share.png',
      titleKey: 'pasteLinkTikTokShareTitle',
      descriptionKey: 'pasteLinkTikTokShareDescription',
    ),
    _PasteLinkStepData(
      assetPath: 'assets/tutorials/paste_link/tiktok_step_2_copy_link.png',
      titleKey: 'pasteLinkTikTokCopyTitle',
      descriptionKey: 'pasteLinkCopyDescription',
    ),
  ];

  late final PageController _controller;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final isLast = _index == _steps.length - 1;
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: size.height * 0.94),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTone.card(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(top: BorderSide(color: AppTone.border(context))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.38),
                  blurRadius: 30,
                  offset: const Offset(0, -12),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 10, 18, 16 + viewPadding.bottom),
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTone.textSecondary(
                        context,
                      ).withValues(alpha: 0.48),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.t('pasteLinkTutorialTitle'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: l.t('close'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryEnd.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.primaryEnd.withValues(alpha: 0.36),
                          ),
                        ),
                        child: Text(
                          '${_index + 1} / ${_steps.length}',
                          style: const TextStyle(
                            color: AppColors.primaryEnd,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          children: [
                            for (var i = 0; i < _steps.length; i++) ...[
                              Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: i <= _index
                                        ? AppColors.primaryEnd
                                        : AppTone.border(context),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              if (i < _steps.length - 1)
                                const SizedBox(width: 4),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _steps.length,
                      onPageChanged: (value) => setState(() => _index = value),
                      itemBuilder: (context, index) =>
                          _PasteLinkStepPage(step: _steps[index]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryEnd.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryEnd.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_rounded,
                          color: AppColors.primaryEnd,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.t('pasteLinkTutorialNote'),
                            style: TextStyle(
                              color: AppTone.textSecondary(context),
                              height: 1.28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _index == 0 ? null : _previous,
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: Text(l.t('back')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: isLast
                              ? () => Navigator.pop(context)
                              : _next,
                          icon: Icon(
                            isLast
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                          ),
                          label: Text(l.t(isLast ? 'done' : 'next')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _previous() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }
}

class _PasteLinkStepPage extends StatelessWidget {
  const _PasteLinkStepPage({required this.step});

  final _PasteLinkStepData step;

  void _openPreview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _PasteLinkImagePreview(assetPath: step.assetPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                Text(
                  l.t(step.titleKey),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  l.t(step.descriptionKey),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTone.textSecondary(context),
                    height: 1.28,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _openPreview(context),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * 0.72,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTone.border(context)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryEnd.withValues(alpha: 0.14),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      step.assetPath,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _openPreview(context),
                  icon: const Icon(Icons.zoom_out_map_rounded, size: 18),
                  label: Text(l.t('tapImageToEnlarge')),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryEnd,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PasteLinkImagePreview extends StatelessWidget {
  const _PasteLinkImagePreview({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF050914),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.asset(assetPath, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: 10,
              end: 10,
              child: IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                tooltip: l.t('close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
