# Security Fixes Checklist - Sokofiti

## 🔴 CRITICAL (Fix Immediately - Within 24-48 hours)

### [x] 1. Remove Cleartext Traffic Permission ✅
**Files to modify:**
- `android/app/src/main/AndroidManifest.xml` - Remove line 52: `android:usesCleartextTraffic="true"`
- `ios/Runner/Info.plist` - Remove lines 117-123 (NSAppTransportSecurity section)

**Testing:**
```bash
# Test that app still works with HTTPS only
flutter run --release
# Verify all API calls use HTTPS
```

---

### [x] 2. Secure Google Maps API Key ✅
**Current issue:** API key exposed in `android/app/src/main/AndroidManifest.xml:57`

**Steps:**
1. Go to Google Cloud Console → APIs & Services → Credentials
2. Find API key: `AIzaSyAqK2VYsRaBG4tgrz5rW2QIArC8JLzit1I`
3. Add restrictions:
   - **Application restrictions:** Android apps
   - Add package name: `com.sokofiti.app`
   - Add SHA-1 certificate fingerprint
4. **API restrictions:** Restrict to Maps SDK for Android
5. Set up billing alerts (e.g., alert at $50, $100)

**Alternative (Better):** Move to build configuration
```gradle
// android/app/build.gradle
android {
    defaultConfig {
        manifestPlaceholders = [MAPS_API_KEY: System.getenv("MAPS_API_KEY") ?: ""]
    }
}
```

```xml
<!-- AndroidManifest.xml -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${MAPS_API_KEY}" />
```

---

### [x] 3. Enable Code Obfuscation ✅
**File:** `android/app/build.gradle`

**Change lines 132-133:**
```gradle
release {
    signingConfig signingConfigs.release
    minifyEnabled true
    shrinkResources true
    proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
}
```

**Create:** `android/app/proguard-rules.pro`
```proguard
# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
```

**Note:** May need to increase Codemagic instance RAM or use local build

---

## 🟡 HIGH PRIORITY (Fix Within 1 Week)

### [x] 4. Disable Verbose Logging in Production ✅
**File:** `lib/utils/network_request_interseptor.dart`

**Wrap all log statements:**
```dart
import 'package:flutter/foundation.dart';

@override
void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
  if (kDebugMode) {
    totalAPICallTimes++;
    log({...}.toString(), name: "Request-API");
  }
  handler.next(options);
}

@override
void onResponse(Response response, ResponseInterceptorHandler handler) {
  if (kDebugMode) {
    log({...}.toString(), name: "Response-API");
  }
  handler.next(response);
}

@override
void onError(DioException err, ErrorInterceptorHandler handler) {
  if (kDebugMode) {
    log({...}.toString(), name: "API-Error");
  }
  handler.next(err);
}
```

---

### [ ] 5. Strengthen Password Policy
**File:** `lib/utils/validator.dart`

**Update validatePassword function (line 109):**
```dart
static String? validatePassword(
  String? password, {
  String? secondFieldValue,
  required BuildContext context,
}) {
  if (password!.isEmpty) {
    return "fieldMustNotBeEmpty".translate(context);
  } else if (password.length < 8) {
    return "Password must be at least 8 characters".translate(context);
  }
  
  // Check for complexity
  bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
  bool hasLowercase = password.contains(RegExp(r'[a-z]'));
  bool hasDigits = password.contains(RegExp(r'[0-9]'));
  
  if (!hasUppercase || !hasLowercase || !hasDigits) {
    return "Password must contain uppercase, lowercase, and numbers".translate(context);
  }
  
  if (secondFieldValue != null) {
    if (password != secondFieldValue) {
      return "fieldSameWarning".translate(context);
    }
  }
  
  return null;
}
```

---

### [x] 6. Remove Dual JWT Storage ✅
**File:** `lib/utils/hive_utils.dart`

**Update setJWT (line 110):**
```dart
static Future<void> setJWT(String token) async {
  // Store in secure storage (encrypted) ONLY
  await SecureStorageService.setJWT(token);
  // Update cache
  _cachedJWT = token;
  // REMOVED: Hive storage for security
}
```

**Migration:** Add one-time migration in app startup to move existing tokens

---

## 🟢 MEDIUM PRIORITY (Fix Within 2-4 Weeks)

### [x] 7. Replace Test Ad IDs ✅
**File:** `android/app/src/main/AndroidManifest.xml:144`

Replace test ID with production AdMob ID from Google AdMob console

---

### [x] 8. Implement SSL Certificate Pinning ✅
**File:** `lib/utils/api.dart`

Add certificate pinning to Dio client

---

### [ ] 9. Add Biometric Authentication
Add local_auth package for fingerprint/Face ID on sensitive operations

---

### [x] 10. Strengthen Root/Jailbreak Detection ✅
**File:** `lib/app/app.dart:62-66`

Change from warning to blocking in production:
```dart
final isCompromised = await DeviceSecurityService.isDeviceCompromised();
if (isCompromised && kReleaseMode) {
  // Show error dialog and exit app
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text('This app cannot run on rooted/jailbroken devices'),
      ),
    ),
  );
}
```

---

## Testing Checklist

After each fix:
- [ ] Test on Android device
- [ ] Test on iOS device  
- [ ] Verify API calls still work
- [ ] Check app doesn't crash
- [ ] Test authentication flow
- [ ] Test payment flow
- [ ] Run `flutter analyze`
- [ ] Build release APK/AAB successfully

---

## Deployment Checklist

Before releasing:
- [ ] All critical fixes completed
- [ ] Code reviewed by team
- [ ] Tested on multiple devices
- [ ] Updated version number
- [ ] Updated changelog
- [ ] Security scan passed
- [ ] Staged rollout (10% → 50% → 100%)

---

*Last updated: December 12, 2024*

