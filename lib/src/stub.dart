// ./lib/src/stub.dart

// Import the unsupported fallback unconditionally (safe everywhere)
import 'package:usercentrics_manager/usercentrics_manager.dart';

// Conditional imports: web first, then mobile, then fallback
import './unsupported_manager.dart'
    if (dart.library.html) './web_manager.dart'
    if (dart.library.io) './mobile_manager.dart';

/// Factory that returns the correct platform-specific PrivacyManager.
PrivacyManager createPrivacyManager() {
  return getManagerInstance();
}
