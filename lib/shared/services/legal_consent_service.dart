import 'package:shared_preferences/shared_preferences.dart';

class LegalConsentService {
  const LegalConsentService();

  static const responsibleUseAgreementVersion = 1;
  static const downloadRightsConfirmationVersion = 1;

  static const responsibleUseAgreementKey =
      'responsible_use_agreement_v$responsibleUseAgreementVersion';
  static const downloadRightsConfirmationKey =
      'download_rights_confirmation_v$downloadRightsConfirmationVersion';

  Future<bool> hasAcceptedResponsibleUse({int? version}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_responsibleUseKey(version)) ?? false;
  }

  Future<void> acceptResponsibleUse({int? version}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_responsibleUseKey(version), true);
  }

  Future<bool> hasConfirmedDownloadRights({int? version}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_downloadRightsKey(version)) ?? false;
  }

  Future<void> confirmDownloadRights({int? version}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_downloadRightsKey(version), true);
  }

  String _responsibleUseKey(int? version) =>
      'responsible_use_agreement_v${version ?? responsibleUseAgreementVersion}';

  String _downloadRightsKey(int? version) =>
      'download_rights_confirmation_v${version ?? downloadRightsConfirmationVersion}';
}
