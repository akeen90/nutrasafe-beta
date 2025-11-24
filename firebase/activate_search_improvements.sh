#!/bin/bash

# Activate Algolia Search Improvements
# This script applies custom ranking settings to all Algolia indices

echo "🚀 Activating Algolia Search Improvements..."
echo ""
echo "This will configure custom ranking rules to ensure:"
echo "  - 'apple' returns before 'applewood'"
echo "  - 'costa' finds 'costa coffee'"
echo "  - Exact matches prioritized over substring matches"
echo ""

# Call the configureAlgoliaIndices function
echo "📋 Configuring Algolia indices..."
firebase functions:call configureAlgoliaIndices --project nutrasafe-705c7

echo ""
echo "✅ Configuration complete!"
echo ""
echo "📝 Next steps:"
echo "1. Test search in your iOS app:"
echo "   - Search for 'apple' - should show 'Apple' before 'Applewood'"
echo "   - Search for 'costa' - should show 'Costa Coffee'"
echo "2. All future food syncs will automatically use the new ranking"
echo "3. Optional: Re-import existing foods to add nameLength/isGeneric attributes"
echo ""
echo "🔗 Search endpoint: https://searchfoodsalgolia-77s4azufda-uc.a.run.app"
