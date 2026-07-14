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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.primaryEnd,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l.t('responsibleUseAgreementTitle'),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
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
                  Text(
                    l.t('responsibleUseMustNotDownload'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
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
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  _LegalLinkTile(
                    label: l.t('termsOfUse'),
                    url: AppConfig.termsUrl,
                    onTap: _openUrl,
                  ),
                  _LegalLinkTile(
                    label: l.t('privacyPolicy'),
                    url: AppConfig.privacyUrl,
                    onTap: _openUrl,
                  ),
                  _LegalLinkTile(
                    label: l.t('acceptableUsePolicy'),
                    url: AppConfig.acceptableUseUrl,
                    onTap: _openUrl,
                  ),
                  _LegalLinkTile(
                    label: l.t('copyrightPolicy'),
                    url: AppConfig.copyrightUrl,
                    onTap: _openUrl,
                  ),
                  _LegalLinkTile(
                    label: l.t('takedownRequest'),
                    url: AppConfig.takedownUrl,
                    onTap: _openUrl,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Semantics(
              label: l.t('responsibleUseCheckbox'),
              checked: _checked,
              child: CheckboxListTile(
                value: _checked,
                onChanged: (value) => setState(() => _checked = value == true),
                title: Text(l.t('responsibleUseCheckbox')),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _decline,
                    child: Text(l.t(widget.reviewOnly ? 'close' : 'decline')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _checked && !_saving ? _agree : null,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(l.t('agreeAndContinue')),
                  ),
                ),
              ],
            ),
          ],
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
    required this.url,
    required this.onTap,
  });

  final String label;
  final String url;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.open_in_new_rounded, size: 20),
          onTap: () => onTap(url),
        ),
      ),
    );
  }
}
