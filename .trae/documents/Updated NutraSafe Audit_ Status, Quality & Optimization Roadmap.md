## Current Architecture
- SwiftUI-first UI with selective UIKit interop
- Navigation via a reusable container providing NavigationStack with fallback
- Data layer: SQLite actor (LIKE-based prioritized search) + Firebase Firestore
- Caching: Image cache with NSCache + disk, async IO for load/save
- Concurrency: async/await throughout; background tasks for debounce and disk IO

## Implemented Improvements (Verified)
- Async image cache APIs in use for UseBy and weight images
- Debounce off-main for search; cancellation guard
- LazyVStack adopted across search, food tab, diary, use-by and food detail lists
- Navigation consolidation in Food flows via container wrapper
- Nutrition card rows restyled: white striped rows inside grey card; per-100g right-aligned
- Additive analysis: boundary-aware allergen detection, tighter preservative fallbacks, CSV fallback merged, first additive card expanded by default
- Search rolled back to LIKE with domain ranking; FTS no longer filters candidates by default

## Performance Status (6/10)
- Pros: Async image IO, early limiting in SQLite/Firebase, debounce off main, lazy lists
- Cons: Very large views still drive recomposition; prints in hot paths; a synchronous weight image save path remains; broad EnvironmentObject usage

## Code Quality Status (6/10)
- Pros: Clear separation (SQLite/Firebase/caching), navigation wrapper, accuracy improvements in additive detection
- Cons: Commented blocks, legacy NavigationView in many screens, prolific prints, scattered TODOs, potential unsafe `!` patterns in large views

## Priority Issues & References
- Synchronous weight image write path: ContentView.swift:3358 (switch to async save API)
- Hot-path logging: FoodDetailViewFromSearch.swift:111–117, 216–233, 977–979; ContentView.swift:635–637, 775–789; FirebaseManager & SQLiteFoodDatabase
- Legacy NavigationView usages: FoodDetailViewFromSearch, SettingsView, DiaryTabView, UseByTabViews
- Oversized views: ContentView.swift (~7.5k), FoodDetailViewFromSearch (~5k), UseByTabViews (~4.1k), DiaryTabView (~3k), SettingsView (~3.7k)

## Metrics
- Commented lines: ~6,439 across 93 files
- Prints: ~1,043 across 42 files
- TODO/FIXME: 21 across 7 files
- Files >1k lines: multiple core screens; see list above

## Roadmap (Next Steps)
1) Replace sync weight image writes with async variants in ContentView; confirm off-main execution
2) Gate and reduce prints in hot paths under DEBUG; keep error logs only
3) Continue migration to navigation container: remove nested NavigationView in remaining sheets
4) Split oversized views into subviews; move heavy onAppear to lightweight async loaders
5) Audit and replace risky `!` usages in biggest views
6) Confirm consolidated additive parsing covers tightened preservative cases end-to-end
7) Optional: reintroduce FTS as a secondary boost (not filter), strictly for name/brand matches, preserving current ranking

## Request to Proceed
Approve and I’ll start with items (1)–(3): async weight image writes, logging gates in hot screens, and navigation consolidation in remaining sheets; then deliver incremental updates with measurements (search latency, page transition smoothness, recomposition reduction).