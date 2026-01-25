# File Structure Reorganization - Step-by-Step Guide

## ⚠️ CRITICAL: DO THIS IN XCODE, NOT FINDER
Moving files in Finder will break the Xcode project. All moves MUST be done in Xcode.

---

## Phase 1: Create Folder Groups (5 minutes)

### In Xcode Project Navigator:

1. Right-click `Views` folder → New Group → Name: `Tabs`
2. Right-click `Tabs` → New Group → Name: `Diary`
3. Right-click `Tabs` → New Group → Name: `Progress`
4. Right-click `Tabs` → New Group → Name: `Health`
5. Right-click `Health` → New Group → Name: `Reactions`
6. Right-click `Health` → New Group → Name: `Fasting`
7. Right-click `Tabs` → New Group → Name: `UseBy`
8. Right-click `Tabs` → New Group → Name: `Add`

9. Right-click `Food` folder → New Group → Name: `Search`
10. Right-click `Food` folder → New Group → Name: `Detail`
11. Right-click `Food` folder → New Group → Name: `Add`
12. Right-click `Food` folder → New Group → Name: `Meals`

13. Right-click `Models` folder → New Group → Name: `Core`
14. Right-click `Models` folder → New Group → Name: `Nutrition`
15. Right-click `Models` folder → New Group → Name: `Health`
16. Right-click `Models` folder → New Group → Name: `Diary`
17. Right-click `Models` folder → New Group → Name: `Infrastructure`

18. Right-click `Managers` folder → New Group → Name: `Core`
19. Right-click `Managers` folder → New Group → Name: `Search`
20. Right-click `Managers` folder → New Group → Name: `Health`
21. Right-click `Managers` folder → New Group → Name: `Nutrition`
22. Right-click `Managers` folder → New Group → Name: `Infrastructure`

**Then build to verify nothing broke:**
```bash
⌘ + B
```

**Commit:**
```bash
git add .
git commit -m "Create new folder group structure (no files moved)"
```

---

## Phase 2: Move Diary Tab Files (10 minutes)

### Drag these files into `Views/Tabs/Diary/`:
- DiaryTabView.swift
- DiaryComponents.swift
- DiaryDailySummaryCard.swift
- DiaryMetricCards.swift
- WeeklySummarySheet.swift
- AdditiveTrackerView.swift
- AdditivePatternViewRedesigned.swift
- AdditiveHistoricalView.swift

**Build & Test:**
```bash
⌘ + B
```

**Commit:**
```bash
git add .
git commit -m "Move Diary tab views to Tabs/Diary/"
```

---

## Phase 3: Move Health Tab Files (15 minutes)

### 3A. Move Fasting Views into `Views/Tabs/Health/Fasting/`:
- FastingMainView.swift
- FastingTimerView.swift
- FastingActionSheet.swift
- FastingConfirmationSheet.swift
- FastingEarlyEndViews.swift
- FastingHistoryDropdown.swift
- FastingInsightsView.swift
- FastingEducationView.swift
- FastingCitationsView.swift
- FastingSourcesView.swift
- FastingPlanViews.swift
- FastingPlanManagementView.swift
- StaleSessionRecoverySheet.swift
- FastingAccessoryInlineWidget.swift

**Build & Test:**
```bash
⌘ + B
```

**Commit:**
```bash
git add .
git commit -m "Move Fasting views to Tabs/Health/Fasting/"
```

### 3B. Move Reaction Views into `Views/Tabs/Health/Reactions/`:
- ManualReactionFoodEntryView.swift

**Build & Test:**
```bash
⌘ + B
```

**Commit:**
```bash
git add .
git commit -m "Move Reaction views to Tabs/Health/Reactions/"
```

### 3C. Move Health Tab Root:
- Rename `FoodTabViews.swift` → Right-click → Rename → `HealthTabViews.swift`
- Move `HealthTabViews.swift` into `Views/Tabs/Health/`

**Build & Test:**
```bash
⌘ + B
```

**Commit:**
```bash
git add .
git commit -m "Move and rename FoodTabViews to Health/HealthTabViews"
```

---

## Phase 4: Move Progress Tab Files (5 minutes)

### Drag into `Views/Tabs/Progress/`:
- LogWeightView.swift
- MicronutrientDashboard.swift
- MicronutrientTimelineView.swift
- SmartRecommendationsView.swift

**Build & Test:**
```bash
⌘ + B
```

**Commit:**
```bash
git add .
git commit -m "Move Progress tab views to Tabs/Progress/"
```

---

## Phase 5: Move Use By Tab Files (5 minutes)

### Drag into `Views/Tabs/UseBy/`:
- UseByTabViews.swift
- UseByAddRedesigned.swift
- UseByQuickAddRedesigned.swift
- UseByFoodDetailRedesigned.swift

**Build & Test:**
```bash
⌘ + B
```

**Commit:**
```bash
git add .
git commit -m "Move Use By views to Tabs/UseBy/"
```

---

## Phase 6: Organize Food Detail Views (10 minutes)

### 6A. Search Views → `Views/Food/Search/`:
- FoodSearchViews.swift
- BarcodeScanningViews.swift

### 6B. Detail Views → `Views/Food/Detail/`:
- FoodDetailViewFromSearch.swift
- FoodDetailWatchTabsView.swift
- FoodDetailNutritionCard.swift
- FoodDetailServingView.swift
- FoodDetailScoresView.swift
- NutraSafeGradeInfoView.swift
- AdditiveRedesignedViews.swift
- AdditiveAnalysisViews.swift
- InferredIngredientsSheet.swift

### 6C. Add Food Views → `Views/Food/Add/`:
- AddFoodAIView.swift
- AddFoodManualViews.swift
- FoodManagementViews.swift

### 6D. Meals → `Views/Food/Meals/`:
- MyMealsView.swift
- CreateMealView.swift

**Build & Test after each subsection:**
```bash
⌘ + B
```

**Commit after all Food views moved:**
```bash
git add .
git commit -m "Organize Food views into Search/Detail/Add/Meals"
```

---

## Phase 7: Organize Models (15 minutes)

### 7A. Core Models → `Models/Core/`:
- CoreModels.swift
- UserModels.swift
- SearchModels.swift

### 7B. Nutrition Models → `Models/Nutrition/`:
- NutritionModels.swift
- ScoringModels.swift
- MicronutrientScoringModels.swift
- NutrientTrackingModels.swift
- NutrientCacheActor.swift
- FoodSafetyModels.swift

### 7C. Health Models → `Models/Health/`:
- HealthKitModels.swift
- FastingModels.swift
- ReactionLogModels.swift
- InferredIngredientModels.swift

### 7D. Diary Models → `Models/Diary/`:
- MealModels.swift
- DiaryCacheActor.swift
- WeekDataCache.swift

### 7E. Infrastructure → `Models/Infrastructure/`:
- CitationManager.swift

**Build & Test:**
```bash
⌘ + B
```

**Commit:**
```bash
git add .
git commit -m "Organize Models into categories"
```

---

## Phase 8: Organize Managers (15 minutes)

### 8A. Core Managers → `Managers/Core/`:
- SubscriptionManager.swift
- OnboardingManager.swift
- MigrationManager.swift
- FeatureTipsManager.swift

### 8B. Search Managers → `Managers/Search/`:
- AlgoliaSearchManager.swift
- SearchNormalization.swift

### 8C. Health Managers → `Managers/Health/`:
- FastingManager.swift
- FastingNotificationManager.swift
- ReactionLogManager.swift

### 8D. Nutrition Managers → `Managers/Nutrition/`:
- MealManager.swift
- InferredIngredientManager.swift
- BackgroundTaskManager.swift

### 8E. Infrastructure → `Managers/Infrastructure/`:
- AnalyticsManager.swift
- ImageCacheManager.swift

**Build & Test:**
```bash
⌘ + B
```

**Commit:**
```bash
git add .
git commit -m "Organize Managers into categories"
```

---

## Phase 9: Delete Unused Files (5 minutes)

### Files confirmed 100% unused:

1. **ReactionLogView.swift** (5,296 lines) - ZERO references
   - Right-click → Delete → Move to Trash

2. **AdditivePatternView.swift** (if confirmed unused)
   - Search first: `⌘ + Shift + F` → "AdditivePatternView"
   - If only self-references → Delete → Move to Trash

3. **FastingRedesign.swift** (if confirmed unused)
   - Search first: `⌘ + Shift + F` → "FastingRedesign"
   - If only self-references → Delete → Move to Trash

**Build & Test:**
```bash
⌘ + B
```

**Test app on simulator - verify ALL tabs work**

**Commit:**
```bash
git add .
git commit -m "Remove unused views: ReactionLogView.swift (-5296 lines)"
```

---

## Final Verification

1. Build succeeds: `⌘ + B`
2. Run on simulator: `⌘ + R`
3. Test each tab:
   - [ ] Diary tab works
   - [ ] Progress tab works
   - [ ] Health tab works (Reactions + Fasting)
   - [ ] Use By tab works
   - [ ] Add menu works
4. Test navigation:
   - [ ] Search food → Food detail
   - [ ] Log reaction
   - [ ] Start fasting
   - [ ] Add to Use By

**Final commit:**
```bash
git add .
git commit -m "Complete file structure reorganization

- Organized Views by tab structure (Diary/Progress/Health/UseBy)
- Categorized Models (Core/Nutrition/Health/Diary/Infrastructure)
- Categorized Managers (Core/Search/Health/Nutrition/Infrastructure)
- Removed 5,296 lines of unused code (ReactionLogView.swift)

New structure makes navigation intuitive and reduces coupling.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Rollback If Anything Goes Wrong

```bash
git reset --hard HEAD~1
```

This will undo the last commit and restore files.

---

## Estimated Time: 90 minutes
## Risk Level: LOW (no code changes, only organization)
## Benefit: Massively improved maintainability
