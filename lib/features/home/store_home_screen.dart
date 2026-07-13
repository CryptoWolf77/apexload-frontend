import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/features/quick_editor/quick_editor_gate.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/download_item_card.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/legal_notice_card.dart';
import 'package:apexload/shared/widgets/premium_badge.dart';
import 'package:apexload/shared/widgets/primary_gradient_button.dart';
import 'package:apexload/shared/widgets/yahyaz_lab_signature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StoreHomeScreen extends ConsumerWidget {
  const StoreHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final recent = ref
        .watch(libraryControllerProvider)
        .where((item) => item.type == DownloadType.video || item.isEdited)
        .take(2)
        .toList();
    final subscription = ref.watch(subscriptionControllerProvider);

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
                    l.t('storeSubtitle'),
                    style: TextStyle(color: AppTone.textSecondary(context)),
                  ),
                ],
              ),
            ),
            PremiumBadge(onTap: () => context.push('/premium')),
          ],
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_fix_high_rounded,
                    color: AppColors.primaryEnd,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.t('storeHeroTitle'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l.t('storeHeroDescription'),
                style: TextStyle(
                  color: AppTone.textSecondary(context),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              PrimaryGradientButton(
                label: l.t('openQuickEditor'),
                icon: Icons.folder_open_rounded,
                onPressed: () => context.go('/quick-editor'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l.t('storeToolsTitle'),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StoreToolCard(
              icon: Icons.content_cut_rounded,
              label: l.t('trimVideo'),
            ),
            _StoreToolCard(
              icon: Icons.volume_off_rounded,
              label: l.t('muteVideo'),
            ),
            _StoreToolCard(
              icon: Icons.graphic_eq_rounded,
              label: l.t('extractAudio'),
            ),
            _StoreToolCard(
              icon: Icons.swap_horizontal_circle_rounded,
              label: l.t('audioSwap'),
            ),
            _StoreToolCard(
              icon: Icons.gif_box_rounded,
              label: l.t('videoToGif'),
            ),
            _StoreToolCard(
              icon: Icons.photo_size_select_small_rounded,
              label: l.t('reelsShortsCreator'),
            ),
            _StoreToolCard(
              icon: Icons.tune_rounded,
              label: l.t('videoOptimizer'),
            ),
            _StoreToolCard(
              icon: Icons.movie_creation_rounded,
              label: l.t('convertVideoToMp4'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        GlassCard(
          onTap: () => context.push('/premium'),
          child: Row(
            children: [
              Icon(
                subscription.isPremium
                    ? Icons.verified_rounded
                    : Icons.workspace_premium_rounded,
                color: AppColors.premiumGold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  subscription.isPremium
                      ? l.t('premiumActive')
                      : l.t('storePremiumPrompt'),
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
        const SizedBox(height: 18),
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
        if (recent.isEmpty)
          GlassCard(
            child: Text(
              l.t('storeNoRecentMedia'),
              style: TextStyle(color: AppTone.textSecondary(context)),
            ),
          )
        else
          ...recent.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DownloadItemCard(
                item: item,
                onOpen: () =>
                    ref.read(localMediaServiceProvider).openItem(item),
                onShare: () =>
                    ref.read(localMediaServiceProvider).shareItem(item),
                onDelete: () async {
                  await ref
                      .read(localMediaServiceProvider)
                      .deleteItemFiles(item);
                  ref.read(libraryControllerProvider.notifier).delete(item.id);
                },
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
}

class _StoreToolCard extends StatelessWidget {
  const _StoreToolCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryEnd),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
