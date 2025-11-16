## Root Cause

* The Use By screen (`UseByTabView`) embeds its own `NavigationView` while the app already wraps all tabs in a top-level `NavigationStack` for iOS 16+ (ContentView\.swift:1506–1512). Nested navigation containers can create an invisible navigation bar overlay on some iOS builds that intercepts touches near the top.

* This manifests as header actions not firing for top-right buttons (cog and plus) on specific device profiles (iPhone 16), while newer profiles (iPhone 17) don’t show the issue.

* Evidence:

  * Inner navigation container start: `UseByTabViews.swift:99` shows `NavigationView { ... }` wrapping the entire screen.

  * Header buttons: `UseByTabViews.swift:110–134` (cog) and `UseByTabViews.swift:135–178` (plus). They’re placed in the manual header under the nested nav, likely under the intercept region.

## Fix Overview

1. Remove the inner `NavigationView` from `UseByTabView` and rely on the parent `NavigationStack`.
2. Keep the existing `.navigationBarHidden(true)` behavior out — it will be unnecessary once the nested nav is gone.
3. Ensure the manual header is laid out below the safe area using one of:

   * Add `safeAreaInset(edge: .top)` or `safeAreaPadding(.top)` to the screen container

   * Or `padding(.top, 8)` combined with `.ignoresSafeArea(.keyboard)` if needed (keyboard sections already managed elsewhere)
4. No change needed to `SpringyButtonStyle` — button styles don’t affect hit-testing.

## Implementation Steps

* In `UseByTabViews.swift`:

  * Remove the outer `NavigationView { ... }` wrapper and its `.navigationViewStyle(StackNavigationViewStyle())`.

  * Make the top-level of `UseByTabView.body` a `VStack(spacing: 0)`.

  * Add `safeAreaInset(edge: .top) { Color.clear.frame(height: 0) }` or equivalent so the header is always below any system bar on all devices.

  * Retain all existing `.sheet`/`.fullScreenCover` modifiers on the root view (they will still work without the inner nav).

* Verify `showingSettings` binding flows to the parent where the settings sheet is presented. If needed, ensure the parent attaches the sheet (it already does for other tabs; add if missing).

## Verification

* Run on iPhone 16 and iPhone 17 simulators; confirm both header buttons respond:

  * Cog: toggles `showingSettings` → settings sheet appears.

  * Plus: sets `selectedTab = .add` → switches to Add tab.

* Add temporary logs around button actions to confirm taps fire on both devices (remove after verification).

* Check overlap by enabling the Xcode Debug View Hierarchy; ensure no invisible bar overlays the header.

## Risk & Rollback

* Low risk: Removing nested `NavigationView` aligns with modern SwiftUI best practices and avoids container conflicts.

* If any unexpected navigation side effects appear, reintroduce navigation behaviors using the parent `NavigationStack` toolbars instead of local nav wrappers.

## Deliverables

* Updated `UseByTabViews.swift` without nested `NavigationView`.

* Safe-area aware header layout.

* Verified tap interactions on iPhone 16 and 17.

