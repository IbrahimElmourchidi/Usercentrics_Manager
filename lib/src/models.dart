/// Represents the result of a data deletion request.
///
/// Used for operations like [PrivacyManager.requestDataDeletion] to inform
/// the consumer whether the operation was successful and provide a message.
typedef DataDeletionResult = ({bool success, String message});

/// Represents the payload of a data access request.
///
/// Used for operations like [PrivacyManager.requestDataAccess]. It can optionally
/// contain a [dataUrl] pointing to the data file.
typedef UserDataPayload = ({bool success, String? dataUrl, String message});

/// A platform-agnostic representation of a service consent.
///
/// This class standardizes the consent information received from both
/// the native Usercentrics SDK and the web JavaScript interop layer.
class PrivacyServiceConsent {
  /// The unique identifier for the service template (e.g., 'A1B2C3D4').
  final String templateId;

  /// The current consent status: true if granted, false if denied/revoked.
  final bool status;

  /// The human-readable name of the service (e.g., 'Google Analytics').
  final String name;

  const PrivacyServiceConsent({
    required this.templateId,
    required this.status,
    required this.name,
  });

  @override
  String toString() =>
      'PrivacyServiceConsent(name: $name, status: $status, id: $templateId)';
}

/// Supported languages for Usercentrics CMP.
enum UsercentricsLanguage {
  // Africa, Middle East & Asia
  afrikaans('af'),
  arabic('ar'), // V2 only
  armenian('hy'),
  azerbaijani('az_latn'),
  belarusian('be'),
  bulgarian('bg'),
  bosnian('bs'),
  catalan('ca'),
  czech('cs'),
  welsh('cy'),
  danish('da'),
  galician('gl'),
  german('de'),
  greek('el'),
  english('en'),
  spanish('es'),
  estonian('et'),
  persian('fa'), // V2 only (Farsi)
  finnish('fi'),
  french('fr'),
  hebrew('he'), // V2 only
  hindi('hi'),
  croatian('hr'),
  hungarian('hu'),
  indonesian('id'),
  icelandic('is'),
  italian('it'),
  japanese('ja'),
  georgian('ka'),
  kazakh('kk'),
  korean('ko'),
  lithuanian('lt'),
  latvian('lv'),
  macedonian('mk'),
  malay('ms'),
  mongolian('mn'),

  // Norwegian variants & Dutch
  norwegianBokmal('nb'),
  dutch('nl'),
  norwegianNynorsk('nn'),
  norwegian('no'),

  // Central & South Europe
  polish('pl'),
  portuguese('pt'),
  portugueseBrazil('pt_br'),
  romanian('ro'),
  russian('ru'),
  slovak('sk'),
  slovenian('sl'),
  albanian('sq'),
  serbianCyrillic('sr'),
  serbianLatin('sr_latn'),
  swedish('sv'),
  thai('th'),
  turkish('tr'),
  ukrainian('uk'),
  urdu('ur'), // V2 only
  uzbekLatin('uz_latn'),
  vietnamese('vi'),

  // Chinese variants
  chineseSimplified('zh'),
  chineseCantoneseHk('zh_hk'),
  chineseTraditional('zh_tw');

  final String code;
  const UsercentricsLanguage(this.code);
}
