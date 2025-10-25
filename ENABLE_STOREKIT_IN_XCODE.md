# How to Enable StoreKit Testing in Xcode (Manual Fix)

## The Problem

Even though the scheme XML has the StoreKit configuration, Xcode isn't using it. You're still seeing Apple ID prompts and `product count: 0`.

## THE FIX: Enable StoreKit in Xcode UI

I've just reopened Xcode for you. Now follow these steps **exactly**:

### Step 1: Open Scheme Editor

1. In Xcode, click on **"NutraSafe Beta"** at the top (next to the play button)
2. Select **"Edit Scheme..."** from the dropdown menu

   OR use keyboard shortcut: **⌘ + <** (Command + Shift + comma)

### Step 2: Enable StoreKit Configuration

1. In the scheme editor, select **"Run"** on the left side
2. Click the **"Options"** tab at the top
3. Look for **"StoreKit Configuration"**
4. From the dropdown, select **"NutraSafe.storekit"**
   - If you don't see it, click **"+ Add Configuration..."** and browse to:
     `/Users/aaronkeen/Documents/My Apps/NutraSafe/NutraSafe.storekit`

### Step 3: Close and Run

1. Click **"Close"** to save the scheme
2. Press **⌘ + R** to run the app

### Step 4: Verify It Works

**In the Xcode console**, you should now see:
```
StoreKit: Loading products for id: com.nutrasafe.pro.monthly
StoreKit: Initial product fetch count: 1  ← This should be 1, not 0!
StoreKit: Loaded product: com.nutrasafe.pro.monthly price=£1.99
```

**In the simulator**:
- Go to Settings → "Unlock NutraSafe Pro"
- You should see a **StoreKit test purchase dialog**
- **NO Apple ID prompt!**

## Visual Guide

```
Xcode Top Bar:
┌─────────────────────────────────────────┐
│ NutraSafe Beta  >  iPhone 17 Pro  ▶︎   │  ← Click here
└─────────────────────────────────────────┘
            ↓
       Click to get dropdown
            ↓
┌─────────────────────────────────────────┐
│ NutraSafe Beta                          │
│ New Scheme...                           │
│ Manage Schemes...                       │
│ Edit Scheme...          ⌘<              │  ← Select this
└─────────────────────────────────────────┘
            ↓
       Opens Scheme Editor
            ↓
┌─────────────────────────────────────────┐
│ Left Panel:        Options Tab:         │
│ Build              ┌─────────────────┐  │
│ > Run ←Click       │ StoreKit Config │  │  ← Find this
│   Test             │ [NutraSafe.storekit] │
│   Profile          └─────────────────┘  │
│   Analyze                                │
│   Archive                                │
└─────────────────────────────────────────┘
```

## What This Does

When StoreKit Configuration is enabled in the scheme:
- ✅ Xcode loads the .storekit file before launching
- ✅ Products from the file become available
- ✅ Test purchases work without Apple ID
- ✅ Full StoreKit testing environment active

When it's NOT enabled (current state):
- ❌ App uses production App Store
- ❌ No products found (haven't created in App Store Connect)
- ❌ Apple ID prompts appear
- ❌ Purchases don't work

## Alternative: Check Current Settings

To verify the current setting:

1. **⌘ + <** to open scheme editor
2. Click **"Run"** → **"Options"**
3. Look at **"StoreKit Configuration"** dropdown
4. Is **"NutraSafe.storekit"** selected?
   - **YES** → Something else is wrong
   - **NO** or **"None"** → This is the problem! Select it!

## If NutraSafe.storekit Doesn't Appear in Dropdown

1. Click **"+ Add Configuration..."** in the dropdown
2. Navigate to: `/Users/aaronkeen/Documents/My Apps/NutraSafe/`
3. Select **"NutraSafe.storekit"**
4. Click **"Open"**
5. It should now be selected in the dropdown

## After Fixing

You should see this console output:
```
✅ StoreKitTest: Session initialized successfully
   - Configuration: NutraSafe.storekit
   - Mode: Local Testing (No Apple ID required)
StoreKit: Loading products for id: com.nutrasafe.pro.monthly
StoreKit: Initial product fetch count: 1
StoreKit: Loaded product: com.nutrasafe.pro.monthly price=£1.99
```

And when you try to purchase:
- **StoreKit purchase dialog** (looks like a system alert)
- Shows: "NutraSafe Pro Monthly - £1.99"
- Shows: "Free for 1 week" (trial offer)
- Buttons: "Subscribe" / "Cancel"

**NO Apple Account sign-in prompt!**

## Summary

The scheme XML file has the configuration, but Xcode's UI setting overrides it. You must:

1. Open Xcode (already open)
2. **⌘ + <** to edit scheme
3. Run → Options → StoreKit Configuration
4. Select **"NutraSafe.storekit"**
5. Close and run (**⌘ + R**)

**Do this now in Xcode** - it will immediately fix the Apple ID prompt issue! 🎯
