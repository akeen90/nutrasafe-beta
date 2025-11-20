## Objective
Update the "Use By" page empty state to display the pastel fridge illustration exactly as shown, with centered layout, headline, supportive copy, and the gradient CTA.

## Affected Files
- `NutraSafe Beta/Views/Use By/UseByTabViews.swift`
  - `UseByExpiryView` empty state block: 710–775
  - `UseByEmptyStateView` component: 1782–1944
  - `AnimatedFridgeIcon`: 5001–5079

## Implementation Steps
1. Keep the existing fridge in `UseByExpiryView` and refine spacing to match the design:
   - Use `AnimatedFridgeIcon()` centered, size ~140–160pt, light shadow.
   - Headline `Text("No items yet")` with `.font(.system(size: 20, weight: .bold))` and `.foregroundColor(.primary)`.
   - Description: "Never forget your food again. Add items to keep track of use-by dates." with `.multilineTextAlignment(.center)` and secondary color.
   - CTA: Gradient button labeled `"Add Your First Item"` using the existing gradient (751–771), full-width within a max card width (e.g., 320–360pt).
2. Unify the secondary empty state `UseByEmptyStateView` to also use the fridge illustration:
   - Replace SF Symbol blocks (`leaf.circle.fill`, `lightbulb.fill`) with `AnimatedFridgeIcon()`.
   - Match headline, description, and CTA to the main empty state for consistency.
   - Expose an `onAddFirstItem` closure to trigger the existing add flow; wire it in `UseByItemsListCard` (call site at 1477).
3. Wrap both empty states in a rounded card container:
   - Apply `RoundedRectangle(cornerRadius: 28)` or `.background(.ultraThinMaterial)` with soft shadow, matching the screenshot.
   - Ensure padding and spacing are consistent (e.g., 24–28pt vertical spacing, 20–24pt horizontal padding).
4. Avoid adding image assets:
   - Use the existing programmatic `AnimatedFridgeIcon` (5001–5079). No new `.xcassets` are required.

## Visual Details
- Layout: Centered stack with generous whitespace; max card width 360pt.
- Colors: Use the current gradient for CTA; keep text primary/secondary for light/dark mode.
- Icon: `AnimatedFridgeIcon` sized to align with screenshot; slight opacity and shadow for depth.

## Accessibility
- Set meaningful label on CTA: `accessibilityLabel("Add your first use-by item")`.
- Ensure Dynamic Type scales headline and description without clipping.
- Provide `AnimatedFridgeIcon` an `accessibilityHidden(true)` since it is decorative.

## Verification
- Build and run the app; navigate to Use By with an empty list.
- Confirm both the main page and any nested card views show the fridge illustration and matching text.
- Tap CTA and verify it launches the add item flow.
- Test light/dark mode and Dynamic Type sizes.

If you confirm, I’ll implement the changes in `UseByTabViews.swift` at the referenced locations, reuse `AnimatedFridgeIcon`, and standardize the empty state UX across the page.