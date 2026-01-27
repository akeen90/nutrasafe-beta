# NutraSafe Offline Database Consolidation Plan

**Created:** 2026-01-27
**Purpose:** Comprehensive plan for implementing offline support with unified local database
**Status:** Planning Phase - Ready for Implementation

---

## 📊 Current Architecture Analysis

### Algolia Indices (9 Food Sources)
Currently searching across **9 separate Algolia indices** with priority tiers:

| Index Name | Priority | Purpose | Record Count | Source |
|-----------|----------|---------|--------------|--------|
| `consumer_foods` | 0 | Generic raw foods (highest priority) | ~5-10K | Generic DB |
| `tesco_products` | 1 | Tesco UK official products | ~10-15K | Tesco API |
| `uk_foods_cleaned` | 2 | Master UK foods database | ~72K | Master DB |
| `verified_foods` | 3 | Admin human-verified foods | ~1-5K | Admin Panel |
| `ai_enhanced` | 4 | AI-enhanced with human approval | ~500-2K | AI + Admin |
| `ai_manually_added` | 5 | AI scanner submissions | ~100-500 | AI Scanner |
| `user_added` | 6 | User custom foods (per-user) | Variable | User Input |
| `foods` | 7 | Original fallback database | ~5-10K | Legacy |
| `fast_foods_database` | 8 | Restaurant chain items | ~2-5K | Fast Food DB |

**Total Estimated Records:** ~95,000 - 120,000 foods

**Current Search Flow:**
```
User Query → Algolia Multi-Index Search (9 parallel requests)
    ↓
Merge & Deduplicate by ID
    ↓
Smart Ranking (15-stage algorithm)
    ↓
Return Top 20 Results
```

**Performance:**
- ✅ Fast: ~200-500ms for multi-index search
- ✅ Smart: Intent-aware ranking, brand synonyms, UK defaults
- ❌ Requires internet connection
- ❌ 9 separate API calls per search (even after caching)

---

### Firebase Firestore Collections (20+ Collections)

**User-Specific Collections** (per-user subcollections):
```
users/{userId}/
  ├── foodEntries/          → Daily food diary entries
  ├── favoriteFoods/        → User's favorite foods
  ├── reactions/            → Allergy/sensitivity reactions
  ├── reactionLogs/         → Detailed reaction tracking
  ├── fastingSessions/      → Active/historical fasting data
  ├── fastingPlans/         → Fasting regimes
  ├── weightHistory/        → Weight tracking over time
  ├── useByItems/           → Use-by date inventory
  ├── useByInventory/       → Legacy inventory system
  ├── safeFoods/            → Foods marked as safe
  ├── customIngredients/    → User-added ingredients
  └── settings/             → User preferences
```

**Global Collections** (shared across all users):
```
Root Level:
  ├── verifiedFoods/              → Admin-verified food database
  ├── aiEnhanced/                 → AI-enhanced foods
  ├── aiManuallyAdded/            → AI scanner foods
  ├── userAdded/                  → All user-submitted foods
  ├── pendingVerifications/       → Foods awaiting admin approval
  ├── submittedFoods/             → User submissions queue
  ├── incomplete_foods/           → Flagged incomplete data
  ├── userEnhancedProductData/    → User-contributed product info
  └── ingredientCache/            → Cached ingredient analysis
```

**Current Firebase Flow:**
```
App Launch → Firebase Auth → Load User Profile
    ↓
Fetch Diary Entries (last 30 days) → Cache in DiaryDataManager
    ↓
Fetch Allergens → Cache (5 min expiration)
    ↓
Fetch Weight History → Cache
```

**Performance:**
- ✅ Good: Firestore has offline persistence enabled (100 MB cache)
- ✅ Auto-sync: Writes queue and sync when online
- ❌ Dairy entries cached for 10 min only (too short for offline)
- ❌ User data works offline, but food search doesn't

---

### Local Storage (UserDefaults & Memory Cache)

**UserDefaults Keys (Current)**:
- `diary_*` → Daily food entries (per-date keys)
- `recentFoods` → Last searched/added foods
- `clientVerifiedFoods` → Client-side verified items
- `localUseByItems` → Use-by inventory
- `hydrationData` → Water intake tracking
- `hasCompletedOnboarding` → Onboarding state
- `cachedDietType`, `cachedProteinGoal`, etc. → User goals
- `nutrient_cache_last_updated` → Cache timestamps

**In-Memory Caches:**
- `DiaryDataManager` → Food entries by date (100 dates max)
- `FirebaseManager.searchCache` → Algolia search results (5 min, 100 queries)
- `FirebaseManager.foodEntriesCache` → Firebase food entries (10 min, 100 dates)
- `AlgoliaSearchManager.searchCache` → Search results (5 min, 100 queries)

**Current Storage Strategy:**
- Short-term caching (5-10 min)
- LRU eviction for memory management
- No persistent food database

---

## 🎯 Goal: Unified Offline Database

### Vision
**Single SQLite database** containing all food data, synced automatically in background.

```
┌─────────────────────────────────────────────────┐
│         NutraSafe Unified Database              │
│              (nutrasafe.sqlite)                 │
└─────────────────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
   ┌────────┐   ┌────────┐   ┌──────────┐
   │ Foods  │   │ Diary  │   │ User Data│
   │ Table  │   │ Table  │   │ Tables   │
   └────────┘   └────────┘   └──────────┘
        │             │             │
        └─────────────┴─────────────┘
                      │
           Automatic Background Sync
                      │
        ┌─────────────┴─────────────┐
        ▼                           ▼
   ┌────────┐                 ┌──────────┐
   │Algolia │                 │ Firebase │
   │Indices │                 │Firestore │
   └────────┘                 └──────────┘
```

**Benefits:**
- ✅ Full offline functionality (search, log, view history)
- ✅ Faster search (local SQLite < 50ms vs Algolia ~300ms)
- ✅ Lower server costs (90% fewer Algolia API calls)
- ✅ Competitive advantage (MyFitnessPal/Nutracheck fail offline)
- ✅ Better UX (instant results, no loading spinners)

---

## 🔒 Privacy & Data Isolation Model

### CRITICAL: What's Stored Where

**Public Data (Shared Across All Users):**
```
┌─────────────────────────────────────────────────┐
│        Food Database (~150 MB)                  │
│        SAME for ALL users                       │
├─────────────────────────────────────────────────┤
│ ✅ 100,000 foods (nutritional facts)            │
│ ✅ Ingredients, barcodes, nutrition data         │
│ ✅ Product images (URLs only)                    │
│                                                   │
│ ❌ NO user_id column (public reference data)    │
│ ❌ NOT personal data (like Wikipedia)           │
└─────────────────────────────────────────────────┘
```

**Private Data (Per-User, Isolated):**
```
┌─────────────────────────────────────────────────┐
│        User Data (~5 MB per user)               │
│        ONLY current user's data                 │
├─────────────────────────────────────────────────┤
│ ✅ Diary entries (what THEY ate)                │
│ ✅ Favorite foods (THEIR favorites)             │
│ ✅ Reactions/sensitivities (THEIR health data)  │
│ ✅ Weight history (THEIR weight)                │
│ ✅ Fasting sessions (THEIR fasting)             │
│ ✅ Use-by items (THEIR inventory)               │
│                                                   │
│ ✅ ALL rows have user_id column (filtered!)     │
│ ✅ Personal data (GDPR protected)               │
└─────────────────────────────────────────────────┘
```

### Storage on Device

**User A's iPhone:**
```
150 MB   Foods Database (public, shared)
+  5 MB   User A's Data (private, filtered by user_id='userA')
──────
155 MB   Total
```

**Shared iPad (Multiple Users):**
```
Before: User A signed in
  150 MB   Foods Database
  +  5 MB   User A's Data
  = 155 MB Total

User A signs out → Clear User A's data

After: User B signs in
  150 MB   Foods Database (stays, it's public)
  +  5 MB   User B's Data (downloaded from Firebase)
  = 155 MB Total

✅ User B NEVER sees User A's diary
✅ Food database is shared (public info)
```

### Query Privacy Enforcement

**Every user data query MUST filter by user_id:**

```swift
// ❌ WRONG - Would expose all users' data
let allEntries = try db.query("SELECT * FROM diary_entries")

// ✅ CORRECT - Only current user's data
let myEntries = try db.query(
    "SELECT * FROM diary_entries WHERE user_id = ?",
    [currentUserId]
)

// ✅ CORRECT - Food search (no user_id filter, it's public)
let foods = try db.query(
    "SELECT * FROM foods WHERE name MATCH ?",
    [searchQuery]
)
```

### Sign Out Behavior

```swift
func signOut() async {
    // 1. Clear user-specific data from local DB
    try localDB.deleteAllData(userId: currentUserId)
    // Deletes from: diary_entries, favorite_foods, reactions,
    //               weight_history, use_by_items, etc.

    // 2. Food database STAYS (it's public data)
    // Don't delete foods table

    // 3. Clear Firebase cached auth
    try await FirebaseManager.shared.signOut()

    print("✅ User data cleared, food database preserved")
}
```

### GDPR Compliance

**Data Minimization:**
- ✅ Store only public food data (nutritional facts)
- ✅ Store only current user's personal data
- ✅ No access to other users' data

**Right to Erasure:**
```swift
func deleteAccount() async throws {
    // 1. Delete from Firebase (source of truth)
    try await firebase.deleteAllUserData(userId: currentUserId)

    // 2. Delete from local device
    try localDB.deleteAllUserData(userId: currentUserId)

    // 3. Food database stays (public, not personal data)
    // Foods table is NOT covered by "right to erasure"
    // It's like deleting Wikipedia from a dictionary app

    print("✅ User account deleted (personal data removed)")
}
```

**Data Portability:**
- User can export their diary as CSV/JSON
- Food database is not "their data" (public reference)

### Multi-User Device Support

**Example: Family iPad**

```
┌─────────────────────────────────────────────────┐
│              Shared iPad                        │
├─────────────────────────────────────────────────┤
│ Foods Database:     150 MB  (once, for everyone)│
│ Alice's Data:         5 MB  (when Alice logs in)│
│ Bob's Data:           5 MB  (when Bob logs in)  │
│ Carol's Data:         5 MB  (when Carol logs in)│
├─────────────────────────────────────────────────┤
│ Total:              165 MB                       │
└─────────────────────────────────────────────────┘

Privacy guarantees:
✅ Alice only sees Alice's diary
✅ Bob only sees Bob's diary
✅ Carol only sees Carol's diary
✅ All share same food database (public info)
```

### Database Schema Privacy

**Foods Table (NO user_id):**
```sql
CREATE TABLE foods (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    calories REAL NOT NULL,
    -- NO user_id column → public data
);
```

**Diary Table (WITH user_id):**
```sql
CREATE TABLE diary_entries (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,  -- ← CRITICAL: filters to current user
    food_id TEXT,
    calories INTEGER NOT NULL,
    date INTEGER NOT NULL,

    INDEX idx_user_date ON diary_entries(user_id, date DESC)
);
```

**Favorite Foods Table (WITH user_id):**
```sql
CREATE TABLE favorite_foods (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,  -- ← CRITICAL: filters to current user
    food_id TEXT NOT NULL,

    INDEX idx_user ON favorite_foods(user_id)
);
```

### Security Best Practices

**1. Always Use Parameterized Queries:**
```swift
// ✅ SAFE - prevents SQL injection
let entries = try db.query(
    "SELECT * FROM diary_entries WHERE user_id = ?",
    [currentUserId]
)

// ❌ UNSAFE - SQL injection risk
let entries = try db.query(
    "SELECT * FROM diary_entries WHERE user_id = '\(currentUserId)'"
)
```

**2. Validate User ID on Every Query:**
```swift
func getDiaryEntries(date: Date) throws -> [DiaryEntry] {
    guard let userId = Auth.shared.currentUserId else {
        throw DatabaseError.notAuthenticated
    }

    return try db.query(
        "SELECT * FROM diary_entries WHERE user_id = ? AND date = ?",
        [userId, date]
    )
}
```

**3. Clear Data on Sign Out:**
```swift
func signOut() {
    // CRITICAL: Must clear all user-specific tables
    let userTables = [
        "diary_entries",
        "favorite_foods",
        "reactions",
        "weight_history",
        "use_by_items",
        "fasting_sessions"
    ]

    for table in userTables {
        try? db.execute(
            "DELETE FROM \(table) WHERE user_id = ?",
            [currentUserId]
        )
    }
}
```

---

## 🗄️ SQLite Database Schema

### Table: `foods`
**Purpose:** Unified food database (all 9 Algolia indices merged)

```sql
CREATE TABLE foods (
    -- Identity
    id TEXT PRIMARY KEY,                    -- Unique food ID
    source TEXT NOT NULL,                   -- Origin: consumer_foods, tesco_products, etc.
    source_priority INTEGER NOT NULL,       -- 0=highest, 8=lowest (for dedup)

    -- Core Info
    name TEXT NOT NULL,                     -- Food name (indexed for search)
    brand TEXT,                             -- Brand name (nullable for generic foods)
    barcode TEXT,                           -- EAN-13 or UPC-A barcode
    gtin TEXT,                              -- GTIN-14 (Tesco format)

    -- Nutrition (per 100g or per serving)
    calories REAL NOT NULL,
    protein REAL NOT NULL,
    carbs REAL NOT NULL,
    fat REAL NOT NULL,
    saturated_fat REAL,
    fiber REAL,
    sugar REAL,
    sodium REAL,

    -- Serving Info
    serving_size_g REAL,                    -- Serving size in grams
    serving_description TEXT,               -- "1 can (330ml)", "1 bar (51g)"
    is_per_unit INTEGER DEFAULT 0,          -- Boolean: per-unit vs per-100g

    -- Portions (JSON array for multi-size items)
    portions TEXT,                          -- JSON: [{"name":"6pc","calories":300,"serving_g":100}]

    -- Extended Data
    ingredients TEXT,                       -- Comma-separated or JSON array
    additives TEXT,                         -- JSON array of additive objects
    micronutrients TEXT,                    -- JSON micronutrient profile

    -- Metadata
    image_url TEXT,                         -- Product image URL
    image_quality TEXT,                     -- "flagged", "verified", null
    is_verified INTEGER DEFAULT 0,          -- Admin-verified flag
    is_fast_food INTEGER DEFAULT 0,         -- Restaurant chain flag

    -- Search Optimization
    search_tokens TEXT NOT NULL,            -- Lowercased searchable text: "mars bar chocolate"

    -- Sync
    last_updated INTEGER NOT NULL,          -- Unix timestamp
    sync_version INTEGER NOT NULL,          -- Database version number

    -- Indexes for fast queries
    INDEX idx_name ON foods(name COLLATE NOCASE),
    INDEX idx_barcode ON foods(barcode),
    INDEX idx_gtin ON foods(gtin),
    INDEX idx_search ON foods(search_tokens),
    INDEX idx_source_priority ON foods(source_priority, name)
);
```

**Estimated Size (Shared Public Data):**
- 100,000 foods × ~2 KB average = **~200 MB** (uncompressed)
- SQLite with compression: **~100-150 MB**
- With images cached: **+50-100 MB** (optional)

**Storage Model:**
- ✅ Downloaded ONCE per device
- ✅ Shared by all users on device
- ✅ NOT deleted when user signs out
- ✅ Public nutritional data (like Wikipedia)

---

### Table: `diary_entries`
**Purpose:** User's food diary (Firebase `foodEntries` cached locally)

```sql
CREATE TABLE diary_entries (
    -- Identity
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,

    -- Food Reference
    food_id TEXT,                           -- Reference to foods.id (if from database)
    food_name TEXT NOT NULL,                -- Food name (stored for custom foods)
    brand_name TEXT,

    -- Nutrition (stored denormalized for offline viewing)
    calories INTEGER NOT NULL,
    protein REAL NOT NULL,
    carbs REAL NOT NULL,
    fat REAL NOT NULL,
    fiber REAL,
    sugar REAL,
    sodium REAL,

    -- Serving Info
    serving_description TEXT NOT NULL,
    quantity REAL NOT NULL DEFAULT 1.0,

    -- Meal Context
    meal_type TEXT NOT NULL,                -- "Breakfast", "Lunch", "Dinner", "Snacks"
    date INTEGER NOT NULL,                  -- Unix timestamp (day start)
    date_logged INTEGER NOT NULL,           -- Unix timestamp (actual log time)

    -- Extended Data
    ingredients TEXT,                       -- JSON array
    barcode TEXT,
    image_url TEXT,
    portions TEXT,                          -- JSON array

    -- Sync
    is_synced INTEGER DEFAULT 0,            -- 0=pending upload, 1=synced
    modified_at INTEGER NOT NULL,           -- Unix timestamp

    -- Indexes
    INDEX idx_user_date ON diary_entries(user_id, date DESC),
    INDEX idx_user_meal ON diary_entries(user_id, meal_type),
    INDEX idx_sync ON diary_entries(is_synced, modified_at)
);
```

**Estimated Size (Per-User Private Data):**
- 1000 diary entries × ~1 KB = **~1 MB** per user
- Most users: **<5 MB** for 1 year of data

**Storage Model:**
- ✅ Filtered by `user_id` (current user only)
- ✅ Deleted when user signs out
- ✅ Re-downloaded when user signs back in
- ✅ Private personal data (GDPR protected)

---

### Table: `favorite_foods`
**Purpose:** User's favorite foods for quick access

```sql
CREATE TABLE favorite_foods (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,                  -- ← FILTERS to current user
    food_id TEXT NOT NULL,                  -- Reference to foods.id
    food_name TEXT NOT NULL,                -- Denormalized for offline
    brand TEXT,
    added_at INTEGER NOT NULL,              -- Unix timestamp
    access_count INTEGER DEFAULT 0,         -- Usage frequency

    INDEX idx_user ON favorite_foods(user_id, added_at DESC),
    INDEX idx_food ON favorite_foods(food_id)
);
```

**Storage Model:**
- ✅ Per-user private data
- ✅ Filtered by `user_id`
- ✅ Deleted on sign out
- ✅ Size: ~50-200 KB per user (20-100 favorites)

---

### Table: `sync_state`
**Purpose:** Track sync status and versions

```sql
CREATE TABLE sync_state (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at INTEGER NOT NULL
);

-- Stored keys:
-- 'db_version' → Current local database version (e.g., "142")
-- 'last_full_sync' → Timestamp of last complete database download
-- 'last_delta_sync' → Timestamp of last incremental update
-- 'pending_uploads' → Count of unsynced diary entries
```

---

## 🔄 Sync Strategy: Smart Hybrid Approach

### Phase 1: Initial Setup (First App Launch)

**Bundle Pre-Seeded Database** (~100 MB with app):
```
NutraSafe Beta/
  Resources/
    nutrasafe_v1.sqlite  ← Pre-populated with 100K foods
```

**On First Launch:**
1. Copy bundled DB to Documents directory
2. Set `db_version` = bundled version (e.g., "1")
3. App is immediately usable offline
4. Background: Check for updates (non-blocking)

**Why Bundle?**
- ✅ Instant offline functionality (no download wait)
- ✅ Better first impression (app works immediately)
- ✅ Reduces server load (no 100K initial downloads)
- ❌ Larger app download (~30 MB → ~130 MB)

**Alternative: On-Demand Download**
- Show "Setting up database..." on first launch
- Download compressed DB (~50 MB with gzip)
- Decompress to SQLite (~100 MB)
- Takes ~30 seconds on WiFi, ~2 min on cellular

**Recommendation:** Bundle for production, on-demand for TestFlight

---

### Phase 2: Incremental Delta Sync (Daily/Weekly)

**Delta Sync API Endpoint:**
```typescript
// Firebase Cloud Function
export const getFoodDatabaseDelta = functions.https.onRequest(async (req, res) => {
  const sinceVersion = parseInt(req.query.since as string);
  const currentVersion = await getCurrentDatabaseVersion();

  if (sinceVersion >= currentVersion) {
    return res.json({
      hasUpdates: false,
      version: currentVersion
    });
  }

  // Get all changes since sinceVersion
  const added = await getAddedFoods(sinceVersion);
  const modified = await getModifiedFoods(sinceVersion);
  const deleted = await getDeletedFoods(sinceVersion);

  res.json({
    hasUpdates: true,
    version: currentVersion,
    added,      // Array of new food objects
    modified,   // Array of updated food objects
    deleted,    // Array of food IDs to remove
    deltaSize: added.length + modified.length + deleted.length
  });
});
```

**Client-Side Delta Sync:**
```swift
func syncDatabaseIfNeeded() async throws {
    guard NetworkMonitor.shared.isConnected else { return }

    let localVersion = localDB.getVersion()
    let remoteVersion = try await api.getCurrentVersion()

    guard remoteVersion > localVersion else {
        print("✅ Database up to date (v\(localVersion))")
        return
    }

    print("📥 Syncing database from v\(localVersion) to v\(remoteVersion)")

    // If gap is small (< 20 versions), use delta sync
    if remoteVersion - localVersion < 20 {
        let delta = try await api.getDelta(since: localVersion)

        try localDB.beginTransaction()

        // Apply changes
        for food in delta.added {
            try localDB.insertFood(food)
        }
        for food in delta.modified {
            try localDB.updateFood(food)
        }
        for foodId in delta.deleted {
            try localDB.deleteFood(foodId)
        }

        localDB.setVersion(remoteVersion)
        try localDB.commitTransaction()

        print("✅ Delta sync complete: +\(delta.added.count) ~\(delta.modified.count) -\(delta.deleted.count)")
    }
    // Large gap → full database download (corrupted or way behind)
    else {
        try await downloadFullDatabase()
    }
}
```

**Sync Triggers:**
1. **App Launch** (if WiFi + 24 hours since last check)
2. **Background Refresh** (iOS wakes app periodically)
3. **Manual Refresh** (settings button)
4. **After Admin Dashboard Updates** (push notification → sync)

**Sync Frequency:**
- **Production:** Weekly (database updates infrequent)
- **Beta:** Daily (more frequent admin changes)
- **Dev:** On-demand only

---

### Phase 3: Diary Entry Sync (Bidirectional)

**Upload Queue (Offline → Firebase):**
```swift
func saveDiaryEntry(_ entry: DiaryFoodItem) async throws {
    // Save to local DB immediately
    try localDB.insertDiaryEntry(entry, synced: false)

    // Update UI instantly (no wait for server)
    await MainActor.run {
        diaryEntries.append(entry)
    }

    // Queue for upload
    if NetworkMonitor.shared.isConnected {
        try await uploadDiaryEntry(entry)
    } else {
        print("📤 Queued for upload when online")
    }
}

func syncPendingUploads() async throws {
    guard NetworkMonitor.shared.isConnected else { return }

    let pending = try localDB.getPendingUploads()
    guard !pending.isEmpty else { return }

    print("📤 Uploading \(pending.count) pending entries...")

    for entry in pending {
        do {
            try await FirebaseManager.shared.saveFoodEntry(entry)
            try localDB.markAsSynced(entry.id)
        } catch {
            print("❌ Failed to upload \(entry.id): \(error)")
            // Keep in queue for retry
        }
    }
}
```

**Download Changes (Firebase → Local):**
```swift
func syncDiaryFromFirebase() async throws {
    guard NetworkMonitor.shared.isConnected else { return }

    let lastSync = UserDefaults.standard.double(forKey: "last_diary_sync")
    let entries = try await FirebaseManager.shared.getFoodEntriesSince(lastSync)

    for entry in entries {
        // Merge with local DB (Firebase is source of truth)
        try localDB.upsertDiaryEntry(entry, synced: true)
    }

    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "last_diary_sync")
}
```

**Conflict Resolution:**
- **Last Write Wins** (Firebase timestamp is source of truth)
- User edits same entry on phone + iPad → Last edit wins
- Rare edge case, acceptable for diary app

---

## 🔍 Search Implementation: Offline-First

### Search Flow (Unified)

```swift
func searchFood(_ query: String) async throws -> [FoodSearchResult] {
    // ALWAYS search local database first (instant results)
    let localResults = try localDB.search(query, limit: 20)

    // If online, also check Algolia for newer items
    if NetworkMonitor.shared.isConnected {
        do {
            let remoteResults = try await AlgoliaSearchManager.shared.search(query: query)

            // Merge: Local + Remote (deduplicate by ID)
            var merged = localResults
            var seenIds = Set(localResults.map { $0.id })

            for result in remoteResults where !seenIds.contains(result.id) {
                merged.append(result)
            }

            // Re-rank merged results
            return rankResults(merged, query: query)
        } catch {
            print("⚠️ Algolia failed, using local only")
            return localResults
        }
    }

    // Offline: return local results only
    return localResults
}
```

### SQLite Full-Text Search (FTS5)

**Create FTS Virtual Table:**
```sql
-- Full-text search index for blazing fast queries
CREATE VIRTUAL TABLE foods_fts USING fts5(
    id UNINDEXED,           -- Food ID (not searchable)
    name,                   -- Searchable: food name
    brand,                  -- Searchable: brand name
    search_tokens,          -- Searchable: preprocessed tokens
    content=foods,          -- Content comes from foods table
    content_rowid=rowid
);

-- Triggers to keep FTS in sync with foods table
CREATE TRIGGER foods_ai AFTER INSERT ON foods BEGIN
  INSERT INTO foods_fts(rowid, id, name, brand, search_tokens)
  VALUES (new.rowid, new.id, new.name, new.brand, new.search_tokens);
END;

CREATE TRIGGER foods_ad AFTER DELETE ON foods BEGIN
  DELETE FROM foods_fts WHERE rowid = old.rowid;
END;

CREATE TRIGGER foods_au AFTER UPDATE ON foods BEGIN
  DELETE FROM foods_fts WHERE rowid = old.rowid;
  INSERT INTO foods_fts(rowid, id, name, brand, search_tokens)
  VALUES (new.rowid, new.id, new.name, new.brand, new.search_tokens);
END;
```

**Search Query (SQLite):**
```swift
func search(_ query: String, limit: Int) throws -> [FoodSearchResult] {
    let sanitized = query
        .replacingOccurrences(of: "\"", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)

    // FTS5 match query with prefix matching
    let sql = """
        SELECT f.* FROM foods f
        JOIN foods_fts fts ON f.rowid = fts.rowid
        WHERE foods_fts MATCH ?
        ORDER BY rank, f.source_priority, f.name
        LIMIT ?
    """

    let stmt = try db.prepare(sql)
    let results = try stmt.run(["\(sanitized)*", limit])

    return results.map { row in
        FoodSearchResult(from: row)
    }
}
```

**Performance:**
- SQLite FTS5: **10-50ms** per query
- Algolia: **200-500ms** per query
- **4-10x faster** for local search

---

## 📱 User Experience Design

### Offline Indicator (UI)

**Top Banner (Subtle):**
```swift
struct OfflineBanner: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    var body: some View {
        if !networkMonitor.isConnected {
            HStack {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.orange)
                Text("Offline - changes will sync when connected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
}
```

**Sync Status (Settings Screen):**
```swift
HStack {
    VStack(alignment: .leading) {
        Text("Food Database")
            .font(.headline)
        if let lastSync = lastSyncDate {
            Text("Updated \(lastSync.timeAgoDisplay())")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    Spacer()
    if isSyncing {
        ProgressView()
    } else {
        Button("Check Now") {
            Task { await syncDatabase() }
        }
    }
}
```

**Pending Uploads Badge:**
```
📤 3 items waiting to sync
```

---

### First Launch Experience

**Option A: Bundled Database (Recommended)**
```
App Launch
    ↓
Splash Screen (1-2 sec)
    ↓
Main Screen (fully functional)
    ↓
Background: Check for updates (non-blocking)
```

**Option B: On-Demand Download**
```
App Launch
    ↓
"Setting up your food database..."
[=========>     ] 60% (8.2 MB / 13.5 MB)
    ↓
"Ready! Your app works offline now."
    ↓
Main Screen
```

---

## 🚀 Implementation Phases

### Phase 1: SQLite Foundation (Week 1)
**Goal:** Basic local database with food search

**Tasks:**
1. ✅ Design SQLite schema
2. ✅ Create `LocalDatabaseManager.swift`
3. ✅ Implement FTS5 search
4. ✅ Export 100K foods from Algolia to SQLite
5. ✅ Bundle database with app
6. ✅ Test search performance

**Deliverable:** Offline food search works

---

### Phase 2: Sync Infrastructure (Week 2)
**Goal:** Background auto-sync

**Tasks:**
1. ✅ Create Firebase Cloud Function: `getFoodDatabaseVersion`
2. ✅ Create Firebase Cloud Function: `getFoodDatabaseDelta`
3. ✅ Implement `SyncManager.swift`
4. ✅ Version check on app launch
5. ✅ Delta sync logic
6. ✅ Full database download fallback

**Deliverable:** Database auto-updates in background

---

### Phase 3: Diary Offline Support (Week 3)
**Goal:** Log food offline

**Tasks:**
1. ✅ Add diary_entries table to SQLite
2. ✅ Implement local diary save
3. ✅ Upload queue for pending entries
4. ✅ Bidirectional sync (Firebase ↔ Local)
5. ✅ Conflict resolution

**Deliverable:** Full offline diary functionality

---

### Phase 4: Polish & UI (Week 4)
**Goal:** Production-ready UX

**Tasks:**
1. ✅ Offline indicator banner
2. ✅ Sync status in settings
3. ✅ Pending uploads badge
4. ✅ Manual refresh button
5. ✅ Error handling & retry logic
6. ✅ First launch tutorial

**Deliverable:** Polished offline experience

---

### Phase 5: Consolidation (Week 5)
**Goal:** Merge remaining Firebase collections into SQLite

**Tasks:**
1. ✅ Migrate `favorite_foods` to SQLite
2. ✅ Migrate `reactionLogs` to SQLite
3. ✅ Migrate `useByItems` to SQLite
4. ✅ Reduce UserDefaults usage
5. ✅ Unified sync manager for all data

**Deliverable:** Single source of truth (SQLite)

---

## 📊 Data Migration Strategy

### Export Algolia → SQLite (One-Time)

**Admin Dashboard Tool:**
```typescript
// firebase/public/admin-v2/src/components/DatabaseExporter.tsx
async function exportAllIndices() {
  const indices = [
    'consumer_foods',
    'tesco_products',
    'uk_foods_cleaned',
    'verified_foods',
    'ai_enhanced',
    'ai_manually_added',
    'foods',
    'fast_foods_database'
  ];

  let allFoods = [];

  for (const index of indices) {
    const foods = await browseAllRecords(index);
    allFoods.push(...foods.map(f => ({ ...f, source: index })));
  }

  // Deduplicate by ID (keep highest priority)
  const deduped = deduplicateByPriority(allFoods);

  // Generate SQLite insert statements
  const sql = generateSQLInserts(deduped);

  // Download as .sql file
  downloadFile('nutrasafe_foods_v1.sql', sql);
}
```

**Build Database Locally:**
```bash
cd "/Users/aaronkeen/Documents/My Apps/NutraSafe"
sqlite3 Resources/nutrasafe_v1.sqlite < nutrasafe_foods_v1.sql
```

**Bundle with Xcode:**
- Add `nutrasafe_v1.sqlite` to Xcode project
- Set target membership: NutraSafe Beta
- Copy to `Resources/` folder

---

### User Data Migration (Automatic)

**On App Update (SQLite Added):**
```swift
func migrateToSQLite() async {
    guard !hasCompletedMigration else { return }

    print("🔄 Migrating user data to SQLite...")

    // 1. Migrate diary entries from UserDefaults
    for date in getDiaryDates() {
        if let entries = loadDiaryFromUserDefaults(date) {
            for entry in entries {
                try? localDB.insertDiaryEntry(entry, synced: true)
            }
        }
    }

    // 2. Migrate favorite foods from Firebase cache
    let favorites = try? await FirebaseManager.shared.getFavoriteFoods()
    for favorite in favorites ?? [] {
        try? localDB.insertFavorite(favorite)
    }

    // 3. Mark migration complete
    UserDefaults.standard.set(true, forKey: "hasCompletedSQLiteMigration")

    print("✅ Migration complete")
}
```

**No Data Loss:**
- Migration runs in background
- Firebase remains source of truth during transition
- Old data cleaned up after successful migration

---

## 🔒 Database Consolidation Benefits

### Before (Current Architecture)
```
┌─────────────────────────────────────────────────┐
│              Data Sources (Distributed)          │
├─────────────────────────────────────────────────┤
│ Algolia: 9 indices (95K-120K foods)             │
│ Firebase: 20+ collections                        │
│ UserDefaults: 30+ keys                           │
│ Memory Cache: 5 separate caches                 │
└─────────────────────────────────────────────────┘

Problems:
❌ Requires internet for food search
❌ Complex caching logic (5 different strategies)
❌ Inconsistent offline behavior
❌ 9 API calls per search (even with cache)
❌ Data scattered across 4 storage systems
❌ Difficult to debug
```

### After (Unified Architecture)
```
┌─────────────────────────────────────────────────┐
│            Single Source of Truth                │
│            nutrasafe.sqlite (150 MB)             │
├─────────────────────────────────────────────────┤
│ ✅ All 100K foods (merged from 9 indices)       │
│ ✅ User diary entries (offline sync)             │
│ ✅ Favorites, reactions, use-by items            │
│ ✅ FTS5 full-text search                         │
│ ✅ Automatic background sync                     │
└─────────────────────────────────────────────────┘
        ↕ (Bidirectional Sync)
┌─────────────────────────────────────────────────┐
│          Cloud Backup (Firebase)                │
└─────────────────────────────────────────────────┘

Benefits:
✅ Full offline functionality
✅ 4-10x faster search (local DB)
✅ Simpler caching (single DB)
✅ 90% fewer API calls → lower costs
✅ Competitive advantage
✅ Easier to maintain
```

---

## 💰 Cost Impact Analysis

### Current Costs (Online-Only)

**Algolia (Search API):**
- 10,000 DAU (daily active users)
- 5 searches per user per day
- = 50,000 searches/day
- = 1.5M searches/month

**Algolia Pricing:**
- Free tier: 10,000 searches/month
- Growth plan: $0.50 per 1,000 searches
- **Monthly cost: (1,500,000 - 10,000) × $0.50 / 1000 = $745/month**

**Firebase:**
- Reads: ~3M reads/month (diary, profile, favorites)
- Firestore free tier: 50,000 reads/day = 1.5M/month
- Overage: $0.06 per 100,000 reads
- **Monthly cost: (3,000,000 - 1,500,000) × $0.06 / 100,000 = $9/month**

**Total Current: ~$754/month at 10K DAU**

---

### After Offline Database

**Algolia (90% Reduction):**
- Local search handles 90% of queries
- Only 5,000 searches/day to Algolia (new items)
- = 150,000 searches/month
- **Monthly cost: (150,000 - 10,000) × $0.50 / 1000 = $70/month**

**Firebase (Similar):**
- Diary sync still needs Firebase
- Slight reduction from local cache
- **Monthly cost: ~$7/month**

**Database Sync API:**
- Delta sync: ~50 KB per user per week
- 10,000 users × 50 KB × 4 weeks = 2 GB/month
- Cloud Functions free tier: 5 GB/month
- **Monthly cost: $0**

**Total After: ~$77/month at 10K DAU**

**💰 Savings: $677/month (90% reduction)**

At 100K DAU: **Savings: $6,770/month** 🤯

---

## ⚡ Performance Benchmarks

### Search Performance (Projected)

| Metric | Current (Algolia) | After (Local SQLite) | Improvement |
|--------|------------------|----------------------|-------------|
| Cold search | 300-500ms | 20-50ms | **6-10x faster** |
| Warm search (cached) | 50-100ms | 10-20ms | **5x faster** |
| Offline search | ❌ Fails | 20-50ms | ♾️ (works!) |
| Battery impact | Moderate (network) | Low (local) | **30% less** |

### App Size

| Current | With Bundled DB | Increase |
|---------|----------------|----------|
| 30 MB (app only) | 130 MB (app + food DB) | +100 MB (shared public data) |

**What's in the 100 MB:**
- ✅ 100,000 foods (nutritional database)
- ✅ Shared by ALL users on device
- ✅ Downloaded ONCE per device
- ❌ NOT per-user (it's public reference data)

**Per-User Data (Separate):**
- ~5 MB per user (diary, favorites, reactions)
- Stored separately in user-specific tables
- Deleted when user signs out

**Total Storage Example:**
- Single user: 130 MB (app + food DB) + 5 MB (user data) = **135 MB**
- Family iPad (3 users): 130 MB (app + food DB) + 15 MB (3 users' data) = **145 MB**

**Mitigation:**
- App thinning (iOS downloads only needed architectures)
- On-demand download option for users with limited storage
- Compress with gzip: 100 MB → 50 MB download

---

## 🧪 Testing Strategy

### Unit Tests
```swift
func testFoodSearch() async throws {
    let db = LocalDatabaseManager.test

    // Insert test data
    try db.insertFood(testFood)

    // Search
    let results = try db.search("banana")

    XCTAssertEqual(results.count, 1)
    XCTAssertEqual(results[0].name, "Banana")
}

func testDeltaSync() async throws {
    let db = LocalDatabaseManager.test
    db.setVersion(100)

    let delta = Delta(
        added: [newFood],
        modified: [updatedFood],
        deleted: ["food-123"]
    )

    try db.applyDelta(delta)

    XCTAssertEqual(db.getVersion(), 101)
}
```

### Integration Tests
- App launch with bundled DB
- Offline search (airplane mode)
- Sync after going online
- Conflict resolution (edit on 2 devices)

### Performance Tests
- Search benchmark: 10,000 queries
- Database size validation
- Memory usage monitoring
- Battery drain test (24 hour offline)

---

## 📋 API Requirements

### New Firebase Cloud Functions

**1. Get Database Version**
```typescript
GET /getCurrentDatabaseVersion
Response: { version: 142, lastUpdated: "2026-01-27T10:00:00Z" }
```

**2. Get Delta Updates**
```typescript
POST /getFoodDatabaseDelta
Body: { since: 100 }
Response: {
  version: 142,
  added: [...],      // New foods
  modified: [...],   // Updated foods
  deleted: [...]     // Deleted food IDs
}
```

**3. Download Full Database**
```typescript
GET /downloadFoodDatabase
Response: {
  version: 142,
  foods: [...],      // All 100K foods
  size: 105000000    // Bytes
}
```

---

## 🚨 Risk Assessment

### Technical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Database corruption | High | Low | Backup + restore from Firebase |
| Large app size | Medium | High | On-demand download option |
| Sync conflicts | Medium | Low | Last-write-wins strategy |
| FTS5 performance | Low | Low | Benchmark + optimize queries |

### User Experience Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Long first launch | Medium | Bundle DB with app OR fast download |
| Storage space | Low | Clear old data, compress DB |
| Stale data | Low | Background sync every 24 hours |

---

## ✅ Success Metrics

### Technical Metrics
- ✅ Offline search success rate: **>99%**
- ✅ Search performance: **<50ms average**
- ✅ Sync success rate: **>95%**
- ✅ API cost reduction: **>80%**

### User Metrics
- ✅ Offline usage: **30-40% of sessions**
- ✅ Search satisfaction: **+20% rating**
- ✅ App rating: **4.5+ stars** (offline = competitive edge)

---

## 🎯 Next Steps (When Ready to Implement)

### Immediate Actions
1. Review this plan with team/stakeholders
2. Decide: Bundle DB or on-demand download?
3. Set up dev environment for SQLite testing
4. Create Firebase Cloud Functions for sync API

### Week 1 Kickoff
1. Export Algolia data to SQLite
2. Create `LocalDatabaseManager.swift`
3. Implement FTS5 search
4. Bundle database with app
5. Test offline search

### Tracking Progress
- Use TaskCreate tool to break down implementation
- Weekly check-ins on sync performance
- User beta testing for offline scenarios

---

## 📚 Technical References

### SQLite Resources
- [SQLite FTS5 Documentation](https://www.sqlite.org/fts5.html)
- [GRDB.swift](https://github.com/groue/GRDB.swift) - Recommended SQLite wrapper

### Sync Patterns
- [Offline-First Database Design](https://rxdb.info/offline-first.html)
- [Delta Sync Implementation](https://www.inkandswitch.com/local-first/)

### Performance
- [SQLite Performance Tuning](https://www.sqlite.org/optoverview.html)

---

## 📝 Notes & Decisions

### Key Architectural Decisions

**Decision 1: SQLite vs Realm vs Core Data**
- **Chosen:** SQLite (via GRDB.swift)
- **Why:** Lightweight, proven performance, FTS5 support, easy export/import

**Decision 2: Bundle vs On-Demand Download**
- **Chosen:** Bundle for production, on-demand for beta
- **Why:** Better first impression, immediate offline functionality

**Decision 3: Sync Frequency**
- **Chosen:** Weekly automatic, daily manual option
- **Why:** Food database changes infrequently, reduces battery/data usage

**Decision 4: Conflict Resolution**
- **Chosen:** Last-write-wins (Firebase timestamp)
- **Why:** Simple, acceptable for diary app (rare edge case)

---

## 🔧 Development Environment Setup

### Required Tools
```bash
# Install GRDB (SQLite wrapper for Swift)
# Add to Xcode project via SPM:
https://github.com/groue/GRDB.swift

# SQLite CLI for testing
brew install sqlite3

# DB Browser for SQLite (GUI)
brew install --cask db-browser-for-sqlite
```

### Project Structure
```
NutraSafe Beta/
  ├── Resources/
  │   └── nutrasafe_v1.sqlite        ← Bundled database
  ├── Managers/
  │   ├── LocalDatabaseManager.swift ← SQLite interface
  │   └── SyncManager.swift          ← Background sync logic
  └── Models/
      └── LocalFoodModels.swift      ← Database models
```

---

**End of Plan Document**

This plan is ready for implementation. Estimated total development time: **4-5 weeks** for full offline support with unified database.

For questions or clarifications, refer to the codebase analysis sections above or grep the following files:
- `AlgoliaSearchManager.swift` - Current search implementation
- `FirebaseManager.swift` - Current Firebase logic
- `CoreModels.swift` - Current local caching
