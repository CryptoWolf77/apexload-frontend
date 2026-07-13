import 'package:apexload/core/constants/app_edition.dart';
import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/constants/legal_documents.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LegalDocumentScreen extends ConsumerWidget {
  const LegalDocumentScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final isStore = ref.watch(appEditionProvider).isStore;
    return GradientScaffold(
      appBar: AppBar(
        title: Text(l.t(document.titleKey)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          Text(
            l.t(document.titleKey),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            l.t(document.updatedKey),
            style: TextStyle(color: AppTone.textSecondary(context)),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Text(
              _editionText(l, document.introKey, isStore),
              style: const TextStyle(height: 1.55),
            ),
          ),
          const SizedBox(height: 14),
          for (final section in document.sections) ...[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 10, 4, 6),
              child: Text(
                _editionText(l, section.titleKey, isStore),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _editionText(l, section.bodyKey, isStore),
                style: TextStyle(
                  color: AppTone.textSecondary(context),
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  String _editionText(AppLocalizations l, String key, bool isStore) {
    final storeKey = '${key}Store';
    if (isStore && l.has(storeKey)) return l.t(storeKey);
    return l.t(key);
  }
}
