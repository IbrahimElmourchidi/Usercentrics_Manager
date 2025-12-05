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
  static final UsercentricsManager _instance = UsercentricsManager._internal();
  factory UsercentricsManager() => _instance;

  // The private delegate holds the concrete platform implementation (Web, Mobile, or Unsupported)
  late final PrivacyManager _delegate;

  UsercentricsManager._internal() {
    // Initialize the delegate using the factory function
    _delegate = stub.createPrivacyManager();
  }

  // --- Exposed API (Forwarded to the delegate) ---

  /// Initialize the privacy manager with the Usercentrics settings ID.
  Future<void> initialize({required String settingsId, String? uid}) =>
      _delegate.initialize(settingsId: settingsId, uid: uid);

  /// Links the session to a logged-in user.
  Future<void> loginUser(String uid) => _delegate.loginUser(uid);

  /// Clears the user session and local storage.
  Future<void> logoutUser() => _delegate.logoutUser();

  /// Show the first layer (Privacy Banner).
  Future<void> showPrivacyBanner() => _delegate.showPrivacyBanner();

  /// Show the second layer (Detailed Privacy Manager).
  Future<void> showPrivacyManager() => _delegate.showPrivacyManager();

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

  /// Current initialization status.
  bool get isInitialized => _delegate.isInitialized;
}
