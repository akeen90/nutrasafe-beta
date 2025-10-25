#!/bin/bash

# Script to run NutraSafe with StoreKit testing enabled on iPhone 17 Pro
# This is the ONLY way to properly test StoreKit in the simulator

echo "🚀 Opening Xcode with NutraSafe project..."
open "/Users/aaronkeen/Documents/My Apps/NutraSafe/NutraSafeBeta.xcodeproj"

echo ""
echo "✅ Xcode is opening!"
echo ""
echo "📱 Next steps:"
echo "   1. Wait for Xcode to fully load"
echo "   2. At the top of Xcode, select:"
echo "      - Scheme: 'NutraSafe Beta'"
echo "      - Destination: 'iPhone 17 Pro'"
echo "   3. Press ⌘ + R (or click the ▶️ Play button)"
echo ""
echo "🛒 To test StoreKit purchases:"
echo "   1. Once app launches, tap Settings (gear icon)"
echo "   2. Scroll to 'Premium Subscription'"
echo "   3. Tap 'Unlock NutraSafe Pro'"
echo "   4. Tap 'Start Free Trial' (£1.99/month with 1 week free)"
echo "   5. Complete the test purchase"
echo ""
echo "🔍 To view test transactions:"
echo "   In Xcode: Debug → StoreKit → Manage Transactions"
echo ""
echo "⚠️  Important: StoreKit testing ONLY works when running from Xcode!"
echo "   Running via 'simctl launch' will NOT load the StoreKit configuration."
echo ""
