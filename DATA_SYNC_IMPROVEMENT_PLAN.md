# NutraSafe Data Storage & Sync Improvement Plan

**Created:** 2026-01-28
**Purpose:** Identify and fix inconsistencies in data storage to prevent duplications, overwrites, and sync bugs

---

## 📊 Current Data Entry Points Analysis

### Summary Table: All User Data Input Areas

| Feature | Entry View | Local Storage | Cloud Storage | Offline-First? | Issues Found |
|---------|------------|---------------|---------------|----------------|--------------|
| **Food Diary** | AddFoodManualViews, AddFoodAIView, BarcodeScanningViews | OfflineDataManager (SQLite) | Firestore `foodEntries` | ✅ Yes | None |
| **Weight Log** | LogWeightView | OfflineDataManager (SQLite) | Firestore `weightHistory` | ✅ Yes | None |
| **Use By Items** | UseByAddRedesigned | OfflineDataManager (SQLite) + UserDefaults fallback | Firestore `useByInventory` | ✅ Yes | ⚠️ Duplicate UserDefaults storage |
| **Fasting Sessions** | FastingRedesign | Direct Firebase only + UserDefaults | Firestore `fastingSessions` | ❌ **NO** | 🔴 **No offline support** |
| **Fasting Plans** | FastingRedesign | Direct Firebase only | Firestore `fastingPlans` | ❌ **NO** | 🔴 **No offline support** |
| **Reaction Logs** | LogReactionSheet | Direct Firebase only | Firestore `reactionLogs` | ❌ **NO** | 🔴 **No offline support** |
| **User Settings** | DietManagementRedesign, Onboarding | OfflineDataManager + UserDefaults (mixed) | Firestore `settings/preferences` | ⚠️ Partial | 🔴 **Dual storage - sync conflicts** |
| **Favorites** | FoodDetailViewFromSearch | Direct Firebase only | Firestore `favoriteFoods` | ❌ **NO** | 🔴 **No offline support** |
| **Allergens** | HealthSafetySettingsViews, Onboarding | UserDefaults only | Firestore `settings/preferences` | ⚠️ Partial | 🔴 **UserDefaults vs Firebase mismatch** |
| **Hydration** | ContentView (HydrationCard) | UserDefaults only | None | N/A | No sync at all |
| **Onboarding Data** | PremiumOnboardingView | UserDefaults only | Some to Firebase | ⚠️ Partial | 🔴 **Inconsistent sync** |

---

## 🔴 Critical Issues Found

### Issue 1: Fasting Data Has NO Offline Support

**Location:** `FirebaseManager.swift:3568-3633`

**Problem:** Fasting sessions and plans write directly to Firebase without going through OfflineDataManager:

```swift
// CURRENT (BAD): Direct Firebase write - fails when offline
func saveFastingSession(_ session: FastingSession) async throws -> String {
    let docRef = db.collection("users").document(userId)
        .collection("fastingSessions").document(session.id ?? UUID().uuidString)
    try docRef.setData(from: session, merge: true)  // ❌ No offline support
    return docRef.documentID
}
```

**Risk:**
- If user starts a fast while offline, data is lost
- Session updates (end fast, snooze) fail silently when offline
- Timer state desync between devices

**Fix Required:** Add fasting to OfflineDataManager with sync queue integration.

---

### Issue 2: Reaction Logs Have NO Offline Support

**Location:** `FirebaseManager.swift:1259-1288`

**Problem:** Reaction logs write directly to Firebase:

```swift
// CURRENT (BAD): Direct Firebase write
func saveReactionLog(_ entry: ReactionLogEntry) async throws -> ReactionLogEntry {
    let docRef = db.collection("users").document(userId)
        .collection("reactionLogs").document()
    try docRef.setData(from: entryWithId)  // ❌ No offline support
    return entryWithId
}
```

**Risk:**
- User logs a reaction while offline → data lost
- No way to correlate reactions with foods eaten that day (both need to be synced)

**Fix Required:** Add reaction_logs table to OfflineDataManager (already exists but not wired up).

---

### Issue 3: Favorites Have NO Offline Support

**Location:** `FirebaseManager.swift:1940-2115`

**Problem:** Favorite foods save directly to Firebase without local caching:

```swift
// CURRENT (BAD): Direct Firebase write
func saveFavoriteFood(_ food: FoodSearchResult) async throws {
    try await db.collection("users").document(userId)
        .collection("favoriteFoods").document(food.id).setData(favoriteData)
}
```

**Risk:**
- User favorites a food offline → appears to work, but not saved
- Unfavoriting offline causes inconsistent state

**Fix Required:** Add favorites to OfflineDataManager sync flow.

---

### Issue 4: Use By Items Have DUAL Storage (UserDefaults + SQLite)

**Location:** `FirebaseManager.swift:1336-1350`

**Problem:** There are TWO local storage mechanisms for Use By items:

```swift
// Storage 1: UserDefaults (legacy, still active)
private func saveUseByItemLocally(_ item: UseByInventoryItem) {
    var localItems = getLocalUseByItems()
    localItems.append(item)
    UserDefaults.standard.set(encoded, forKey: "localUseByItems")  // ❌ Duplicate!
}

// Storage 2: OfflineDataManager SQLite (new, also active)
OfflineDataManager.shared.saveUseByItem(item)  // ✅ Correct path
```

**Risk:**
- Data can exist in UserDefaults but not SQLite (or vice versa)
- When reading, which source of truth is used?
- Potential duplicates when both are checked

**Fix Required:** Remove UserDefaults storage, use only OfflineDataManager.

---

### Issue 5: User Settings Have INCONSISTENT Storage

**Location:** Multiple files

**Problem:** Settings are stored in 3+ places with no clear source of truth:

| Setting | UserDefaults Key | OfflineDataManager | Firestore |
|---------|------------------|-------------------|-----------|
| Height | `userHeightCm` | ✅ Yes | ✅ Yes |
| Weight | `userWeightKg` | ❌ No | ✅ Yes |
| Caloric Goal | `cachedCaloricGoal` | ✅ Yes | ✅ Yes |
| Exercise Goal | `cachedExerciseGoal` | ✅ Yes | ✅ Yes |
| Step Goal | `cachedStepGoal` | ✅ Yes | ✅ Yes |
| Protein % | `cachedProteinGoal` | ✅ Yes | ✅ Yes |
| Allergens | `userAllergens` | ✅ Yes | ✅ Yes |
| Diet Type | `cachedDietType` | ❌ No | ✅ Yes |
| User Intent | `userIntent` | N/A (local only) | ❌ No |
| Sensitivities | `userSensitivities` | N/A (local only) | ❌ No |

**Risk:**
- UserDefaults and Firebase can have different values
- App restart may show stale cached data
- Settings changes made offline may be lost

**Fix Required:** Consolidate ALL settings through OfflineDataManager → Firebase sync.

---

### Issue 6: Allergens Have DUAL Save Paths

**Location:** `HealthSafetySettingsViews.swift:337` vs `OnboardingTheme.swift:522`

**Problem:** Allergens are saved in two different flows:

```swift
// Path 1: Settings screen (saves to UserDefaults AND tries Firebase)
UserDefaults.standard.set(Array(allSelected), forKey: "userAllergens")
Task { try? await FirebaseManager.shared.updateAllergens(allergens) }

// Path 2: Onboarding (saves to UserDefaults only, Firebase syncs later)
UserDefaults.standard.set(allergenStrings, forKey: "userAllergens")
// Firebase sync happens in OnboardingManager.saveToFirebase()
```

**Risk:**
- If Firebase fails in Path 1, UserDefaults has new value but Firebase has old
- Sync conflict if user updates allergens on two devices

**Fix Required:** Single save path through OfflineDataManager.

---

### Issue 7: OfflineSyncManager Doesn't Handle All Collections

**Location:** `OfflineSyncManager.swift:250-383`

**Problem:** The sync manager only processes these collections:

```swift
switch operation.collection {
case "foodEntries": ...
case "useByInventory": ...
case "weightHistory": ...
case "settings": ...
default:
    throw SyncError.unknownCollection  // ❌ Missing collections!
}
```

**Missing Collections:**
- `fastingSessions` - exists in OfflineDataManager but not synced
- `fastingPlans` - exists in OfflineDataManager but not synced
- `reactionLogs` - exists in OfflineDataManager but not synced
- `favoriteFoods` - exists in OfflineDataManager but not synced

**Fix Required:** Add sync handlers for all collections.

---

### Issue 8: Hydration Data Has NO Cloud Sync

**Location:** `ContentView.swift:940`

**Problem:** Water intake is UserDefaults only:

```swift
UserDefaults.standard.set(hydrationData, forKey: "hydrationData")
```

**Risk:**
- Data lost on device change/reinstall
- No cross-device sync for family iPad scenarios

**Fix Required:** Add hydration to OfflineDataManager (optional - low priority).

---

### Issue 9: Delete Operations May Cause Sync Conflicts

**Location:** `OfflineDataManager.swift:453-475`, `OfflineSyncManager.swift:386-407`

**Problem:** Delete uses soft-delete locally but hard-delete on server:

```swift
// Local: Soft delete (mark as deleted)
let sql = "UPDATE food_entries SET sync_status = 'deleted' WHERE id = ?"

// Server: Hard delete (permanent)
try await docRef.delete()
```

**Risk:**
- If sync fails after local soft-delete, item appears deleted but exists on server
- Re-fetch from server could resurrect "deleted" items

**Current Mitigation:** `cleanupDeletedRecords()` removes soft-deleted items after successful sync.

**Improvement Needed:** Better error handling if server delete fails.

---

### Issue 10: No Conflict Detection for Concurrent Edits

**Location:** `OfflineSyncManager.swift:268-286`

**Problem:** Current conflict resolution uses `lastModified` timestamp comparison:

```swift
if operation.timestamp >= serverDate {
    transaction.setData(dict, forDocument: docRef)
} else {
    print("Skipping sync - server has newer data")  // ❌ Local changes lost!
}
```

**Risk:**
- User edits on Phone (offline) while iPad syncs a different edit
- Phone comes online, its edit is SILENTLY discarded
- User loses their work with no notification

**Fix Required:** Show conflict dialog OR merge changes where possible.

---

## ✅ Correctly Implemented Areas

These features follow the offline-first pattern correctly:

1. **Food Diary Entries** - Full offline support, sync queue, conflict resolution
2. **Weight History** - Full offline support with cache update
3. **Use By Items** (SQLite path) - Correct, but needs UserDefaults removal

---

## 🛠️ Recommended Fixes (Priority Order)

### Priority 1: Critical Data Loss Prevention

#### Fix 1.1: Add Fasting to Offline Sync

```swift
// In FirebaseManager.swift - saveFastingSession()
func saveFastingSession(_ session: FastingSession) async throws -> String {
    guard let userId = currentUser?.uid else {
        throw NSError(domain: "NutraSafeAuth", code: -1, ...)
    }

    let sessionId = session.id ?? UUID().uuidString
    var sessionWithId = session
    sessionWithId.id = sessionId

    // OFFLINE-FIRST: Save to local SQLite first
    OfflineDataManager.shared.saveFastingSession(sessionWithId)

    // Trigger background sync
    OfflineSyncManager.shared.triggerSync()

    return sessionId
}
```

**Also required:**
- Add `saveFastingSession(_ session:)` to OfflineDataManager
- Add `"fastingSessions"` case to OfflineSyncManager.processAddOrUpdate()
- Same for `saveFastingPlan()`, `updateFastingSession()`, `deleteFastingSession()`

#### Fix 1.2: Add Reaction Logs to Offline Sync

Same pattern as fasting - route through OfflineDataManager first.

#### Fix 1.3: Add Favorites to Offline Sync

Same pattern - save locally first, sync in background.

---

### Priority 2: Remove Duplicate Storage

#### Fix 2.1: Remove UserDefaults from Use By Items

**Delete these methods in FirebaseManager.swift:**
- `saveUseByItemLocally()` (lines 1336-1342)
- `getLocalUseByItems()` (lines 1344-1350)

**Remove all references to `localUseByItems` UserDefaults key.**

---

### Priority 3: Consolidate Settings Storage

#### Fix 3.1: Single Settings Save Path

Create a new method that handles ALL settings atomically:

```swift
func saveAllUserSettings(_ settings: UserSettings) {
    // 1. Save to OfflineDataManager (single transaction)
    OfflineDataManager.shared.saveUserSettings(settings)

    // 2. Update UserDefaults cache (for immediate UI reads)
    UserDefaults.standard.set(settings.caloricGoal, forKey: "cachedCaloricGoal")
    // ... other cached values for fast UI reads

    // 3. Trigger sync
    OfflineSyncManager.shared.triggerSync()
}
```

---

### Priority 4: Better Conflict Handling

#### Fix 4.1: Notify User of Conflicts

When server has newer data, don't silently discard local changes:

```swift
if operation.timestamp < serverDate {
    // Server is newer - notify user
    await MainActor.run {
        NotificationCenter.default.post(
            name: .syncConflictDetected,
            object: nil,
            userInfo: [
                "collection": operation.collection,
                "documentId": operation.documentId,
                "localTimestamp": operation.timestamp,
                "serverTimestamp": serverDate
            ]
        )
    }

    // Keep local copy in conflict state for manual resolution
    OfflineDataManager.shared.markAsConflict(
        collection: operation.collection,
        documentId: operation.documentId
    )
}
```

---

### Priority 5: Complete Sync Manager Coverage

#### Fix 5.1: Add Missing Collection Handlers

In `OfflineSyncManager.processAddOrUpdate()`:

```swift
case "fastingSessions":
    docRef = db.collection("users").document(userId)
        .collection("fastingSessions").document(operation.documentId)
    // ... encode FastingSession and setData

case "fastingPlans":
    docRef = db.collection("users").document(userId)
        .collection("fastingPlans").document(operation.documentId)
    // ... encode FastingPlan and setData

case "reactionLogs":
    docRef = db.collection("users").document(userId)
        .collection("reactionLogs").document(operation.documentId)
    // ... encode ReactionLogEntry and setData

case "favoriteFoods":
    docRef = db.collection("users").document(userId)
        .collection("favoriteFoods").document(operation.documentId)
    // ... encode FoodSearchResult and setData
```

---

## 📋 Implementation Checklist

### Phase 1: Critical Fixes (Days 1-3)

- [ ] **1.1** Add `saveFastingSession` to OfflineDataManager
- [ ] **1.2** Add `saveFastingPlan` to OfflineDataManager
- [ ] **1.3** Add fastingSessions/fastingPlans to OfflineSyncManager
- [ ] **1.4** Add `saveReactionLog` to OfflineDataManager
- [ ] **1.5** Add reactionLogs to OfflineSyncManager
- [ ] **1.6** Add `saveFavoriteFood` to OfflineDataManager
- [ ] **1.7** Add favoriteFoods to OfflineSyncManager

### Phase 2: Remove Duplicates (Day 4)

- [ ] **2.1** Delete `saveUseByItemLocally()` from FirebaseManager
- [ ] **2.2** Delete `getLocalUseByItems()` from FirebaseManager
- [ ] **2.3** Remove `localUseByItems` UserDefaults references
- [ ] **2.4** Test Use By functionality end-to-end

### Phase 3: Settings Consolidation (Days 5-6)

- [ ] **3.1** Create unified `UserSettings` model
- [ ] **3.2** Create `saveAllUserSettings()` method
- [ ] **3.3** Update Onboarding to use unified save
- [ ] **3.4** Update DietManagementRedesign to use unified save
- [ ] **3.5** Update HealthSafetySettingsViews to use unified save
- [ ] **3.6** Test settings sync across device reinstall

### Phase 4: Conflict Handling (Days 7-8)

- [ ] **4.1** Add `sync_status = 'conflict'` state
- [ ] **4.2** Add `markAsConflict()` to OfflineDataManager
- [ ] **4.3** Add `.syncConflictDetected` notification
- [ ] **4.4** Create conflict resolution UI (optional)
- [ ] **4.5** Test multi-device edit scenarios

### Phase 5: Testing & Validation (Days 9-10)

- [ ] **5.1** Test each feature in airplane mode
- [ ] **5.2** Test sync after reconnection
- [ ] **5.3** Test multi-device sync conflicts
- [ ] **5.4** Test data persistence after app reinstall
- [ ] **5.5** Verify no duplicate entries in Firebase

---

## 🧪 Testing Scenarios

### Scenario 1: Offline Fasting Session
1. Put device in airplane mode
2. Start a fast
3. Wait 30 minutes, end the fast
4. Turn airplane mode off
5. **Expected:** Fast session syncs to Firebase with correct duration

### Scenario 2: Reaction Log While Offline
1. Log some food entries
2. Put device in airplane mode
3. Log a reaction
4. Turn airplane mode off
5. **Expected:** Reaction syncs with correct food associations

### Scenario 3: Settings Edit Conflict
1. Device A edits caloric goal to 2000
2. Device B (offline) edits caloric goal to 2500
3. Device B comes online
4. **Expected:** User notified of conflict, can choose which value to keep

### Scenario 4: Use By Item Sync
1. Add Use By item while offline
2. Come online
3. Check Firebase console
4. **Expected:** Item appears in `useByInventory` collection
5. **Verify:** No `localUseByItems` in UserDefaults

---

## 📊 Data Flow Diagrams

### Current (Inconsistent) Flow

```
User Action
    ↓
    ├─→ Food Entry → OfflineDataManager → Sync Queue → Firebase ✅
    ├─→ Weight Log → OfflineDataManager → Sync Queue → Firebase ✅
    ├─→ Use By Item → OfflineDataManager + UserDefaults → Firebase ⚠️
    ├─→ Fasting → Direct Firebase (fails offline) ❌
    ├─→ Reaction → Direct Firebase (fails offline) ❌
    ├─→ Favorites → Direct Firebase (fails offline) ❌
    └─→ Settings → UserDefaults + Maybe Firebase ⚠️
```

### Target (Unified) Flow

```
User Action
    ↓
All Data → OfflineDataManager (SQLite)
    ↓
Sync Queue → OfflineSyncManager
    ↓
Firebase (all collections)
    ↓
Conflict Detection → User Notification (if needed)
```

---

## 📁 Files to Modify

| File | Changes Needed |
|------|----------------|
| `OfflineDataManager.swift` | Add fasting, reaction, favorites save methods |
| `OfflineSyncManager.swift` | Add missing collection handlers |
| `FirebaseManager.swift` | Route all saves through OfflineDataManager |
| `FastingViewModel.swift` | Update to use offline-first pattern |
| `LogReactionSheet.swift` | Update to use offline-first pattern |
| `FoodDetailViewFromSearch.swift` | Update favorites to offline-first |
| `OnboardingTheme.swift` | Consolidate settings save path |
| `DietManagementRedesign.swift` | Use unified settings save |
| `HealthSafetySettingsViews.swift` | Use unified allergens save |

---

## 🎯 Success Metrics

After implementing these fixes:

- ✅ All user data entry points work offline
- ✅ Zero data loss when offline
- ✅ Single source of truth (OfflineDataManager → Firebase)
- ✅ No duplicate storage mechanisms
- ✅ Conflicts detected and surfaced to user
- ✅ All 7 collections synced consistently

---

## 📝 Notes

### Why This Matters

1. **User Trust:** Data loss destroys user trust. Users expect their food log to be there when they open the app.

2. **Competitive Advantage:** MyFitnessPal and Nutracheck have poor offline support. Full offline functionality is a differentiator.

3. **Maintainability:** Having 3-4 different storage mechanisms creates bugs. Single source of truth is easier to debug.

4. **Sync Reliability:** Firebase offline persistence is good, but custom sync gives us control over conflict resolution.

### Trade-offs

- **Complexity:** More code in OfflineDataManager, but simpler overall architecture
- **Storage:** SQLite file grows with user data (~5-10 MB typical)
- **Migration:** Existing users may have data in old storage locations - need migration path

### Related Documentation

- [OFFLINE_DATABASE_CONSOLIDATION_PLAN.md](OFFLINE_DATABASE_CONSOLIDATION_PLAN.md) - Full offline architecture plan
- [CLAUDE.md](CLAUDE.md) - Development guidelines

---

**End of Plan**
