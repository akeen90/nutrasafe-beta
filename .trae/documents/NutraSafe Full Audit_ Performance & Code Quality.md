## Issue
- Error: Cannot find `FoodScoresSectionView` in scope at `Views/Food/FoodDetailViewFromSearch.swift:3118`.
- Cause: The new component file `Views/Components/Food/FoodScoresSectionView.swift` is likely not included in the app target, so the type isn’t compiled and visible.

## Fix Plan (Quick & Reliable)
1. Inline the `FoodScoresSectionView` struct directly into `FoodDetailViewFromSearch.swift` (below the main view type), ensuring it’s compiled in the same file and scope.
2. Keep the call site unchanged (`foodScoresSection` returns `FoodScoresSectionView(...)`) so we maintain the refactor and reduce recomposition.
3. Rebuild to validate that the symbol is resolved.

## Alternative (If you prefer to keep separate file)
- Add `Views/Components/Food/FoodScoresSectionView.swift` to the app target in Xcode and ensure it’s part of the NutraSafe Beta target. Confirm `import SwiftUI` is present.

Approve to proceed and I will apply the inline fix immediately and verify the build. 