# StoreKit Testing - Quick Start Guide

## The Issue You're Seeing

The error `AppStore.sync() failed: userCancelled` means StoreKit testing isn't fully initialized. This happens when running the app directly via `simctl` instead of through Xcode.

## ✅ Solution: Run from Xcode

For StoreKit to work properly in the simulator, you need to run the app from Xcode, which automatically loads the StoreKit configuration file.

### Steps to Test:

1. **Open Xcode**:
   ```bash
   open "/Users/aaronkeen/Documents/My Apps/NutraSafe/NutraSafeBeta.xcodeproj"
   ```

2. **Select the Scheme**:
   - At the top of Xcode, make sure **"NutraSafe Beta"** is selected
   - Select **"iPhone 16 Pro"** as the destination

3. **Run the App**:
   - Press **⌘ + R** (or click the ▶️ Play button)
   - Xcode will build and launch the app with StoreKit testing enabled

4. **Test the Purchase**:
   - Once the app launches, go to **Settings** (gear icon)
   - Scroll to **"Premium Subscription"**
   - Tap **"Unlock NutraSafe Pro"**
   - Tap **"Start Free Trial"** (or "Subscribe")
   - You should see a StoreKit test purchase dialog
   - Tap **"Subscribe"** to complete the test purchase

5. **View Transactions in Xcode**:
   - While the app is running, go to **Debug** → **StoreKit** → **Manage Transactions**
   - You'll see your test purchase listed
   - You can delete it, refund it, or fast-forward time

## Why This Happens

When you run via Xcode:
- ✅ Xcode automatically loads the StoreKit configuration from the scheme
- ✅ The StoreKit test environment is properly initialized
- ✅ Products load correctly
- ✅ Purchases work as expected

When you run via `simctl launch`:
- ❌ No Xcode to load the configuration
- ❌ StoreKit defaults to production mode (no test products)
- ❌ `AppStore.sync()` fails with `userCancelled`

## Alternative: Add StoreKit File to Bundle

If you want the app to work without Xcode, you need to:

1. Add the StoreKit file to the app bundle (currently it's not included)
2. The code in `SubscriptionManager.swift` already tries to load it from the bundle
3. But this requires adding `NutraSafe.storekit` to the "Copy Bundle Resources" build phase

However, for testing purposes, **running from Xcode is the recommended approach**.

## Quick Test Script

Here's a simple way to open Xcode and run:

```bash
# Open Xcode project
open "/Users/aaronkeen/Documents/My Apps/NutraSafe/NutraSafeBeta.xcodeproj"

# Wait for Xcode to open, then press ⌘ + R to run
```

## What You Should See (Console Logs)

When it works correctly from Xcode, you'll see:

```
StoreKit: Loading products for id: com.nutrasafe.pro.monthly
StoreKit: Initial product fetch count: 1
StoreKit: Loaded product: com.nutrasafe.pro.monthly price=£1.99
StoreKit: refreshStatus — isSubscribed=false isInTrial=false statusCount=0
```

After purchasing:
```
StoreKit: Starting purchase for com.nutrasafe.pro.monthly
StoreKit: Purchase verified. Finishing transaction [ID]
StoreKit: refreshStatus — isSubscribed=true isInTrial=true statusCount=1
```

## Expected Behavior

### Before Purchase:
- PaywallView shows "Start Free Trial" button
- Price displays as "£1.99/month"
- Free trial description: "after 1-week free trial"

### During Purchase:
- StoreKit dialog appears with your test subscription
- Shows "NutraSafe Pro Monthly - £1.99/month"
- Shows "Free for 1 week" (trial offer)

### After Purchase:
- `subscriptionManager.isSubscribed` = `true`
- `subscriptionManager.isInTrial` = `true`
- Premium features unlock

## Managing Test Purchases

### View All Transactions:
**Debug** → **StoreKit** → **Manage Transactions**

### Delete Test Purchase (Reset):
1. Open **Manage Transactions**
2. Select the transaction
3. Click **Delete** or press Delete key
4. Relaunch the app

### Test Subscription Renewal:
1. Open **Manage Transactions**
2. Select the transaction
3. Click **Speed Up Time** to jump to renewal date
4. Watch the console for renewal logs

### Test Trial Expiration:
1. Purchase with free trial
2. Open **Manage Transactions**
3. Click **Speed Up Time** to jump 7 days forward
4. Trial expires, billing should start

## Production vs Testing

### Current Setup (Testing):
- Product ID: `com.nutrasafe.pro.monthly` ✅
- Price: £1.99/month ✅
- Free trial: 1 week ✅
- StoreKit configuration file: `/Users/.../NutraSafe.storekit` ✅

### For Production (App Store):
- Create the **same** product in App Store Connect
- Use **same** product ID: `com.nutrasafe.pro.monthly`
- Set **same** price: £1.99/month
- Configure **same** free trial: 1 week
- No code changes needed - app will automatically use App Store products

## Troubleshooting

### "No products found"
→ Make sure you're running from Xcode, not `simctl launch`

### "userCancelled" error
→ StoreKit testing isn't initialized - run from Xcode

### Products load but purchase doesn't work
→ Check Xcode console for detailed error messages
→ Try Debug → StoreKit → Manage Transactions → Delete all transactions

### Want to test without Xcode?
→ You'll need to add the StoreKit file to the app bundle's "Copy Bundle Resources" phase

---

**Ready to test? Open Xcode and press ⌘ + R!** 🚀
