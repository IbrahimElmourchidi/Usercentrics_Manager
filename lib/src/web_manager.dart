// File: ./lib/src/web_manager.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:usercentrics_manager/src/exceptions.dart';
import 'package:usercentrics_sdk/usercentrics_sdk.dart';

import 'interface.dart';
import 'models.dart';

class UsercentricsWebManager implements PrivacyManager {
  static final UsercentricsWebManager _instance =
      UsercentricsWebManager._internal();
  factory UsercentricsWebManager() => _instance;
  UsercentricsWebManager._internal();

  bool _isInitialized = false;
  final _consentController =
      StreamController<List<PrivacyServiceConsent>>.broadcast();
  List<PrivacyServiceConsent> _lastKnownConsents = [];

  // Store cleanup callbacks for event listeners
  final List<VoidCallback> _eventListeners = [];

  // Completer to track when UC_UI is ready
  final Completer<void> _readyCompleter = Completer<void>();
  Future<void> get _ready => _readyCompleter.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint(
              'UsercentricsWebManager: CMP script did not load within 20s.');
          if (!_readyCompleter.isCompleted) {
            _readyCompleter
                .complete(); // allow methods to proceed (graceful degrade)
          }
        },
      );

  @override
  bool get isInitialized => _isInitialized;

  @override
  Stream<List<PrivacyServiceConsent>> get consentStream =>
      _consentController.stream.startWith(_lastKnownConsents);

  // --- Core Lifecycle ---
  @override
  Future<void> initialize(
      {required String settingsId,
      String? uid,
      UsercentricsLanguage? defaultLanguage}) async {
    if (_isInitialized) return;
    _injectScript(settingsId, defaultLanguage?.code);
    _setupJsListeners();
    _isInitialized = true;
    if (uid != null) {
      await loginUser(uid);
    }
  }

  void _injectScript(String settingsId, String? languageCode) {
    if (html.document.getElementById('usercentrics-cmp') != null) return;
    final script = html.ScriptElement()
      ..id = 'usercentrics-cmp'
      ..src = 'https://web.cmp.usercentrics.eu/ui/loader.js'
      ..async = true
      ..setAttribute('data-settings-id', settingsId);

    // Apply language if provided
    if (languageCode != null) {
      script.setAttribute('data-language', languageCode);
    }

    html.document.head!.append(script);
    debugPrint('[UC] Usercentrics script injected to DOM.');
  }

  void _setupJsListeners() {
    const jsCode = '''
      function sendConsentsToFlutter() {
        if(window.UC_UI) {
          window.UC_UI.getServicesBaseInfo().then(info => {
            window.dispatchEvent(new CustomEvent('flutterConsent', { detail: JSON.stringify(info) }));
          });
        }
      }

      // Signal that Usercentrics CMP is ready
      function signalReady() {
        window.dispatchEvent(new CustomEvent('usercentricsReady'));
      }

      // Check immediately or wait for UC_UI
      if (window.UC_UI) {
        signalReady();
        sendConsentsToFlutter();
      } else {
        window.addEventListener("UC_UI_READY", () => {
          signalReady();
          sendConsentsToFlutter();
        });
      }

      window.addEventListener("UC_UI_VIEW_CHANGED", sendConsentsToFlutter);
    ''';

    final script = html.ScriptElement()..text = jsCode;
    html.document.head!.append(script);

    // Listen for consent updates
    void onConsentEvent(html.Event event) {
      try {
        final customEvent = event as html.CustomEvent;
        final detail = customEvent.detail as String;
        final list = jsonDecode(detail) as List;
        final consents = list
            .map((e) => PrivacyServiceConsent(
                  templateId: e['id'] ?? '',
                  status: (e['consent']?['status'] as bool?) ?? false,
                  name: e['name'] ?? 'Unknown',
                ))
            .toList();
        _lastKnownConsents = consents;
        _consentController.add(consents);
      } catch (e) {
        debugPrint('[Usercentrics Web] Error parsing consent data: $e');
      }
    }

    html.window.addEventListener('flutterConsent', onConsentEvent);
    _eventListeners.add(() =>
        html.window.removeEventListener('flutterConsent', onConsentEvent));

    // Listen for CMP ready signal
    void onReadyEvent(html.Event _) {
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    }

    html.window.addEventListener('usercentricsReady', onReadyEvent);
    _eventListeners.add(() =>
        html.window.removeEventListener('usercentricsReady', onReadyEvent));
  }

  @override
  Future<void> showPrivacyBannerIfNeeded() async {
    // Web CMP usually shows automatically on load if consents are missing.
    // However, we can enforce it if the list is empty (implying no decision).
    _ensureInitialized('showPrivacyBannerIfNeeded');
    await _ready;
    if (_lastKnownConsents.isEmpty) {
      await _safeExecJs('showFirstLayer');
    }
  }

  @override
  Future<void> loginUser(String uid) async {
    _ensureInitialized('loginUser');
    await _safeExecJs('restoreUserSession', "'$uid'");
  }

  @override
  Future<void> logoutUser() async {
    _ensureInitialized('logoutUser');
    await _safeExecJs('reset');
    _updateConsents([]);
  }

  @override
  Future<void> showPrivacyBanner() async {
    _ensureInitialized('showPrivacyBanner');
    await _safeExecJs('showFirstLayer');
  }

  @override
  Future<void> showPrivacyManager() async {
    _ensureInitialized('showPrivacyManager');
    await _safeExecJs('showSecondLayer');
  }

  // --- Compliance Operations ---
  @override
  Future<void> setConsentStatus(String serviceId, bool status) async {
    _ensureInitialized('setConsentStatus');
    final method = status ? 'acceptService' : 'rejectService';
    await _safeExecJs(method, "'$serviceId'");
    await _triggerJsUpdateSafe();
  }

  @override
  Future<bool> getConsentStatus(String serviceId) async {
    _ensureInitialized('getConsentStatus');
    final service = _lastKnownConsents.firstWhere(
      (s) => s.templateId == serviceId,
      orElse: () =>
          PrivacyServiceConsent(templateId: serviceId, status: false, name: ''),
    );
    return service.status;
  }

  @override
  Future<DataDeletionResult> requestDataDeletion() async {
    _ensureInitialized('requestDataDeletion');
    await logoutUser();
    return (
      success: true,
      message: 'Local session cleared on web via CMP reset.'
    );
  }

  @override
  Future<UserDataPayload> requestDataAccess() async {
    _ensureInitialized('requestDataAccess');
    return (
      success: false,
      dataUrl: null,
      message: 'Full data access request must be handled by backend API.'
    );
  }

  @override
  Future<void> setTrackingEnabled(bool enabled) async {
    _ensureInitialized('setTrackingEnabled');
    final method = enabled ? 'acceptAllServices' : 'denyAllServices';
    await _safeExecJs(method);
    await _triggerJsUpdateSafe();
  }

  @override
  Future<bool> isUserTracked() async {
    return _lastKnownConsents.any((s) => s.status);
  }

  // --- Helpers ---
  Future<void> _safeExecJs(String method, [String args = '']) async {
    await _ready; // Wait until UC_UI is ready or timeout
    _execJs(method, args);
  }

  Future<void> _triggerJsUpdateSafe() async {
    await _ready;
    _execJs(
        'getServicesBaseInfo().then(info => { window.dispatchEvent(new CustomEvent(\'flutterConsent\', { detail: JSON.stringify(info) })); })');
  }

  void _execJs(String method, [String args = '']) {
    final script = html.ScriptElement()
      ..text = "if(window.UC_UI) window.UC_UI.$method($args);";
    html.document.head!.append(script).remove();
  }

  void _updateConsents(List<PrivacyServiceConsent> consents) {
    _lastKnownConsents = consents;
    _consentController.add(consents);
  }

  @override
  Future<void> changeLanguage(UsercentricsLanguage language) async {
    _ensureInitialized('isUserTracked');
    if (!_isInitialized) return;
    await _safeExecJs('changeLanguage', "'${language.code}'");
    // Trigger a manual consent update to fetch translated text and current status
    await _triggerJsUpdateSafe();
  }

  /// Throws [NotInitializedException] if the manager is not initialized.
  void _ensureInitialized(String methodName) {
    if (!_isInitialized) {
      throw UserscentericsNotInitializedException(methodName: methodName);
    }
  }

  // --- Resource cleanup ---
  @override
  void dispose() {
    // Close stream controller
    if (!_consentController.isClosed) {
      _consentController.close();
    }

    // Remove all registered DOM event listeners
    for (final removeListener in _eventListeners) {
      try {
        removeListener();
      } catch (_) {
        // Ignore errors if listener was already removed or window is gone
      }
    }
    _eventListeners.clear();
  }
}

/// Extension to allow streams to emit an initial value.
extension StreamStartWith<T> on Stream<T> {
  Stream<T> startWith(T initialValue) {
    return Stream.value(initialValue).asyncExpand((_) => this);
  }
}

/// Factory function required by lib/src/stub.dart.
PrivacyManager getManagerInstance() => UsercentricsWebManager();
