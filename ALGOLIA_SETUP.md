# Algolia Integration Setup Guide

## Overview
Algolia provides lightning-fast, typo-tolerant search across all your food databases. This integration replaces the slower SQLite local search with instant cloud-based search.

## ✅ Completed Setup

### 1. Firebase Functions (Backend)
- ✅ Installed Algolia SDK (`algoliasearch@5.44.0`)
- ✅ Secured Admin API Key in Firebase Secrets (never in code!)
- ✅ Created automatic sync functions:
  - `syncVerifiedFoodToAlgolia` - Syncs verified foods
  - `syncFoodToAlgolia` - Syncs regular foods
  - `syncManualFoodToAlgolia` - Syncs user-added foods
- ✅ Created search endpoint: `searchFoodsAlgolia`
- ✅ Created bulk import function: `bulkImportFoodsToAlgolia`

### 2. iOS App (AlgoliaManager)
- ✅ Created `AlgoliaManager.swift` with search capabilities
- ✅ Search-Only API Key embedded (safe to expose in app)
- ✅ Created `AlgoliaFood` model for search results

## 📋 Next Steps

### Step 1: Add Algolia Swift SDK to Xcode

1. Open `NutraSafeBeta.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select "NutraSafe Beta" target
4. Go to "Package Dependencies" tab
5. Click the **+** button
6. Enter URL: `https://github.com/algolia/algoliasearch-client-swift`
7. Click "Add Package"
8. Select "AlgoliaSearchClient" product
9. Click "Add Package"

### Step 2: Import Initial Data to Algolia

Run this command in Firebase Console or through a Cloud Function caller:

\`\`\`javascript
// Call the bulk import function to populate Algolia indices
firebase functions:call bulkImportFoodsToAlgolia
\`\`\`

Or use the Firebase Console → Functions → `bulkImportFoodsToAlgolia` → Test

This will index all existing foods into Algolia.

### Step 3: Retry Failed Firestore Triggers

The following functions failed to deploy due to Eventarc permissions (needs a few minutes):

\`\`\`bash
cd firebase/functions
firebase deploy --only functions:syncVerifiedFoodToAlgolia,functions:syncFoodToAlgolia,functions:syncManualFoodToAlgolia
\`\`\`

These enable automatic syncing when foods are added/updated/deleted in Firebase.

### Step 4: Update Search Functionality

Replace SQLite search calls with Algolia in:
- `FoodTabViews.swift` - Main search
- `BarcodeScanningViews.swift` - Barcode search
- Any other search interfaces

Example usage:

\`\`\`swift
import AlgoliaSearchClient

class SomeView: View {
    @StateObject private var algoliaManager = AlgoliaManager()
    @State private var searchResults: [AlgoliaFood] = []

    func performSearch() {
        Task {
            do {
                searchResults = try await algoliaManager.searchFoods(query: "chicken")
            } catch {
                print("Search error: \\(error)")
            }
        }
    }
}
\`\`\`

## 🔑 API Keys (Secured)

### Firebase Functions (Server-Side)
- **Admin API Key**: Stored in Firebase Secrets
  - Access via: `defineSecret("ALGOLIA_ADMIN_API_KEY")`
  - **Never** commit to git
  - Used for: Writing/updating Algolia indices

### iOS App (Client-Side)
- **Search-Only API Key**: `577cc4ee3fed660318917bbb54abfb2e`
  - Safe to expose in client code
  - Used for: Read-only search queries
  - No ability to modify indices

## 📊 Algolia Indices

### Index Structure
1. **`verified_foods`** - Curated, verified food database
2. **`foods`** - Community/OpenFoodFacts foods
3. **`manual_foods`** - User-added custom foods

### Searchable Attributes
- Food name
- Brand name
- Ingredients list
- Barcode

### Filterable Attributes
- Calories, protein, carbs, fat, fiber, sugar, sodium
- Category, source, verified status
- Allergens, additives
- Nutrition grade, score

## 🎯 Search Features

### Basic Search
\`\`\`swift
let foods = try await algoliaManager.searchFoods(query: "chocolate")
\`\`\`

### Autocomplete
\`\`\`swift
let suggestions = try await algoliaManager.autocomplete(query: "choc")
\`\`\`

### Barcode Search
\`\`\`swift
let food = try await algoliaManager.searchByBarcode("5000112637588")
\`\`\`

### Filtered Search
\`\`\`swift
// High protein, low carb foods
let foods = try await algoliaManager.searchWithFilters(
    query: "chicken",
    minProtein: 20,
    maxCarbs: 10,
    verified: true
)
\`\`\`

## 🔄 Data Synchronization

### Automatic (After Firestore Triggers Deploy)
Algolia indices automatically sync when:
- New food added to Firebase → Added to Algolia
- Food updated in Firebase → Updated in Algolia
- Food deleted from Firebase → Deleted from Algolia

### Manual Sync
Re-run bulk import to refresh all data:
\`\`\`bash
firebase functions:call bulkImportFoodsToAlgolia
\`\`\`

## 🎨 Migration from SQLite

### Phase 1: Parallel Running (Recommended)
- Keep SQLite for local offline fallback
- Use Algolia as primary search when online
- Compare results during testing

### Phase 2: Full Migration
Once confident in Algolia:
1. Remove SQLite database initialization
2. Remove local search code
3. Update all search calls to use `AlgoliaManager`
4. Keep SQLite schema for other app features (diary, etc.)

## 📝 Notes

- **No API keys in git**: All secrets secured via Firebase or gitignored
- **Search-Only key safe**: The iOS API key can only search, not modify data
- **Fast search**: Algolia provides results in ~20ms globally
- **Typo tolerance**: Algolia handles misspellings automatically
- **Scalable**: Handles millions of records efficiently

## 🔗 Resources

- [Algolia Dashboard](https://www.algolia.com/apps/WK0TIF84M2)
- [Algolia Swift Client Docs](https://www.algolia.com/doc/api-client/getting-started/install/swift/)
- [Firebase Functions Logs](https://console.firebase.google.com/project/nutrasafe-705c7/functions/logs)

---

**Status**: ✅ Backend deployed | ⏳ Waiting for iOS SDK integration
