import 'dart:async';
import 'package:flutter/foundation.dart';

import 'interface.dart';
import 'models.dart';

/// Placeholder implementation of [PrivacyManager] for unsupported platforms.
///
/// This class prevents build errors on platforms where dart.library.io and
/// dart.library.html are both false, ensuring the application can still compile
/// and run, albeit with non-functional privacy controls.
class UsercentricsUnsupportedManager implements PrivacyManager {
  @override
  Stream<List<PrivacyServiceConsent>> get consentStream => Stream.value([]);

  @override
  bool get isInitialized => false;

  @override
  Future<void> initialize(
      {required String settingsId,
      String? uid,
      UsercentricsLanguage? defaultLanguage}) async {
    // Log a warning that a stub is being used on an unsupported platform
    debugPrint(
        'UsercentricsManager: Using unsupported stub. No consent management available.');
  }

  @override
  Future<void> loginUser(String uid) async {}

  @override
  Future<void> logoutUser() async {}

  @override
  Future<void> showPrivacyBanner() async {}

  @override
  Future<void> showPrivacyManager() async {}

  @override
  Future<void> showPrivacyBannerIfNeeded() async {}

  @override
  Future<void> setConsentStatus(String serviceId, bool status) async {}

  @override
  Future<bool> getConsentStatus(String serviceId) async => false;

  @override
  Future<DataDeletionResult> requestDataDeletion() async => (
        success: false,
        message: 'Platform not supported. Data deletion failed.'
      );

  @override
  Future<UserDataPayload> requestDataAccess() async => (
        success: false,
        dataUrl: null,
        message: 'Platform not supported. Data access failed.'
      );

  @override
  Future<void> setTrackingEnabled(bool enabled) async {}

  @override
  Future<bool> isUserTracked() async => false;

  @override
  Future<void> changeLanguage(UsercentricsLanguage language) async {}

  @override
  void dispose() {}
}

/// Factory function required by lib/src/factory.dart.
/// This function is conditionally loaded when no other platform is detected.
PrivacyManager getManagerInstance() => UsercentricsUnsupportedManager();
