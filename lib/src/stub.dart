import './interface.dart';
import './unsupported_manager.dart';

// Conditional imports:
// 1. If dart.library.io is available (mobile/desktop), the functions exported
//    by 'mobile_manager.dart' will be used to resolve names in this file.
// 2. Otherwise (e.g., on Web where dart.library.html is available), the functions
//    exported by 'web_manager.dart' will be used.
// 3. If neither is available, the local definitions (like the fallback below) are used.
import './web_manager.dart' if (dart.library.io) 'mobile_manager.dart';

// Note: Because dart.library.io is checked, and web is the implicit default if
// dart.library.io is false, this structure correctly handles the three cases
// (Mobile, Web, Unsupported).

/// Creates the platform-specific instance of [PrivacyManager].
///
/// This function relies on the conditional imports above to dynamically load
/// the correct platform manager implementation via the exported factory function
/// [getManagerInstance].
PrivacyManager createPrivacyManager() {
  // getManagerInstance is resolved at compile time to the correct platform class's factory function.
  return getManagerInstance();
}

// Fallback definition for getManagerInstance.
// If the conditional imports fail or run on an unsupported platform (e.g., pure Dart CLI),
// this fallback is used, returning the safe unsupported stub.
PrivacyManager getManagerInstance() => UsercentricsUnsupportedManager();
