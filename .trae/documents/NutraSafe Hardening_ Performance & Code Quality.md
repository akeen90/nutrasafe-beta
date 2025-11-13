## Goals
- Improve perceived speed and responsiveness (search, navigation, scrolling)
- Eliminate main-thread blocking and reduce recomposition overhead
- Clean codebase (remove dead/backup code, reduce logging, fix unsafe patterns)

## Scope & Priorities
- Focus on high-traffic flows: search, food detail, diary, use-by
- Quick wins first (low risk/high impact), then deeper refactors and search upgrades

## Phase 1: Quick Wins (Start Immediately)
1) Eliminate main-thread disk IO in image cache
- Ensure all Views call async cache APIs (`saveUseByImageAsync`, `loadUseByImageAsync`) and weight equivalents
- Replace any remaining sync calls with async ones; audit call sites in `ContentView.swift`, `UseByTabViews.swift`, and `FoodSearchViews.swift`
- Verify with Instruments Main Thread Checker

2) Fix debounce to avoid main-actor sleeping
- Audit `.onChange` search debounces; ensure `Task.sleep` runs in background task
- Targets: `Views/Use By/UseByTabViews.swift` inline search; `Views/Food/FoodSearchViews.swift` live search

3) Convert heavy lists to lazy containers
- Use `LazyVStack/List` on large result/scroll screens
- Targets: `DiaryTabView.swift` (main ScrollView), `UseByTabViews.swift`, `FoodDetailViewFromSearch.swift`, `FoodSearchViews.swift`

4) Reduce logging in hot paths
- Replace `print` in search/DB paths with gated logs (`#if DEBUG`) or a light logger
- Targets: `FirebaseManager.swift` search functions, `SQLiteFoodDatabase.swift` search functions, view-level prints

5) Remove backups/unused files
- Delete `*.bak*` files and stubs like `Untitled.swift`; keep backups outside source

## Phase 2: Navigation & View Splits
6) Consolidate navigation
- Prefer a root `NavigationStack` with `@available(iOS 16, *)` and `NavigationView` fallback
- Remove nested `NavigationView` in sheets; centralize routing to reduce invalidations
- Targets: `FoodTabViews.swift`, `FoodDetailViewFromSearch.swift`, `SettingsView.swift`

7) Split giant views into components
- Extract subviews with minimal bindings to reduce invalidation scope and compile time
- Start with `FoodDetailViewFromSearch.swift`: Nutrition Facts, Scores (already extracted), Ingredients, Verification, Watch tabs
- Split `ContentView.swift` into feature-specific containers; reduce top-level state propagation

## Phase 3: Search Optimization
8) Introduce SQLite FTS5
- Create `fts5` virtual table for text fields (name, brand, ingredients)
- Populate on startup/migration, keep existing exact-match indices
- Update `searchFoods(query:limit:)` to use `MATCH` for substring; add ranking by BM25 + domain rules

9) Early limiting and per-source ranking
- Apply per-source limits earlier; rank before merging to minimize allocations
- Targets: `FirebaseManager.swift:searchFoods`

10) Cache row-level grades
- Memoize processing/sugar grades per `food.id` for search list cells
- Extend to detail screen partials where recompute occurs often

## Phase 4: Stability & Cleanliness
11) Audit and replace force-unwraps
- Replace with `guard let`/optional chaining in high-traffic files and HealthKit interfaces
- Targets: `FoodTabViews.swift`, `SettingsView.swift`, `HealthKitModels.swift`, `CitationManager.swift`

12) Move heavy `.onAppear` work off main and memoize
- Use background tasks to compute; store results in lightweight caches
- Targets: `FoodDetailViewFromSearch.swift` ingredients/additive scoring block

13) Narrow `EnvironmentObject` scope
- Localize state or use smaller view models to reduce ripple; pass bindings or observed objects only where needed

## Validation & Metrics
- Baseline: measure search latency and page transition time; count recompositions on key screens
- Post-change: re-measure; target ≥25–40% reduction in recomposition for heavy screens and faster search
- Instruments: Main Thread Checker & Time Profiler to confirm no UI-thread I/O and reduced CPU in list diffing

## Deliverables
- Code changes for Phases 1–4
- A short report with before/after metrics and key file references
- A cleanup list of removed files and resolved TODOs

## Timeline
- Week 1: Phase 1 quick wins + partial Phase 2 (start component extraction)
- Week 2: Navigation consolidation + componentization of food detail and content view
- Week 3: FTS5 implementation + search ranking limits + caching
- Week 4: Stability audit (force-unwraps), environment scope reduction, cleanup and final metrics

Approve to proceed and I will start Phase 1 immediately, deliver incremental updates and measurements after each subtask.