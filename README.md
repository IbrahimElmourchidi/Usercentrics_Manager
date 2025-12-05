# Usercentrics Manager

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?logo=flutter&logoColor=white)
![Pub Version](https://img.shields.io/pub/v/usercentrics_manager?color=blue)
![License](https://img.shields.io/badge/license-MIT-blue)

A **unified, cross-platform privacy compliance facade** for Flutter apps targeting **iOS, Android, and Web**, built on top of [Usercentrics CMP](https://usercentrics.com/).

Write **one consent logic** that works everywhere — no platform-specific branching needed.

---

## ✨ Features

- **✅ Unified API**: Single `PrivacyManager` interface for mobile (via native SDK) and web (via JS injection).
- **✅ Auto Script Injection (Web)**: No manual `<script>` tags — the package injects and configures the Usercentrics CMP automatically.
- **✅ Native Performance**: Fully wraps the official `usercentrics_sdk` on mobile for optimal UX.
- **✅ Reactive Consent Stream**: Listen to real-time consent changes via `consentStream`.
- **✅ Cross-Device Sync**: Restore user consent across devices using `loginUser(uid)`.
- **✅ Compliance-Ready**: Supports GDPR (Right to Erasure, Right to Access) and CCPA (Do Not Sell).
- **✅ Safe Fallback**: Gracefully degrades on unsupported platforms (e.g., CLI/Dart-only).

---

## 🛠️ Installation

### 1. Add the dependency

Add to your `pubspec.yaml`:

```yaml
dependencies:
  usercentrics_manager: ^0.1.0  # Use latest version from pub.dev
```

> ✅ **No need** to manually add `usercentrics_sdk` or `universal_html` — they’re included as transitive dependencies.

Then run:
```bash
flutter pub get
```

---

### 2. Platform Setup

#### 🤖 Android (`android/app/build.gradle`)
Ensure `minSdkVersion` is **21 or higher**:

```gradle
android {
  defaultConfig {
    minSdkVersion 21
  }
}
```

#### 🍏 iOS (`ios/Podfile`)
Set platform to **iOS 11.0+**:

```ruby
platform :ios, '11.0'
```

> No `Info.plist` changes are required unless your app accesses camera, location, etc. (handled separately).

#### 🌐 Web
**No changes to `web/index.html` needed!**  
The package automatically injects the Usercentrics loader script into `<head>` on `initialize()`.

> ⚠️ **Important for Web**: Your Content Security Policy (CSP) must allow scripts from `https://web.cmp.usercentrics.eu`:
> ```http
> Content-Security-Policy: script-src 'self' https://web.cmp.usercentrics.eu;
> ```

---

## 🚀 Usage

### 1. Initialize at App Startup

```dart
import 'package:usercentrics_manager/usercentrics_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final manager = UsercentricsManager();
  await manager.initialize(
    settingsId: 'YOUR_USERCENTRICS_SETTINGS_ID', // From Usercentrics Dashboard
    uid: 'user-123', // Optional: restore cross-device session
  );

  runApp(const MyApp());
}
```

---

### 2. React to Consent Changes

Use `StreamBuilder` to dynamically enable/disable tracking:

```dart
StreamBuilder<List<PrivacyServiceConsent>>(
  stream: UsercentricsManager().consentStream,
  builder: (context, snapshot) {
    final consents = snapshot.data ?? [];
    final analyticsAllowed = consents.any(
      (c) => c.templateId == 'GOOGLE_ANALYTICS_ID' && c.status,
    );

    if (analyticsAllowed) {
      // Initialize Firebase Analytics, Mixpanel, etc.
    }

    return Text('Analytics: ${analyticsAllowed ? '✅' : '❌'}');
  },
);
```

---

### 3. User Session Management

```dart
// On user login
await UsercentricsManager().loginUser('user-123');

// On logout
await UsercentricsManager().logoutUser(); // Clears local consent
```

---

### 4. Show Consent UI

```dart
// Show initial banner (First Layer)
await UsercentricsManager().showPrivacyBanner();

// Show detailed settings (Second Layer)
await UsercentricsManager().showPrivacyManager();
```

---

### 5. Programmatic Consent Control

```dart
// Accept a specific service
await UsercentricsManager().setConsentStatus('GOOGLE_ANALYTICS_ID', true);

// Deny all tracking (e.g., for "Do Not Sell" toggle)
await UsercentricsManager().setTrackingEnabled(false);
```

---

## 📚 Full API Reference

| Method | Description |
|--------|-------------|
| `initialize({required String settingsId, String? uid})` | Initializes SDK (mobile) or injects script (web). |
| `loginUser(String uid)` | Restores cross-device consent session. |
| `logoutUser()` | Clears local consent data and session. |
| `showPrivacyBanner()` | Opens the first-layer consent banner. |
| `showPrivacyManager()` | Opens the second-layer privacy settings. |
| `setConsentStatus(String serviceId, bool status)` | Grants or revokes consent for a specific service. |
| `getConsentStatus(String serviceId)` | Returns current consent status for a service. |
| `setTrackingEnabled(bool enabled)` | Accepts all (`true`) or denies all (`false`) services. |
| `isUserTracked()` | Returns `true` if any tracking service is consented. |
| `requestDataDeletion()` | Clears **local** consent data (Right to Erasure). |
| `requestDataAccess()` | Returns info (usually requires backend implementation). |
| `consentStream` → `Stream<List<PrivacyServiceConsent>>` | Emits updated consent list on every change. |
| `isInitialized` → `bool` | `true` after successful initialization. |

> 📝 All methods are **no-op safe** on unsupported platforms.

---

## 🤝 About the Author

<div align="center">
  <a href="https://github.com/IbrahimElmourchidi">
    <img src="https://github.com/IbrahimElmourchidi.png" width="80" alt="Ibrahim El Mourchidi" style="border-radius: 50%;">
  </a>
  <h3>Ibrahim El Mourchidi</h3>
  <p>Flutter & Firebase Developer • Cairo, Egypt</p>
  <p>
    <a href="https://github.com/IbrahimElmourchidi">
      <img src="https://img.shields.io/github/followers/IbrahimElmourchidi?label=Follow&style=social" alt="GitHub Follow">
    </a>
    <a href="mailto:ibrahimelmourchidi@gmail.com">
      <img src="https://img.shields.io/badge/Email-D14836?logo=gmail&logoColor=white" alt="Email">
    </a>
  </p>
</div>

- 🔹 Top-rated Flutter freelancer (100% Job Success on Upwork)
- 🔹 Built 10+ production apps with real-time & payment features
- 🔹 Passionate about clean architecture, compliance, and UX

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.
```

You can copy this entire block into a file named `README.txt`, or rename it to `README.md` to use it directly in your GitHub repository.

Would you like me to generate a **`LICENSE`** file or help you **publish this package to pub.dev** next?