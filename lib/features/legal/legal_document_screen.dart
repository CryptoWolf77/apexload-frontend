import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/constants/legal_documents.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
import 'package:flutter/material.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
              l.t(document.introKey),
              style: const TextStyle(height: 1.55),
            ),
          ),
          const SizedBox(height: 14),
          for (final section in document.sections) ...[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 10, 4, 6),
              child: Text(
                l.t(section.titleKey),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                l.t(section.bodyKey),
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
}
