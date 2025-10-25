#!/bin/bash

echo "🧪 Testing StoreKit on iPhone 17 Pro"
echo "===================================="
echo ""

# Launch with console output
echo "📱 Launching NutraSafe..."
echo ""
echo "👀 Watch for this success message:"
echo "   ✅ StoreKitTest: Session initialized successfully"
echo "      - Configuration: NutraSafe.storekit"
echo "      - Mode: Local Testing (No Apple ID required)"
echo ""
echo "🔍 Console Output:"
echo "-------------------"

xcrun simctl launch --console "iPhone 17 Pro" com.nutrasafe.beta

echo ""
echo "-------------------"
echo ""
echo "📊 Next Steps:"
echo "1. If you saw the success message above, you're good!"
echo "2. In the simulator, go to Settings → 'Unlock NutraSafe Pro'"
echo "3. Tap 'Start Free Trial'"
echo "4. You should see a StoreKit dialog (NOT Apple ID sign-in)"
echo ""
echo "❌ If you saw 'StoreKitTest not found' instead:"
echo "   Run from Xcode with: ⌘ + R"
echo ""
