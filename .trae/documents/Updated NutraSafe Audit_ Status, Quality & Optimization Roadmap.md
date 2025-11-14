## Objectives
- Ensure items like “Greggs Bacon and Sausage Roll” always show ingredients
- Merge verified Firebase data into local results even when SQLite returns items
- Relax strict brand/name enrichment gates while keeping accuracy
- Add client barcode Cloud fallback

## Changes
1) Parallel Verified Enrichment
- Update `FirebaseManager.searchFoods` to call the Cloud Function search in parallel with local sources
- Merge results by a deterministic key (normalized `brand+name`), preferring verified `ingredients`, `isVerified`, and micronutrients
- Files: `NutraSafe Beta/FirebaseManager.swift` (searchFoods merge section)

2) Normalization & Matching Utility
- Add a small helper to normalize brand/name (trim, lowercase, strip punctuation and corporate suffixes “PLC”, “Ltd”), collapse whitespace
- Use for map keys and enrichment comparisons
- Files: `NutraSafe Beta/FirebaseManager.swift` (private helpers)

3) Relax Pending Verification Gate
- In `FoodSearchViews`, enrich when:
  - Name matches (normalized)
  - Brand matches OR either side brand is missing (normalized)
- Keep existing safeguards to avoid wrong matches
- Files: `NutraSafe Beta/Views/Food/FoodSearchViews.swift` (pending verifications enrichment block)

4) Barcode Client Fallback
- If SQLite barcode search has no ingredients or not found, call the Cloud Function barcode search (server already aggregates verified/foods and OpenFoodFacts)
- Merge response into the local result
- Files: `NutraSafe Beta/FirebaseManager.swift` (barcode search path)

5) Ingredients Field Consistency
- Ensure client consistently reads `ingredients` string and splits to `[String]`; retain `ingredientsText` only for ingest collections
- Files: `NutraSafe Beta/FirebaseManager.swift` (collection mappings)

6) Debug Trace (optional)
- Under `#if DEBUG`, log enrichment decisions: match keys, chosen source (verified/pending), and final ingredients count
- Files: `NutraSafe Beta/FirebaseManager.swift`, `NutraSafe Beta/Views/Food/FoodSearchViews.swift`

## Validation
- Test cases:
  - “Greggs Bacon and Sausage Roll” → ingredients populated from verified
  - Items with brand variants (“Greggs”, “Greggs PLC”) → enriched post-normalization
  - Barcode-only items → Cloud fallback enriches
  - Simple fruit (Apple) → no additives, no false enrichment
- Manual runs and quick Instruments checks to confirm no UI stalls

## Deliverables
- Updated search/enrichment with verified merge, relaxed gate, barcode fallback, normalization helpers, and DEBUG traces
- Short report: examples verified and places changed

Approve to proceed and I will implement these targeted fixes and validate with the above test cases.