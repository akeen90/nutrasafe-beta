# Firebase-First Database Fix Implementation

## Problem Identified

The v1 admin dashboard's database check feature and all bulk fix functions were updating **Algolia directly** instead of updating **Firebase first** (the source of truth).

This caused fixes to **keep reverting** because:

1. User makes fix → Updates Algolia → Fix appears to work
2. Firebase still has old data
3. Firebase triggers automatic sync to Algolia
4. Algolia gets overwritten with old data → **Fix reverts**

## Solution

Implemented a **Firebase-first approach** that updates Firebase (source of truth) first, then syncs to Algolia:

```
✅ NEW FLOW:
User makes fix → Update Firebase → Sync to Algolia → Both stay in sync permanently
```

## Functions Updated

### 1. **batchUpdateFoodsWithFirebase** (NEW)
- Created new Cloud Function for batch updates
- Handles both Firebase-backed indices and Algolia-only indices
- Used by admin dashboard for individual saves and bulk "Apply All Changes"

### 2. **fixKjKcalCombinedCalories**
- Fixes kJ+kcal combined calorie values
- Now updates Firebase first, then syncs to Algolia
- Prevents fixes from reverting

### 3. **fixSimpleIngredients**
- Adds missing ingredients for simple foods
- Now uses Firebase-first approach
- Permanent fixes

### 4. **fixHtmlCode**
- Removes HTML tags from food names/brands/ingredients
- Now uses Firebase-first approach
- Permanent fixes

### 5. **rescanProducts**
- Re-fetches fresh data from Tesco API
- Now uses Firebase-first approach
- Permanent updates

## Implementation Details

### Helper Function

Created `applyBatchUpdatesFirebaseFirst()` helper that:

- Detects if index is Algolia-only or Firebase-backed
- For **Algolia-only** indices (`uk_foods_cleaned`, `fast_foods_database`, `generic_database`):
  - Updates Algolia directly (no Firebase)
- For **Firebase-backed** indices (`tesco_products`, `verified_foods`, etc.):
  - Updates Firebase in batches (500 items per Firestore batch limit)
  - Then syncs to Algolia (1000 items per batch)
  - Adds `updatedAt` timestamp to track changes

### Index Mapping

```typescript
const INDEX_TO_COLLECTION = {
  'verified_foods': 'verifiedFoods',
  'foods': 'foods',
  'manual_foods': 'manualFoods',
  'user_added': 'userAdded',
  'ai_enhanced': 'aiEnhanced',
  'ai_manually_added': 'aiManuallyAdded',
  'tescoProducts': 'tesco_products',
  'tesco_products': 'tesco_products',
};
```

## Files Changed

1. **firebase/functions/src/scan-database.ts**
   - Added `applyBatchUpdatesFirebaseFirst()` helper
   - Added `batchUpdateFoodsWithFirebase` function
   - Updated `fixKjKcalCombinedCalories`
   - Updated `fixSimpleIngredients`
   - Updated `fixHtmlCode`
   - Updated `rescanProducts`

2. **firebase/functions/src/index.ts**
   - Exported `batchUpdateFoodsWithFirebase`

3. **firebase/public/admin.html**
   - Line 7145: Individual saves now call `batchUpdateFoodsWithFirebase`
   - Line 10243: Bulk "Apply All Changes" now calls `batchUpdateFoodsWithFirebase`

## Deployment Status

✅ All functions deployed successfully:
- `batchUpdateFoodsWithFirebase` - DEPLOYED
- `fixKjKcalCombinedCalories` - UPDATED
- `fixSimpleIngredients` - UPDATED
- `fixHtmlCode` - UPDATED
- `rescanProducts` - UPDATED

✅ Admin dashboard updated and deployed

## Testing

To verify the fix works:

1. Use the database check feature to fix a kJ/kcal issue
2. Wait 1-2 minutes for Firebase sync
3. Re-scan the same index
4. **Expected**: Fix should still be there (not reverted)

## Impact

**Before**: All database fixes were temporary and would revert
**After**: All database fixes are permanent and sync correctly between Firebase and Algolia

This fixes the critical bug where:
- kJ+kcal calorie fixes kept coming back
- HTML code removals reverted
- Ingredient additions disappeared
- Any manual edits were lost after sync
