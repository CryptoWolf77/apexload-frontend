import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class YahyazLabSignature extends StatelessWidget {
  const YahyazLabSignature({
    super.key,
    this.compact = false,
    this.onTap,
    this.semanticLabel,
  });

  static const linkKey = ValueKey('yahyaz-lab-logo-link');

  final bool compact;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final logoWidth = compact ? 150.0 : 180.0;
    final logo = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: compact ? 170 : 220,
        maxHeight: compact ? 70 : 88,
      ),
      child: Image.asset(
        'assets/images/yahyaz_lab_logo.png',
        width: logoWidth,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context).t('madeBy'),
            style: TextStyle(
              color: AppTone.textSecondary(context),
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: compact ? 5 : 7),
          if (onTap == null)
            logo
          else
            Semantics(
              button: true,
              label: semanticLabel,
              child: GestureDetector(
                key: linkKey,
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: logo,
              ),
            ),
        ],
      ),
    );
  }
}
