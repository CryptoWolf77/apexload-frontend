import 'package:apexload/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';

Future<bool> showDownloadRightsConfirmationDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DownloadRightsConfirmationDialog(),
  );
  return result == true;
}

class _DownloadRightsConfirmationDialog extends StatefulWidget {
  const _DownloadRightsConfirmationDialog();

  @override
  State<_DownloadRightsConfirmationDialog> createState() =>
      _DownloadRightsConfirmationDialogState();
}

class _DownloadRightsConfirmationDialogState
    extends State<_DownloadRightsConfirmationDialog> {
  var _checked = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.t('confirmDownloadRightsTitle')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.t('confirmDownloadRightsMessage')),
            const SizedBox(height: 12),
            Semantics(
              label: l.t('confirmDownloadRightsCheckbox'),
              checked: _checked,
              child: CheckboxListTile(
                value: _checked,
                onChanged: (value) => setState(() => _checked = value == true),
                title: Text(l.t('confirmDownloadRightsCheckbox')),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.t('cancel')),
        ),
        FilledButton(
          onPressed: _checked ? () => Navigator.of(context).pop(true) : null,
          child: Text(l.t('continue')),
        ),
      ],
    );
  }
}
