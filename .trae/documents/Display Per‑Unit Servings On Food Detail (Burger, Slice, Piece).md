## Problem

* After typing in the Add Use By search, taps on the top header actions (Search, AI/Manual, Barcode, Close/X) intermittently don’t register.

* Cause: Focused `TextField` + scrolling results can intercept touches; header lives above but hit-testing prefers the focused field until keyboard is dismissed. This varies across iOS builds.

## Fix Scope (covers ALL top actions)

1. Proactively dismiss keyboard on all header actions:

   * In `AddUseByItemSheet` header (Close/X and mode chips via `AddOptionSelector`) and in `AddOptionSelector` itself, call `UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)` before changing state.
2. Improve search bar hit-testing:

   * Convert the trailing clear (x) into an overlay of the search field so it sits above the `TextField` for reliable taps.
3. Enable scroll-based keyboard dismissal:

   * Add `.scrollDismissesKeyboard(.interactively)` on the results `ScrollView` inside `UseByInlineSearchView`.
4. Ensure header is topmost:

   * Keep `.zIndex(2)` on the header container and `.zIndex(0)` on content to prevent overlaying.

## Implementation (files/areas)

* `NutraSafe Beta/Views/Use By/UseByTabViews.swift`:

  * `AddUseByItemSheet` header HStack: add keyboard-dismiss call in Close/X and each chip tap.

  * `UseByInlineSearchView`: change the clear button to a trailing overlay; add `.scrollDismissesKeyboard(.interactively)` on the results `ScrollView`.

* `NutraSafe Beta/ContentView.swift` (`AddOptionSelector`, \~6958): add the keyboard-dismiss call at the start of the `Button(action:)` so switching Search/AI/Manual/Barcode always works immediately after typing.

## Verification

* Reproduce on iPhone 16/17: type a query; tap Close/X, Search, AI/Manual, or Barcode → taps register immediately (no need to manually dismiss keyboard).

## Risk

* Low; localized UI behavior changes. Easy rollback if needed.

## Deliverables

* Updated header actions and search bar behavior for reliable interaction across devices.

