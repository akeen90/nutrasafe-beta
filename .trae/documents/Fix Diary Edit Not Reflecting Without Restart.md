## Root Cause
- When editing a diary entry, `FoodDetailViewFromSearch.addToFoodLog()` picks a `targetDate` from `UserDefaults` key `preselectedDate` or falls back to `Date()` (NutraSafe Beta/Views/Food/FoodDetailViewFromSearch.swift:2019–2026).
- The edit sheet launched from the diary does not set `preselectedDate`. Therefore, edits are saved to today instead of the diary’s currently selected date, so the UI doesn’t show the change until you restart (and the app defaults to today).

## Changes
1. Pass the selected diary date directly into the edit screen.
   - In `NutraSafe Beta/Views/DiaryTabView.swift:388–402` where `FoodDetailViewFromSearch` is presented, add a new parameter `diaryDate: selectedDate`.
2. Use the explicit `diaryDate` for saves in edit mode.
   - In `NutraSafe Beta/Views/Food/FoodDetailViewFromSearch.swift`, add a stored property `diaryDate: Date?`.
   - In `addToFoodLog()` (1911+), set `targetDate` as:
     - If `diaryEntryId != nil` (editing): use `diaryDate ?? selectedDate` (explicit property); do NOT use `UserDefaults` for edit path.
     - If adding from Add tab: keep current `preselectedDate`/fallback logic.
3. No change required to reload logic.
   - `DiaryDataManager.replaceFoodItem(...)` and `moveFoodItem(...)` already trigger `dataReloadTrigger` after syncing (NutraSafe Beta/Models/CoreModels.swift:724–727, 842–845), and `DiaryTabView` listens to it and calls `loadFoodData()` (Views/DiaryTabView.swift:430–432).

## Minimal Alternative (if you prefer fewer code changes)
- When opening the edit sheet, set `UserDefaults.standard.set(selectedDate.timeIntervalSince1970, forKey: "preselectedDate")` similar to the Add flow (Views/DiaryTabView.swift:954). This will keep the existing edit screen logic working. The explicit parameter is cleaner and less error‑prone.

## Verification
- Open diary on a non‑today date, edit a food’s serving size, press Update.
- Confirm the card values and meal totals update immediately without restart.
- Test both per‑unit and per‑100g items, and also changing meal type (move across meals) to verify date correctness.

If you approve, I’ll implement the explicit `diaryDate` parameter and the edit‑path save logic, then verify with the above scenarios.