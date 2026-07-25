import 'package:apexload/core/constants/app_config.dart';
import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ResponsibleUseAgreementScreen extends ConsumerStatefulWidget {
  const ResponsibleUseAgreementScreen({super.key, this.reviewOnly = false});

  final bool reviewOnly;

  @override
  ConsumerState<ResponsibleUseAgreementScreen> createState() =>
      _ResponsibleUseAgreementScreenState();
}

class _ResponsibleUseAgreementScreenState
    extends ConsumerState<ResponsibleUseAgreementScreen> {
  var _checked = false;
  var _saving = false;

  Future<void> _openUrl(String url) async {
    final l = AppLocalizations.of(context);
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        AppNotification.error(context, message: l.t('couldNotOpenLink'));
      }
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('ApexLoad legal link failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (mounted) {
        AppNotification.error(context, message: l.t('couldNotOpenLink'));
      }
    }
  }

  Future<void> _agree() async {
    if (!_checked || _saving) return;
    setState(() => _saving = true);
    await ref.read(legalConsentServiceProvider).acceptResponsibleUse();
    if (!mounted) return;
    if (widget.reviewOnly && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/home');
    }
  }

  void _decline() {
    if (widget.reviewOnly && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    context.go('/quick-editor');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final prohibited = [
      'responsibleUseNoPrivateProfiles',
      'responsibleUseNoLoginOnly',
      'responsibleUseNoPaidMedia',
      'responsibleUseNoDrm',
      'responsibleUseNoRestricted',
      'responsibleUseNoCopyright',
      'responsibleUseNoPrivacyViolations',
      'responsibleUseNoIllegalOrPlatformViolations',
    ];

    return GradientScaffold(
      appBar: AppBar(
        title: Text(l.t('responsibleUseAgreementTitle')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: widget.reviewOnly,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primaryStart,
                              AppColors.primaryEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l.t('responsibleUseMustNotDownload'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.t('responsibleUseSummary'),
                    style: TextStyle(
                      color: AppTone.textSecondary(context),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final key in prohibited)
                    _ProhibitedItem(label: l.t(key)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.t('legalLinks'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _LegalLinkTile(
                    label: l.t('termsOfUse'),
                    icon: Icons.article_outlined,
                    url: AppConfig.termsUrl,
                    onTap: _openUrl,
                  ),
                  const Divider(height: 1),
                  _LegalLinkTile(
                    label: l.t('privacyPolicy'),
                    icon: Icons.privacy_tip_outlined,
                    url: AppConfig.privacyUrl,
                    onTap: _openUrl,
                  ),
                  const Divider(height: 1),
                  _LegalLinkTile(
                    label: l.t('acceptableUsePolicy'),
                    icon: Icons.rule_rounded,
                    url: AppConfig.acceptableUseUrl,
                    onTap: _openUrl,
                  ),
                  const Divider(height: 1),
                  _LegalLinkTile(
                    label: l.t('copyrightPolicy'),
                    icon: Icons.copyright_rounded,
                    url: AppConfig.copyrightUrl,
                    onTap: _openUrl,
                  ),
                  const Divider(height: 1),
                  _LegalLinkTile(
                    label: l.t('takedownRequest'),
                    icon: Icons.report_outlined,
                    url: AppConfig.takedownUrl,
                    onTap: _openUrl,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _ConsentCard(
              key: const ValueKey('responsible-use-consent'),
              selected: _checked,
              label: l.t('responsibleUseCheckbox'),
              onTap: _saving
                  ? null
                  : () => setState(() => _checked = !_checked),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _checked && !_saving ? _agree : null,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  l.t('agreeAndContinue'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _saving ? null : _decline,
                child: Text(l.t(widget.reviewOnly ? 'close' : 'decline')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({
    super.key,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? AppColors.primaryEnd : AppTone.border(context);
    return Semantics(
      button: true,
      checked: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryEnd.withValues(alpha: 0.1)
                  : AppTone.card(context).withValues(alpha: 0.76),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent, width: selected ? 1.5 : 1),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryEnd.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryStart
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: selected
                          ? AppColors.primaryStart
                          : AppTone.textSecondary(context),
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 19,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppTone.textPrimary(context),
                      fontWeight: FontWeight.w700,
                      height: 1.4,
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

class _ProhibitedItem extends StatelessWidget {
  const _ProhibitedItem({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.block_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _LegalLinkTile extends StatelessWidget {
  const _LegalLinkTile({
    required this.label,
    required this.icon,
    required this.url,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String url;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          minTileHeight: 58,
          contentPadding: const EdgeInsets.symmetric(horizontal: 2),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryEnd.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryEnd, size: 20),
          ),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            'apexload.org',
            style: TextStyle(
              color: AppTone.textSecondary(context),
              fontSize: 12,
            ),
          ),
          trailing: Icon(
            Icons.arrow_outward_rounded,
            color: AppTone.textSecondary(context),
            size: 20,
          ),
          onTap: () => onTap(url),
        ),
      ),
    );
  }
}
