class LegalSection {
  const LegalSection({required this.titleKey, required this.bodyKey});

  final String titleKey;
  final String bodyKey;
}

class LegalDocument {
  const LegalDocument({
    required this.titleKey,
    required this.updatedKey,
    required this.introKey,
    required this.sections,
  });

  final String titleKey;
  final String updatedKey;
  final String introKey;
  final List<LegalSection> sections;
}

abstract final class ApexLoadLegalDocuments {
  static const privacy = LegalDocument(
    titleKey: 'privacyPolicy',
    updatedKey: 'legalLastUpdated',
    introKey: 'privacyIntro',
    sections: [
      LegalSection(titleKey: 'privacyDataTitle', bodyKey: 'privacyDataBody'),
      LegalSection(
        titleKey: 'privacyProcessingTitle',
        bodyKey: 'privacyProcessingBody',
      ),
      LegalSection(titleKey: 'privacyLocalTitle', bodyKey: 'privacyLocalBody'),
      LegalSection(
        titleKey: 'privacyPermissionsTitle',
        bodyKey: 'privacyPermissionsBody',
      ),
      LegalSection(
        titleKey: 'privacyThirdPartiesTitle',
        bodyKey: 'privacyThirdPartiesBody',
      ),
      LegalSection(
        titleKey: 'privacyAccountsTitle',
        bodyKey: 'privacyAccountsBody',
      ),
      LegalSection(
        titleKey: 'privacyChoicesTitle',
        bodyKey: 'privacyChoicesBody',
      ),
      LegalSection(titleKey: 'legalContactTitle', bodyKey: 'legalContactBody'),
    ],
  );

  static const terms = LegalDocument(
    titleKey: 'termsOfUse',
    updatedKey: 'legalLastUpdated',
    introKey: 'termsIntro',
    sections: [
      LegalSection(titleKey: 'termsUseTitle', bodyKey: 'termsUseBody'),
      LegalSection(
        titleKey: 'termsCopyrightTitle',
        bodyKey: 'termsCopyrightBody',
      ),
      LegalSection(
        titleKey: 'termsProhibitedTitle',
        bodyKey: 'termsProhibitedBody',
      ),
      LegalSection(
        titleKey: 'termsPlatformsTitle',
        bodyKey: 'termsPlatformsBody',
      ),
      LegalSection(
        titleKey: 'termsSubscriptionsTitle',
        bodyKey: 'termsSubscriptionsBody',
      ),
      LegalSection(
        titleKey: 'termsLimitationsTitle',
        bodyKey: 'termsLimitationsBody',
      ),
      LegalSection(titleKey: 'legalContactTitle', bodyKey: 'legalContactBody'),
    ],
  );
}
