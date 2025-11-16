## Cause
- `NutritionFactsSectionView` references `isPerUnit` and `servingUnit` that exist only in the parent view, causing compile errors in `FoodDetailViewFromSearch.swift`.

## Fix
1. Add `isPerUnit: Bool` and `servingUnitLabel: String` parameters to `NutritionFactsSectionView` and store them as properties.
2. Pass these from the parent via `nutritionFactsSection` when constructing the section.
3. Inside `NutritionFactsSectionView`:
   - Change the header text from static to `isPerUnit ? "Per \(servingUnitLabel)" : "Per 100g"`.
   - Use a dynamic right value: `let rightCalories = isPerUnit ? adjustedCalories : per100Calories`.
   - Update the legacy `row` function to use `isPerUnit ? perServing : per100` and suffix `unit/(isPerUnit ? servingUnitLabel : "100g")`.
4. Keep `nutritionRowModern` in the parent using the existing `isPerUnit` and `servingUnit` state; no changes needed there.

## Verification
- Build for simulator and device; ensure no compile errors.
- Open a per‑unit food (e.g., burger): header shows “Per burger”, rows show per‑unit values on the right.
- Open a gram‑based food: header shows “Per 100g”, rows show per‑100g values on the right.

## Risk
- Low and localized to FoodDetailViewFromSearch.swift. Easy rollback.