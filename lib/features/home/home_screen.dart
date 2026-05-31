import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/core/utils/platform_detector.dart';
import 'package:apexload/features/quick_editor/quick_editor_gate.dart';
import 'package:apexload/shared/services/api_analyze_service.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:apexload/shared/widgets/download_item_card.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/legal_notice_card.dart';
import 'package:apexload/shared/widgets/platform_chip.dart';
import 'package:apexload/shared/widgets/premium_badge.dart';
import 'package:apexload/shared/widgets/primary_gradient_button.dart';
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
      setState(() => _platform = detectPlatformName(_urlController.text));
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
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      AppNotification.info(
        context,
        message: AppLocalizations.of(context).t('pasteFirst'),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ref.read(analyzeServiceProvider).analyze(url);
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
    if (lower.contains('youtube requires sign-in') ||
        lower.contains('youtube requested sign-in') ||
        lower.contains('not a bot') ||
        lower.contains('refresh youtube cookies')) {
      return l.t('youtubeRequiresAuth');
    }
    return message.isEmpty ? l.t('analyzeFailed') : message;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final recent = ref.watch(libraryControllerProvider).take(2).toList();
    final subscription = ref.watch(subscriptionControllerProvider);
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
              Text(
                l.t('pasteYourVideoLink'),
                style: Theme.of(context).textTheme.titleLarge,
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
                  suffixIcon: IconButton(
                    tooltip: 'Paste from clipboard',
                    onPressed: _paste,
                    icon: const Icon(Icons.content_paste_rounded),
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
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) =>
                PlatformChip(label: AppConstants.supportedPlatforms[index]),
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemCount: AppConstants.supportedPlatforms.length,
          ),
        ),
        const SizedBox(height: 20),
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
              onDelete: () =>
                  ref.read(libraryControllerProvider.notifier).delete(item.id),
              onRename: () {},
              onEdit: () {
                final premium = ref
                    .read(subscriptionControllerProvider)
                    .isPremium;
                if (!premium) {
                  showQuickEditorPremiumSheet(context);
                  return;
                }
                context.push('/quick-editor', extra: item);
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (!subscription.isPremium)
          GlassCard(
            onTap: () => context.push('/premium'),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.premiumGold,
                  size: 34,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.t('upgradeToPremium'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l.t('homeUpgradeCopy')} ${l.t('noWatermarkWhenAvailable').toLowerCase()}.',
                        style: TextStyle(color: AppTone.textSecondary(context)),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTone.textSecondary(context),
                ),
              ],
            ),
          )
        else
          GlassCard(
            onTap: () => context.push('/premium'),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.premiumGold,
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l.t('premiumActive'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTone.textSecondary(context),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        const LegalNoticeCard(compact: true),
        const SizedBox(height: 22),
        const YahyazLabSignature(compact: true),
      ],
    );
  }
}
