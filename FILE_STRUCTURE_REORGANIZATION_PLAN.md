# NutraSafe File Structure Reorganization Plan

## CRITICAL RULES
1. **DO NOT DELETE ANY FILES** - Only move them
2. **Test build after EVERY section** of moves
3. **Commit after each successful build**
4. **Use Xcode's "Move to Group" feature** to preserve imports
5. **If ANY build fails, IMMEDIATELY REVERT** the last commit

## Current Tab Structure (From ContentView.swift)
- **Diary** - Main food diary and nutrition tracking
- **Progress** - Weight tracking and diet insights
- **Add** - Central add menu (not a tab view)
- **Health** (named "food" internally) - Reactions + Fasting
- **Use By** - Food expiry tracking

## Proposed Structure

```
NutraSafe Beta/
├── App/
│   ├── NutraSafeBetaApp.swift
│   ├── ContentView.swift
│   └── AuthenticationView.swift
│
├── Views/
│   ├── Tabs/
│   │   ├── Diary/
│   │   │   ├── DiaryTabView.swift (ROOT)
│   │   │   ├── DiaryComponents.swift
│   │   │   ├── DiaryDailySummaryCard.swift
│   │   │   ├── DiaryMetricCards.swift
│   │   │   ├── WeeklySummarySheet.swift
│   │   │   ├── AdditiveTrackerView.swift
│   │   │   ├── AdditivePatternView.swift (OLD - unused?)
│   │   │   ├── AdditivePatternViewRedesigned.swift
│   │   │   └── AdditiveHistoricalView.swift
│   │   │
│   │   ├── Progress/
│   │   │   ├── ProgressTabView.swift (needs to be identified)
│   │   │   ├── LogWeightView.swift
│   │   │   ├── MicronutrientDashboard.swift
│   │   │   ├── MicronutrientTimelineView.swift
│   │   │   └── SmartRecommendationsView.swift
│   │   │
│   │   ├── Health/
│   │   │   ├── FoodTabViews.swift (ROOT - renamed from Food)
│   │   │   ├── Reactions/
│   │   │   │   ├── ReactionLogView.swift (UNUSED - 5296 lines)
│   │   │   │   ├── ManualReactionFoodEntryView.swift
│   │   │   │   └── [Other reaction views]
│   │   │   │
│   │   │   └── Fasting/
│   │   │       ├── FastingMainView.swift (ACTIVE)
│   │   │       ├── FastingTimerView.swift
│   │   │       ├── FastingActionSheet.swift
│   │   │       ├── FastingConfirmationSheet.swift
│   │   │       ├── FastingEarlyEndViews.swift
│   │   │       ├── FastingHistoryDropdown.swift
│   │   │       ├── FastingInsightsView.swift
│   │   │       ├── FastingEducationView.swift
│   │   │       ├── FastingCitationsView.swift
│   │   │       ├── FastingSourcesView.swift
│   │   │       ├── FastingPlanViews.swift
│   │   │       ├── FastingPlanManagementView.swift
│   │   │       ├── StaleSessionRecoverySheet.swift
│   │   │       ├── FastingAccessoryInlineWidget.swift
│   │   │       └── FastingRedesign.swift (OLD - unused?)
│   │   │
│   │   ├── UseBy/
│   │   │   ├── UseByTabViews.swift (ROOT)
│   │   │   ├── UseByAddRedesigned.swift
│   │   │   ├── UseByQuickAddRedesigned.swift
│   │   │   └── UseByFoodDetailRedesigned.swift
│   │   │
│   │   └── Add/
│   │       └── AddTabView.swift
│   │
│   ├── Food/
│   │   ├── Search/
│   │   │   ├── FoodSearchViews.swift
│   │   │   └── BarcodeScanningViews.swift (DIARY-ONLY context)
│   │   │
│   │   ├── Detail/
│   │   │   ├── FoodDetailViewFromSearch.swift (MAIN)
│   │   │   ├── FoodDetailWatchTabsView.swift
│   │   │   ├── FoodDetailNutritionCard.swift
│   │   │   ├── FoodDetailServingView.swift
│   │   │   ├── FoodDetailScoresView.swift
│   │   │   ├── NutraSafeGradeInfoView.swift
│   │   │   ├── AdditiveRedesignedViews.swift
│   │   │   ├── AdditiveAnalysisViews.swift
│   │   │   └── InferredIngredientsSheet.swift
│   │   │
│   │   ├── Add/
│   │   │   ├── AddFoodAIView.swift (DIARY-ONLY)
│   │   │   ├── AddFoodManualViews.swift
│   │   │   └── FoodManagementViews.swift
│   │   │
│   │   └── Meals/
│   │       ├── MyMealsView.swift
│   │       └── CreateMealView.swift
│   │
│   ├── Onboarding/
│   │   ├── WelcomeScreenView.swift
│   │   └── Premium/
│   │       ├── PremiumOnboardingView.swift
│   │       ├── OnboardingTheme.swift
│   │       ├── GoalsOnboardingScreens.swift
│   │       ├── ExtendedOnboardingScreens.swift
│   │       └── OrganicShapes.swift
│   │
│   ├── Settings/
│   │   ├── SettingsView.swift (ROOT)
│   │   ├── AppleHealthSettingsView.swift
│   │   ├── HealthSafetySettingsViews.swift
│   │   ├── DietManagementRedesign.swift
│   │   ├── PaywallView.swift
│   │   ├── SourcesAndCitationsView.swift
│   │   ├── PrivacyPolicyView.swift
│   │   └── TermsAndConditionsView.swift
│   │
│   ├── Auth/
│   │   └── SignInSheet.swift
│   │
│   └── Components/ (SHARED UI COMPONENTS)
│       ├── CustomTabBar.swift
│       ├── ActionButtons.swift
│       ├── AddActionMenu.swift
│       ├── FeatureTipOverlay.swift
│       ├── NutraSafeTipRow.swift
│       ├── DiarySegmentedControl.swift
│       ├── PremiumFeatureWrapper.swift
│       ├── MacroViews.swift
│       ├── NutritionScoreViews.swift
│       ├── NutrientDetailModal.swift
│       ├── NutrientGapsView.swift
│       ├── NutrientTrackingTypes.swift
│       └── Food/
│           └── FoodScoresSectionView.swift
│
├── ViewModels/
│   ├── AdditiveTrackerViewModel.swift
│   ├── AdditiveResearchDatabase.swift
│   ├── FastingViewModel.swift
│   └── SettingsViewModel.swift
│
├── Models/
│   ├── Core/
│   │   ├── CoreModels.swift
│   │   ├── UserModels.swift
│   │   └── SearchModels.swift
│   │
│   ├── Nutrition/
│   │   ├── NutritionModels.swift
│   │   ├── ScoringModels.swift
│   │   ├── MicronutrientScoringModels.swift
│   │   ├── NutrientTrackingModels.swift
│   │   ├── NutrientCacheActor.swift
│   │   └── FoodSafetyModels.swift
│   │
│   ├── Health/
│   │   ├── HealthKitModels.swift
│   │   ├── FastingModels.swift
│   │   ├── ReactionLogModels.swift
│   │   └── InferredIngredientModels.swift
│   │
│   ├── Diary/
│   │   ├── MealModels.swift
│   │   ├── DiaryCacheActor.swift
│   │   └── WeekDataCache.swift
│   │
│   └── Infrastructure/
│       └── CitationManager.swift
│
└── Managers/
    ├── Core/
    │   ├── FirebaseManager.swift (already exists)
    │   ├── SubscriptionManager.swift
    │   ├── OnboardingManager.swift
    │   ├── MigrationManager.swift
    │   └── FeatureTipsManager.swift
    │
    ├── Search/
    │   ├── AlgoliaSearchManager.swift
    │   └── SearchNormalization.swift
    │
    ├── Health/
    │   ├── HealthKitManager.swift (already exists)
    │   ├── FastingManager.swift
    │   ├── FastingNotificationManager.swift
    │   └── ReactionLogManager.swift
    │
    ├── Nutrition/
    │   ├── MealManager.swift
    │   ├── InferredIngredientManager.swift
    │   └── BackgroundTaskManager.swift
    │
    └── Infrastructure/
        ├── AnalyticsManager.swift
        └── ImageCacheManager.swift
```

## UNUSED FILES TO INVESTIGATE (Mark for Deletion)

### Confirmed Unused:
1. **ReactionLogView.swift** (5296 lines, 24 structs)
   - Replaced by: FoodTabViews.swift → FoodReactionsView
   - Safe to delete: YES (after final verification)

2. **FastingRedesign.swift**
   - Replaced by: FastingMainView.swift
   - Safe to delete: NEEDS VERIFICATION

3. **AdditivePatternView.swift**
   - Replaced by: AdditivePatternViewRedesigned.swift
   - Safe to delete: NEEDS VERIFICATION

### Potentially Unused (Need Deep Verification):
- Check if any views in `/Food/` are only used for legacy flows
- Check if any `/Diary/` additive views are duplicates

## REORGANIZATION EXECUTION ORDER

### Phase 1: Create Group Structure (No File Moves)
1. Create all new folder groups in Xcode
2. Commit: "Create new folder structure (no files moved)"

### Phase 2: Move Core Tab Views (One at a Time)
1. Move DiaryTabView.swift → Views/Tabs/Diary/
2. Build & Test
3. Commit: "Move DiaryTabView to new structure"
4. Repeat for each tab root view

### Phase 3: Move Tab-Specific Views (By Feature)
1. Move all Fasting/ files → Views/Tabs/Health/Fasting/
2. Build & Test
3. Commit: "Move Fasting views to Health tab structure"
4. Repeat for each feature folder

### Phase 4: Move Shared Components
1. Move Components/ files (carefully - most used)
2. Build & Test
3. Commit: "Move shared components to new structure"

### Phase 5: Reorganize Models & Managers
1. Create subgroups in Models/
2. Move files to subgroups
3. Build & Test
4. Commit: "Organize Models into categories"
5. Repeat for Managers/

### Phase 6: Delete Unused Files (FINAL STEP)
1. Delete ReactionLogView.swift (ONLY if verified unused)
2. Build & Test
3. Commit: "Remove unused ReactionLogView (5296 lines)"

## VERIFICATION CHECKLIST

Before deleting any file:
- [ ] Search entire codebase for imports: `import.*FileName`
- [ ] Search for view instantiation: `FileNameWithoutExtension(`
- [ ] Check Navigation: `NavigationLink.*destination`
- [ ] Check Sheets: `.sheet.*FileNameWithoutExtension`
- [ ] Check Full Screen: `.fullScreenCover.*FileNameWithoutExtension`
- [ ] Verify NOT used in: AppDelegate, SceneDelegate, @main
- [ ] Verify NOT referenced in: Firebase functions, Web dashboard
- [ ] Build succeeds without file
- [ ] Run app and test ALL tabs

## BUILD VALIDATION AFTER EACH PHASE

```bash
cd "/Users/aaronkeen/Documents/My Apps/NutraSafe"
xcodebuild -project NutraSafeBeta.xcodeproj \
  -scheme "NutraSafe Beta" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' \
  build
```

## ROLLBACK PROCEDURE

If build fails:
```bash
git reset --hard HEAD~1
```

## BENEFITS OF THIS STRUCTURE

1. **Clear Navigation**: Each tab has its own folder
2. **Feature Isolation**: Related views grouped together
3. **Easier Maintenance**: Find files by feature, not alphabetically
4. **Better Onboarding**: New developers understand structure instantly
5. **Reduced Coupling**: Shared components clearly separated
6. **Performance**: Unused code identified and removed

## ESTIMATED IMPACT

- **Files to move**: ~110 view files
- **Commits**: ~15-20 small, safe commits
- **Time**: 2-3 hours (with testing)
- **Risk**: LOW (no code changes, only organization)
- **LOC reduction**: ~5,300 lines (from removing ReactionLogView.swift)
