# Safaricom Phone Number Validation - Testing Guide

## ✅ Implementation Complete

Safaricom-only phone number validation has been implemented across the entire app.

---

## 🔍 What Was Implemented

### **Validation Logic** (`lib/utils/validator.dart`)

1. **Accepts both formats:**
   - With country code: `+254712345678`, `254712345678`
   - Without country code: `0712345678`
   - With spaces/dashes: `0712 345 678`, `+254-712-345-678`

2. **Valid Safaricom Prefixes:**
   - `0700-0709` (old format)
   - `0710-0719` (old format)
   - `0720-0729` (old format)
   - `0740-0749` (newer)
   - `0757-0759` (newer)
   - `0768-0769` (newer)
   - `0790-0799` (newer)

3. **Error Messages:**
   - Not 10 digits: `"Please enter a valid 10-digit Safaricom number"`
   - Not Safaricom: `"Only Safaricom numbers are allowed (07XX)"`

### **Where Validation is Applied:**

✅ **User Registration** (`signup_main_screen.dart`)
- Line 295, 298: Uses `CustomTextFieldValidator.phoneNumber`
- Validates on "Continue" button click (line 125: `form.validate()`)

✅ **Login Screen** (`login_screen.dart`)
- Line 437: Uses `CustomTextFieldValidator.phoneNumber`

✅ **Post Ad Screen** (`add_item_details.dart`)
- Line 738: Uses `CustomTextFieldValidator.phoneNumber`
- Validates on "Next" button click (line 367: `_formKey.currentState?.validate()`)

✅ **Edit Profile** (`edit_profile.dart`)
- Line 235: Uses `CustomTextFieldValidator.phoneNumber`

✅ **Job Application** (`job_application_form.dart`)
- Line 324: Uses `CustomTextFieldValidator.phoneNumber`

---

## 🧪 Testing Instructions

### **IMPORTANT: Hot Restart Required**
Before testing, perform a **FULL HOT RESTART** (not just hot reload):
1. Stop the app completely
2. Run `flutter clean` (optional but recommended)
3. Run `flutter run` again

### **Test 1: User Registration with Invalid Number**

1. Open the app
2. Go to Sign Up screen
3. Enter an **Airtel number**: `0812345678`
4. Click "Continue"
5. **Expected:** Error message: `"Only Safaricom numbers are allowed (07XX)"`
6. **Check console logs** for: `🔍 Validating Safaricom number: 0812345678`

### **Test 2: User Registration with Valid Safaricom Number**

1. Enter a **Safaricom number**: `0712345678`
2. Click "Continue"
3. **Expected:** Proceeds to OTP screen
4. **Check console logs** for: `✅ VALID Safaricom number!`

### **Test 3: Post Ad with Invalid Number**

1. Login to the app
2. Go to "Post Ad"
3. Fill in all required fields
4. In phone number field, enter: `0612345678` (invalid prefix)
5. Click "Next"
6. **Expected:** Error message: `"Only Safaricom numbers are allowed (07XX)"`

### **Test 4: Post Ad with Valid Safaricom Number**

1. In phone number field, enter: `0722123456`
2. Click "Next"
3. **Expected:** Proceeds to next step

### **Test 5: Different Number Formats**

Test these valid formats (all should work):
- `0712345678` ✅
- `+254712345678` ✅
- `254712345678` ✅
- `0712 345 678` ✅
- `+254-712-345-678` ✅

Test these invalid formats (all should fail):
- `0812345678` ❌ (Airtel)
- `0612345678` ❌ (Invalid prefix)
- `712345678` ❌ (Missing leading 0)
- `071234567` ❌ (Only 9 digits)
- `07123456789` ❌ (11 digits)

---

## 🐛 Troubleshooting

### **If validation doesn't work:**

1. **Check console logs:**
   - Look for `🔍 Validating Safaricom number:` messages
   - If you don't see these logs, the validator isn't being called

2. **Verify hot restart:**
   - Make sure you did a FULL restart, not just hot reload
   - Try `flutter clean` then `flutter run`

3. **Check form validation:**
   - Ensure the form's `validate()` method is being called
   - Check if there are any errors in the console

4. **Verify validator is attached:**
   - Check that `validator: CustomTextFieldValidator.phoneNumber` is present
   - Check that `isMobileRequired` is not set to `false`

---

## 📊 Validation Flow

```
User enters phone number
        ↓
User clicks Submit/Continue
        ↓
Form.validate() is called
        ↓
CustomTextFormField validator is triggered
        ↓
Validator.validatePhoneNumber() is called
        ↓
validateSafaricomNumber() is called
        ↓
Checks:
  1. Remove spaces/dashes
  2. Convert +254/254 to 0
  3. Verify 10 digits starting with 0
  4. Check Safaricom prefix (07XX)
        ↓
Returns error message OR null (valid)
```

---

## 📝 Console Log Examples

### **Valid Safaricom Number:**
```
🔍 Validating Safaricom number: 0712345678
  Cleaned number: 0712345678
  ✅ VALID Safaricom number!
```

### **Invalid Prefix:**
```
🔍 Validating Safaricom number: 0812345678
  Cleaned number: 0812345678
  ❌ FAILED: Not a Safaricom prefix (0812)
```

### **With Country Code:**
```
🔍 Validating Safaricom number: +254712345678
  Cleaned number: 254712345678
  Converted from +254 to: 0712345678
  ✅ VALID Safaricom number!
```

---

## ✅ Confirmation Checklist

After testing, confirm:
- [ ] Airtel numbers (08XX) are rejected during registration
- [ ] Airtel numbers (08XX) are rejected when posting ads
- [ ] Safaricom numbers (07XX) work for registration
- [ ] Safaricom numbers (07XX) work for posting ads
- [ ] Numbers with country code (+254) are accepted
- [ ] Numbers with spaces/dashes are accepted
- [ ] Console logs show validation is working
- [ ] Error messages are clear and helpful

