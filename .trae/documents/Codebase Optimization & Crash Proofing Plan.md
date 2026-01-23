# Revised Optimization Plan

I will proceed with the optimization and cleanup as requested, specifically targeting the legacy SQLite database removal and applying the critical fixes.

## 📋 Execution Steps

### 1. 💾 Backup
*   Create a local git commit to save the current state before any changes.

### 2. 🧹 Cleanup (Legacy SQLite Removal)
*   **Delete Files**:
    *   `NutraSafe Beta/Database/nutrasafe_foods.db` (Legacy DB)
    *   `NutraSafe Beta/Database/SQLiteFoodDatabase.swift` (Legacy wrapper)
*   **Update Code**:
    *   Remove references to `SQLiteFoodDatabase` from `FirebaseManager.swift`.
    *   *Note:* I will **keep** `MicronutrientDatabase.swift` as it uses a different, active database (`micronutrients_ingredients_v6.db`).

### 3. 🚀 Performance Optimization (Main Thread Fix)
*   **Refactor `NutrientTrackingManager.swift`**:
    *   Change `loadFromCache()` to an `async` method.
    *   Move file reading (`Data(contentsOf:)`) to a background task to stop UI freezing.

### 4. 🛡️ Crash Proofing (Stability)
*   **Fix Regex Crashes**:
    *   Update `StrictMicronutrientValidator.swift` and `ScoringModels.swift` to use safe regex initialization instead of `try!`.
*   **Fix Date Crashes**:
    *   Update `NutrientTrackingManager.swift` to use safe optional binding for date calculations instead of force unwrapping (`!`).
*   **Enhance Error Handling**:
    *   Update `ErrorHandler.swift` to log non-fatal errors to Crashlytics (if available) or the system logger.

### 5. 💾 Final Commit
*   Commit all changes with a descriptive message.

**Ready to execute?**