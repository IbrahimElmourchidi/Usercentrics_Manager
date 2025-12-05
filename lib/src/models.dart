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
