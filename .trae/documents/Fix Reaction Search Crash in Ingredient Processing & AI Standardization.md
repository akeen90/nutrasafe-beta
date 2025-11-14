## Suspected Crash Points
- Unsafe parenthesis parsing: uses `firstIndex("(")` and `lastIndex(")")` without ensuring `openParen < closeParen`; can slice with invalid ranges when only a trailing `(` or mismatched order exists.
- Invalid Cloud Function URL string: includes backticks and spaces (`" `https://...` "`), causing URL init to fail and thrown errors that may bubble up without handling, crashing reaction search.
- Missing network guards: no timeout/retry; errors not caught locally.

## Fix Plan
1) Safe Parenthesis Parsing
- Replace the single-pass `firstIndex/lastIndex` logic with a resilient parser:
  - Ensure `openParen` exists and `closeParen` exists and `openParen < closeParen` before slicing.
  - Support multiple parenthetical groups by iterating while pairs exist; for each, extract `main` and `sub`, normalize, and deduplicate.
  - If parentheses are unbalanced, treat the string as `main` only (no slicing) to avoid out-of-range errors.
- Keep percentage removal and punctuation trimming; perform normalization (`\s+` collapse) after extraction.

2) Fix Cloud Function URL and Harden Networking
- Use a clean endpoint string: `https://us-central1-nutrasafe-705c7.cloudfunctions.net/standardizeIngredients` (no backticks/spaces).
- Build requests via `URLComponents` to avoid malformed URLs.
- Add a small network wrapper with:
  - 10s timeout
  - JSON decode with clear error handling
  - Graceful fallback: on any error, return original `ingredients` unmodified (never throw up to UI).
- Log under `#if DEBUG` for diagnostics; no logs on release.

3) Error Containment
- Wrap `standardizeIngredientsWithAI` calls in `do/catch` and continue with local processing on failure.
- Ensure reaction search UI never throws; return best-effort processed ingredients.

4) Validation
- Test with inputs containing:
  - "butter (milk)" → ["butter", "milk"]
  - "raising agent (E500)" → ["raising agent", "E500"]
  - Unbalanced: "flavor (natural" → ["flavor (natural"] (no crash)
  - Percentages: "milk (2%)" → ["milk"]
- Verify the Greggs example and any items with complex parentheses/percentages.

## Deliverables
- Updated ingredient normalization function with safe parenthesis handling
- Corrected AI standardization URL and resilient networking
- Catch-all error handling so reactions never crash

Approve to proceed and I will implement these fixes and validate on real product labels.