## Root Causes (from code review and crash log)
- Recursive layout loop in a SwiftUI `List/Form` during reaction logging (UIKit `UICollectionViewFeedbackLoopDebugger`): rows change height while the list auto-adjusts `contentOffset` via animations.
- Rapid tab taps trigger overlapping loads (Firebase fetches, UI recompositions), causing jank and occasional freezes.
- Search results auto‑scroll and keyboard observers adjust content offset repeatedly while self‑sizing rows update → potential feedback loop.

## Fix Strategy Overview
- Prevent overlapping navigation/loads with a short tap throttle and cancellable tasks.
- Stabilize all self‑sizing list rows used in reaction logging and meal selection.
- Remove/limit animated contentOffset changes in search and lists.
- Cache and reuse data across tabs; avoid redundant onAppear loads.

## Implementation Plan
### 1) Navigation Throttle and Task Cancellation
- In custom tab bar or tab selection handlers, add a 250–300ms throttle (`isNavigating` flag). Disable taps until selection settles.
- Track per‑screen load `Task`s; cancel on tab change (`onDisappear`). Use `@State var loadTask: Task<Void, Never>?` and `.cancel()` before starting new work.
- Replace `.task { ... }` long operations with explicit start/stop tied to tab lifecycle.

### 2) Reaction Logging: Stabilize List/Form Rows
- In `LogReactionSheet` (ReactionLogView.swift):
  - Set a fixed minimum row height via `.environment(\ .defaultMinListRowHeight, 44)` on the `Form` and meal selection `List`.
  - Disable animations for row height changes: `.animation(nil, value: foodLoggedInDiary)`, `.animation(nil, value: recentMeals)`, and wrap selection updates in `withTransaction { $0.animation = nil }`.
  - Ensure row contents do not change intrinsic size across states (e.g., keep accessory area width constant; use `.frame(maxWidth: .infinity, alignment: .leading)` and avoid toggling large blocks).
  - Use `.listStyle(.insetGrouped)` and avoid dynamic `.background`/overlays that change height.

### 3) Meal Selection Sheet List
- In the `showMealSelection` sheet:
  - Apply same row height constraint and disable animations on selection.
  - Remove any contentOffset adjustments; let the list be static.

### 4) Search Results View (AddFoodSearchView)
- Remove animated `scrollProxy.scrollTo` loops or change to non‑animated scrolling and throttle to only one scroll when results appear/keyboard changes.
- Avoid `.fixedSize` on text that can cause a reflow; prefer `lineLimit(2)` + `.frame(maxWidth: .infinity, alignment: .leading)`.
- Ensure the sheet `FoodDetailViewFromSearch` doesn’t trigger layout loops by changing vertical content size repeatedly during appear; disable implicit animations on state that changes layout.

### 5) Data Prefetch + Caching Across Tabs
- Use existing background preload (ContentView.swift:1700+) and expand it to cache Use By, reactions, weight history.
- Store results in managers (`DiaryDataManager`, `ReactionLogManager`, `FirebaseManager`) and guard loads with `hasLoadedOnce` flags already present.
- On tab change, avoid re‑fetch unless invalidated by specific notifications.

### 6) Defensive UI Settings
- Add `.scrollDismissesKeyboard(.interactively)` to search screens to reduce keyboard‑induced layout thrash.
- Add `.transaction { $0.animation = nil }` on containers wrapping Lists/Forms that frequently toggle sections.

## Files To Update
- `Views/Components/CustomTabBar.swift` (or equivalent): add tap throttle.
- `Views/ReactionLogView.swift`:
  - `LogReactionSheet` Form and `showMealSelection` List → fixed min row height, disable animations.
- `Views/Food/FoodSearchViews.swift`:
  - Throttle and de‑animate `scrollProxy.scrollTo`; reduce repeated contentOffset changes.
  - Remove/adjust `.fixedSize` that can cause inconsistent row sizing.
- `Views/Food/FoodDetailViewFromSearch.swift`:
  - Disable implicit animations on layout‑affecting state changes.
- Managers (`DiaryDataManager`, `ReactionLogManager`): ensure loads are cached and cancelable.

## Validation
- Reproduce Pret’s Lasagne Soup add flow; confirm no crash.
- Stress test rapid tab switching; confirm no freezes and smooth transitions.
- Xcode “UICollectionViewFeedbackLoopDebugger” no longer logs recursion.
- Instruments (Time Profiler, Allocations): verify reduced main‑thread work during tab switches.

## Rollback Safety
- Changes are localized and guarded; if a specific de‑animation causes undesired UX, revert per‑screen while keeping task cancellation/throttle improvements.

Confirm and I’ll implement the above optimizations and crash fixes across the listed files.