## Summary
- The iOS client’s direct Algolia REST search sends `optionalWords` for every query and the synonym re‑ranking only checks full‑string containment. This lets single‑word matches like “egg” outrank precise two‑word matches like “egg boiled”.

## Evidence
- Client search params add `optionalWords: query` unconditionally in `NutraSafe Beta/Managers/AlgoliaSearchManager.swift:571–578`.
- Two‑word query handling creates word‑order variants, but the final `rankResultsForSynonymSearch` only does exact/startsWith/contains on the full string and doesn’t score word‑wise presence (`AlgoliaSearchManager.swift:406–445`).
- The initial smart ranking (`rankResults`) does include word‑wise scoring (`AlgoliaSearchManager.swift:496–558`), but it’s not used after combining synonym/variant queries.

## Fixes
1. Only set `optionalWords` for 3+ word queries.
- Compute word count and omit `optionalWords` and `removeWordsIfNoResults` for two‑word queries. This forces both words (“boiled” and “egg”) to be required while still allowing your existing word‑order variants to match.
- File: `NutraSafe Beta/Managers/AlgoliaSearchManager.swift`.

2. Strengthen synonym re‑ranking to be word‑aware.
- Update `rankResultsForSynonymSearch` to:
  - Add a score when all query words appear in the name in any order (prefix or exact), mirroring `rankResults` logic.
  - Add a score when any query word matches the start of the name.
  - Keep existing exact/startsWith/contains bonuses and verified/length bonuses.
- File: `NutraSafe Beta/Managers/AlgoliaSearchManager.swift`.

3. Optional (only if noise persists): reduce ingredient noise.
- Consider disabling typo tolerance on `ingredients` or lowering its impact via index settings so “egg” in ingredients doesn’t outrank precise name matches. This is configured in Functions scripts (`firebase/functions/src/algolia-sync.ts` and `firebase/functions/configure-algolia-direct.js`). We can change later if needed.

## Implementation Steps
1. Edit `searchIndex(...)`:
- Build `params` with `query`, `hitsPerPage`, `typoTolerance`, `getRankingInfo`.
- If `queryWords.count >= 3`, set `optionalWords = query` and `removeWordsIfNoResults = "allOptional"`; else omit both.

2. Edit `rankResultsForSynonymSearch(...)`:
- Compute `queryWords` set and `nameWords` per result.
- Add scoring rules:
  - +3000 if all query words appear in name (any order, prefix or exact).
  - +2000 if any query word matches the start of the name.
- Keep exact/startsWith/contains checks and the verified/length bonuses.

3. Build & verify on device/simulator:
- Search: “boiled egg”, “egg boiled”, “poached egg”, “fried egg”.
- Acceptance: items named “Egg Boiled …” rank ahead of unrelated egg items (salad/mayo/bacon).

## Rollback/Side‑Effects
- Restricting `optionalWords` to 3+ words improves precision for 2‑word phrases without hurting longer queries.
- Synonym re‑ranking becomes consistent with the smart ranking used per index.

## Next Actions (upon approval)
- Apply the Swift changes.
- Run a quick smoke test and share before/after screenshots and timings.
- If ingredient noise still dominates, fine‑tune index typo tolerance for `ingredients`.