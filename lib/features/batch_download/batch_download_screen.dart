import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/premium_locked_card.dart';
import 'package:apexload/shared/widgets/primary_gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BatchDownloadScreen extends ConsumerStatefulWidget {
  const BatchDownloadScreen({super.key});

  @override
  ConsumerState<BatchDownloadScreen> createState() =>
      _BatchDownloadScreenState();
}

class _BatchDownloadScreenState extends ConsumerState<BatchDownloadScreen> {
  final _links = TextEditingController();
  List<String> _valid = [];
  List<String> _invalid = [];

  @override
  void dispose() {
    _links.dispose();
    super.dispose();
  }

  void _validate() {
    final lines = _links.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    setState(() {
      _valid = lines.where((line) => line.startsWith('http')).toList();
      _invalid = lines.where((line) => !line.startsWith('http')).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(subscriptionControllerProvider).isPremium;
    final l = AppLocalizations.of(context);
    if (!premium) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: PremiumLockedCard(
            title: l.t('batchPremiumTitle'),
            description: l.t('batchPremiumMessage'),
            onUpgrade: () => context.push('/premium'),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 104),
      children: [
        Text(
          l.t('batchDownloads'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            children: [
              TextField(
                controller: _links,
                minLines: 6,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: l.t('pasteOneLinkPerLine'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _BatchActionButton(
                      label: l.t('import'),
                      icon: Icons.content_paste_rounded,
                      primary: false,
                      onPressed: () async {
                        final text = await ref
                            .read(clipboardServiceProvider)
                            .readText();
                        _links.text = text;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BatchActionButton(
                      label: l.t('validate'),
                      icon: Icons.fact_check_rounded,
                      primary: true,
                      onPressed: _validate,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_valid.isNotEmpty || _invalid.isNotEmpty)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.t('queuePreview'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                ..._valid.map((link) => _QueueRow(link: link, valid: true)),
                ..._invalid.map((link) => _QueueRow(link: link, valid: false)),
                const SizedBox(height: 14),
                PrimaryGradientButton(
                  label: l.t('startBatchDownload'),
                  icon: Icons.playlist_add_check_rounded,
                  // TODO: Replace this mock queue action with the real VPS
                  // /api/batch endpoint after backend integration.
                  onPressed: _valid.isEmpty
                      ? null
                      : () => AppNotification.success(
                          context,
                          message: l.t('batchQueueCreated'),
                        ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BatchActionButton extends StatelessWidget {
  const _BatchActionButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight
        ? AppColors.primaryStart.withValues(alpha: 0.45)
        : AppColors.primaryEnd.withValues(alpha: 0.65);
    final textColor = primary
        ? Colors.white
        : isLight
        ? AppColors.lightTextPrimary
        : AppColors.textPrimary;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: primary
            ? const LinearGradient(
                colors: [AppColors.primaryStart, AppColors.primaryEnd],
              )
            : null,
        color: primary
            ? null
            : isLight
            ? AppColors.lightSurface
            : AppColors.cardLight.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary ? Colors.transparent : borderColor),
        boxShadow: [
          BoxShadow(
            color: primary
                ? AppColors.primaryStart.withValues(alpha: 0.24)
                : Colors.black.withValues(alpha: isLight ? 0.06 : 0.12),
            blurRadius: primary ? 18 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: primary ? Colors.white : AppColors.primaryEnd,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.link, required this.valid});

  final String link;
  final bool valid;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        valid ? Icons.check_circle_rounded : Icons.error_rounded,
        color: valid ? AppColors.success : AppColors.error,
      ),
      title: Text(link, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        valid
            ? AppLocalizations.of(context).t('ready')
            : AppLocalizations.of(context).t('invalidLink'),
        style: TextStyle(color: AppTone.textSecondary(context)),
      ),
    );
  }
}
