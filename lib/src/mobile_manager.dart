import 'dart:async';
import 'package:flutter/foundation.dart';
// Note: This import relies on the dependency defined in pubspec.yaml
import 'package:usercentrics_sdk/usercentrics_sdk.dart';
import 'interface.dart';
import 'models.dart';

class UsercentricsMobileManager implements PrivacyManager {
  static final UsercentricsMobileManager _instance =
      UsercentricsMobileManager._internal();
  factory UsercentricsMobileManager() => _instance;
  UsercentricsMobileManager._internal();

  bool _isInitialized = false;
  // Controller to stream consent updates to the package consumer
  final _consentController =
      StreamController<List<PrivacyServiceConsent>>.broadcast();
  List<PrivacyServiceConsent> _lastKnownConsents = [];

  @override
  bool get isInitialized => _isInitialized;

  @override
  // Start the stream with the last known consents for immediate state access
  Stream<List<PrivacyServiceConsent>> get consentStream =>
      _consentController.stream.startWith(_lastKnownConsents);

  @override
  Future<void> initialize({required String settingsId, String? uid}) async {
    try {
      if (_isInitialized) return;

      // Initialize the native Usercentrics SDK
      Usercentrics.initialize(
        settingsId: settingsId,
        loggerLevel: kDebugMode
            ? UsercentricsLoggerLevel.debug
            : UsercentricsLoggerLevel.none,
      );

      // Restore user session if a UID is provided
      if (uid != null) {
        await Usercentrics.restoreUserSession(controllerId: uid);
      }

      _isInitialized = true;
      // Fetch initial status and update local state
      _updateConsents((await Usercentrics.status).consents);
    } catch (e) {
      debugPrint("Usercentrics Init Failed on Mobile: $e");
    }
  }

  @override
  Future<void> loginUser(String uid) async {
    final status = await Usercentrics.restoreUserSession(controllerId: uid);
    _updateConsents(status.consents);
  }

  @override
  Future<void> logoutUser() async {
    await Usercentrics.clearUserSession();
    _updateConsents([]); // Clear local consents upon logout
  }

  @override
  Future<void> showPrivacyBanner() async {
    // Show the first layer (banner) and update consents upon completion
    final response = await Usercentrics.showFirstLayer();
    if (response != null) _updateConsents(response.consents);
  }

  @override
  Future<void> showPrivacyManager() async {
    // Show the second layer (detailed settings) and update consents upon completion
    final response = await Usercentrics.showSecondLayer();
    if (response != null) _updateConsents(response.consents);
  }

  // --- Compliance Operations ---

  @override
  Future<void> setConsentStatus(String serviceId, bool status) async {
    // To set a single consent, we must first retrieve all current decisions,
    // modify the target decision, and then save the entire list back to the SDK.
    final decisions = _lastKnownConsents.map((e) {
      return UserDecision(
        serviceId: e.templateId,
        // Only modify the status of the target service ID, keep others as they were
        consent: e.templateId == serviceId ? status : e.status,
      );
    }).toList();

    // Save the new list of decisions
    final consents = await Usercentrics.saveDecisions(
      decisions: decisions,
      consentType: UsercentricsConsentType.explicit,
    );
    _updateConsents(consents);
  }

  @override
  Future<bool> getConsentStatus(String serviceId) async {
    // Retrieve status from the cached list
    return _lastKnownConsents
        .firstWhere((element) => element.templateId == serviceId,
            orElse: () => const PrivacyServiceConsent(
                templateId: '', status: false, name: ''))
        .status;
  }

  @override
  Future<DataDeletionResult> requestDataDeletion() async {
    // For the CMP, this primarily means clearing local consent data
    await logoutUser();
    return (
      success: true,
      message: 'Local session cleared via Usercentrics SDK'
    );
  }

  @override
  Future<UserDataPayload> requestDataAccess() async {
    // The SDK does not typically handle the full data access request,
    // as that often requires server-side data processing.
    return (
      success: false,
      dataUrl: null,
      message: 'Full data access request must be handled by backend API.'
    );
  }

  @override
  Future<void> setTrackingEnabled(bool enabled) async {
    // Accept or deny all services based on the input
    final consents = enabled
        ? await Usercentrics.acceptAll(
            consentType: UsercentricsConsentType.explicit)
        : await Usercentrics.denyAll(
            consentType: UsercentricsConsentType.explicit);
    _updateConsents(consents);
  }

  @override
  Future<bool> isUserTracked() async {
    // If any service has consent, we consider the user 'tracked'
    return _lastKnownConsents.any((e) => e.status);
  }

  // --- Helpers ---

  /// Helper to map the native SDK model ([UsercentricsServiceConsent]) to our
  /// shared package model ([PrivacyServiceConsent]) and update the stream.
  void _updateConsents(List<UsercentricsServiceConsent> sdkConsents) {
    final mapped = sdkConsents
        .map((c) => PrivacyServiceConsent(
              templateId: c.templateId,
              status: c.status,
              name: c.dataProcessor,
            ))
        .toList();

    _lastKnownConsents = mapped;
    _consentController.add(mapped);
  }
}

/// Extension to allow streams to emit an initial value.
extension StreamStartWith<T> on Stream<T> {
  Stream<T> startWith(T initialValue) {
    return Stream.value(initialValue).asyncExpand((_) => this);
  }
}

/// Factory function required by lib/src/factory.dart.
/// This function is conditionally loaded when dart.library.io is detected.
PrivacyManager getManagerInstance() => UsercentricsMobileManager();
