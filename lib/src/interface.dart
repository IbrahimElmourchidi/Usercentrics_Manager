import 'dart:async';
// Assumes lib/src/models.dart is in the same directory and defines these types
import 'models.dart';

abstract class PrivacyManager {
  /// Stream that emits the latest list of active consents, allowing the consuming
  /// application to react to changes in real-time (e.g., after the user interacts
  /// with the CMP banner).
  Stream<List<PrivacyServiceConsent>> get consentStream;

  /// Returns true if the underlying Usercentrics SDK/Web CMP has been successfully
  /// initialized.
  bool get isInitialized;

  /// Initializes the CMP/SDK with the necessary settings.
  ///
  /// [settingsId]: The unique ID provided by the CMP.
  /// [uid]: Optional user ID to restore a cross-device session.
  /// [language]: Optional language setting for the CMP UI.
  Future<void> initialize({
    required String settingsId,
    String? uid,
    UsercentricsLanguage? defaultLanguage,
  });

  /// Links the current session to a logged-in user, facilitating cross-device consent.
  Future<void> loginUser(String uid);

  /// Clears the user session and local consent data.
  Future<void> logoutUser();

  /// Displays the first layer of the CMP (e.g., the initial banner).
  Future<void> showPrivacyBanner();

  /// Displays the second layer of the CMP (e.g., the detailed settings manager).
  Future<void> showPrivacyManager();

  /// Automatically shows the Privacy Banner if consent is required
  /// (i.e., no decision has been made yet).
  Future<void> showPrivacyBannerIfNeeded();

  // --- Compliance Operations ---

  /// Sets the consent status for a specific service template ID.
  ///
  /// [serviceId]: The template ID of the service (e.g., Google Analytics).
  /// [status]: True to grant consent, false to revoke/deny.
  Future<void> setConsentStatus(String serviceId, bool status);

  /// Retrieves the current consent status for a specific service template ID.
  Future<bool> getConsentStatus(String serviceId);

  /// Requests the deletion of local consent data (Right to Erasure - Local only).
  /// Note: Full backend data deletion must typically be implemented separately.
  Future<DataDeletionResult> requestDataDeletion();

  /// Requests the user's data held by the CMP (Right to Access).
  /// Note: The [UserDataPayload] may contain a link to the data file.
  Future<UserDataPayload> requestDataAccess();

  /// Toggles global tracking/data processing, often corresponding to specific
  /// opt-out rights (e.g., CCPA "Do Not Sell").
  Future<void> setTrackingEnabled(bool enabled);

  /// Convenience method to check if any non-essential tracking/data processing
  /// is currently enabled based on existing consents.
  Future<bool> isUserTracked();

  /// Dynamically changes the language of the CMP UI and reloads content.
  ///
  /// The language must be configured and visible in the Usercentrics Admin Interface.
  Future<void> changeLanguage(UsercentricsLanguage language);

  /// Disposes of internal resources (e.g., stream controllers, event listeners).
  /// Should be called when the manager is no longer needed (e.g., app shutdown).
  void dispose();
}
