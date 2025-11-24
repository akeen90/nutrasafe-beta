## What’s Actually Failing
- The crash happens immediately after selecting a search result and returning to the reaction form.
- The reaction form is a SwiftUI `Form` (`NutraSafe Beta/Views/Food/FoodTabViews.swift:1739`) which is backed by a UIKit `UICollectionView`. Apple’s “UICollectionViewFeedbackLoopDebugger” error indicates self-sizing rows keep changing size, or the list’s contentOffset/insets keep being adjusted.
- In our form, multiple sections are self-sizing and change as soon as a food is selected:
  - `onChange(of: selectedFood)` at `FoodTabViews.swift:1783–1787` calls `autoLoadIngredientsFromFood`, which updates `suspectedIngredients` immediately and then again later from an async AI refinement (`2000–2008`).
  - The “Symptoms” and “Suspected Ingredients” sections render variable-size chip grids using `LazyVGrid(.flexible columns)`, which reflow as content changes. Inside `Form`, this causes cell height to oscillate across layout passes.
- That combination (Form + dynamic grids + rapid state changes) matches Apple’s described loop: sizes are inconsistent so the collection view keeps coalescing and re-laying out.

## Minimal, Targeted Fix (No broad refactor)
1. Stop immediate, chained layout changes while the sheet is dismissing.
   - Remove the auto-import on selection: delete `onChange(of: selectedFood)` block at `1783–1787` so ingredients only load when the user taps “Load from Food”.
2. Make the grids report stable sizes.
   - Add `.animation(nil, value: symptoms)` and `.animation(nil, value: suspectedIngredients)` on the containers of those chip grids to avoid animated size changes inside a self-sizing `Form`.
3. Reset the form’s row when a new food is selected.
   - Add `.id(selectedFood?.id ?? "none")` to the main container inside `Form` to ensure a single, consistent measurement per selection.

## Robust Fix (Preferred)
- Replace the `Form` with `ScrollView { VStack(...) }` in `LogReactionView`.
  - File/lines: change the `Form {` starting at `FoodTabViews.swift:1739` to `ScrollView { VStack(spacing: 20) { ... } }` and preserve the existing inner content and styling.
  - Add `.animation(nil, value: symptoms)` and `.animation(nil, value: suspectedIngredients)` to keep size stable during updates.
  - Optionally add `.id(selectedFood?.id ?? "none")` to the `VStack` to reset once per selection.
- This removes UIKit’s `List/Form` self-sizing machinery entirely and is the most reliable way to prevent feedback loops with dynamic chip layouts.

## Verification Plan
- Reproduce with Pret’s Lasagne Soup and other foods with long ingredient lists.
- Confirm no crash, ingredients chips render, and Save works.
- Also test typing custom symptoms/ingredients rapidly to ensure stability.

## Why This Matches Your “New Issue” Observation
- The recent addition of dynamic chips (Symptoms/Ingredients) inside the reaction form, plus the auto-load on selection, is exactly the kind of change that can introduce this layout loop in SwiftUI forms. The search screen is fine (it uses `ScrollView`), but returning to the `Form` triggers the loop.

If you prefer the minimal fix, I’ll implement that first. Otherwise I’ll apply the robust fix that removes `Form` entirely for this screen and verify the scenario end-to-end.