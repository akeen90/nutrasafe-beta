## Understanding
- You want to keep the serving unit selector (g/ml/oz/etc.) as‑is for gram/volume foods.
- When a food is added using the “Unit” option with a custom label (e.g., Burger), the Food Detail page must display per‑unit: left editor shows “1 burger”, nutrition right column header shows “Per burger”, and values use per‑unit.

## Likely Root Cause
- Food Detail currently defaults to grams when it can’t confidently parse the unit (e.g., servingDescription not in the expected format).
- The detection relies on parsing text; it should pivot on the saved flag from the add flow.

## Fix Overview
1. Use the persisted flag to drive detection:
   - `isPerUnit = food.isPerUnit == true || !["g","ml","oz","kg","lb"].contains(servingUnit.lowercased())`.
   - Prefer the explicit `food.isPerUnit` set by Add Food.
2. Set initial editor state for per‑unit foods:
   - `servingAmount = "1"`.
   - `servingUnit = unitLabel` where:
     - `unitLabel = extractUnitLabel(food.servingDescription)` if it starts with `"1 "`.
     - Else `unitLabel = food.servingUnit` if present in record.
     - Else fallback to simple heuristics from the food name (burger/pizza/sandwich/etc.).
3. Prevent grams override on appear for per‑unit:
   - Guard the `onAppear` grams detection with `if !isPerUnit` so per‑unit items aren’t rewritten to `100 g`.
4. Ensure display uses per‑unit consistently:
   - Header shows `isPerUnit ? "Per \(servingUnit)" : "Per 100g"`.
   - Right values use `isPerUnit ? perServing : per100g` and suffix `unit/(isPerUnit ? servingUnit : "100g")`.

## Code Changes (localized)
- `NutraSafe Beta/Views/Food/FoodDetailViewFromSearch.swift`:
  - Initialization block (lines ~60–129): prefer `food.isPerUnit == true` to set `servingAmount`/`servingUnit`; add fallback to `food.servingUnit` when `servingDescription` isn’t in `"1 <unit>"` form.
  - Body `onAppear` (lines ~1362–1407): wrap grams extraction with `if !isPerUnit`.
  - Keep the already added dynamic per‑unit labels and right values (lines ~1780–1825, 2058–2156).

## Verification
- Add a new item via Unit option with label “Burger”. Open Food Detail:
  - Serving editor shows `1 burger`.
  - Calories card shows `Per burger` with correct values.
  - Nutrition rows show `g/burger` on the right column.
- Add a standard gram‑based item → still shows `Per 100g`.

## Risk
- Low; changes are confined to detection and initial state. Gram/volume foods remain unchanged.

## Notes
- This does not remove or change the unit selector; it only ensures saved per‑unit items render per‑unit without being forced to grams by default text parsing.
