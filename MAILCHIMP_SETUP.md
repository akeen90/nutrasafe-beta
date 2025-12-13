# Mailchimp Email Marketing Integration - Setup Guide

## Overview

GDPR-compliant email marketing integration that syncs user consent from the NutraSafe app to Mailchimp.

**Features:**
- ✅ GDPR-compliant opt-in during onboarding
- ✅ Users can manage consent in Settings → Email Preferences
- ✅ Automatic sync to Mailchimp when consent changes
- ✅ Unsubscribe support (updates Mailchimp when user opts out)
- ✅ Consent timestamps stored for compliance

---

## 1. Get Mailchimp Credentials

### API Key
1. Log in to Mailchimp
2. Go to **Account** → **Extras** → **API Keys**
3. Create a new API key
4. Copy the API key (starts with something like `abc123def456-us1`)

### Audience ID
1. Go to **Audience** → **All contacts**
2. Click **Settings** → **Audience name and defaults**
3. Copy the **Audience ID** (10-character alphanumeric code)

### Server Prefix
The server prefix is the part after the dash in your API key (e.g., `us1`, `us2`, `us19`)

---

## 2. Configure Firebase Functions

Set your Mailchimp credentials in Firebase Functions config:

```bash
cd "/Users/aaronkeen/Documents/My Apps/NutraSafe/firebase/functions"

firebase functions:config:set \
  mailchimp.api_key="YOUR_API_KEY_HERE" \
  mailchimp.audience_id="YOUR_AUDIENCE_ID_HERE" \
  mailchimp.server_prefix="us1"
```

**Example:**
```bash
firebase functions:config:set \
  mailchimp.api_key="abc123def456-us1" \
  mailchimp.audience_id="a1b2c3d4e5" \
  mailchimp.server_prefix="us1"
```

**Verify configuration:**
```bash
firebase functions:config:get
```

---

## 3. Deploy Firebase Functions

Build and deploy the Mailchimp sync functions:

```bash
cd "/Users/aaronkeen/Documents/My Apps/NutraSafe/firebase/functions"

npm run build
firebase deploy --only functions:syncEmailConsentToMailchimp,functions:syncAllEmailConsentsToMailchimp
```

---

## 4. How It Works

### During Onboarding
1. User completes onboarding screens
2. **Email Consent Page** appears (after disclaimer)
3. User can check "I'd like to receive emails about updates and offers"
4. Choice is saved to Firestore (`users/{userId}/emailMarketingConsent`)
5. **Firestore Trigger** `syncEmailConsentToMailchimp` automatically:
   - Subscribes user to Mailchimp if they opted in
   - Does nothing if they opted out

### In Settings
1. User goes to **Settings** → **Email Preferences**
2. Toggle email consent on/off
3. Click "Save Preferences"
4. Firestore document updates
5. **Firestore Trigger** automatically:
   - Subscribes if user opted in
   - Unsubscribes if user opted out

### GDPR Compliance
- ✅ Checkbox NOT pre-checked (explicit opt-in required)
- ✅ Consent timestamp stored in Firestore
- ✅ Withdrawal timestamp stored when user opts out
- ✅ Privacy policy clearly stated
- ✅ Easy unsubscribe from Settings or email links

---

## 5. Data Structure in Firestore

Each user document (`users/{userId}`) contains:

```javascript
{
  email: "user@example.com",
  emailMarketingConsent: true,             // User opted in
  emailMarketingConsentDate: Timestamp,    // When they opted in
  emailMarketingConsentWithdrawn: false,   // Not withdrawn
  emailMarketingConsentWithdrawnDate: null // No withdrawal
}
```

**When user opts out:**
```javascript
{
  email: "user@example.com",
  emailMarketingConsent: false,            // User opted out
  emailMarketingConsentDate: Timestamp,    // Original opt-in date
  emailMarketingConsentWithdrawn: true,    // Withdrawn
  emailMarketingConsentWithdrawnDate: Timestamp  // When they opted out
}
```

---

## 6. Bulk Sync Existing Users

If you already have users who opted in before this feature was deployed:

```bash
# Call the manual sync function
firebase functions:call syncAllEmailConsentsToMailchimp
```

This will:
1. Query all users with `emailMarketingConsent == true`
2. Subscribe each one to Mailchimp
3. Return stats: `{ syncedCount, errorCount, totalUsers }`

---

## 7. Testing

### Test Opt-In
1. Reset onboarding: Delete app and reinstall
2. Go through onboarding
3. Check "I'd like to receive emails" on Email Consent page
4. Complete onboarding
5. Check Firebase Console → Firestore → `users/{userId}`
   - Should see `emailMarketingConsent: true`
6. Check Mailchimp → Audience → All contacts
   - User should appear as "Subscribed"

### Test Opt-Out
1. Open app → Settings → Email Preferences
2. Toggle OFF "Send me emails"
3. Click "Save Preferences"
4. Check Firestore
   - Should see `emailMarketingConsentWithdrawn: true`
5. Check Mailchimp
   - User should show as "Unsubscribed"

### Test Logs
View Firebase Functions logs to see sync activity:

```bash
firebase functions:log --only syncEmailConsentToMailchimp
```

Look for:
- ✅ `User {userId} opted IN - subscribing {email} to Mailchimp`
- ✅ `Subscribed {email} to Mailchimp: {mailchimp_id}`
- 🚫 `User {userId} opted OUT - unsubscribing {email} from Mailchimp`

---

## 8. Mailchimp Tags

Users are tagged with:
- **NutraSafe App** - Shows they came from the app

You can use this tag to:
- Create segments for app-specific campaigns
- Track where subscribers came from
- Differentiate app users from web users

---

## 9. Troubleshooting

### "Mailchimp config not set" error
**Solution:** Make sure you've run `firebase functions:config:set` (see step 2)

### "Member Exists" error
**Meaning:** User is already in your Mailchimp audience
**Solution:** The function will automatically update their status instead of creating a duplicate

### Function not triggering
1. Check Firebase Console → Functions → Logs
2. Verify function deployed: `firebase functions:list`
3. Test manually: Create/update a user doc in Firestore Console

### API Key Invalid
1. Verify API key is active in Mailchimp
2. Check server prefix matches (e.g., `us1`, `us19`)
3. Regenerate API key if needed

---

## 10. Cost Considerations

### Firebase Functions
- **Firestore Trigger** (syncEmailConsentToMailchimp):
  - Runs once per user consent change
  - Very low cost (typically < $0.01/month for most apps)

- **Manual Sync** (syncAllEmailConsentsToMailchimp):
  - Only run once or rarely
  - Cost depends on user count (still minimal for < 10K users)

### Mailchimp
- Free tier: Up to 500 contacts
- Paid tiers start at ~$13/month for 501-1,000 contacts
- Pricing scales with audience size

---

## 11. Next Steps

1. **Set up Mailchimp campaigns:**
   - Welcome email for new subscribers
   - Monthly newsletter with nutrition tips
   - Feature announcements
   - Exclusive offers

2. **Configure unsubscribe link:**
   - Mailchimp automatically adds this to emails
   - Users can also unsubscribe via Settings

3. **Monitor metrics:**
   - Track open rates, click rates
   - A/B test subject lines
   - Optimize send times

4. **Comply with email regulations:**
   - CAN-SPAM (US)
   - GDPR (EU)
   - CASL (Canada)

---

## Files Changed

### iOS App
- `NutraSafe Beta/Models/UserModels.swift` - Added email consent fields
- `NutraSafe Beta/Views/Onboarding/OnboardingScreens.swift` - Added EmailConsentPage
- `NutraSafe Beta/Views/Onboarding/OnboardingView.swift` - Integrated consent page
- `NutraSafe Beta/ContentView.swift` - Save consent to Firestore
- `NutraSafe Beta/Views/Settings/SettingsView.swift` - Added Email Preferences menu + EmailMarketingConsentView
- `NutraSafe Beta/FirebaseManager.swift` - Added updateEmailMarketingConsent() and getEmailMarketingConsent() methods

### Firebase Functions
- `firebase/functions/src/mailchimp-sync.ts` - NEW: Mailchimp integration
- `firebase/functions/src/index.ts` - Export Mailchimp functions

### Security
- `firestore.rules` - Already allows users to update their own consent (no changes needed)

---

## Support

If you encounter issues:
1. Check Firebase Functions logs: `firebase functions:log`
2. Check Mailchimp Activity Feed
3. Verify config: `firebase functions:config:get`

---

**That's it! Your GDPR-compliant email marketing is ready to go.** 🚀
