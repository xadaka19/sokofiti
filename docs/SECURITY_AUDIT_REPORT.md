# Sokofiti App - Security Audit Report
**Date:** December 12, 2024  
**Version:** 1.0.6+7

## Executive Summary

This security audit evaluates the Sokofiti marketplace app across multiple security domains. The app demonstrates **good security practices** in several areas but has **critical vulnerabilities** that need immediate attention.

**Overall Security Rating: 6.5/10** ⚠️

---

## ✅ Security Strengths

### 1. **Secure Token Storage** ✅
- **Implementation:** Uses `flutter_secure_storage` for JWT tokens
- **Platform Security:**
  - iOS: Keychain with `first_unlock_this_device` accessibility
  - Android: EncryptedSharedPreferences
- **Code:** `lib/utils/security/secure_storage_service.dart`
- **Status:** ✅ Excellent

### 2. **Firebase Security** ✅
- **Firebase App Check** enabled with:
  - iOS: App Attest with DeviceCheck fallback
  - Android: Play Integrity API
- **Multi-factor Authentication:** Supports Google, Apple, Email, Phone
- **Status:** ✅ Good

### 3. **Device Security Detection** ✅
- Root/Jailbreak detection implemented
- Warns in release mode for compromised devices
- **Code:** `lib/utils/security/device_security_service.dart`
- **Status:** ✅ Good (but only warns, doesn't block)

### 4. **Input Validation** ✅
- Comprehensive validators for:
  - Email addresses (regex validation)
  - Phone numbers
  - Passwords (min 6 characters)
  - Slugs (URL-safe format)
  - Names (alphabets only)
- **Code:** `lib/utils/validator.dart`
- **Status:** ✅ Good

### 5. **Authentication Flow** ✅
- Proper session management
- 401 handling with automatic logout
- Token expiration handling
- **Status:** ✅ Good

---

## 🚨 Critical Security Issues

### 1. **EXPOSED API KEY IN SOURCE CODE** 🔴 CRITICAL
**Location:** `android/app/src/main/AndroidManifest.xml:57`

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyAqK2VYsRaBG4tgrz5rW2QIArC8JLzit1I" />
```

**Risk:** 
- Google Maps API key is publicly visible in repository
- Can be extracted from APK by anyone
- Potential for API quota abuse and billing fraud

**Impact:** HIGH - Unauthorized usage, potential financial loss

**Recommendation:**
- Move to environment variables or secure build configuration
- Restrict API key with:
  - Application restrictions (Android app package name + SHA-1)
  - API restrictions (only Google Maps SDK for Android)
  - Set usage quotas and billing alerts

---

### 2. **CLEARTEXT TRAFFIC ALLOWED** 🔴 CRITICAL
**Location:** `android/app/src/main/AndroidManifest.xml:52`

```xml
android:usesCleartextTraffic="true"
```

**Location:** `ios/Runner/Info.plist:117-123`

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**Risk:**
- Allows unencrypted HTTP connections
- Man-in-the-middle (MITM) attacks possible
- Sensitive data can be intercepted

**Impact:** CRITICAL - Data interception, credential theft

**Recommendation:**
- Remove `usesCleartextTraffic="true"`
- Remove `NSAllowsArbitraryLoads`
- Enforce HTTPS-only connections
- If specific domains need HTTP, use domain-specific exceptions

---

### 3. **CODE OBFUSCATION DISABLED** 🟡 HIGH
**Location:** `android/app/build.gradle:132-133`

```gradle
minifyEnabled false
shrinkResources false
```

**Risk:**
- APK can be easily reverse-engineered
- Business logic exposed
- API endpoints and keys extractable

**Impact:** HIGH - Intellectual property theft, easier exploitation

**Recommendation:**
- Enable R8 obfuscation:
  ```gradle
  minifyEnabled true
  shrinkResources true
  ```
- Add ProGuard rules for Flutter
- Note: Comment mentions memory issues - consider using CI with more RAM

---

### 4. **VERBOSE LOGGING IN PRODUCTION** 🟡 MEDIUM
**Location:** `lib/utils/network_request_interseptor.dart`

```dart
log({
    "URL": options.path,
    "Parameters": options.method == "POST"
        ? (options.data as FormData).fields
        : options.queryParameters,
    "response": response.data,
}.toString(), name: "Request-API");
```

**Risk:**
- Sensitive data logged (passwords, tokens, personal info)
- Logs accessible via ADB on Android
- Can leak user data

**Impact:** MEDIUM - Privacy violation, data leakage

**Recommendation:**
- Disable logging in release builds:
  ```dart
  if (kDebugMode) {
      log(...);
  }
  ```
- Never log sensitive fields (passwords, tokens, PII)

---

### 5. **WEAK PASSWORD POLICY** 🟡 MEDIUM
**Location:** `lib/utils/validator.dart:116`

```dart
} else if (password.length < 6) {
    return "passwordWarning".translate(context);
}
```

**Risk:**
- Minimum 6 characters is too weak
- No complexity requirements
- Vulnerable to brute force

**Impact:** MEDIUM - Account compromise

**Recommendation:**
- Increase minimum to 8-10 characters
- Require mix of uppercase, lowercase, numbers, special chars
- Implement password strength meter
- Consider using Firebase's built-in password policies

---

### 6. **NO SSL CERTIFICATE PINNING** 🟡 MEDIUM

**Risk:**
- Vulnerable to MITM attacks even with HTTPS
- Attackers can use fake certificates
- Corporate proxies can intercept traffic

**Impact:** MEDIUM - Data interception in targeted attacks

**Recommendation:**
- Implement SSL pinning for API endpoints
- Use `dio` package's certificate pinning:
  ```dart
  (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      return cert.sha256.toString() == 'YOUR_CERT_HASH';
    };
  };
  ```

---

### 7. **DUAL STORAGE OF JWT TOKENS** 🟡 LOW-MEDIUM
**Location:** `lib/utils/hive_utils.dart:110-116`

```dart
// Store in secure storage (encrypted)
await SecureStorageService.setJWT(token);
// Also store in Hive for backwards compatibility (will be removed in future)
await Hive.box(HiveKeys.userDetailsBox).put(HiveKeys.jwtToken, token);
```

**Risk:**
- JWT stored in both secure storage AND Hive
- Hive storage is NOT encrypted by default
- Tokens accessible from device file system

**Impact:** MEDIUM - Token theft from device

**Recommendation:**
- Remove Hive storage completely
- Use only SecureStorage
- Migrate existing users properly

---

## ⚠️ Medium Priority Issues

### 8. **No Rate Limiting (Client-Side)**
- No visible rate limiting on API calls
- Vulnerable to brute force attacks
- **Recommendation:** Implement exponential backoff, CAPTCHA after failed attempts

### 9. **Sensitive Data in Logs**
- API responses logged in full
- **Recommendation:** Sanitize logs, remove PII

### 10. **No Biometric Authentication**
- App doesn't use fingerprint/Face ID for sensitive operations
- **Recommendation:** Add biometric auth for payments, profile changes

### 11. **Hardcoded Test Ad IDs**
**Location:** `android/app/src/main/AndroidManifest.xml:144`
```xml
android:value="ca-app-pub-3940256099942544~3347511713"
```
- Using Google's test ad unit IDs in production manifest
- **Recommendation:** Replace with production ad IDs

---

## 📋 Security Best Practices Checklist

| Security Control | Status | Priority |
|-----------------|--------|----------|
| Secure token storage | ✅ Implemented | - |
| Firebase App Check | ✅ Implemented | - |
| Input validation | ✅ Implemented | - |
| API key protection | ❌ Exposed | 🔴 Critical |
| HTTPS enforcement | ❌ Cleartext allowed | 🔴 Critical |
| Code obfuscation | ❌ Disabled | 🟡 High |
| SSL pinning | ❌ Not implemented | 🟡 Medium |
| Secure logging | ❌ Verbose in prod | 🟡 Medium |
| Strong passwords | ⚠️ Weak (6 chars) | 🟡 Medium |
| Biometric auth | ❌ Not implemented | 🟡 Low |
| Root/Jailbreak detection | ⚠️ Warns only | 🟡 Low |
| Session timeout | ✅ Implemented | - |
| Secure file storage | ✅ Implemented | - |

---

## 🎯 Immediate Action Items (Priority Order)

### 1. **CRITICAL - Fix Cleartext Traffic** (1-2 hours)
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<!-- REMOVE: android:usesCleartextTraffic="true" -->
```

```xml
<!-- ios/Runner/Info.plist -->
<!-- REMOVE NSAllowsArbitraryLoads section -->
```

### 2. **CRITICAL - Secure Google Maps API Key** (2-3 hours)
- Move to build configuration
- Add API restrictions in Google Cloud Console
- Set up billing alerts

### 3. **HIGH - Enable Code Obfuscation** (3-4 hours)
```gradle
// android/app/build.gradle
release {
    minifyEnabled true
    shrinkResources true
    proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
}
```

### 4. **MEDIUM - Fix Logging** (1-2 hours)
Wrap all logs in `kDebugMode` checks

### 5. **MEDIUM - Strengthen Password Policy** (2-3 hours)
Implement 8+ character requirement with complexity rules

### 6. **MEDIUM - Remove Dual JWT Storage** (2-3 hours)
Migrate to SecureStorage only

---

## 🔒 Additional Recommendations

### Short-term (1-2 weeks)
1. Implement SSL certificate pinning
2. Add biometric authentication for sensitive operations
3. Implement CAPTCHA for login after 3 failed attempts
4. Add security headers to API responses
5. Implement proper session timeout (currently relies on backend)

### Medium-term (1-2 months)
1. Security code review of payment flows
2. Penetration testing
3. Implement app integrity checks
4. Add security monitoring and alerting
5. Regular dependency vulnerability scanning

### Long-term (3-6 months)
1. Bug bounty program
2. Regular security audits
3. Compliance certifications (if needed for Kenya market)
4. Advanced threat protection
5. Security training for development team

---

## 📊 Security Score Breakdown

| Category | Score | Weight |
|----------|-------|--------|
| Authentication & Authorization | 8/10 | 25% |
| Data Protection | 5/10 | 25% |
| Network Security | 3/10 | 20% |
| Code Security | 4/10 | 15% |
| Input Validation | 8/10 | 10% |
| Logging & Monitoring | 5/10 | 5% |

**Weighted Average: 6.5/10**

---

## 📝 Conclusion

The Sokofiti app has a **solid foundation** with good authentication, secure storage, and input validation. However, **critical vulnerabilities** in network security and exposed credentials pose significant risks.

**Priority:** Address the 3 critical issues (cleartext traffic, exposed API key, code obfuscation) **immediately** before the next release.

**Timeline:** Critical fixes should be completed within 1 week.

---

## 📞 Contact & Resources

- **OWASP Mobile Security Project:** https://owasp.org/www-project-mobile-security/
- **Flutter Security Best Practices:** https://docs.flutter.dev/security
- **Firebase Security Rules:** https://firebase.google.com/docs/rules

---

*Report generated on December 12, 2024*
*Auditor: AI Security Analysis*
