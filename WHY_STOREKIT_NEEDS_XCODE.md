# Why StoreKit Testing Requires Xcode

## The Issue You're Experiencing

You're seeing these errors:
```
StoreKit: Loading products for id: com.nutrasafe.pro.monthly
StoreKit: Initial product fetch count: 0
StoreKit: No products found; attempting AppStore.sync()
StoreKit: Failed to sync or load products: userCancelled
StoreKit: Products still unavailable after all attempts. Using premium override only.
StoreKit: purchase() ignored — product is nil (not loaded)
```

## Why This Happens

### When Running from Xcode ✅
- Xcode reads the scheme configuration
- Sees: `<StoreKitConfigurationFileReference identifier = "/path/to/NutraSafe.storekit">`
- **Automatically injects** StoreKit test environment into the app
- Products load from your `.storekit` file
- Purchases work perfectly

### When Running via Command Line ❌
- You run: `xcrun simctl launch "iPhone 17 Pro" com.nutrasafe.beta`
- The app launches **without** Xcode
- No StoreKit configuration is injected
- App tries to connect to real App Store
- Real App Store says: "No product with that ID exists" (because you haven't set it up in App Store Connect yet)
- Result: `userCancelled` error

## How Apple's StoreKit Testing Works

Apple provides two ways to test in-app purchases:

### 1. StoreKit Configuration Files (Local Testing) ⭐️ **This is what you have**
- Create a `.storekit` file with test products
- **Must run from Xcode** to load the configuration
- No internet connection needed
- Instant purchases, no delays
- Full control over renewal times, expirations, etc.

**Limitation**: Only works when launched from Xcode

### 2. Sandbox Testing (Apple's Test Environment)
- Set up products in App Store Connect
- Use sandbox test accounts
- Can run without Xcode
- Requires internet connection
- Slower (real server roundtrips)

**You haven't set this up yet** - and you don't need to for local development!

## The Solution

### Option 1: Run from Xcode (Recommended for Testing) ⭐️

This is what you should do:

```bash
# Easy way - run the script
cd "/Users/aaronkeen/Documents/My Apps/NutraSafe"
./scripts/run_with_storekit.sh

# Or manually
open "NutraSafeBeta.xcodeproj"
# Then press ⌘ + R in Xcode
```

**Benefits**:
- ✅ StoreKit testing works perfectly
- ✅ No App Store Connect setup needed
- ✅ Instant purchases
- ✅ Full debugging with breakpoints
- ✅ View transactions in Debug → StoreKit → Manage Transactions

### Option 2: Set Up Sandbox Testing (For TestFlight/Production)

Only do this when you're ready for TestFlight or App Store:

1. **In App Store Connect**:
   - Create the product: `com.nutrasafe.pro.monthly`
   - Set price: £1.99/month
   - Configure 1-week free trial
   - Submit for review

2. **Create Sandbox Test Account**:
   - Go to App Store Connect → Users & Access → Sandbox Testers
   - Create a test Apple ID
   - Use this on your device/simulator

3. **Test**:
   - Now you can run via `simctl launch`
   - Products will load from Apple's sandbox servers
   - Uses your sandbox test account

**But you don't need this yet!** Just use Xcode for local testing.

## Current StoreKit Configuration

Your `.storekit` file is properly set up:

```json
{
  "productID": "com.nutrasafe.pro.monthly",
  "displayPrice": "1.99",
  "recurringSubscriptionPeriod": "P1M",
  "introductoryOffer": {
    "paymentMode": "free",
    "subscriptionPeriod": "P1W"
  }
}
```

✅ Product ID: `com.nutrasafe.pro.monthly`
✅ Price: £1.99/month
✅ Free trial: 1 week
✅ Xcode scheme: Configured to load this file

**Everything is ready!** You just need to run from Xcode.

## Testing Workflow

### Daily Development (Use Xcode):

```bash
# Open project in Xcode
open "/Users/aaronkeen/Documents/My Apps/NutraSafe/NutraSafeBeta.xcodeproj"

# In Xcode:
# 1. Select "NutraSafe Beta" scheme
# 2. Select "iPhone 17 Pro" destination
# 3. Press ⌘ + R

# Test purchases:
# 1. Settings → Unlock NutraSafe Pro
# 2. Complete test purchase
# 3. Debug → StoreKit → Manage Transactions
```

### Before App Store Submission:

1. Set up the product in App Store Connect
2. Create sandbox test account
3. Test on real device with sandbox account
4. Submit for App Store review

## Why Xcode is Better for Development

| Feature | Running from Xcode | Running from simctl |
|---------|-------------------|-------------------|
| StoreKit testing | ✅ Works perfectly | ❌ Doesn't work |
| Debugging | ✅ Full breakpoints | ❌ No debugging |
| Console logs | ✅ Real-time in Xcode | ⚠️ Only via log stream |
| Transaction management | ✅ Debug menu | ❌ Not available |
| Speed to test | ✅ One click (⌘+R) | ⚠️ Manual commands |
| Hot reload | ✅ Available | ❌ Must rebuild |

## Quick Reference

### To Test StoreKit Right Now:

1. Run the script:
   ```bash
   cd "/Users/aaronkeen/Documents/My Apps/NutraSafe"
   ./scripts/run_with_storekit.sh
   ```

2. In Xcode, press **⌘ + R**

3. In the app:
   - Tap Settings
   - Tap "Unlock NutraSafe Pro"
   - Tap "Start Free Trial"
   - Complete test purchase

4. In Xcode:
   - Debug → StoreKit → Manage Transactions
   - See your test purchase
   - Delete it to reset

### Expected Console Output (When It Works):

```
StoreKit: Loading products for id: com.nutrasafe.pro.monthly
StoreKit: Initial product fetch count: 1
StoreKit: Loaded product: com.nutrasafe.pro.monthly price=£1.99
StoreKit: refreshStatus — isSubscribed=false isInTrial=false
```

After purchase:
```
StoreKit: Starting purchase for com.nutrasafe.pro.monthly
StoreKit: Purchase verified. Finishing transaction
StoreKit: refreshStatus — isSubscribed=true isInTrial=true
```

## Summary

**The error you're seeing is expected behavior** when running without Xcode.

✅ **Your StoreKit configuration is correct**
✅ **Your code is correct**
✅ **You just need to run from Xcode**

Run the script and test your £1.99/month subscription with 1-week free trial! 🚀
