import 'package:apexload/shared/services/legal_consent_service.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('responsible use acceptance is stored by version', () async {
    SharedPreferences.setMockInitialValues({});
    const service = LegalConsentService();

    expect(await service.hasAcceptedResponsibleUse(), isFalse);
    await service.acceptResponsibleUse();

    expect(await service.hasAcceptedResponsibleUse(), isTrue);
    expect(await service.hasAcceptedResponsibleUse(version: 2), isFalse);
  });

  test('download rights confirmation is stored by version', () async {
    SharedPreferences.setMockInitialValues({});
    const service = LegalConsentService();

    expect(await service.hasConfirmedDownloadRights(), isFalse);
    await service.confirmDownloadRights();

    expect(await service.hasConfirmedDownloadRights(), isTrue);
    expect(await service.hasConfirmedDownloadRights(version: 2), isFalse);
  });

  test('responsible use localization keys exist in English and Arabic', () {
    final keys = [
      'responsibleUseAgreementTitle',
      'responsibleUseCheckbox',
      'confirmDownloadRightsTitle',
      'confirmDownloadRightsCheckbox',
      'backendProcessingDisclosure',
      'acceptableUsePolicy',
      'copyrightPolicy',
      'submitTakedownRequest',
    ];

    for (final locale in const [Locale('en'), Locale('ar')]) {
      final l = AppLocalizations(locale);
      for (final key in keys) {
        expect(l.t(key), isNot(key));
        expect(l.t(key).trim(), isNotEmpty);
      }
    }
  });
}
