import 'src/interface.dart';
import 'src/models.dart';
// Import the factory logic that conditionally loads the correct platform implementation
import 'src/stub.dart' as stub;

// Export shared models and interface so the consuming application can use the types
export 'src/models.dart';
export 'src/interface.dart';

/// The main entry point for the Usercenteric Manager package.
///
/// This class acts as a singleton facade, exposing the [PrivacyManager]
/// interface methods to the outside world without exposing the complexities
/// of platform-specific implementations.
class UsercentricsManager {
  static final UsercentricsManager instance = UsercentricsManager._internal();

  // The private delegate holds the concrete platform implementation (Web, Mobile, or Unsupported)
  late final PrivacyManager _delegate;

  UsercentricsManager._internal() {
    // Initialize the delegate using the factory function
    _delegate = stub.createPrivacyManager();
  }

  // --- Exposed API (Forwarded to the delegate) ---

  /// Initialize the privacy manager.
  ///
  /// [language] allows setting the CMP language explicitly using the [UsercentricsLanguage] enum.
  Future<void> initialize({
    required String settingsId,
    String? uid,
    UsercentricsLanguage? defaultLanguage,
  }) =>
      _delegate.initialize(
        settingsId: settingsId,
        uid: uid,
        defaultLanguage: defaultLanguage,
      );

  /// Links the session to a logged-in user.
  Future<void> loginUser(String uid) => _delegate.loginUser(uid);

  /// Clears the user session and local storage.
  Future<void> logoutUser() => _delegate.logoutUser();

  /// Show the first layer (Privacy Banner).
  Future<void> showPrivacyBanner() => _delegate.showPrivacyBanner();

  /// Show the second layer (Detailed Privacy Manager).
  Future<void> showPrivacyManager() => _delegate.showPrivacyManager();

  /// Shows the banner only if the user has not yet given/denied consent.
  Future<void> showPrivacyBannerIfNeeded() =>
      _delegate.showPrivacyBannerIfNeeded();

  /// Set the consent status for a specific service ID (Template ID).
  Future<void> setConsentStatus(String serviceId, bool status) =>
      _delegate.setConsentStatus(serviceId, status);

  /// Get the current consent status for a specific service ID.
  Future<bool> getConsentStatus(String serviceId) =>
      _delegate.getConsentStatus(serviceId);

  /// Requests deletion of local consent data.
  Future<DataDeletionResult> requestDataDeletion() =>
      _delegate.requestDataDeletion();

  /// Requests user data.
  Future<UserDataPayload> requestDataAccess() => _delegate.requestDataAccess();

  /// Toggles global tracking (e.g., CCPA "Do Not Sell").
  Future<void> setTrackingEnabled(bool enabled) =>
      _delegate.setTrackingEnabled(enabled);

  /// Convenience method to check if tracking is generally enabled.
  Future<bool> isUserTracked() => _delegate.isUserTracked();

  /// Stream of current service consents.
  Stream<List<PrivacyServiceConsent>> get consentStream =>
      _delegate.consentStream;

  /// Dynamically changes the language of the CMP UI.
  Future<void> changeLanguage(UsercentricsLanguage language) =>
      _delegate.changeLanguage(language);

  /// Disposes of internal resources.
  /// Call this when your app shuts down or if you need to reinitialize the manager.
  void dispose() => _delegate.dispose();

  /// Current initialization status.
  bool get isInitialized => _delegate.isInitialized;
}
