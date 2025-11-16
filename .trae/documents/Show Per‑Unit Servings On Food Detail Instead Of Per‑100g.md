## Goal
Display nutrition per serving unit (e.g., “1 burger”) on the food detail page when foods are per‑unit, and replace the “Per 100g” column/labels with “Per <unit>”.

## Detection
- Define per‑unit mode as any serving unit that is not a mass/volume: `!['g','ml','oz','kg','lb'].contains(servingUnit.lowercased())`.
- We already split serving amount/unit (`servingAmount`, `servingUnit`) in FoodDetailViewFromSearch.swift and set per‑unit defaults for “1 unit” foods.

## UI Changes
- Replace static “Per 100g” labels with dynamic text:
  - Section header at FoodDetailViewFromSearch.swift:2057 → `Text(isPerUnit ? "Per \(servingUnit)" : "Per 100g")`.
  - Modern rows at 1764–1807: change right suffix from `unit + "/100g"` to `unit + (isPerUnit ? "/\(servingUnit)" : "/100g")` and show the appropriate value.
  - Legacy `row` at 2106–2135: change the appended `" \(unit)/100g"` similarly.

## Data Values
- For per‑unit foods, the right column should show “per <unit>” values (equal to per‑serving for 1 unit). Implementation:
  - Introduce `isPerUnit` computed property near serving properties.
  - When building rows, pass `perRight = isPerUnit ? perServing : per100g`.
- Existing totals already branch for per‑unit vs per‑100g (1845–1863); no change needed.

## Serving Options (optional)
- Extend `servingUnitOptions` (≈301) to include common per‑unit labels: `serving`, `piece`, `slice`, `burger`. This improves editing consistency.

## Verification
- Fast‑food example without grams: shows “Per burger” on the right and serving selectors display “1 burger”.
- A typical packaged food with grams: continues showing “Per 100g”.
- Check calories/macros match expected for both modes.

## Risk
- Low; changes are localized to labels and per‑right value selection. Rollback is easy.

## Deliverables
- Updated dynamic labels and value selection in FoodDetailViewFromSearch.swift.
- Optional expanded unit picker list for per‑unit editing consistency.