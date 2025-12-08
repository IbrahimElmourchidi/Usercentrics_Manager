# Usercentrics Manager

A **unified, cross-platform privacy compliance facade** for Flutter apps targeting **iOS, Android, and Web**, built on top of [Usercentrics CMP](https://usercentrics.com/).

Write **one consent logic** that works everywhere — no platform-specific branching needed.

[![pub package](https://img.shields.io/pub/v/usercentrics_manager.svg)](https://pub.dev/packages/usercentrics_manager)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 📋 Table of Contents

- [Features](#-features)
- [Installation](#-installation)
- [Platform Setup](#-platform-setup)
- [Quick Start](#-quick-start)
- [Detailed Usage](#-detailed-usage)
- [Complete API Reference](#-complete-api-reference)
- [Premium Features](#-premium-features)
- [Advanced Examples](#-advanced-examples)
- [Troubleshooting](#-troubleshooting)
- [About the Author](#-about-the-author)
- [License](#-license)

---

## ✨ Features

- **✅ Unified API**: Single `UsercentricsManager.instance` interface for mobile (via native SDK) and web (via JS injection)
- **✅ Auto Script Injection (Web)**: No manual `<script>` tags — the package injects and configures the Usercentrics CMP automatically
- **✅ Native Performance**: Fully wraps the official `usercentrics_sdk` on mobile for optimal UX
- **✅ Dynamic Localization**: Change the CMP language on the fly using `changeLanguage()` with 50+ supported languages (requires premium account for multi-language dashboard configuration)
- **✅ Reactive Consent Stream**: Listen to real-time consent changes via `consentStream`
- **✅ Cross-Device Sync**: Restore user consent across devices using `loginUser(uid)`
- **✅ Compliance-Ready**: Supports GDPR (Right to Erasure, Right to Access) and CCPA (Do Not Sell)
- **✅ Safe Fallback**: Gracefully degrades on unsupported platforms (e.g., CLI/Dart-only)
- **✅ Exception Handling**: Clear error messages when methods are called before initialization

---

## 🛠️ Installation

### 1. Add the dependency

Add to your `pubspec.yaml`:

```yaml
dependencies:
  usercentrics_manager: ^0.1.1  # Use latest version from pub.dev
```

> ✅ **No need** to manually add `usercentrics_sdk` or `universal_html` — they're included as transitive dependencies.

Then run:

```bash
flutter pub get
```

---

## 🔧 Platform Setup

### 🤖 Android

**Minimum Requirements:**
- `minSdkVersion 21` or higher
- `compileSdkVersion 33` or higher (recommended)

Update `android/app/build.gradle`:

```gradle
android {
  defaultConfig {
    minSdkVersion 21
    compileSdkVersion 33
  }
}
```

**ProGuard Rules** (if using code obfuscation):

Add to `android/app/proguard-rules.pro`:

```proguard
-keep class com.usercentrics.sdk.** { *; }
```

---

### 🍏 iOS

**Minimum Requirements:**
- iOS 11.0 or higher
- Swift 5.0+

Update `ios/Podfile`:

```ruby
platform :ios, '11.0'
```

Then run:

```bash
cd ios && pod install
```

> 📝 **Note**: No `Info.plist` changes are required unless your app accesses camera, location, etc. (handled separately by iOS).

---

### 🌐 Web

**No changes to `web/index.html` needed!**  
The package automatically injects the Usercentrics loader script into `<head>` during `initialize()`.

**Content Security Policy (CSP):**

Ensure your CSP allows scripts from Usercentrics:

```http
Content-Security-Policy: script-src 'self' https://web.cmp.usercentrics.eu;
```

If using a meta tag in `web/index.html`:

```html
<meta http-equiv="Content-Security-Policy" 
      content="script-src 'self' https://web.cmp.usercentrics.eu;">
```

---

## 🚀 Quick Start

### 1. Initialize at App Startup

```dart
import 'package:flutter/material.dart';
import 'package:usercentrics_manager/usercentrics_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await UsercentricsManager.instance.initialize(
      settingsId: 'YOUR_USERCENTRICS_SETTINGS_ID', // From Usercentrics Dashboard
      uid: 'user-123', // Optional: restore cross-device session
      defaultLanguage: UsercentricsLanguage.english, // Optional: set initial language
    );
    
    print('✅ Usercentrics initialized successfully');
  } catch (e) {
    print('❌ Usercentrics initialization failed: $e');
  }

  runApp(const MyApp());
}
```

### 2. Show Consent Banner

```dart
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Privacy Demo')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              // Show banner only if consent is needed
              await UsercentricsManager.instance.showPrivacyBannerIfNeeded();
            },
            child: const Text('Check Privacy Settings'),
          ),
        ),
      ),
    );
  }
}
```

---

## 📖 Detailed Usage

### Listening to Consent Changes

Use `StreamBuilder` to react to consent updates in real-time:

```dart
class ConsentAwareWidget extends StatelessWidget {
  const ConsentAwareWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PrivacyServiceConsent>>(
      stream: UsercentricsManager.instance.consentStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final consents = snapshot.data!;
        
        // Check specific service consent
        final analyticsConsent = consents.firstWhere(
          (c) => c.templateId == 'YOUR_ANALYTICS_TEMPLATE_ID',
          orElse: () => const PrivacyServiceConsent(
            templateId: '',
            status: false,
            name: '',
          ),
        );

        if (analyticsConsent.status) {
          // Initialize analytics
          print('✅ Analytics enabled');
        } else {
          print('❌ Analytics disabled');
        }

        return Column(
          children: [
            Text('Total Services: ${consents.length}'),
            Text('Consented Services: ${consents.where((c) => c.status).length}'),
            ...consents.map((c) => ListTile(
              title: Text(c.name),
              trailing: Icon(
                c.status ? Icons.check_circle : Icons.cancel,
                color: c.status ? Colors.green : Colors.red,
              ),
            )),
          ],
        );
      },
    );
  }
}
```

### Managing User Sessions

```dart
// On user login - restore their consent preferences
Future<void> onUserLogin(String userId) async {
  try {
    await UsercentricsManager.instance.loginUser(userId);
    print('✅ User session restored');
  } catch (e) {
    print('❌ Failed to restore session: $e');
  }
}

// On user logout - clear local consent data
Future<void> onUserLogout() async {
  try {
    await UsercentricsManager.instance.logoutUser();
    print('✅ User session cleared');
  } catch (e) {
    print('❌ Failed to clear session: $e');
  }
}
```

### Dynamic Language Switching

```dart
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  Future<void> _changeLanguage(UsercentricsLanguage language) async {
    try {
      await UsercentricsManager.instance.changeLanguage(language);
      print('✅ Language changed to ${language.code}');
    } catch (e) {
      print('❌ Failed to change language: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<UsercentricsLanguage>(
      items: [
        DropdownMenuItem(
          value: UsercentricsLanguage.english,
          child: Text('English'),
        ),
        DropdownMenuItem(
          value: UsercentricsLanguage.french,
          child: Text('Français'),
        ),
        DropdownMenuItem(
          value: UsercentricsLanguage.german,
          child: Text('Deutsch'),
        ),
        DropdownMenuItem(
          value: UsercentricsLanguage.spanish,
          child: Text('Español'),
        ),
      ],
      onChanged: (language) {
        if (language != null) _changeLanguage(language);
      },
    );
  }
}
```

> ⚠️ **Premium Feature**: Multi-language support requires a premium Usercentrics account. You must first configure and enable additional languages in your Usercentrics Dashboard before calling `changeLanguage()`.

### Programmatic Consent Management

```dart
// Accept specific service
await UsercentricsManager.instance.setConsentStatus(
  'GOOGLE_ANALYTICS_TEMPLATE_ID',
  true, // grant consent
);

// Reject specific service
await UsercentricsManager.instance.setConsentStatus(
  'FACEBOOK_PIXEL_TEMPLATE_ID',
  false, // revoke consent
);

// Accept all services
await UsercentricsManager.instance.setTrackingEnabled(true);

// Reject all services (e.g., "Do Not Sell" toggle)
await UsercentricsManager.instance.setTrackingEnabled(false);

// Check if specific service is consented
bool isAnalyticsEnabled = await UsercentricsManager.instance.getConsentStatus(
  'GOOGLE_ANALYTICS_TEMPLATE_ID',
);

// Check if any tracking is enabled
bool isTracked = await UsercentricsManager.instance.isUserTracked();
```

### GDPR Compliance Operations

```dart
// Right to Erasure (Data Deletion)
Future<void> deleteUserData() async {
  final result = await UsercentricsManager.instance.requestDataDeletion();
  
  if (result.success) {
    print('✅ ${result.message}');
    // Note: This only clears LOCAL consent data
    // You must implement backend deletion separately
  } else {
    print('❌ ${result.message}');
  }
}

// Right to Access (Data Export)
Future<void> exportUserData() async {
  final result = await UsercentricsManager.instance.requestDataAccess();
  
  if (result.success && result.dataUrl != null) {
    // Open the data URL or download the file
    print('✅ Data available at: ${result.dataUrl}');
  } else {
    print('ℹ️ ${result.message}');
    // Typically requires backend implementation
  }
}
```

---

## 📚 Complete API Reference

### Core Methods

| Method | Returns | Description | Premium Required? |
|--------|---------|-------------|-------------------|
| `initialize({required String settingsId, String? uid, UsercentricsLanguage? defaultLanguage})` | `Future<void>` | Initializes the SDK (mobile) or injects script (web). Must be called before any other method. | ❌ No |
| `consentStream` | `Stream<List<PrivacyServiceConsent>>` | Stream that emits the current list of service consents. Updates automatically when consent changes. | ❌ No |
| `isInitialized` | `bool` | Returns `true` if the manager has been successfully initialized. | ❌ No |
| `dispose()` | `void` | Cleans up resources (stream controllers, event listeners). Call when shutting down. | ❌ No |

### UI Display Methods

| Method | Returns | Description | Premium Required? |
|--------|---------|-------------|-------------------|
| `showPrivacyBanner()` | `Future<void>` | Displays the first layer consent banner. | ❌ No |
| `showPrivacyManager()` | `Future<void>` | Displays the second layer detailed privacy settings. | ❌ No |
| `showPrivacyBannerIfNeeded()` | `Future<void>` | Automatically shows the banner only if no consent decision has been made yet. | ❌ No |

### Session Management

| Method | Returns | Description | Premium Required? |
|--------|---------|-------------|-------------------|
| `loginUser(String uid)` | `Future<void>` | Restores a user's consent session across devices using their unique ID. | ⚠️ **Yes** - Cross-device consent sync |
| `logoutUser()` | `Future<void>` | Clears the current user session and local consent data. | ❌ No |

### Consent Operations

| Method | Returns | Description | Premium Required? |
|--------|---------|-------------|-------------------|
| `setConsentStatus(String serviceId, bool status)` | `Future<void>` | Grants (`true`) or revokes (`false`) consent for a specific service by its template ID. | ❌ No |
| `getConsentStatus(String serviceId)` | `Future<bool>` | Returns the current consent status for a specific service template ID. | ❌ No |
| `setTrackingEnabled(bool enabled)` | `Future<void>` | Accepts all services (`true`) or denies all services (`false`). Useful for "Accept All" / "Reject All" buttons. | ❌ No |
| `isUserTracked()` | `Future<bool>` | Returns `true` if any service has been granted consent, `false` if all are denied. | ❌ No |

### Localization

| Method | Returns | Description | Premium Required? |
|--------|---------|-------------|-------------------|
| `changeLanguage(UsercentricsLanguage language)` | `Future<void>` | Dynamically changes the CMP UI language. Supports 50+ languages via the `UsercentricsLanguage` enum. **Note**: Languages must be configured in the Usercentrics Dashboard first. | ⚠️ **Yes** - Multi-language support requires premium |

### GDPR/CCPA Compliance

| Method | Returns | Description | Premium Required? |
|--------|---------|-------------|-------------------|
| `requestDataDeletion()` | `Future<DataDeletionResult>` | Implements the Right to Erasure by clearing **local** consent data. Backend deletion must be handled separately. | ⚠️ **Partial** - Full GDPR suite may require premium |
| `requestDataAccess()` | `Future<UserDataPayload>` | Implements the Right to Access. Returns information about the user's data. **Note**: Full implementation typically requires backend integration. | ⚠️ **Partial** - Full GDPR suite may require premium |

---

## 💎 Premium Features

Some Usercentrics features require a **premium account**. Check with [Usercentrics Sales](https://usercentrics.com/contact/) for details.

### Features Requiring Premium

| Feature | Method | Why Premium? |
|---------|--------|--------------|
| **Cross-Device Consent Sync** | `loginUser(String uid)` | Requires backend infrastructure to store and synchronize consent across multiple devices. |
| **Multi-Language Support** | `changeLanguage(UsercentricsLanguage language)` | Ability to add and configure multiple languages in the Usercentrics Dashboard requires a premium account. Free accounts are limited to one language. |
| **Advanced GDPR Tools** | `requestDataDeletion()`, `requestDataAccess()` | Full GDPR compliance suite with automated data export and deletion workflows. |
| **Custom Branding** | Configuration in Dashboard | White-label CMP with custom colors, fonts, and logos. |
| **A/B Testing** | Configuration in Dashboard | Test different consent banner designs to optimize consent rates. |
| **Advanced Analytics** | Dashboard only | Detailed reports on consent rates, service adoption, and user behavior. |

> 💡 **Tip**: The core consent management functionality (show banner, accept/deny services) works with **free accounts**. Multi-language support and cross-device sync require premium plans.

---

## 🎯 Advanced Examples

### Conditional Feature Initialization

```dart
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  StreamSubscription? _consentSubscription;
  bool _isInitialized = false;

  void initialize() {
    _consentSubscription = UsercentricsManager.instance.consentStream.listen(
      (consents) {
        final analyticsConsent = consents.firstWhere(
          (c) => c.templateId == 'YOUR_ANALYTICS_ID',
          orElse: () => const PrivacyServiceConsent(
            templateId: '',
            status: false,
            name: '',
          ),
        );

        if (analyticsConsent.status && !_isInitialized) {
          _initializeAnalytics();
        } else if (!analyticsConsent.status && _isInitialized) {
          _disableAnalytics();
        }
      },
    );
  }

  void _initializeAnalytics() {
    // Initialize Firebase Analytics, Mixpanel, etc.
    print('📊 Analytics initialized');
    _isInitialized = true;
  }

  void _disableAnalytics() {
    // Disable tracking
    print('📊 Analytics disabled');
    _isInitialized = false;
  }

  void dispose() {
    _consentSubscription?.cancel();
  }
}
```

### Custom Privacy Settings Screen

```dart
class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: StreamBuilder<List<PrivacyServiceConsent>>(
        stream: UsercentricsManager.instance.consentStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final consents = snapshot.data!;

          return ListView(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Your Privacy',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Control how your data is used',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              // Quick Actions
              ListTile(
                leading: const Icon(Icons.done_all),
                title: const Text('Accept All'),
                onTap: () async {
                  await UsercentricsManager.instance.setTrackingEnabled(true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All services enabled')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Reject All'),
                onTap: () async {
                  await UsercentricsManager.instance.setTrackingEnabled(false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All services disabled')),
                    );
                  }
                },
              ),

              const Divider(),

              // Individual Service Controls
              ...consents.map((consent) => SwitchListTile(
                title: Text(consent.name),
                subtitle: Text('ID: ${consent.templateId}'),
                value: consent.status,
                onChanged: (value) async {
                  await UsercentricsManager.instance.setConsentStatus(
                    consent.templateId,
                    value,
                  );
                },
              )),

              const Divider(),

              // Additional Actions
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Show Full Privacy Manager'),
                onTap: () async {
                  await UsercentricsManager.instance.showPrivacyManager();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text('Delete My Data'),
                onTap: () async {
                  final result = await UsercentricsManager.instance.requestDataDeletion();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result.message)),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
```

### Error Handling

```dart
Future<void> safeInitialize() async {
  try {
    if (UsercentricsManager.instance.isInitialized) {
      print('ℹ️ Already initialized');
      return;
    }

    await UsercentricsManager.instance.initialize(
      settingsId: 'YOUR_SETTINGS_ID',
    );
    
    print('✅ Initialization successful');
  } on UserscentericsNotInitializedException catch (e) {
    print('❌ Initialization error: $e');
  } catch (e) {
    print('❌ Unexpected error: $e');
  }
}

Future<void> safeConsentOperation() async {
  try {
    await UsercentricsManager.instance.setConsentStatus(
      'ANALYTICS_ID',
      true,
    );
  } on UserscentericsNotInitializedException catch (e) {
    print('❌ Not initialized: ${e.methodName}');
    print('💡 Call initialize() first');
  } catch (e) {
    print('❌ Operation failed: $e');
  }
}
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. **"Method called before initialize()"**

**Error**: `UserscentericsNotInitializedException`

**Solution**: Ensure you call `initialize()` in `main()` before `runApp()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UsercentricsManager.instance.initialize(settingsId: 'YOUR_ID');
  runApp(const MyApp());
}
```

#### 2. **Web: Banner not showing**

**Possible Causes**:
- CSP blocking the script
- Settings ID incorrect
- Network connectivity issues

**Solution**:
1. Check browser console for CSP errors
2. Verify Settings ID in Usercentrics Dashboard
3. Ensure `https://web.cmp.usercentrics.eu` is whitelisted in CSP

#### 3. **Mobile: Gradle build fails**

**Error**: "Execution failed for task ':app:checkDebugAarMetadata'"

**Solution**: Update `minSdkVersion` to 21 in `android/app/build.gradle`

#### 4. **iOS: Pod install fails**

**Solution**:
```bash
cd ios
rm -rf Pods Podfile.lock
pod repo update
pod install
```

#### 5. **Consent not persisting**

**Cause**: User logged out or cleared app data

**Solution**: Use `loginUser(uid)` to restore cross-device consent when user logs in

---

## 🌍 Supported Languages

The package supports **50+ languages** via the `UsercentricsLanguage` enum:

**European Languages**: English, German, French, Spanish, Italian, Portuguese, Dutch, Polish, Romanian, Swedish, Danish, Finnish, Norwegian, Czech, Hungarian, Greek, Croatian, Bulgarian, Slovak, Slovenian, Serbian, Ukrainian, Russian, Turkish

**Asian Languages**: Arabic, Hebrew, Hindi, Japanese, Korean, Chinese (Simplified, Traditional, Cantonese), Thai, Vietnamese, Indonesian, Malay, Urdu, Persian (Farsi), Armenian, Georgian, Kazakh, Azerbaijani, Mongolian, Uzbek

**African Languages**: Afrikaans

**Other**: Welsh, Catalan, Galician, Icelandic, Albanian, Bosnian, Macedonian, Belarusian, Estonian, Latvian, Lithuanian

---

## 🔒 Privacy & Security

- **No Data Collection**: This package does not collect or transmit any data beyond what Usercentrics SDK requires for consent management
- **Local Storage**: Consent decisions are stored locally on the device
- **Encryption**: Usercentrics SDK uses industry-standard encryption for data transmission
- **GDPR Compliant**: Fully compliant with GDPR, CCPA, and other privacy regulations

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
<a href="https://www.linkedin.com/in/IbrahimElmourchidi">
<img src="https://img.shields.io/badge/LinkedIn-Profile-blue?style=flat&logo=linkedin" alt="LinkedIn Profile">
</a>
</p>
</div>

- 🔹 Top-rated Flutter freelancer (100% Job Success on [Upwork](https://www.upwork.com/freelancers/~0105391a1bbefa5522))
- 🔹 Built 20+ production apps with real-time & payment features
- 🔹 Passionate about clean architecture, compliance, and UX

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">
Made with ❤️ by Ibrahim El Mourchidi
<br>
<sub>If this package helped you, consider giving it a ⭐ on GitHub!</sub>
</div>