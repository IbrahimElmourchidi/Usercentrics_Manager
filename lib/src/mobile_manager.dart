import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:usercentrics_manager/src/exceptions.dart';
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
  Future<void> initialize({
    required String settingsId,
    String? uid,
    UsercentricsLanguage? defaultLanguage,
  }) async {
    try {
      if (_isInitialized) return;

      // Initialize native SDK with language option

      Usercentrics.initialize(
        settingsId: settingsId,
        defaultLanguage: defaultLanguage?.code,
        loggerLevel: kDebugMode
            ? UsercentricsLoggerLevel.debug
            : UsercentricsLoggerLevel.none,
      );

      if (uid != null) {
        await Usercentrics.restoreUserSession(controllerId: uid);
      }

      _isInitialized = true;
      _updateConsents((await Usercentrics.status).consents);
    } catch (e) {
      debugPrint("Usercentrics Init Failed on Mobile: $e");
    }
  }

  @override
  Future<void> changeLanguage(UsercentricsLanguage language) async {
    _ensureInitialized('changeLanguage');
    if (!_isInitialized) return;
    try {
      await Usercentrics.changeLanguage(language: language.code);
      // Fetch new status and update consents after language change
      _updateConsents((await Usercentrics.status).consents);
    } catch (e) {
      debugPrint("Usercentrics Change Language Failed on Mobile: $e");
    }
  }

  @override
  Future<void> loginUser(String uid) async {
    _ensureInitialized('loginUser');
    final status = await Usercentrics.restoreUserSession(controllerId: uid);
    _updateConsents(status.consents);
  }

  @override
  Future<void> logoutUser() async {
    _ensureInitialized('logoutUser');
    await Usercentrics.clearUserSession();
    _updateConsents([]); // Clear local consents upon logout
  }

  @override
  Future<void> showPrivacyBanner() async {
    _ensureInitialized('showPrivacyBanner');
    // Show the first layer (banner) and update consents upon completion
    final response = await Usercentrics.showFirstLayer();
    if (response != null) _updateConsents(response.consents);
  }

  @override
  Future<void> showPrivacyManager() async {
    _ensureInitialized('showPrivacyManager');
    // Show the second layer (detailed settings) and update consents upon completion
    final response = await Usercentrics.showSecondLayer();
    if (response != null) _updateConsents(response.consents);
  }

  @override
  Future<void> showPrivacyBannerIfNeeded() async {
    _ensureInitialized('showPrivacyBannerIfNeeded');
    // The native SDK provides a specific flag to check if consent is missing
    final status = await Usercentrics.status;
    if (status.shouldCollectConsent) {
      await showPrivacyBanner();
    }
  }

  // --- Compliance Operations ---

  @override
  Future<void> setConsentStatus(String serviceId, bool status) async {
    _ensureInitialized('setConsentStatus');
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
    _ensureInitialized('getConsentStatus');
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
    _ensureInitialized('requestDataDeletion');
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
    _ensureInitialized('requestDataAccess');
    return (
      success: false,
      dataUrl: null,
      message: 'Full data access request must be handled by backend API.'
    );
  }

  @override
  Future<void> setTrackingEnabled(bool enabled) async {
    // Accept or deny all services based on the input
    _ensureInitialized('setTrackingEnabled');
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

  /// Throws [NotInitializedException] if the manager is not initialized.
  void _ensureInitialized(String methodName) {
    if (!_isInitialized) {
      throw UserscentericsNotInitializedException(methodName: methodName);
    }
  }

  @override
  void dispose() {
    _consentController.close();
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
