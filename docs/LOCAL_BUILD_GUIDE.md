# Local Build Guide for Sokofiti Android Release

## When to Build Locally

Build locally if:
- ✅ Codemagic builds fail with OutOfMemoryError
- ✅ You need full R8 optimization (smaller APK)
- ✅ You want faster iteration (no CI queue time)
- ✅ You have a machine with 16GB+ RAM

## Prerequisites

### 1. Install Required Tools

```bash
# Flutter SDK (stable channel)
flutter --version

# Java JDK 17
java -version

# Android SDK
# Install via Android Studio or command line tools
```

### 2. Set Up Keystore

You need the release keystore file and credentials:

**Option A: Get from Codemagic**
1. Download keystore from Codemagic environment variables
2. Save as `android/app/release-keystore.jks`

**Option B: Use existing keystore**
```bash
# Place your keystore file
cp /path/to/your/keystore.jks android/app/release-keystore.jks
```

### 3. Create key.properties

Create `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=YOUR_KEY_ALIAS
storeFile=release-keystore.jks
```

**Security:** Add to `.gitignore` (already configured)

### 4. Set Up Google Services

Create `android/app/google-services.json`:

```bash
# Get from Firebase Console or Codemagic
# Project Settings > General > Your apps > Download google-services.json
```

### 5. Set Environment Variables (Optional)

```bash
# Google Maps API Key
export MAPS_API_KEY="your_maps_api_key_here"

# If not set, fallback key from build.gradle will be used
```

## Build Commands

### Clean Build (Recommended)

```bash
# Clean previous builds
flutter clean
cd android && ./gradlew clean && cd ..

# Get dependencies
flutter pub get

# Build release AAB
flutter build appbundle --release
```

### Quick Build (Skip Clean)

```bash
flutter build appbundle --release
```

### Build APK Instead of AAB

```bash
# For direct installation/testing
flutter build apk --release

# For split APKs (smaller size)
flutter build apk --release --split-per-abi
```

## Build Output

### App Bundle (AAB)
```
build/app/outputs/bundle/release/app-release.aab
```

### APK
```
build/app/outputs/flutter-apk/app-release.apk
```

### Split APKs
```
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

## Memory Configuration for Local Builds

### If You Have 16GB+ RAM

Edit `android/gradle.properties`:

```properties
# Use more memory for faster builds
org.gradle.jvmargs=-Xmx16g -Xms4g -Dfile.encoding=UTF-8 -XX:MaxMetaspaceSize=1g -XX:+UseG1GC

# Enable parallel builds
org.gradle.parallel=true

# Enable full R8 optimization
android.enableR8.fullMode=true

# More workers for faster builds
android.r8.maxWorkers=4
```

### If You Have 32GB+ RAM

```properties
# Maximum optimization
org.gradle.jvmargs=-Xmx24g -Xms8g -Dfile.encoding=UTF-8 -XX:MaxMetaspaceSize=2g -XX:+UseG1GC
org.gradle.parallel=true
android.enableR8.fullMode=true
android.r8.maxWorkers=8
```

### Enable Resource Shrinking

Edit `android/app/build.gradle`:

```gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true  // Enable for smaller APK
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

## Troubleshooting

### Build Fails with "Keystore not found"

```bash
# Check keystore exists
ls -la android/app/release-keystore.jks

# Check key.properties
cat android/key.properties
```

### Build Fails with "google-services.json not found"

```bash
# Check file exists
ls -la android/app/google-services.json

# Download from Firebase Console if missing
```

### OutOfMemoryError on Local Build

```bash
# Reduce memory in gradle.properties
org.gradle.jvmargs=-Xmx8g -Xms2g

# Disable resource shrinking
shrinkResources false
```

### Gradle Daemon Issues

```bash
# Stop all Gradle daemons
cd android && ./gradlew --stop

# Clear Gradle cache
rm -rf ~/.gradle/caches/

# Rebuild
cd .. && flutter clean && flutter build appbundle --release
```

## Upload to Play Store

### Using Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Go to **Release > Production**
4. Click **Create new release**
5. Upload `app-release.aab`
6. Fill in release notes
7. Review and rollout

### Using Fastlane (Advanced)

```bash
# Install fastlane
gem install fastlane

# Configure fastlane (one-time setup)
cd android && fastlane init

# Upload to Play Store
fastlane supply --aab build/app/outputs/bundle/release/app-release.aab
```

## Comparison: Local vs Codemagic

| Feature | Local Build | Codemagic |
|---------|-------------|-----------|
| **Memory** | 16GB+ (your machine) | 32GB (mac_pro_m2) |
| **Speed** | Faster (no queue) | Slower (queue + setup) |
| **Optimization** | Full R8 possible | Limited by RAM |
| **APK Size** | Smaller (full optimization) | Larger (reduced optimization) |
| **Setup** | Manual keystore setup | Automated |
| **Security** | Keystore on local machine | Keystore in CI secrets |
| **Cost** | Free | Codemagic pricing |

## Recommended Workflow

### For Development/Testing
```bash
# Build locally for quick iteration
flutter build apk --release --split-per-abi
```

### For Production Release
```bash
# Option 1: Build locally with full optimization
flutter clean
flutter build appbundle --release

# Option 2: Use Codemagic (if memory issue is fixed)
git push origin main
# Wait for Codemagic build
```

## Security Checklist

Before building:
- ✅ `key.properties` is in `.gitignore`
- ✅ `google-services.json` is in `.gitignore`
- ✅ Keystore file is in `.gitignore`
- ✅ Never commit secrets to git
- ✅ Use environment variables for API keys

After building:
- ✅ Test the APK/AAB on real device
- ✅ Verify code obfuscation is enabled
- ✅ Check APK size is reasonable
- ✅ Test all critical features

## Next Steps

1. **Build locally** using this guide
2. **Test thoroughly** on real devices
3. **Upload to Play Store** for internal testing
4. **Promote to production** after testing

---

**Need Help?**
- Check `docs/R8_MEMORY_OPTIMIZATION.md` for memory tuning
- Review `android/app/build.gradle` for build configuration
- See `codemagic.yaml` for CI/CD setup

