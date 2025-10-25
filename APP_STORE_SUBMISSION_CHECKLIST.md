# NutraSafe - App Store Submission Checklist

## 🎯 Overview

Getting your app ready for App Store review with in-app purchases/subscriptions.

---

## Step 1: App Store Connect Setup

### 1.1 Create App Listing

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **"My Apps"** → **"+"** → **"New App"**
3. Fill in:
   - **Platform**: iOS
   - **Name**: NutraSafe (or your preferred name)
   - **Primary Language**: English (U.K.)
   - **Bundle ID**: Select `com.nutrasafe.beta` (or whatever your bundle ID is)
   - **SKU**: Can be anything unique (e.g., `nutrasafe-001`)
   - **User Access**: Full Access

### 1.2 App Information

**Category**: Health & Fitness
**Secondary Category** (optional): Food & Drink

**Privacy Policy URL**: `https://nutrasafe-705c7.web.app/privacy-policy.html` ✅ (you already have this)

**Terms and Conditions URL** (optional): Create if needed

---

## Step 2: Create In-App Purchase in App Store Connect

### 2.1 Set Up Subscription

1. In App Store Connect, open your app
2. Go to **"Features"** tab → **"In-App Purchases"** or **"Subscriptions"**
3. Click **"+"** → **"Auto-Renewable Subscription"**

### 2.2 Subscription Group

Create a new subscription group:
- **Reference Name**: NutraSafe Pro
- **Group Name** (customer-facing): Leave blank or use "NutraSafe Pro"

### 2.3 Subscription Details

**CRITICAL - Must match your code exactly:**

- **Product ID**: `com.nutrasafe.pro.monthly` ⚠️ MUST MATCH EXACTLY
- **Reference Name**: NutraSafe Pro Monthly
- **Subscription Duration**: 1 Month

### 2.4 Subscription Pricing

1. **Price**: £1.99 (or select Tier 2)
2. **Availability**: All territories (or select specific countries)

### 2.5 Free Trial (Introductory Offer)

1. Click **"Introductory Offer"** section
2. **Type**: Free
3. **Duration**: 1 Week (7 days)
4. **Number of Periods**: 1
5. **Availability**: All customers eligible for introductory offer

### 2.6 Localization

**English (U.K.)**:
- **Display Name**: NutraSafe Pro Monthly
- **Description**: Unlock premium features including advanced nutrition tracking, personalized insights, and unlimited food scanning.

### 2.7 Review Information

Upload **screenshots** showing:
- What the subscription unlocks
- The paywall/purchase screen
- Premium features in action

**Review Notes**: Explain what premium features do

---

## Step 3: App Metadata & Assets

### 3.1 Required Screenshots

You need screenshots for:
- **6.7" Display** (iPhone 17 Pro Max, 16 Pro Max, 15 Pro Max, 14 Pro Max)
- **6.5" Display** (Optional but recommended)

**Minimum**: 3 screenshots, **Maximum**: 10 screenshots

**What to show**:
1. Main nutrition tracking screen
2. Micronutrient dashboard
3. Food scanning/search
4. Use-by date tracking
5. Premium features

### 3.2 App Preview (Optional but Recommended)

Short video (15-30 seconds) showing app in action

### 3.3 Description

Write compelling app description highlighting:
- Food safety tracking
- Nutrition insights
- Allergen detection
- Use-by date reminders
- **Premium features** (be clear what requires subscription)

### 3.4 Keywords

Examples: nutrition, food safety, allergen, tracker, health, diet, expiry

### 3.5 Support URL

Create a support page or use: `https://nutrasafe.co.uk` (if you have one)

### 3.6 Marketing URL (Optional)

Your website or landing page

---

## Step 4: App Privacy Details

### 4.1 Privacy Nutrition Labels

In App Store Connect:
1. Go to **App Privacy** section
2. Click **"Get Started"**
3. Answer questions about data collection:

**Data You Collect**:
- Contact Info (Email - for account creation)
- Health & Fitness (Food intake, nutrition data)
- Identifiers (User ID)
- Purchases (Purchase history for subscription)

**Data Linked to User**: Yes (for account features)
**Data Used to Track**: No (unless you use analytics)

### 4.2 Privacy Policy

Ensure your privacy policy covers:
- What data you collect (email, food logs, health data)
- How you use it (app functionality, Firebase storage)
- Third parties (Firebase, any analytics)
- User rights (deletion, export)

---

## Step 5: Build Configuration

### 5.1 Check Bundle ID & Version

In Xcode:
1. Select **NutraSafe Beta** target
2. **General** tab
3. Verify:
   - **Bundle Identifier**: Matches App Store Connect
   - **Version**: 1.0 (or your version)
   - **Build**: 1 (increment for each upload)

### 5.2 Capabilities & Entitlements

Verify these are enabled:
- ✅ In-App Purchase
- ✅ Sign in with Apple (if you use it)
- ✅ Push Notifications (if you use them)
- ✅ HealthKit (you use this)

### 5.3 App Icon

Ensure you have a 1024×1024px App Icon in Assets.xcassets

### 5.4 Remove Test/Debug Code

- Remove any hardcoded test credentials
- Remove excessive console logging (keep errors only)
- Ensure no "Test" or "Debug" text visible to users

---

## Step 6: Create Archive & Upload

### 6.1 Select Device

1. In Xcode, at the top, click device selector
2. Select **"Any iOS Device (arm64)"**

### 6.2 Archive the Build

1. Menu: **Product** → **Archive**
2. Wait for build to complete
3. Archives window opens automatically

### 6.3 Validate the Archive

1. In Archives window, select your archive
2. Click **"Validate App"**
3. Choose your team/account
4. Click **"Validate"**
5. Wait for validation (checks for common issues)
6. Fix any errors if found

### 6.4 Upload to App Store Connect

1. Click **"Distribute App"**
2. Select **"App Store Connect"**
3. Click **"Upload"**
4. Choose distribution options:
   - ✅ Include bitcode: No (deprecated)
   - ✅ Upload symbols: Yes
   - ✅ Manage version and build number: Automatic
5. Click **"Upload"**
6. Wait (can take 10-30 minutes to process)

---

## Step 7: TestFlight (Beta Testing - Optional but Recommended)

### 7.1 Internal Testing

1. After upload processes, go to App Store Connect
2. Select your app → **TestFlight** tab
3. Build appears under **"iOS Builds"**
4. Add **Internal Testers** (up to 100, must be in your team)
5. Click **"Start Testing"**
6. Testers get email with TestFlight invite

### 7.2 External Testing (Public Beta - Optional)

1. Create external test group
2. Add beta testers (up to 10,000)
3. Submit for **Beta App Review** (faster than full review)
4. Once approved, testers can download

### 7.3 Test the Subscription

**IMPORTANT**: In TestFlight, you MUST test with **sandbox test account**:

1. Go to App Store Connect → **Users and Access** → **Sandbox Testers**
2. Create a **Sandbox Test Account**:
   - Email: Use a fake email (doesn't need to exist)
   - Password: Make one up
   - Region: United Kingdom
3. On your **physical iPhone** (not simulator):
   - Settings → App Store → **Sandbox Account**
   - Sign in with sandbox test account
4. Install app from TestFlight
5. Test the subscription purchase
6. Verify free trial works
7. Subscription will auto-renew **very quickly** in sandbox (minutes, not months)

---

## Step 8: Submit for App Review

### 8.1 Add Build to Submission

1. In App Store Connect, go to your app
2. Click **"+ Version"** or **"Prepare for Submission"**
3. **Version**: 1.0
4. **Build**: Select the build you uploaded
5. Click **"Select a build before you submit your app"**
6. Choose your build

### 8.2 App Review Information

**Contact Information**:
- First Name, Last Name
- Phone Number
- Email

**Demo Account** (REQUIRED for apps with login):
- Username: Create a test account
- Password: Provide password
- **Important**: Give them an account with subscription active OR tell them how to test subscription

**Notes**:
```
This app includes a £1.99/month subscription with a 1-week free trial.

To test premium features:
1. Use the provided demo account (already has active subscription)
OR
2. Tap "Unlock NutraSafe Pro" → "Start Free Trial" to test purchase flow

Premium features include:
- Micronutrient tracking dashboard
- Advanced nutrition insights
- Use-by date reminders
- Reaction tracking

Please test on a device that can access HealthKit if possible.
```

### 8.3 Version Release

Choose:
- **Automatically release** after approval
- **Manually release** (you choose when)

### 8.4 Submit for Review

1. Review everything
2. Click **"Add for Review"** or **"Submit for Review"**
3. Confirm

---

## Step 9: App Review Process

### 9.1 Timeline

- **In Review**: 24-48 hours typically
- **May ask questions**: Respond quickly (24 hours)
- **Approval**: You'll get email notification

### 9.2 Common Rejection Reasons

**For Subscription Apps**:
1. ❌ **Subscription not clearly explained** → Make sure benefits are obvious
2. ❌ **Can't test subscription** → Provide demo account with active subscription
3. ❌ **Price not visible before purchase** → Your paywall shows price ✅
4. ❌ **Missing privacy policy** → You have one ✅
5. ❌ **Crashes or bugs** → Test thoroughly in TestFlight first

### 9.3 If Rejected

1. Read rejection reason carefully
2. Fix the issue
3. Upload new build OR update metadata
4. Resubmit

---

## Step 10: After Approval

### 10.1 App Goes Live

- Available on App Store within hours
- Users can search for it
- Subscription is live (real money!)

### 10.2 Monitor

1. **Sales & Trends**: See downloads
2. **Payments**: See subscription revenue (minus Apple's 30% first year, 15% after)
3. **Ratings & Reviews**: Respond to user feedback
4. **Crash Reports**: Fix issues in updates

---

## Quick Pre-Flight Checklist

Before uploading your first build:

- [ ] Bundle ID matches App Store Connect
- [ ] Subscription created in App Store Connect with EXACT product ID: `com.nutrasafe.pro.monthly`
- [ ] Free trial configured (1 week, free)
- [ ] App icon present (1024×1024)
- [ ] Privacy policy URL added
- [ ] Screenshots ready (at least 3)
- [ ] App description written
- [ ] Demo account created for reviewers
- [ ] Tested subscription flow thoroughly
- [ ] No test/debug code visible
- [ ] All features work on real device

---

## Key Things to Remember

1. **Product ID must match EXACTLY**: `com.nutrasafe.pro.monthly`
2. **Test with sandbox account** on real device via TestFlight first
3. **Provide demo account** with active subscription for reviewers
4. **Clearly explain** what the subscription includes
5. **Privacy policy** is required and must be accurate

---

## Resources

- [App Store Connect](https://appstoreconnect.apple.com)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [In-App Purchase Guidelines](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase)
- [TestFlight Beta Testing](https://developer.apple.com/testflight/)

---

## Need Help?

- **Technical Issues**: Check Xcode logs, Firebase console
- **Review Questions**: Respond in Resolution Center in App Store Connect
- **Subscription Issues**: Check App Store Connect → Agreements, Tax & Banking

---

**You're ready to ship! 🚀**

Good luck with your submission!
