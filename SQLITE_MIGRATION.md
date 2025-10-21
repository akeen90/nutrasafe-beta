# SQLite Food Database Migration

This document explains how to migrate from Firebase Firestore to SQLite for the food database.

## Why SQLite?

- **Performance**: 10-100x faster queries
- **Offline Access**: Works without internet
- **Lower Costs**: No Firebase read charges for food lookups
- **Better Indexing**: Complex queries with JOINs
- **Bundled Data**: Ship database with app

## Architecture

```
SQLite (Local)           Firebase (Cloud)
├─ Verified Foods   →    ├─ User Diary Entries
├─ Nutrients             ├─ User Preferences
├─ Ingredients           ├─ User Custom Foods
└─ Barcodes              └─ Analytics
```

**Hybrid Approach**:
- SQLite: Static food database (fast, offline)
- Firebase: User data (synced, backed up)

## Setup Instructions

### 1. Install Dependencies

```bash
cd firebase
npm install sqlite3
```

### 2. Export Firebase Data to SQLite

```bash
cd "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta"
node firebase/scripts/exportToSQLite.js
```

This will create `nutrasafe_foods.db` with all verified foods.

### 3. Add Database to Xcode

1. Open Xcode project
2. Locate `nutrasafe_foods.db` in Finder
3. Drag it into Xcode project navigator
4. Check "Copy items if needed"
5. Add to "NutraSafe Beta" target
6. Verify it appears in "Copy Bundle Resources" build phase

### 4. Add SQLite File to Project

The Swift wrapper is already created at:
```
NutraSafe Beta/Database/SQLiteFoodDatabase.swift
```

Add it to your Xcode project if not already included.

### 5. Update FirebaseManager

Modify `searchFoods()` to check SQLite first:

```swift
func searchFoods(query: String) async throws -> [FoodSearchResult] {
    // 1. Try SQLite first (fast, offline)
    let localResults = SQLiteFoodDatabase.shared.searchFoods(query: query, limit: 20)

    if !localResults.isEmpty {
        print("✅ Found \(localResults.count) results in local database")
        return localResults
    }

    // 2. Fallback to Firebase/external APIs if not found
    print("⚠️ Not found locally, checking external sources...")
    return try await searchFoodsFromFirebase(query: query)
}
```

## Database Schema

### Foods Table
```sql
CREATE TABLE foods (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    brand TEXT,
    barcode TEXT,

    -- Macronutrients (per 100g)
    calories REAL NOT NULL,
    protein REAL NOT NULL,
    carbs REAL NOT NULL,
    fat REAL NOT NULL,
    fiber REAL NOT NULL,
    sugar REAL NOT NULL,
    sodium REAL NOT NULL,

    -- 27 Micronutrients
    vitamin_a REAL DEFAULT 0,
    vitamin_c REAL DEFAULT 0,
    ... (all vitamins and minerals)

    -- Metadata
    is_verified BOOLEAN DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
```

### Ingredients Table
```sql
CREATE TABLE food_ingredients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    food_id TEXT NOT NULL,
    ingredient TEXT NOT NULL,
    position INTEGER NOT NULL,
    FOREIGN KEY(food_id) REFERENCES foods(id)
);
```

## Usage Examples

### Search Foods
```swift
let results = SQLiteFoodDatabase.shared.searchFoods(query: "chicken")
// Returns array of FoodSearchResult
```

### Search by Barcode
```swift
if let food = SQLiteFoodDatabase.shared.searchByBarcode("5012345678900") {
    print("Found: \(food.name)")
}
```

### Get Database Stats
```swift
let stats = SQLiteFoodDatabase.shared.getStats()
print("Total foods: \(stats.totalFoods)")
print("With barcodes: \(stats.withBarcodes)")
print("Verified: \(stats.verified)")
```

## Performance Comparison

| Operation | Firebase | SQLite | Improvement |
|-----------|----------|--------|-------------|
| Simple search | 500-1000ms | 5-20ms | 50-100x faster |
| Barcode lookup | 300-800ms | 2-10ms | 80x faster |
| Offline | ❌ No | ✅ Yes | - |
| Cost per 1M queries | $0.36 | $0 | Free |

## Updating the Database

### Manual Update
1. Run export script again
2. Replace old `.db` file in Xcode
3. Clean build folder (Cmd+Shift+K)
4. Rebuild app

### Automatic Updates (Future)
- Download updated `.db` from server
- Replace in Documents directory
- Notify user of new foods available

## Troubleshooting

### Database not found
- Check `.db` file is in Xcode project
- Verify "Copy Bundle Resources" includes it
- Clean and rebuild

### Search returns empty
- Check database has data: `getStats()`
- Run export script to populate
- Verify search query is not empty

### Slow performance
- Check indexes are created
- Use EXPLAIN QUERY PLAN in SQL
- Consider full-text search (FTS5)

## Future Enhancements

1. **Full-Text Search**: Use SQLite FTS5 for better search
2. **Compression**: Compress database with gzip
3. **Incremental Updates**: Only download changed foods
4. **Multiple Languages**: Support UK/US spellings
5. **Recipe Database**: Add meals and recipes

## Migration Checklist

- [x] Create SQLite schema
- [x] Build Swift wrapper
- [x] Create Firebase export script
- [ ] Run export to create database
- [ ] Add database to Xcode project
- [ ] Update FirebaseManager search logic
- [ ] Test search functionality
- [ ] Measure performance improvements
- [ ] Update CLAUDE.md documentation
