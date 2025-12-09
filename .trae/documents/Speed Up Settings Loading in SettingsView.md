## Diagnosis
- Settings sections fetch data on appear and after saves: nutrition goals, progress goals, health & safety.
- Reads use Firestore and happen sequentially; UI waits before showing editable fields.
- Writes trigger a full reload, adding extra latency.
- Some values use @AppStorage (instant), but calories/macros/weights rely on network reads without a local cache.

## Goals
- Show editable values immediately with cached data.
- Refresh in the background and merge updates without blocking UI.
- Avoid redundant reads after writes; keep UI responsive.

## Data Layer Improvements
- Add lightweight caches in the app’s data layer:
  1. Cached user settings and macro goals in memory (`@Published`) and persisted in `UserDefaults` for cold starts.
  2. Helpers: `getCachedUserSettings()`, `getCachedMacroGoals()`, `updateCachedUserSettings(_:)`, `updateCachedMacroGoals(_:)`.
  3. Warm caches on app launch and foreground using existing managers.
- Use concurrent fetches:
  - In settings load, run `async let` for settings + macro goals + reactions to reduce wall time.

## SettingsView Behavior
- Bind inputs (calories, macros, goals) to cache-backed values so the form renders instantly.
- On appear:
  - Render cached values immediately.
  - Start a background refresh that merges new data into the cache and updates the form without blocking.
- Replace “reload after save” with optimistic updates:
  - Update cache and UI immediately on change.
  - Fire-and-forget save; on error, show a small toast and revert the single field from last good value (no full reload).

## Write Path Optimization
- Remove `await loadNutritionGoals()`/`await loadProgressData()` calls after every save.
- Centralize saves in view model; update cache first, then call Firestore with retry.
- Batch writes where feasible (e.g., macros in one document), minimizing round trips.

## UI Micro-Optimizations
- Skeleton placeholders with `.redacted(reason: .placeholder)` for fields that have no cached value yet.
- Break large settings into smaller subviews to reduce initial layout work.
- Disable expensive animations and transitions on initial load (`.transaction { $0.disablesAnimations = true }`).

## Background Refresh
- Use existing background task hooks to warm caches daily and on foreground entry.
- After refresh, emit a published change so Settings instantly reflects fresh values.

## Instrumentation
- Add lightweight timing logs around settings fetches and writes to measure improvements.
- Log cache hits vs network fetches to verify instant rendering paths.

## Rollout Steps
1. Implement `SettingsViewModel` that surfaces cached values and manages optimistic saves.
2. Add cache structures and persistence to the data layer; wire warm-up on app start/foreground.
3. Update `SettingsView` to use cache-backed bindings and remove blocking reloads.
4. Add concurrent fetch and merge logic; add skeleton placeholders.
5. Add instrumentation and verify on device; iterate based on timings.

## Expected Outcome
- Editable fields (calories/macros/weights) render instantly from cache.
- Network refresh occurs in the background; users can edit immediately.
- Saves feel immediate; no visible stutter from follow-up reloads.
