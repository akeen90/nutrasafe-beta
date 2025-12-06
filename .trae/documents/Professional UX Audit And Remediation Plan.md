## Problem Summary
- Scanning finds products but nutrition does not appear, while text search of the same product shows nutrition. This indicates a mismatch between the barcode pipeline and the text-search pipeline in how nutrition fields are fetched/mapped/displayed.

## Likely Causes
- Barcode path uses a different backend/response shape than text search, and the mapping to `FoodSearchResult` drops nutrition.
- Missing `servingDescription` (affects per‑serving computations in UI) or nutrition keys differ (e.g., `per100g` vs direct doubles).
- UI components expect per‑100g fields but barcode path returns per‑serving or unlabeled values.

## Observed Code Paths
- Text search: Algolia REST (instant) via `AlgoliaSearchManager.parseResponse` -> `FoodSearchResult` with calories/protein/carbs… per 100g.
- Barcode scan:
  - Diary: `AddFoodBarcodeView` calls Cloud Function `searchFoodByBarcode` returning `BarcodeSearchResponse` (NutritionModels.swift:209–237) → mapped to `FoodSearchResult`.
  - Use By: now Algolia exact barcode first, then Cloud Function fallback.

## Remediation Plan
### 1) Unify the Pipeline
- Use Algolia exact barcode lookup first for both Diary and Use By (index filters `barcode:<code>`), then fallback to Cloud Function.
- Ensure both paths produce `FoodSearchResult` with consistent per‑100g nutrition fields.

### 2) Normalize Mapping
- Confirm `BarcodeSearchResponse.toFoodSearchResult()` sets:
  - `calories` (Double or `{kcal}`)
  - `protein`, `carbohydrates`, `fat`, `fiber`, `sugar`, `sodium` (per 100g), matching decoder expectations.
- Always set `servingDescription` (e.g., "per 100g") when the source doesn’t provide a specific serving to support UI calculations.

### 3) Instrument & Validate
- Add temporary debug logging around barcode scan result (keys and values) to compare with text search results.
- Build a small unit test for `FoodSearchResult` decoding using mock barcode JSON and ensure non‑zero macros.

### 4) UI Consistency Checks
- Ensure `FoodSearchResultRowEnhanced` uses per‑100g values directly for tags and per‑serving only for the header calorie chip.
- Verify that “Product Found” flows in scanner show the same nutrition set as text search.

### 5) Edge Cases
- OpenFoodFacts fallback: confirm transform sets nutriments consistently (per 100g) and sets `serving_description` to "per 100g".
- Missing fields: default to 0 only when absent; avoid swallowing valid numeric strings by tightening decode.

### 6) Verification Steps
- Scan a known product and perform text search for the same; compare values inline.
- Validate on device and simulator with Instruments to ensure no UI jank from the added logging.

## Deliverables
- Unified barcode pipeline using Algolia-first, consistent nutrition mapping, and verified UI display parity with text search.
- Unit test covering barcode → `FoodSearchResult` decoding.
- Temporary debug logs removed after validation.