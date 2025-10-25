# StoreKit Testing Guide for NutraSafe

## Setup Complete ✅

Your StoreKit testing environment is now fully configured! Here's what's been set up:

### Configuration Details

1. **StoreKit Configuration File**: `NutraSafe.storekit`
   - Product ID: `com.nutrasafe.pro.monthly`
   - Price: £1.99/month
   - Free Trial: 1 week
   - Display Name: "NutraSafe Pro Monthly"

2. **Xcode Scheme**: Updated to use `NutraSafe.storekit` for local testing

3. **Subscription Manager**: Fully integrated with StoreKit 2 APIs

## Testing in Simulator

### Step 1: Launch the App
The app is now running in your iPhone 16 Pro simulator. You should be able to:

1. Navigate to Settings (tap the gear icon in the tab bar)
2. Look for the "Upgrade to Pro" or subscription-related button
3. Tap it to open the PaywallView

### Step 2: Test Purchase Flow

When you tap the "Start Free Trial" or "Subscribe" button:

1. **Local StoreKit Testing**: A dialog will appear showing your test subscription
2. **No Real Money**: This is completely safe - no actual charges will occur
3. **Free Trial**: You should see the 1-week free trial offer
4. **Confirmation**: Tap "Subscribe" in the StoreKit dialog to complete the test purchase

### Step 3: Verify Subscription Status

After purchasing:
- The subscription manager should recognize you as subscribed
- `isSubscribed` should be `true`
- `isInTrial` should be `true` (since you used the free trial)
- Premium features should unlock

### Step 4: Managing Test Subscriptions

#### In Xcode:
1. Go to **Debug** menu → **StoreKit** → **Manage Transactions**
2. You'll see all test transactions
3. You can:
   - Delete transactions to reset
   - Refund purchases
   - Fast-forward subscription renewals
   - Test subscription expiration

#### Testing Scenarios:

**Test Free Trial**:
```
1. Purchase subscription with free trial
2. In StoreKit Transaction Manager, speed up time to expire trial
3. Verify app handles trial expiration correctly
```

**Test Restore Purchases**:
```
1. Make a test purchase
2. Delete the app from simulator
3. Reinstall and tap "Restore Purchases"
4. Verify subscription is restored
```

**Test Cancellation**:
```
1. Purchase subscription
2. Tap "Manage Subscription" button
3. Cancel the subscription
4. Verify app handles cancellation gracefully
```

**Test Failed Purchases**:
```
1. In Xcode: Debug → StoreKit → Enable StoreKit Testing
2. Enable "Fail Transactions" in StoreKit settings
3. Try to purchase
4. Verify app handles failure with proper error message
```

## Code Implementation Details

### SubscriptionManager Features:
- ✅ Product loading with retry logic
- ✅ StoreKitTest session initialization
- ✅ Free trial detection
- ✅ Transaction verification
- ✅ Restore purchases functionality
- ✅ Manage subscriptions sheet
- ✅ Premium override for testing

### Premium Features Check:
```swift
// Subscription is active if:
// 1. User has valid subscription, OR
// 2. isPremiumOverride is true (for testing/admin)

var isPremium: Bool {
    subscriptionManager.isSubscribed ||
    subscriptionManager.isPremiumOverride
}
```

## Debugging Tips

### Enable StoreKit Logging:
Watch the Xcode console for logs starting with "StoreKit:" to see:
- Product loading status
- Purchase attempts
- Transaction verification
- Subscription status changes

### Common Issues:

**"No products found"**:
- Check that `NutraSafe.storekit` is in the project root
- Verify Xcode scheme has StoreKit configuration enabled
- Clean build folder and rebuild

**"Purchase not completing"**:
- Check Transaction Manager for stuck transactions
- Delete test transactions and try again
- Restart simulator

**"Free trial not showing"**:
- Verify `introductoryOffer` is configured in StoreKit file
- Check `paymentMode` is set to `free` (not `payAsYouGo`)

## Production Considerations

Before App Store submission:

1. **Create Real Product in App Store Connect**:
   - Product ID must match: `com.nutrasafe.pro.monthly`
   - Price: £1.99/month
   - Set up 1-week free trial

2. **StoreKit Configuration in Production**:
   - The scheme configuration only affects local testing
   - Production builds will use real App Store products
   - No code changes needed when moving to production

3. **Testing on Real Device (TestFlight)**:
   - Use Sandbox Apple ID for testing
   - Go to Settings → App Store → Sandbox Account
   - Sign in with test account before testing purchases

## Quick Commands

**Build and Run**:
```bash
xcodebuild -project "NutraSafeBeta.xcodeproj" -scheme "NutraSafe Beta" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' build
```

**Install to Simulator**:
```bash
xcrun simctl install "iPhone 16 Pro" \
  "/Users/aaronkeen/Library/Developer/Xcode/DerivedData/NutraSafeBeta-*/Build/Products/Debug-iphonesimulator/NutraSafe Beta.app"
```

**Launch App**:
```bash
xcrun simctl launch "iPhone 16 Pro" com.nutrasafe.beta
```

## Next Steps

1. ✅ Test the purchase flow in the simulator
2. Navigate to Settings and tap "Upgrade to Pro"
3. Complete a test purchase
4. Verify premium features unlock
5. Test restore purchases
6. Test subscription management

Your StoreKit testing environment is ready! 🎉
