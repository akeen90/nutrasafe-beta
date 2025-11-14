## Diagnosis
- Crashes occur in reaction search when ingredient parsing or AI standardization throws uncaught errors in `Views/Food/FoodTabViews.swift`.
- Risky code:
  - Parenthesis slicing without order check (`FoodTabViews.swift:1960–1971`): uses `firstIndex("(")` and `lastIndex(")")` but does not verify `openParen < closeParen`.
  - Network call is `throws` with no local catch at call site (`FoodTabViews.swift:1872` calls `try await standardizeIngredientsWithAI(standardized)`), so any failure (network/decoder) cancels the task and can crash the UI flow.
  - `standardizeIngredientsWithAI` lacks timeout and error handling; returns `throws` up the stack (`FoodTabViews.swift:1984–2004`).

## Fix Plan
1) Safe Parenthesis Parsing
- Verify `openParen` and `closeParen` exist and `openParen < closeParen` before slicing.
- Handle nested/multiple parentheses in a loop; if unbalanced, skip slicing and keep original cleaned text.
- Keep percentage removal and punctuation trimming; normalize whitespace after parsing.

2) Resilient AI Standardization
- Correctly guard and contain errors:
  - Add 10s timeout to `URLSession`
  - Wrap request in `do/catch` and return the input `ingredients` on any error
  - Decode safely; if decode fails or `success == false`, fall back without throwing
  - Add DEBUG-only logs of failures
- Change call site `FoodTabViews.swift:1872` to `do/catch` and continue pipeline if AI step fails (never crash).

3) Cancellation & Debounce
- Treat `CancellationError` specially and stop processing without error propagation when the user changes input mid-flight.
- Debounce upstream if needed to avoid sending AI requests while the user is typing rapidly.

4) Validation
- Test cases:
  - “butter (milk)” → [butter, milk]
  - “raising agent (E500)” → [raising agent, E500]
  - Unbalanced: “flavor (natural” → returns original without crash
  - “milk (2%)” → cleans to [milk]
- Reproduce with “cake” query in reaction search: confirm no crash and responsive UI.

## Deliverables
- Updated parsing and robust networking in `Views/Food/FoodTabViews.swift`
- Safe call sites with `do/catch`
- Instrumented (DEBUG) logs for troubleshooting without affecting release performance

Approve to proceed and I will implement these changes and validate against your reported scenario.