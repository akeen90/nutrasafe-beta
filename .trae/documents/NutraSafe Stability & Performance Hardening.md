## Goals

* Eliminate UI blocking and reduce recomposition in large views

* Accelerate search and page transitions while preserving correctness

* Improve cleanliness (dead code, logging, force-unwraps) for maintainability

## Phase 1: Quick Wins (Low Risk, High Impact)

1. Move disk IO off main in `Managers/ImageCacheManager.swift`

   * Replace `@MainActor` methods doing `Data(contentsOf:)` and writes with background tasks; publish results on main

   * Target: `Managers/ImageCacheManager.swift:178–185, 187–205`
2. Fix main-actor debounce in search views

   * Move `Task.sleep` off `@MainActor`, perform debounce on a background task and marshal results back

   * Targets: `Views/Use By/UseByTabViews.swift:2386–2389`, review `Views/Food/FoodSearchViews.swift:503–516`
3. Gate or remove `print()` logging in hot paths

   * Add `DebugLogger` wrapper; disable logs in release or behind a flag

   * Targets: `Database/SQLiteFoodDatabase.swift` (init/search paths), `FirebaseManager.swift` (search merge), `FoodSearchViews.swift`

## Phase 2: Search Optimization

1. Early limiting and ranking during merges

   * Apply per-source limits before merge; rank+limit immediately after merge to avoid large arrays

   * Target: `FirebaseManager.swift:685–698`
2. Caching precomputed scores for list rows

   * Cache nutrition/processing grades for search rows to avoid recompute on scroll

   * Target: `Views/Food/FoodSearchViews.swift:109–119`
3. Optional: Introduce SQLite FTS5 for ingredient/name text search

   * Add FTS table and update `searchFoods(query:limit:)` to use MATCH; keep existing indices for exact fields

   * Target: `Database/SQLiteFoodDatabase.swift:309–423`

## Phase 3: UI Recomposition Reduction

1. Split giant views into focused subviews to limit invalidation

   * Start with `ContentView.swift` (7530), `FoodDetailViewFromSearch.swift` (5006), `UseByTabViews.swift` (4137), `FoodTabViews.swift` (3075), `DiaryTabView.swift` (3051)

   * Extract independent sections with dedicated view models where helpful
2. Consolidate navigation

   * Prefer a single root `NavigationStack`; avoid nested `NavigationView` in sheets unless necessary

   * Targets: `ContentView.swift` multi-sheet bodies, `FoodTabViews.swift`, `DiaryTabView.swift`

## Phase 4: Stability Improvements

1. Audit and replace force-unwraps with safe binding

   * Prioritize high-traffic views and managers; replace with `guard let`/`if let`

   * Focus: `Views/Food/FoodDetailViewFromSearch.swift`, `Models/ScoringModels.swift`, `FirebaseManager.swift`, `ContentView.swift`
2. Clean dead/commented-out code and TODOs

* Remove large commented blocks (e.g., `ContentView.swift:4192–4918`), convert TODOs to tracked tasks or resolve

## Verification

* Add lightweight performance checks: measure search latency and page transition time before/after

* Run through critical flows to ensure no regressions

* Use Instruments (`Time Profiler`, `Main Thread Checker`) to confirm main-thread blocking eliminated

## Deliverables

* Refactored IO and debounce

* Reduced logging in hot paths

* Faster search merges and cached row scores

* Split large views and simplified navigation

* Safer optionals and cleaner codebase

