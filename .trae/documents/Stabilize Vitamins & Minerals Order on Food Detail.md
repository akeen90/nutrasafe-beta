## Findings
- The vitamins/minerals cards render from `getDetectedNutrients()` which returns `Array(Set)`; order is nondeterministic and can change every render, causing visible "jumping".
- Source: `NutrientDetector.detectNutrients` returns `Array(detectedNutrients)` from a `Set` in NutrientTrackingModels.swift:428–429.
- The UI iterates directly over this array in `vitaminsContent` using `ForEach(Array(detectedNutrients.enumerated()), id: \.element)` in FoodDetailViewFromSearch.swift:3696–3709, while tab switching is animated (`withAnimation`) in FoodDetailViewFromSearch.swift:3510–3512, amplifying the reorder effect.

## Changes
1. Deterministic ordering
- Sort detected nutrient IDs before use, using the canonical order from `NutrientDatabase.allNutrients` (vitamins first, then minerals). Fallback to alphabetical for unknown IDs.
- Implement either inside `NutrientDetector.detectNutrients(in:)` (preferred, ensures consistency everywhere) or sort in `vitaminsContent` before `ForEach`.

2. UI iteration stability
- Remove `enumerated()` and iterate `ForEach(sortedIds, id: \.self)`.
- Keep `cardId` as the `.id(...)` for scroll targeting.

3. Animation smoothing
- Prevent implicit reordering animations for the vitamins list by adding `.transaction { $0.disablesAnimations = true }` on the container that holds `ForEach(sortedIds, ...)` or `.animation(nil, value: sortedIds)`.
- Keep expand/collapse animation inside `NutrientInfoCard` intact.

4. Optional caching
- Memoize the sorted nutrient IDs based on `food.ingredients` so the list doesn’t recompute on unrelated state changes. Update when `cachedIngredients` changes.

## Implementation Sketch
- In `NutrientDetector.detectNutrients`:
  - Build `let order = NutrientDatabase.allNutrients.map { $0.id }`.
  - Return `Array(detected).sorted { (order.firstIndex(of: $0) ?? Int.max, $0) < (order.firstIndex(of: $1) ?? Int.max, $1) }`.
- In `vitaminsContent`:
  - Replace the `ForEach(Array(detectedNutrients.enumerated()), ...)` with `ForEach(sortedDetected, id: \.self) { nutrientId in ... }` and wrap the list container with a transaction that disables animations.

## Verification
- Open a food with multiple detected nutrients, switch tabs, expand/collapse a few cards, and adjust serving size. Confirm card order is stable and no jumping occurs.
- Use existing debug logs in FoodDetailViewFromSearch.swift to print the sorted IDs once per render to validate determinism. 