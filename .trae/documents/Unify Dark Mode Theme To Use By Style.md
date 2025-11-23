## Goal
Make the entire app adopt the same dark mode look as Use By: midnight blue background, glass cards, and consistent strokes/shadows. Keep light mode as the current glass style.

## Approach
- Centralize background logic into a single adaptive component that returns:
  - Light: current glass gradient with subtle blue/purple radial highlights
  - Dark: midnight blue gradient (Use By style)
- Replace per‑screen custom backgrounds (Diary, Health, Progress, etc.) with the shared adaptive background.
- Ensure card surfaces use materials that already look correct in dark mode (e.g., `.ultraThinMaterial`) and keep existing glass strokes/shadows.

## Implementation
### Shared Adaptive Background
- Create `AppBackgroundView` in `AppTheme.swift`:
  - Uses `@Environment(\.colorScheme)` to switch between:
    - Light: glass gradient (same as Health)
    - Dark: midnight blue gradient (same as Use By)
  - `.ignoresSafeArea()`

### Replace Per‑Screen Backgrounds
- `Views/Food/FoodTabViews.swift`
  - Header container and screen `.background(...)` → `AppBackgroundView()`
  - Keep segmented control and cards’ glass styling intact
- `ContentView.swift` (Progress)
  - Replace `progressGlassBackground` with `AppBackgroundView()`
  - Keep glass card visuals; ensure inner spacing stays consistent with History
- `Views/DiaryTabView.swift`
  - Replace `diaryBlueBackground` usages with `AppBackgroundView()`
  - Remove the local gradient function to avoid duplication
- Other screens currently using `Color.adaptiveBackground`
  - Optionally swap to `AppBackgroundView()` for perfect parity; otherwise, ensure `adaptiveBackground` maps to the same midnight palette defined in `AppTheme.swift`

### Card Surface Consistency (Dark Mode)
- Confirm cards use `.ultraThinMaterial` and the light gradient stroke:
  - Health cards: already glass
  - Use By list rows: already glass with stroke
  - Progress and Diary cards: confirm background/stroke are glass and balanced in dark mode

## Files To Update
- `AppTheme.swift`: add `AppBackgroundView`
- `Views/Food/FoodTabViews.swift`: swap background calls
- `ContentView.swift` (Progress view container): swap background calls
- `Views/DiaryTabView.swift`: swap background calls
- Optional: settings and other secondary views if they use their own backgrounds

## Verification
- Run the app in both light and dark modes:
  - Check Diary, Health, Progress, Use By for:
    - Background matches spec (glass in light, midnight in dark)
    - Cards remain readable, strokes/shadows subtle
    - No layout regressions (segment control, headers, lists)
- Quick pass for any remaining hard‑coded `.systemBackground` blocks that might pop in dark mode; replace with `.ultraThinMaterial` where appropriate.

## Rollback Safety
- Keep old background helpers until the swap is complete; remove after verifying parity.
- Scope is UI only; no functional changes.

Confirm this plan and I’ll implement the shared adaptive background and update the targeted screens accordingly.