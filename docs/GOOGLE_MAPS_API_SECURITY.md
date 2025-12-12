# Google Maps API Key Security Setup

## 🔐 Current Status

The Google Maps API key has been moved from hardcoded in AndroidManifest.xml to environment variables for better security.

**API Key:** `AIzaSyAqK2VYsRaBG4tgrz5rW2QIArC8JLzit1I`

## ⚠️ CRITICAL: Add API Restrictions in Google Cloud Console

### Step 1: Access Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (likely "eclassify-wrteam" or similar)
3. Navigate to: **APIs & Services** → **Credentials**
4. Find the API key: `AIzaSyAqK2VYsRaBG4tgrz5rW2QIArC8JLzit1I`

### Step 2: Add Application Restrictions

Click on the API key and configure:

#### **Application restrictions:**
- Select: **Android apps**
- Click **Add an item**
- Add the following:
  - **Package name:** `com.sokofiti.app`
  - **SHA-1 certificate fingerprint:** (Get from your keystore - see below)

#### Get SHA-1 Fingerprint:

**For Debug:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**For Release (your keystore):**
```bash
keytool -list -v -keystore android/app/release-keystore.jks -alias sokofiti -storepass Djabari2019# -keypass Djabari2019#
```

Look for the line starting with `SHA1:` and copy the fingerprint (format: `AA:BB:CC:DD:...`)

### Step 3: Add API Restrictions

In the same API key settings:

#### **API restrictions:**
- Select: **Restrict key**
- Select only the APIs you need:
  - ✅ Maps SDK for Android
  - ✅ Places API (if using autocomplete)
  - ✅ Geocoding API (if using address lookup)
  - ✅ Directions API (if using navigation)

**Remove access to all other APIs**

### Step 4: Set Up Billing Alerts

1. Go to **Billing** → **Budgets & alerts**
2. Create a new budget:
   - **Name:** "Google Maps API Alert"
   - **Budget amount:** $100/month (adjust based on expected usage)
   - **Alert thresholds:** 50%, 90%, 100%
   - **Add email notifications**

### Step 5: Monitor Usage

1. Go to **APIs & Services** → **Dashboard**
2. Click on **Maps SDK for Android**
3. Monitor daily usage
4. Set up quotas if needed:
   - Go to **Quotas**
   - Set daily request limits (e.g., 10,000 requests/day)

---

## 🔧 Local Development Setup

### For Local Builds:

**Option 1: Set environment variable (Recommended)**
```bash
# Add to your ~/.bashrc or ~/.zshrc
export MAPS_API_KEY="AIzaSyAqK2VYsRaBG4tgrz5rW2QIArC8JLzit1I"

# Or set temporarily
export MAPS_API_KEY="AIzaSyAqK2VYsRaBG4tgrz5rW2QIArC8JLzit1I"
flutter build apk --release
```

**Option 2: Use fallback (Current setup)**
The build.gradle already has a fallback, so local builds will work without setting the env variable.

---

## 🚀 Codemagic CI/CD Setup

### Add Environment Variable in Codemagic:

1. Go to your Codemagic app settings
2. Navigate to **Environment variables**
3. Add new variable:
   - **Name:** `MAPS_API_KEY`
   - **Value:** `AIzaSyAqK2VYsRaBG4tgrz5rW2QIArC8JLzit1I`
   - **Group:** (Optional) Create a group like "API Keys"
   - **Secure:** ✅ Check this box

4. Make sure it's available for your workflow

---

## 📱 iOS Setup (If Needed)

If you're also using Google Maps on iOS, you'll need to:

1. Add the API key to `ios/Runner/AppDelegate.swift`:
   ```swift
   GMSServices.provideAPIKey(ProcessInfo.processInfo.environment["MAPS_API_KEY"] ?? "YOUR_FALLBACK_KEY")
   ```

2. Update `ios/Runner/Info.plist` if needed

3. Add iOS app restrictions in Google Cloud Console:
   - **Bundle ID:** `com.sokofiti.app` (or your iOS bundle ID)

---

## ✅ Verification Checklist

After setting up restrictions:

- [ ] API key has application restrictions (Android package + SHA-1)
- [ ] API key has API restrictions (only Maps SDK for Android)
- [ ] Billing alerts are set up
- [ ] Environment variable `MAPS_API_KEY` is set in Codemagic
- [ ] Local builds work with environment variable
- [ ] Release build works on Codemagic
- [ ] Maps functionality works in the app
- [ ] No unauthorized usage alerts

---

## 🔍 Troubleshooting

### Maps not loading in app:

1. **Check SHA-1 fingerprint matches:**
   - The SHA-1 in Google Cloud Console must match your signing keystore
   - Debug and release builds use different keystores

2. **Check package name:**
   - Must be exactly `com.sokofiti.app`

3. **Check API is enabled:**
   - Maps SDK for Android must be enabled in Google Cloud Console

4. **Check billing:**
   - Billing must be enabled for the project

### Build fails with "MAPS_API_KEY not found":

- Make sure environment variable is set
- The fallback in build.gradle should prevent this

---

## 📊 Cost Estimation

Google Maps pricing (as of 2024):
- **Maps SDK for Android:** $7 per 1,000 loads
- **Free tier:** $200/month credit (≈28,500 map loads)

**Typical usage for marketplace app:**
- Average user opens map 2-3 times per session
- With 1,000 daily active users: ~2,500 map loads/day
- Monthly: ~75,000 loads = ~$325/month (after free credit)

**Recommendation:** Monitor usage closely in first month to adjust budget alerts.

---

*Last updated: December 12, 2024*

