## Goal
Eliminate freezes and slowdowns when switching tabs rapidly by cancelling in-flight work, avoiding unnecessary rebuilds, and reusing cached data. Keep functionality intact.

## Root Causes (observed in code)
- Multiple views load data in `onAppear` without cancellation; rapid tab switches start concurrent Firebase tasks that compete for the main thread.
- Some views force full rebuilds (`DiaryTabView` uses `.id(diarySubTab)`) increasing recomposition cost.
- Data loads are repeated despite `hasLoadedOnce` flags (no cancellation/reset on disappear; notifications can re-trigger loads).

## Strategy
- Adopt structured concurrency with cancellable tasks per screen.
- Convert `onAppear` loaders to `.task(id:)` and keep a `Task` handle for explicit cancellation on disappear/tab change.
- Add lightweight throttling for tab taps at the ContentView level.
- Reuse cached data and only refresh when truly needed.

## Implementation Plan
### 1) Cancellable Loads Per Screen
- Add `@State private var loadTask: Task<Void, Never>?` to each screen that loads remotely (Progress, Diary, Use By, Health reactions).
- Replace `onAppear { Task { await load() } }` with:
  - `.task(id: reloadKey) { loadTask?.cancel(); loadTask = Task { await load() } }`
  - Use `reloadKey` based on a stable trigger (e.g., `selectedTab`, `hasLoadedOnce == false`, or an explicit counter).
- In `onDisappear`, cancel: `loadTask?.cancel()`.
- Inside `load...()` functions:
  - Check `Task.isCancelled` before and after network calls; early-return if cancelled.
  - Wrap network calls in `withTaskCancellationHandler` or periodic `Task.checkCancellation()` to keep responsiveness.

### 2) Remove Costly Rebuilds
- `DiaryTabView`: Remove `.id(diarySubTab)` on the scroll container; switch content with `if/else` only (already present) to avoid full view identity changes and state resets.

### 3) Tab Tap Throttling (UI Guard)
- In the shared tab selection (`ContentView`): introduce a short guard (e.g., 200–300 ms) between tab changes:
  - Store `@State private var lastTabChange = Date()` and ignore changes within the guard window.
  - Alternatively, disable tab bar interactions for 250 ms after a change using a state flag.
- Keep guard small enough to feel instant but prevent double-activations.

### 4) Background Prefetch (Low Priority)
- ContentView: pre-warm data for adjacent tabs after app launch and when idle using `Task(priority: .background)`:
  - UseBy items, weight history, reactions summaries.
  - Respect existing `hasLoadedOnce` and caches; no UI blocking.

### 5) Cache & Main-Thread Discipline
- Confirm all image decode and heavier computations occur off the main actor; only UI updates on `@MainActor`.
- Strengthen existing caches (Use By `SimpleImageCache`, Progress weight history in memory) to avoid refetching.

### 6) Notifications Debounce
- Where `onReceive` triggers reloads (e.g., Use By), debounce and coalesce reloads to avoid burst loads:
  - Introduce `@State private var reloadDebounceTimer` or use an async debounce via `Task.sleep` with cancellation.

## Files To Update (code edits after approval)
- `Views/Use By/UseByTabViews.swift`: Add `loadTask`, convert loader to `.task(id:)`, cancel on disappear; debounce `.onReceive`.
- `ContentView.swift` (Progress): Add `loadTask`, convert loader; add tab change guard; prefetch background tasks.
- `Views/Food/FoodTabViews.swift` & `FoodReactionsView`: Introduce `loadTask` around `reactionManager.reloadIfAuthenticated()`.
- `Views/DiaryTabView.swift`: Remove `.id(diarySubTab)`; add `loadTask` for diary loads; cancel on disappear.

## Verification
- Add simple logging (DEBUG only) to confirm cancellations and guard behavior when rapidly tapping tabs.
- Manual test: rapidly switch tabs; ensure no freeze, loaders cancel immediately, and UI stays responsive.

## Rollback
- All changes are additive and guarded; we can revert the task/cancellation wrappers or the tap guard independently without affecting data or business logic.

Shall I proceed with these optimizations?