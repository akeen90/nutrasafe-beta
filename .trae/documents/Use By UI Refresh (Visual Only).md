## Goals
- Improve visual clarity and polish in Use By screens with no functional changes
- Modern card layout, consistent spacing/typography, clearer status indicators

## Scope
- File: `Views/Use By/UseByTabViews.swift`
- Create small reusable components under `Views/Components/UseBy/` (visual-only)
- Respect existing data flow, bindings, and actions

## Visual Changes
1) Card Layout for Items
- Replace plain rows with card-style containers (rounded 12–16, subtle shadow) on `systemBackground`
- Left: thumbnail (40–56px with rounded corners)
- Center: product name (semibold), secondary line (quantity or location)
- Right: expiry badge (pill) with days left and small calendar icon

2) Status Badges
- Color-coded badges for time-to-expiry:
  - Overdue: red ("Expired")
  - Due today: orange ("Today")
  - Soon (≤3 days): yellow ("Soon")
  - Safe (>3 days): green ("OK")
- Implement as a pure view (no logic change; use existing derived values)

3) Section Styling
- Add section headers with uppercase caption and divider
- Use grouped background (`systemGroupedBackground`) with consistent 16–20 padding
- Remove hard separators; prefer card spacing and subtle dividers within cards

4) Typography & Spacing
- Standardize font sizes: title 15–16 semibold, subtitle 12–13 regular, badge 11–12
- Use 8/12/16 spacing scale; align iconography to baseline

5) Inline Search & Filters (Visual Only)
- Rounded search field with magnifier and clear button styling
- Pill segmented toggles for views (e.g., "All", "Soon", "Expired") if present; keep existing state

6) Empty/Loading States
- Card-styled empty states with friendly icon (folder or clock) and concise message
- Skeleton shimmer for image + text while loading thumbnails (visual only; reuse isLoading flags)

7) Swipe Actions & Buttons
- Update trailing swipe action tint colors to semantic (red for delete, blue/purple for move/copy)
- Primary actions (Add Item) as filled rounded button with consistent height (44)

8) Accessibility & Contrast
- Ensure color badges meet contrast; use system colors with opacity where needed
- Larger hit areas for row tap (contentShape full card)

## Implementation Plan
- Add components:
  - `UseByItemCardView`: layout for row card (thumbnail + title + badge)
  - `UseByExpiryBadge`: renders pill with days left and color
  - `UseBySectionHeader`: simple header + divider
  - `UseByEmptyStateView`: icon + message card
  - (Optional) `UseBySkeletonRowView`: placeholder shimmer while `isLoading`
- Update `UseByTabViews.swift` to use components with existing data/bindings
- Centralize spacing and colors via `AppTheme` or local constants

## Non-Functional Guarantees
- No changes to models, managers, or any behavior
- All actions, swipes, sheets, and data remain intact
- Purely visual composition changes

## Validation
- Run through list add/delete/move/copy; verify visuals only changed
- Check theme in light/dark mode, dynamic text sizes (Accessibility Sizes)

## Deliverables
- New component files under `Views/Components/UseBy/`
- Updated `UseByTabViews.swift` using the new components
- Before/after screenshots for key states