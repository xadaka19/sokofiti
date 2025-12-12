# Codemagic Environment Variables Setup Guide

## 📋 Required Environment Variables

You need to add the following environment variables in your Codemagic project settings:

### 1. **MAPS_API_KEY** (NEW - Required)

**Value:** `AIzaSyAqK2VYsRaBG4tgrz5rW2QIArC8JLzit1I`

**How to add:**
1. Go to Codemagic → Your Project → Settings
2. Click on "Environment variables"
3. Click "Add variable"
4. Name: `MAPS_API_KEY`
5. Value: `AIzaSyAqK2VYsRaBG4tgrz5rW2QIArC8JLzit1I`
6. Group: Select your build configuration group
7. ✅ Check "Secure" (recommended but not required for API keys with restrictions)
8. Click "Add"

**Important:** This is your Google Maps API key. Make sure to:
- Add API restrictions in Google Cloud Console (see below)
- Add application restrictions (Android/iOS package names)
- Set up billing alerts

---

### 2. **CM_KEYSTORE** (Existing)

**Status:** ✅ Already configured  
**Purpose:** Base64-encoded Android release keystore  
**Used in:** Pre-build script to decode keystore file

---

### 3. **GOOGLE_SERVICES_JSON** (Existing)

**Status:** ✅ Already configured  
**Purpose:** Base64-encoded Firebase configuration  
**Used in:** Pre-build script to decode google-services.json

---

## 🔧 Pre-Build Script (Current - No Changes Needed)

Your current pre-build script is **correct** and doesn't need modification:

```bash
#!/bin/sh
set -e
set -x

# Path to where the keystore will be placed
KEYSTORE_PATH="$CM_BUILD_DIR/android/app/release-keystore.jks"

# Decode the keystore from environment variable
echo "$CM_KEYSTORE" | base64 --decode > "$KEYSTORE_PATH"

# Verify it exists and has content
if [ ! -f "$KEYSTORE_PATH" ] || [ ! -s "$KEYSTORE_PATH" ]; then
  echo "❌ Release keystore missing or empty. Aborting build."
  exit 1
fi

echo "✅ Release keystore found at: $KEYSTORE_PATH"
ls -l "$KEYSTORE_PATH"

# Decode google-services.json
GOOGLE_SERVICES_PATH="$CM_BUILD_DIR/android/app/google-services.json"

echo "🔹 Decoding google-services.json from base64..."
echo "$GOOGLE_SERVICES_JSON" | base64 --decode > "$GOOGLE_SERVICES_PATH"

# Verify it exists and has content
if [ ! -f "$GOOGLE_SERVICES_PATH" ] || [ ! -s "$GOOGLE_SERVICES_PATH" ]; then
  echo "❌ google-services.json missing or empty. Aborting build."
  exit 1
fi

echo "✅ google-services.json created successfully at: $GOOGLE_SERVICES_PATH"
ls -l "$GOOGLE_SERVICES_PATH"
```

**Why no changes needed:**
- The `MAPS_API_KEY` is already handled in `codemagic.yaml` (lines 77-85)
- The pre-build script runs before the main build
- The environment variable is automatically available to Gradle during the build phase
- The `codemagic.yaml` exports it explicitly for clarity

---

## 🔐 Google Cloud Console - API Key Security

### Restrict Your Google Maps API Key

**⚠️ IMPORTANT:** Your API key is currently unrestricted. Follow these steps:

1. **Go to Google Cloud Console:**
   - Visit: https://console.cloud.google.com/apis/credentials
   - Select your project

2. **Find your API key:**
   - Look for: `AIzaSyAqK2VYsRaBG4tgrz5rW2QIArC8JLzit1I`
   - Click on it to edit

3. **Add Application Restrictions:**
   - Select "Android apps"
   - Click "Add an item"
   - Package name: `com.sokofiti.app`
   - SHA-1 certificate fingerprint: (Get from your release keystore)
   
   To get SHA-1 fingerprint:
   ```bash
   keytool -list -v -keystore release-keystore.jks -alias upload
   ```

4. **Add API Restrictions:**
   - Select "Restrict key"
   - Check these APIs:
     - ✅ Maps SDK for Android
     - ✅ Maps SDK for iOS (if using iOS)
     - ✅ Places API (if using places)
     - ✅ Geocoding API (if using geocoding)

5. **Set Up Billing Alerts:**
   - Go to Billing → Budgets & alerts
   - Create alert at $50, $100, $200

6. **Save changes**

---

## ✅ Verification Checklist

Before triggering a build in Codemagic:

- [ ] `MAPS_API_KEY` environment variable added in Codemagic
- [ ] `CM_KEYSTORE` environment variable exists (already configured)
- [ ] `GOOGLE_SERVICES_JSON` environment variable exists (already configured)
- [ ] Pre-build script is configured in Codemagic UI
- [ ] Google Maps API key has application restrictions
- [ ] Google Maps API key has API restrictions
- [ ] Billing alerts are set up

---

## 🚀 Build Process Flow

1. **Pre-build script runs:**
   - Decodes `CM_KEYSTORE` → `release-keystore.jks`
   - Decodes `GOOGLE_SERVICES_JSON` → `google-services.json`

2. **Codemagic.yaml scripts run:**
   - Exports `MAPS_API_KEY` environment variable
   - Runs Gradle build

3. **Gradle build:**
   - Reads `MAPS_API_KEY` from environment
   - Injects into AndroidManifest.xml via `manifestPlaceholders`
   - Builds APK/AAB with the API key

---

## 🐛 Troubleshooting

### Build fails with "MAPS_API_KEY not found"
- Check that the environment variable is added in Codemagic
- Verify it's in the correct group (same as your build configuration)
- Check the build logs for the export script output

### Maps not loading in the app
- Verify API key restrictions in Google Cloud Console
- Check that package name matches: `com.sokofiti.app`
- Verify SHA-1 fingerprint is correct
- Check that Maps SDK for Android is enabled

### "API key not valid" error
- Ensure API restrictions include Maps SDK for Android
- Verify application restrictions include your package name
- Wait 5-10 minutes after making changes (propagation time)

---

## 📞 Support

If you encounter issues:
1. Check Codemagic build logs
2. Verify environment variables are set
3. Check Google Cloud Console for API key status
4. Review the security implementation summary in `docs/SECURITY_IMPLEMENTATION_SUMMARY.md`

