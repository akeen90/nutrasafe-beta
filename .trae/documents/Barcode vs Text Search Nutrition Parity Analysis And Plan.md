## Pipelines Overview
- Main Search (Algolia):
  - Source: `AlgoliaSearchManager.search(...)` parses hits into `FoodSearchResult` with per‑100g macros and optional `servingSizeG`, `per_unit_nutrition`.
  - Mapping: `AlgoliaSearchManager.parseResponse(...)` sets `calories`, `protein`, `carbs`, `fat`, `fiber`, `sugar`, `sodium`, `brandName`, `servingSize`, `servingSizeG`, `per_unit_nutrition` → `FoodSearchResult`.
  - Code: Managers/AlgoliaSearchManager.swift:546–601.

- Barcode Scan:
  - Diary path: `AddFoodBarcodeView` → `searchProductByBarcode(...)` to Cloud Function `searchFoodByBarcode` → `BarcodeSearchResponse` → `FoodSearchResult`.
  - Mapping: `BarcodeSearchResponse.toFoodSearchResult()` sets macros and serving description, but may miss servingSizeG/isPerUnit; sodium unit can vary.
  - Code: Views/Food/BarcodeScanningViews.swift:340–391; Models/NutritionModels.swift:209–237.
  - Use By path: Algolia exact barcode first, then Cloud Function fallback (already aligned).

## Symptoms & Root Causes
- Symptom: Scan finds the product but UI shows no nutrition, while text search does.
- Likely causes:
  - Missing `servingDescription` (UI relies on it for per‑serving computations).
  - Inconsistent nutrition keys/units on barcode path (per‑serving vs per‑100g; sodium mg vs g).
  - Barcode mapping not setting `servingSizeG` or `isPerUnit`, causing per‑serving calculations to default incorrectly.
  - Differences in pipeline (Algolia vs Cloud Function) produce different shapes for `FoodSearchResult`.

## Evidence Pointers
- Main search mapping handles `Double`/`Int` coercion (Algolia) for macros (Managers/AlgoliaSearchManager.swift:559–566).
- Barcode mapping sets direct doubles but could leave `servingDescription` nil (Models/NutritionModels.swift:209–237). UI per‑serving calorie calc uses `servingDescription` (FoodSearchViews.swift:139–170).
- Detail UI computes per‑serving calories from per‑100g macros (FoodDetailViewFromSearch.swift:139–170), and relies on serving metadata initialized in the view’s `init` (FoodDetailViewFromSearch.swift:119–198).

## Fix Strategy
1) Normalize mapping on barcode path:
- Always set `servingDescription` to "per 100g" when absent.
- Add `servingSizeG` when known; otherwise leave calculation on per‑100g.
- Ensure all macros are per‑100g (not per serving) to match main search.
- Confirm sodium is consistent with main search (prefer mg per 100g or convert appropriately).

2) Unify retrieval order:
- Use Algolia exact barcode lookup first for both Diary and Use By; fallback to Cloud Function for OFF/Firestore hits.
- Keep consistent `FoodSearchResult` shape across both.

3) Instrumentation & Validation:
- Add debug prints in barcode path (name, per‑100g macros, servingDescription/sizeG) to compare with main search for the same product.
- Temporarily log when macros are zero or missing.

4) UI Consistency:
- Ensure detail view reads per‑100g macros and displays nutrition regardless of serving metadata, only scaling per‑serving where appropriate.

## Deliverables
- Updated barcode mapping (serving defaults, consistent per‑100g macros, sodium consistency).
- Algolia‑first barcode lookup in Diary scanner for parity.
- Debug logs added (and removable) to confirm nutrition parity.
- Quick unit test validating `BarcodeSearchResponse` → `FoodSearchResult` includes non‑zero macros.

## Rollout & Safety
- No backend changes; unify client mapping and retrieval order.
- Keep changes localized to barcode scanner + mapping; easy to revert.
- Validate with a few known products by scanning and text search; compare logs and UI.
