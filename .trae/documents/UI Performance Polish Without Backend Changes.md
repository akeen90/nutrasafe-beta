## Goals
- Reduce perceived and actual UI latency across all pages without touching Firebase/Cloud Functions.
- Unify typography, spacing, and surfaces so screens feel solid (no "zoomed in" look).
- Prevent jank by eliminating heavy view work on the main thread and curbing layout re-composition.

## Core Strategies
- SwiftUI rendering hygiene: aggressively avoid unnecessary re-renders, animate sparingly, and virtualize lists.
- Lightweight visuals: favor simple surfaces over gradients/material blur; consistent tokens from `DesignSystem`.
- Async work isolation: move image decoding, cache warm-ups, and ranking to background tasks; cancel on disappear.

## Design System Alignment
- Typography: replace ad‑hoc 38pt/rounded with `AppTypography` (largeTitle/title2/title3; body/subheadline).
- Spacing: adopt `AppSpacing` grid to reduce oversized padding; tighten headers and cards.
- Surfaces: swap gradient/blur backgrounds for `AppColors.background` and `standardCard/elevatedCard`.
- Shadows: use `AppShadow.small/medium`; remove costly layered shadows.

## Rendering & State Management
- Convert `@ObservedObject` → `@StateObject` where view owns the model to stop duplicate subscriptions.
- Memoize computed props: cache sorted/filtered arrays and stats; recompute only when source data changes.
- List virtualization: ensure `LazyVStack`/`List` uses stable `id`; split heavy row subviews into pure value views.
- Animation discipline: disable implicit animations for large collections (`.transaction { $0.disablesAnimations = true }`).
- Notification throttling: debounce high-frequency `NotificationCenter` updates with Combine before updating state.

## Async & Images
- Image pipeline: keep `SimpleImageCache` but decode on a background thread; scale down before render.
- Async loaders: wrap image and network fetches in `Task` with `.userInitiated` priority; cancel on `onDisappear`.
- Prefetch small thumbnails where lists appear; load full-resolution only when detail is opened.

## Screen-Specific Actions
- Use By
  - Header: `AppTypography.largeTitle`, smaller horizontal padding; remove blur/gradients.
  - Items: cached sort/filter; pure row component; explicit `id` and minimal modifiers.
  - Presentation: avoid nested modals; keep one sheet at a time; delay expensive work until save.

- Health → Fasting
  - Replace large rounded fonts with `AppTypography`; trim header paddings.
  - Timer: update only the time label each tick; avoid recomputing complex sections every second.
  - Insights cards: static rendering with memoized values; no repeated shadow stacking.

- Food Tab
  - Segmented control: reuse tokenized styles; remove extra material overlays.
  - Results lists: stable keys, lean rows; async ingredient expansions off main thread.

- Diary
  - Date grouping and totals: compute once per day; cache; update only when entries change.
  - Cards: standard card tokens; reduce nested stacks.

## Smoothness & Feel
- Haptics: keep light haptics; avoid repeated triggers on state changes.
- Transitions: simplify to `.opacity` or none for large containers; avoid complex matched geometry for core flows.
- Material effects: limit `.ultraThinMaterial` usage; use solid surfaces except for small badges.

## Instrumentation & Validation
- Add signposts/timing logs around list render and image decode (compile-time flag only; no backend changes).
- Use Instruments’ SwiftUI and Time Profiler to confirm reduced recomposition and shorter frame times.
- Target: headers render <16ms, list scroll smooth at 60fps on simulator and device.

## Rollout & Guardrails
- Strictly UI-only: no changes to Firebase calls, data formats, or Cloud Functions.
- Incremental commits per screen to minimize risk and enable quick visual checks.
- Keep a feature flag (internal) to toggle gradients/material for A/B visual comparison during QA.

## Deliverables
- Updated headers, backgrounds, and spacing across Use By, Health/Fasting, Food, Diary.
- Cached/memoized views with throttled notifications.
- Async image pipeline improvements and cancellation.
- QA report with Instruments screenshots and before/after metrics.
