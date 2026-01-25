import SwiftUI
import Foundation
import FirebaseFirestore
import Combine

@ViewBuilder
func navigationContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    if #available(iOS 16.0, *) {
        NavigationStack { content() }
    } else {
        NavigationView { content() }
            .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Food Tab Navigation System
// Extracted from ContentView.swift (lines 4761-4936) + supporting components
// Complete food hub navigation with sub-tabs and comprehensive food tracking

struct FoodTabView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var showingSettings: Bool
    @Binding var selectedTab: TabItem
    @State private var selectedFoodSubTab: FoodSubTab = .reactions
    @EnvironmentObject var firebaseManager: FirebaseManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var fastingViewModelWrapper: FastingViewModelWrapper

    // MARK: - Feature Tips
    @State private var showingHealthTip = false
    @State private var showingFastingTip = false

    enum FoodSubTab: String, CaseIterable {
        case reactions = "Reactions"
        case fasting = "Fasting"

        var icon: String {
            switch self {
            case .reactions: return "exclamationmark.triangle.fill"
            case .fasting: return "clock.fill"
            }
        }
    }

    init(showingSettings: Binding<Bool>, selectedTab: Binding<TabItem>) {
        self._showingSettings = showingSettings
        self._selectedTab = selectedTab
    }

    var body: some View {
        navigationContainer {
            VStack(spacing: 0) {
                // Header - Modern tab header with segmented control
                TabHeaderView(
                    tabs: FoodSubTab.allCases,
                    selectedTab: $selectedFoodSubTab,
                    onSettingsTapped: { showingSettings = true }
                )
                // PERFORMANCE: Use opacity-based switching to keep views loaded and avoid re-initialization delays
                ZStack {
                    FoodReactionsView(selectedTab: $selectedTab)
                        .opacity(selectedFoodSubTab == .reactions ? 1 : 0)
                        .allowsHitTesting(selectedFoodSubTab == .reactions)

                    Group {
                        if let viewModel = fastingViewModelWrapper.viewModel {
                            FastingMainView(viewModel: viewModel)
                        } else {
                            ProgressView()
                        }
                    }
                    .opacity(selectedFoodSubTab == .fasting ? 1 : 0)
                    .allowsHitTesting(selectedFoodSubTab == .fasting)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(AppAnimatedBackground())
            .navigationBarHidden(true)
        }
        .onAppear {
            // Show feature tip on first visit
            if !FeatureTipsManager.shared.hasSeenTip(.healthOverview) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingHealthTip = true
                }
            }
        }
        .onChange(of: selectedFoodSubTab) { _, newTab in
            // Show fasting tip on first visit to fasting sub-tab
            if newTab == .fasting && !FeatureTipsManager.shared.hasSeenTip(.healthFasting) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingFastingTip = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToFasting)) { _ in
                        selectedFoodSubTab = .fasting
        }
        .featureTip(isPresented: $showingHealthTip, tipKey: .healthOverview)
        .featureTip(isPresented: $showingFastingTip, tipKey: .healthFasting)
        .trackScreen("Health")
    }
}

// MARK: - Food Tab Glass Background
private var foodGlassBackground: some View {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.92, green: 0.96, blue: 1.0),
                Color(red: 0.93, green: 0.88, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        RadialGradient(
            colors: [AppPalette.standard.accent.opacity(0.10), Color.clear],
            center: .topLeading,
            startRadius: 0,
            endRadius: 300
        )
        RadialGradient(
            colors: [AppPalette.standard.primary.opacity(0.08), Color.clear],
            center: .bottomTrailing,
            startRadius: 0,
            endRadius: 280
        )
    }
    .ignoresSafeArea()
}

// MARK: - Native Segmented Control
struct SegmentedControlView<Tab: Hashable & CaseIterable & RawRepresentable>: View where Tab.RawValue == String {
    let tabs: [Tab]
    @Binding var selectedTab: Tab
    @Namespace private var animation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(
                            selectedTab == tab ?
                            LinearGradient(
                                colors: [
                                    AppPalette.standard.accent,
                                    AppPalette.standard.accent.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.secondary, Color.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            ZStack {
                                if selectedTab == tab {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [Color.white.opacity(0.35), Color.white.opacity(0.15)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                                        .matchedGeometryEffect(id: "segmentedControl", in: animation)
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .frame(height: 40)
    }
}

// MARK: - Food Sub Views
struct FoodReactionsView: View {
    @Binding var selectedTab: TabItem
    @ObservedObject private var reactionManager = ReactionManager.shared
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var hasLoadedOnce = false // PERFORMANCE: Guard flag to prevent redundant loads
    @State private var showingPaywall = false
    @State private var selectedSubTab: ReactionSubTab = .overview
    @State private var selectedSymptomFilter: String? = nil

    // MARK: - Scroll Reset Trigger
    // Combines main tab and subtab to reset scroll when returning to this tab
    private var scrollResetTrigger: String {
        "\(selectedTab)-\(selectedSubTab)"
    }

    enum ReactionSubTab: String, CaseIterable {
        case overview = "Overview"
        case timeline = "Timeline"
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Sub-tab picker
                reactionSubTabPicker
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 4)

                // Content based on selected sub-tab
                // Using id() to force complete view recreation and prevent stale references
                Group {
                    switch selectedSubTab {
                    case .overview:
                        foodBasedReactionsView
                    case .timeline:
                        reactionTimelineView
                    }
                }
                .id(selectedSubTab)
                .frame(width: geometry.size.width)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
    }

    // MARK: - Sub-Tab Picker
    private var reactionSubTabPicker: some View {
        HStack(spacing: 0) {
            ForEach(ReactionSubTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedSubTab = tab
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: selectedSubTab == tab ? .semibold : .medium))
                        .foregroundColor(selectedSubTab == tab ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedSubTab == tab ?
                            LinearGradient(
                                colors: [
                                    AppPalette.standard.accent,
                                    AppPalette.standard.accent.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    // MARK: - Timeline View
    private var reactionTimelineView: some View {
        ScrollViewWithTopReset(.vertical, showsIndicators: true, resetOn: scrollResetTrigger) {
            VStack(spacing: 16) {
                // Symptom filter
                symptomFilterSection
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // Filtered reactions
                let filteredReactions = filteredTimelineReactions

                if filteredReactions.isEmpty {
                    // Calm empty state with signal icon
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [AppPalette.standard.accent.opacity(0.06), Color.clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 40
                                    )
                                )
                                .frame(width: 80, height: 80)

                            NutraSafeSignalIcon(color: AppPalette.standard.accent.opacity(0.3), size: 36)
                        }

                        VStack(spacing: 6) {
                            Text("Nothing here yet")
                                .font(.system(size: 18, weight: .medium, design: .serif))
                                .foregroundColor(.secondary)

                            if let symptom = selectedSymptomFilter {
                                Text("No \(symptom.lowercased()) entries to show")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                } else {
                    // Softer count - only show when filtering
                    if selectedSymptomFilter != nil {
                        Text("Showing \(filteredReactions.count) \(filteredReactions.count == 1 ? "entry" : "entries")")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                    }

                    // Reaction cards with spacing
                    VStack(spacing: 14) {
                        ForEach(filteredReactions) { reaction in
                            TimelineReactionRow(reaction: reaction)
                                .environmentObject(reactionManager)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
    }

    // MARK: - Symptom Filter Section (Calm Redesign)
    // Removed clinical "Filter by Symptom" label - chips speak for themselves
    private var symptomFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // All entries option
                symptomChip(symptom: nil, label: "All entries")

                // Unique symptoms from reactions
                ForEach(uniqueSymptoms, id: \.self) { symptom in
                    symptomChip(symptom: symptom, label: symptom)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
    }

    private func symptomChip(symptom: String?, label: String) -> some View {
        let isSelected = selectedSymptomFilter == symptom

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedSymptomFilter = symptom
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            HStack(spacing: 6) {
                // Small signal dot - color indicates selection
                Circle()
                    .fill(isSelected ? Color.white : AppPalette.standard.accent.opacity(0.6))
                    .frame(width: 6, height: 6)

                Text(label)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        isSelected
                            ? AnyShapeStyle(LinearGradient(colors: [AppPalette.standard.accent, AppPalette.standard.primary], startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(.ultraThinMaterial)
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected ? Color.clear : AppPalette.standard.tertiary.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isSelected ? AppPalette.standard.accent.opacity(0.25) : Color.black.opacity(0.03),
                        radius: isSelected ? 8 : 4,
                        y: isSelected ? 3 : 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var uniqueSymptoms: [String] {
        var symptomCounts: [String: Int] = [:]
        for reaction in reactionManager.reactions {
            for symptom in reaction.symptoms {
                symptomCounts[symptom, default: 0] += 1
            }
        }
        // Sort by frequency
        return symptomCounts.sorted { $0.value > $1.value }.map { $0.key }
    }

    private var filteredTimelineReactions: [FoodReaction] {
        guard let symptom = selectedSymptomFilter else {
            return reactionManager.reactions
        }
        return reactionManager.reactions.filter { $0.symptoms.contains(symptom) }
    }

    private var foodBasedReactionsView: some View {
        ScrollViewWithTopReset(.vertical, showsIndicators: true, resetOn: scrollResetTrigger) {
            VStack(spacing: 12) {
                // Reaction Summary
                FoodReactionSummaryCard(selectedTab: $selectedTab)
                    .environmentObject(reactionManager)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // Recent Reactions - limited for free users
                FoodReactionListCard(
                    title: "Recent Reactions",
                    reactions: Array(reactionManager.reactions.prefix(
                        subscriptionManager.hasAccess ? 10 : SubscriptionManager.freeReactionsLimit
                    ))
                )
                .environmentObject(reactionManager)
                .padding(.horizontal, 16)

                // Show upgrade prompt if free user has more reactions
                if !subscriptionManager.hasAccess && reactionManager.reactions.count > SubscriptionManager.freeReactionsLimit {
                    Button(action: { showingPaywall = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppPalette.standard.accent)

                            Text("+\(reactionManager.reactions.count - SubscriptionManager.freeReactionsLimit) more reactions")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)

                            Spacer()

                            Text("Unlock")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(AppPalette.standard.accent))
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppPalette.standard.accent.opacity(0.08))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)
                }

                // Pattern Analysis - Premium Feature
                PremiumFeatureWrapper(
                    featureName: "Pattern Analysis",
                    featureDescription: "Discover which ingredients keep appearing in your reactions to uncover possible food intolerances",
                    onUpgradeTapped: { showingPaywall = true }
                ) {
                    FoodPatternAnalysisCard()
                        .environmentObject(reactionManager)
                } blurredPreview: {
                    // Blurred preview of pattern card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "chart.bar.doc.horizontal.fill")
                                .foregroundColor(.purple)
                            Text("Ingredient Patterns")
                                .font(.headline)
                            Spacer()
                        }

                        // Show fake ingredient patterns to tease the feature
                        ForEach(["Gluten", "Dairy", "Soy"], id: \.self) { ingredient in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 10, height: 10)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ingredient)
                                        .font(.system(size: 15, weight: .medium))
                                    Text("Found in multiple reactions")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text("67%")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                            .padding(10)
                            .background(Color.adaptiveCard)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.adaptiveCard)
                    )
                }
                .padding(.horizontal, 16)

                // Info Notice for Patterns (only show for premium users with < 3 reactions)
                if subscriptionManager.hasAccess && reactionManager.reactions.count < 3 {
                    VStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundColor(AppPalette.standard.accent)

                        Text("Log at least 3 reactions to see patterns")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppPalette.standard.accent.opacity(0.1))
                    )
                    .padding(.horizontal, 16)
                }

                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onChanged { value in
                    // Block horizontal dragging by checking if drag is more horizontal than vertical
                    if abs(value.translation.width) > abs(value.translation.height) {
                        // This consumes horizontal drags, blocking them
                    }
                },
            including: .all
        )
        .onAppear {
            guard !hasLoadedOnce else { return }
            hasLoadedOnce = true
            reactionManager.reloadIfAuthenticated()
        }
        .alert("Error", isPresented: $reactionManager.showingError) {
            Button("OK", role: .cancel) {
                reactionManager.errorMessage = nil
            }
        } message: {
            Text(reactionManager.errorMessage ?? "Unknown error occurred")
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(subscriptionManager)
        }
    }
}

struct RecipesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Recipe Collections
                RecipeCollectionsCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                // Favourite Recipes
                FavouriteRecipesCard()
                    .padding(.horizontal, 16)
                
                // Safe Recipe Suggestions
                SafeRecipeSuggestionsCard()
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
    }
}

// MARK: - Food Tab Component Cards
struct FoodReactionSummaryCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedTab: TabItem
    @State private var showingLogReaction = false
    @EnvironmentObject var reactionManager: ReactionManager
    @ObservedObject private var logManager = ReactionLogManager.shared

    // MARK: - Computed Insights

    /// Most common symptom with percentage
    private var mostCommonSymptom: (symptom: String, percentage: Int)? {
        guard !reactionManager.reactions.isEmpty else { return nil }

        var symptomCounts: [String: Int] = [:]
        for reaction in reactionManager.reactions {
            for symptom in reaction.symptoms {
                symptomCounts[symptom, default: 0] += 1
            }
        }

        guard let (symptom, count) = symptomCounts.max(by: { $0.value < $1.value }) else { return nil }
        let percentage = Int((Double(count) / Double(reactionManager.reactions.count)) * 100)
        return (symptom, percentage)
    }

    /// Peak timing for reactions (Morning/Afternoon/Evening/Night)
    private var peakTiming: String? {
        guard !reactionManager.reactions.isEmpty else { return nil }

        let calendar = Calendar.current
        var timingCounts: [String: Int] = ["Morning": 0, "Afternoon": 0, "Evening": 0, "Night": 0]

        for reaction in reactionManager.reactions {
            let hour = calendar.component(.hour, from: reaction.timestamp.dateValue())
            switch hour {
            case 5..<12: timingCounts["Morning", default: 0] += 1
            case 12..<17: timingCounts["Afternoon", default: 0] += 1
            case 17..<21: timingCounts["Evening", default: 0] += 1
            default: timingCounts["Night", default: 0] += 1
            }
        }

        return timingCounts.max(by: { $0.value < $1.value })?.key
    }

    /// Reactions logged in the last 30 days
    private var reactionsInLast30Days: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) else { return 0 }
        return reactionManager.reactions.filter { $0.timestamp.dateValue() >= thirtyDaysAgo }.count
    }

    /// Top allergen trigger(s) from reactions - UK 14 major allergens only
    /// Returns multiple allergens if there's a tie
    private var topAllergenTriggers: [(name: String, count: Int)]? {
        var allergenCounts: [String: Int] = [:]

        for reaction in reactionManager.reactions {
            for ingredient in reaction.suspectedIngredients {
                // Only count UK 14 major allergens
                if let baseAllergen = getBaseAllergenForSummary(for: ingredient) {
                    allergenCounts[baseAllergen, default: 0] += 1
                }
            }
        }

        guard !allergenCounts.isEmpty else { return nil }

        // Find the maximum count
        let maxCount = allergenCounts.values.max() ?? 0
        guard maxCount >= 2 else { return nil }

        // Get all allergens with the max count (handles ties)
        let topAllergens = allergenCounts
            .filter { $0.value == maxCount }
            .map { (name: $0.key, count: $0.value) }
            .sorted { $0.name < $1.name } // Alphabetical for consistency

        return topAllergens.isEmpty ? nil : topAllergens
    }

    /// Top ingredient trigger from detailed trigger analysis with percentage and foods
    /// Uses crossReactionFrequency data for accurate pattern detection
    private var topIngredientTrigger: (name: String, percentage: Int, foods: [String])? {
        guard !logManager.reactionLogs.isEmpty else { return nil }

        // Find the ingredient with the highest cross-reaction frequency
        var ingredientData: [String: (percentage: Double, foods: Set<String>)] = [:]

        for log in logManager.reactionLogs {
            guard let analysis = log.triggerAnalysis else { continue }

            for ingredient in analysis.topIngredients.prefix(5) {
                let name = ingredient.ingredientName
                let currentData = ingredientData[name] ?? (percentage: 0, foods: Set<String>())

                // Take max percentage (not sum)
                let newPercentage = max(currentData.percentage, ingredient.crossReactionFrequency)

                // Collect all foods that contain this ingredient
                var allFoods = currentData.foods
                allFoods.formUnion(ingredient.contributingFoodNames)

                ingredientData[name] = (percentage: newPercentage, foods: allFoods)
            }
        }

        // Find the ingredient with the highest percentage
        guard let topIngredient = ingredientData.max(by: { $0.value.percentage < $1.value.percentage }),
              topIngredient.value.percentage >= 30 else { return nil }

        let percentage = Int(topIngredient.value.percentage)
        let foods = Array(topIngredient.value.foods.prefix(3)) // Limit to 3 foods for readability

        return (name: topIngredient.key, percentage: percentage, foods: foods)
    }

    // UK's 14 Major Allergens detection for summary card
    private func getBaseAllergenForSummary(for ingredient: String) -> String? {
        let lower = ingredient.lowercased()

        // Milk and dairy
        let dairyKeywords = ["milk", "dairy", "cream", "butter", "cheese", "yogurt", "yoghurt", "whey", "casein", "lactose", "ghee"]
        if dairyKeywords.contains(where: { lower.contains($0) }) { return "Dairy" }

        // Eggs
        let eggKeywords = ["egg", "albumin", "mayonnaise", "meringue"]
        if eggKeywords.contains(where: { lower.contains($0) }) { return "Eggs" }

        // Peanuts
        if lower.contains("peanut") || lower.contains("groundnut") { return "Peanuts" }

        // Tree nuts
        let nutKeywords = ["almond", "hazelnut", "walnut", "cashew", "pistachio", "pecan", "brazil nut", "macadamia", "pine nut", "chestnut"]
        if nutKeywords.contains(where: { lower.contains($0) }) { return "Tree Nuts" }

        // Gluten
        let glutenKeywords = ["wheat", "gluten", "barley", "rye", "oats", "spelt", "semolina", "flour", "bread"]
        if glutenKeywords.contains(where: { lower.contains($0) }) { return "Gluten" }

        // Soya
        let soyKeywords = ["soy", "soya", "tofu", "tempeh", "edamame"]
        if soyKeywords.contains(where: { lower.contains($0) }) { return "Soya" }

        // Fish
        let fishKeywords = ["fish", "salmon", "tuna", "cod", "anchovy", "sardine", "mackerel", "haddock"]
        if fishKeywords.contains(where: { lower.contains($0) }) { return "Fish" }

        // Crustaceans
        let crustaceanKeywords = ["shrimp", "prawn", "crab", "lobster", "crawfish", "crayfish"]
        if crustaceanKeywords.contains(where: { lower.contains($0) }) { return "Shellfish" }

        // Molluscs
        let molluscKeywords = ["mollusc", "clam", "mussel", "oyster", "scallop", "squid", "octopus"]
        if molluscKeywords.contains(where: { lower.contains($0) }) { return "Molluscs" }

        // Sesame
        if lower.contains("sesame") || lower.contains("tahini") { return "Sesame" }

        // Mustard
        if lower.contains("mustard") { return "Mustard" }

        // Celery
        if lower.contains("celery") || lower.contains("celeriac") { return "Celery" }

        // Lupin
        if lower.contains("lupin") { return "Lupin" }

        // Sulphites
        let sulphiteKeywords = ["sulphite", "sulfite", "sulphur dioxide", "sulfur dioxide"]
        if sulphiteKeywords.contains(where: { lower.contains($0) }) { return "Sulphites" }

        return nil
    }

    // MARK: - Palette for Intent-Aware Colors
    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    // MARK: - Natural Language Insight Generation

    /// Generates the primary insight statement in natural language
    private var primaryInsightText: String {
        guard let symptom = mostCommonSymptom else {
            return "We're tracking your reactions and looking for patterns."
        }

        var insight = "\(symptom.symptom) has appeared in most of your logged reactions"

        // Add timing context inline
        if let timing = peakTiming {
            let timingPhrase: String
            switch timing.lowercased() {
            case "morning": timingPhrase = "often in the mornings"
            case "afternoon": timingPhrase = "frequently in the afternoons"
            case "evening": timingPhrase = "often in the evenings"
            case "night": timingPhrase = "typically at night"
            default: timingPhrase = "throughout the day"
            }
            insight += ", \(timingPhrase)"
        }

        // Add trigger context if available - focus on INGREDIENT pattern with percentage
        if let trigger = topIngredientTrigger {
            insight += ". \(trigger.name) appears in \(trigger.percentage)% of reactions"

            // Show which specific foods contained it (up to 3 for readability)
            if !trigger.foods.isEmpty {
                let foodList = trigger.foods.prefix(2).joined(separator: ", ")
                insight += " (in \(foodList))"
            }
        }

        return insight + "."
    }

    /// Secondary observation about recent activity
    private var recentActivityObservation: String? {
        if reactionsInLast30Days == 0 {
            return "No reactions logged in the last 30 days"
        } else if reactionsInLast30Days <= 2 {
            return "Only \(reactionsInLast30Days) reaction\(reactionsInLast30Days == 1 ? "" : "s") in the last month"
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Smart Insights (show if 3+ reactions, otherwise show building state)
            if reactionManager.reactions.count >= 3 {
                // MARK: - Insight Hero Card (NutraSafe Design)
                // Single dominant card with natural language insight
                VStack(alignment: .leading, spacing: 16) {
                    // Signal icon with ambient glow
                    HStack {
                        ZStack {
                            // Ambient glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [palette.accent.opacity(0.15), Color.clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 32
                                    )
                                )
                                .frame(width: 64, height: 64)

                            // Signal icon container
                            SignalIconContainer(color: palette.accent, size: 48)
                        }

                        Spacer()
                    }
                    .padding(.bottom, 4)

                    // Primary insight statement
                    Text(primaryInsightText)
                        .font(.system(size: 20, weight: .medium, design: .serif))
                        .foregroundColor(palette.textPrimary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Secondary observation (if available)
                    if let observation = recentActivityObservation {
                        Text(observation)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(palette.textSecondary)
                            .padding(.top, 2)
                    }

                    // Context chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Timing chip
                            if let timing = peakTiming {
                                insightContextChip(
                                    label: "\(timing) pattern",
                                    color: palette.accent
                                )
                            }

                            // Trigger chip - show ingredient with percentage
                            if let trigger = topIngredientTrigger {
                                insightContextChip(
                                    label: "\(trigger.name) \(trigger.percentage)%",
                                    color: .orange.opacity(0.9)
                                )
                            }

                            // Frequency chip
                            if reactionsInLast30Days > 0 {
                                insightContextChip(
                                    label: "\(reactionsInLast30Days) this month",
                                    color: palette.textSecondary
                                )
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                    .padding(.top, 4)
                }
                .padding(20)

            } else {
                // MARK: - Building State (NutraSafe Design)
                // Gentle guidance with signal icon
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [palette.accent.opacity(0.08), Color.clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 28
                                    )
                                )
                                .frame(width: 56, height: 56)

                            SignalIconContainer(color: palette.accent.opacity(0.5), size: 40)
                        }

                        Spacer()

                        // Progress indicator
                        HStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .fill(index < reactionManager.reactions.count ? palette.accent : palette.tertiary.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }

                    let remaining = 3 - reactionManager.reactions.count
                    Text(remaining == 1
                        ? "One more reaction and we'll start spotting patterns for you."
                        : "Log a couple more reactions and we'll begin identifying patterns.")
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundColor(palette.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
            }

            // MARK: - Log Reaction Button (Secondary Visual Weight)
            Button(action: { showingLogReaction = true }) {
                HStack(spacing: 10) {
                    // Subtle plus indicator
                    ZStack {
                        Circle()
                            .fill(palette.accent.opacity(colorScheme == .dark ? 0.2 : 0.12))
                            .frame(width: 28, height: 28)

                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(palette.accent)
                    }

                    Text("Log Reaction")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(palette.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                .stroke(palette.accent.opacity(0.25), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(SpringyButtonStyle())
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
        )
        .fullScreenCover(isPresented: $showingLogReaction) {
            LogReactionSheet(selectedDayRange: .threeDays)
        }
    }

    // MARK: - Insight Context Chip
    private func insightContextChip(label: String, color: Color) -> some View {
        HStack(spacing: 5) {
            // Small signal dot
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(color.opacity(colorScheme == .dark ? 0.15 : 0.08))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

struct StatMiniCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(colorScheme == .dark ? Color(.systemGray4) : Color.white.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(colorScheme == .dark ? 0.2 : 0.06), radius: 6, x: 0, y: 3)
    }
}

struct FoodReactionListCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let reactions: [FoodReaction]
    @EnvironmentObject var reactionManager: ReactionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with title (no export button - moved to Patterns section)
            HStack(alignment: .center) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
            }

            if reactions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.green.opacity(0.6))
                    Text("No reactions logged")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                List {
                    ForEach(reactions, id: \.id) { reaction in
                        FoodReactionRow(reaction: reaction)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        await reactionManager.deleteReaction(reaction)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .environment(\.defaultMinListRowHeight, 0)
                .frame(height: CGFloat(min(reactions.count, 5) * 56))
            }
        }
        .padding(AppSpacing.large)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(colorScheme == .dark ? Color(.systemGray4) : Color.white.opacity(0.6), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 10, x: 0, y: 4)
    }
}

struct FoodReactionRow: View {
    let reaction: FoodReaction
    @State private var showingDetail = false

    var body: some View {
        Button(action: { showingDetail = true }) {
            HStack(spacing: 16) {
                // Larger circular severity indicator
                ZStack {
                    Circle()
                        .fill(severityColor(for: reaction.severity).opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(severityColor(for: reaction.severity))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(reaction.foodName)
                        .font(.callout.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(reaction.symptoms.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(severityText(for: reaction.severity))
                        .font(.caption.weight(.bold))
                        .foregroundColor(severityColor(for: reaction.severity))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(severityColor(for: reaction.severity))
                        .frame(width: severityBarWidth(for: reaction.severity), height: 3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showingDetail) {
            ReactionDetailView(reaction: reaction)
        }
    }

    private func severityColor(for severity: ReactionSeverity) -> Color {
        switch severity {
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        }
    }

    private func severityText(for severity: ReactionSeverity) -> String {
        switch severity {
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        }
    }

    private func severityBarWidth(for severity: ReactionSeverity) -> CGFloat {
        switch severity {
        case .mild: return 25
        case .moderate: return 40
        case .severe: return 55
        }
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDate(date, inSameDayAs: now) {
            return "Today"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now) ?? now) {
            return "Yesterday"
        } else {
            let daysDiff = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            return "\(daysDiff) days ago"
        }
    }
    
    private func dateDisplayText(_ date: Date) -> String {
        // PERFORMANCE: Use cached static formatter
        DateHelper.mediumDateFormatter.string(from: date)
    }
}

// MARK: - Timeline Reaction Row (Calm Redesign)
/// Glassmorphic card design matching onboarding style
struct TimelineReactionRow: View {
    let reaction: FoodReaction
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingDetail = false

    var body: some View {
        Button(action: { showingDetail = true }) {
            HStack(alignment: .top, spacing: 14) {
                // Circular signal icon with radial glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppPalette.standard.accent.opacity(0.08), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 22
                            )
                        )
                        .frame(width: 44, height: 44)

                    Circle()
                        .fill(AppPalette.standard.accent.opacity(0.1))
                        .frame(width: 36, height: 36)

                    // Small severity dot
                    Circle()
                        .fill(severityColor(for: reaction.severity))
                        .frame(width: 10, height: 10)
                }

                // Main content
                VStack(alignment: .leading, spacing: 5) {
                    // Symptoms with serif font for editorial feel
                    Text(reaction.symptoms.joined(separator: ", "))
                        .font(.system(size: 17, weight: .medium, design: .serif))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    // Friendly date format
                    Text(friendlyDateString)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)

                    // Food name
                    if !reaction.foodName.isEmpty {
                        Text(reaction.foodName)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary.opacity(0.8))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Subtle chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.4))
                    .padding(.top, 4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.15), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showingDetail) {
            ReactionDetailView(reaction: reaction)
        }
    }

    // Friendly date formatting - "Tuesday, morning" or "Yesterday, afternoon"
    private var friendlyDateString: String {
        let date = reaction.timestamp.dateValue()
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: date)

        // Time of day
        let timeOfDay: String
        switch hour {
        case 5..<12: timeOfDay = "morning"
        case 12..<17: timeOfDay = "afternoon"
        case 17..<21: timeOfDay = "evening"
        default: timeOfDay = "night"
        }

        // Relative day
        if calendar.isDateInToday(date) {
            return "Today, \(timeOfDay)"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday, \(timeOfDay)"
        } else if let daysAgo = calendar.dateComponents([.day], from: date, to: now).day, daysAgo < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return "\(formatter.string(from: date)), \(timeOfDay)"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            return "\(formatter.string(from: date)), \(timeOfDay)"
        }
    }

    private func severityColor(for severity: ReactionSeverity) -> Color {
        switch severity {
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        }
    }
}

struct FoodPatternAnalysisCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var reactionManager: ReactionManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showOtherIngredients = false
    @State private var showingPDFExportSheet = false
    @State private var showingPaywall = false

    // Tab selection for categorizing patterns
    enum PatternTab: String, CaseIterable {
        case allergens = "Allergens"
        case additives = "Additives"
        case ingredients = "Ingredients"
    }
    @State private var selectedPatternTab: PatternTab = .allergens
    @State private var watchedAdditives: Set<String> = []

    // Confidence level based on data points
    private var confidenceLevel: (label: String, color: Color, description: String) {
        let count = reactionManager.reactions.count
        switch count {
        case 0...2:
            return ("Not enough data", .gray, "Log at least 3 reactions")
        case 3...5:
            return ("Low", .orange, "Based on \(count) reactions")
        case 6...10:
            return ("Moderate", .yellow, "Based on \(count) reactions")
        case 11...20:
            return ("Good", .green, "Based on \(count) reactions")
        default:
            return ("High", .green, "Based on \(count)+ reactions")
        }
    }

    // Top allergen or additive insight (excludes plain ingredients)
    private var topTriggerInsight: (text: String, subtext: String, icon: String, color: Color)? {
        // Find top allergen
        let topAllergen = allergenTriggers.first
        // Find top additive (that isn't also an allergen)
        let topAdditive = additiveTriggers.first

        // Prefer allergen if it has higher percentage, otherwise show additive
        if let allergen = topAllergen {
            if let additive = topAdditive {
                // Both exist - show whichever is more common
                if allergen.percentage >= additive.percentage {
                    let category = allergen.baseAllergen ?? "Allergen"
                    return (
                        "\(category) appears in \(allergen.percentage)% of your reactions",
                        "Most common trigger detected",
                        "exclamationmark.triangle.fill",
                        .orange
                    )
                } else {
                    return (
                        "\(additive.ingredient) appears in \(additive.percentage)% of your reactions",
                        "Most common additive detected",
                        "eye.fill",
                        .orange
                    )
                }
            } else {
                // Only allergen exists
                let category = allergen.baseAllergen ?? "Allergen"
                return (
                    "\(category) appears in \(allergen.percentage)% of your reactions",
                    "Most common trigger detected",
                    "exclamationmark.triangle.fill",
                    .orange
                )
            }
        } else if let additive = topAdditive {
            // Only additive exists
            return (
                "\(additive.ingredient) appears in \(additive.percentage)% of your reactions",
                "Most common additive detected",
                "eye.fill",
                .orange
            )
        }

        return nil
    }

    // Get symptoms associated with a specific allergen category
    private func symptomsForCategory(_ category: String) -> [(symptom: String, count: Int)] {
        var symptomCounts: [String: Int] = [:]

        for reaction in reactionManager.reactions {
            // Check if any suspected ingredient in this reaction matches the category
            let matchesCategory = reaction.suspectedIngredients.contains { ingredient in
                getBaseAllergen(for: ingredient) == category
            }

            if matchesCategory {
                for symptom in reaction.symptoms {
                    symptomCounts[symptom, default: 0] += 1
                }
            }
        }

        // Return sorted by count (most common first), limited to top 3
        return symptomCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { (symptom: $0.key, count: $0.value) }
    }

    // E-numbers and additives derived from or processed with allergens
    private func getAllergenFromAdditive(_ ingredient: String) -> String? {
        let lower = ingredient.lowercased()

        // Sulphites (E220-E228) - must be declared if >10mg/kg
        if lower.contains("e220") || lower.contains("e221") || lower.contains("e222") ||
           lower.contains("e223") || lower.contains("e224") || lower.contains("e225") ||
           lower.contains("e226") || lower.contains("e227") || lower.contains("e228") {
            return "Sulphites"
        }

        // Milk-derived additives
        // E101 (Riboflavin) - can be dairy-derived
        // E153 (Vegetable carbon) - sometimes processed with milk proteins
        // E270 (Lactic acid) - often dairy-derived
        // E322 (Lecithin) - when from milk (soy lecithin is fine)
        // E325-E327 (Lactates) - derived from lactic acid (milk)
        // E472b (Lactic acid esters) - milk-derived
        // E481 (Sodium stearoyl lactylate) - contains lactylate from milk
        // E966 (Lactitol) - derived from lactose (milk sugar)
        if lower.contains("e270") || lower.contains("e325") || lower.contains("e326") ||
           lower.contains("e327") || lower.contains("e472b") || lower.contains("e481") ||
           lower.contains("e966") || lower.contains("lactitol") || lower.contains("lactate") ||
           lower.contains("lactic acid") {
            return "Milk"
        }

        // Egg-derived additives
        // E322 (Lecithin) - when from eggs
        // E1105 (Lysozyme) - derived from egg whites
        if lower.contains("e1105") || lower.contains("lysozyme") {
            return "Eggs"
        }

        // Fish-derived additives
        // E1105 (Lysozyme) - can also be fish-derived
        // E640 (Glycine) - sometimes fish-derived
        // Fish gelatine used in some additives
        if lower.contains("fish gelatin") || lower.contains("fish gelatine") {
            return "Fish"
        }

        // Soy-derived additives
        // E322 (Lecithin) - often soy-derived (most common source)
        // E426 (Soybean hemicellulose)
        // E479b (Soy oil oxidized with mono- and diglycerides)
        if (lower.contains("e322") && (lower.contains("soy") || lower.contains("soya"))) ||
           lower.contains("e426") || lower.contains("e479b") ||
           lower.contains("soy lecithin") || lower.contains("soya lecithin") {
            return "Soya"
        }

        // Gluten-derived additives
        // E1404-E1451 (Modified starches) - can be wheat-derived
        // E953 (Isomalt) - often derived from wheat
        // Maltodextrin - often wheat-derived (but can be corn)
        // Dextrose/glucose syrup - can be wheat-derived
        if (lower.contains("modified starch") || lower.contains("maltodextrin")) &&
           (lower.contains("wheat") || lower.contains("gluten")) {
            return "Gluten"
        }

        // Celery-derived
        // E640 (Glycine) - can be celery-derived
        if lower.contains("celery") && (lower.contains("extract") || lower.contains("e640")) {
            return "Celery"
        }

        return nil
    }

    // UK's 14 Major Allergens - Base Categories (comprehensive detection)
    private func getBaseAllergen(for ingredient: String) -> String? {
        let lower = ingredient.lowercased()

        // First check if it's an additive derived from allergens
        if let allergenFromAdditive = getAllergenFromAdditive(ingredient) {
            return allergenFromAdditive
        }

        // Milk and dairy products (uses comprehensive cheese/dairy list)
        if AllergenDetector.shared.containsDairyMilk(in: lower) {
            return "Milk"
        }

        // Eggs (comprehensive)
        let eggKeywords = ["egg", "albumin", "mayonnaise", "meringue", "ovalbumin", "lecithin", "lysozyme",
                           "quiche", "frittata", "omelette", "omelet", "brioche", "challah", "hollandaise",
                           "béarnaise", "bearnaise", "aioli", "carbonara", "pavlova", "soufflé", "souffle",
                           "custard", "eggnog", "scotch egg"]
        if eggKeywords.contains(where: { lower.contains($0) }) {
            return "Eggs"
        }

        // Peanuts (separate from tree nuts)
        let peanutKeywords = ["peanut", "groundnut", "arachis", "peanut butter", "peanut oil", "satay", "monkey nuts"]
        if peanutKeywords.contains(where: { lower.contains($0) }) {
            return "Peanuts"
        }

        // Tree nuts (comprehensive)
        let treeNutKeywords = ["almond", "hazelnut", "walnut", "cashew", "pistachio", "pecan", "filbert",
                               "brazil nut", "macadamia", "pine nut", "chestnut", "praline", "gianduja",
                               "marzipan", "frangipane", "nougat", "nutella", "nut butter", "almond flour",
                               "ground almonds", "flaked almonds", "walnut oil", "hazelnut oil"]
        if treeNutKeywords.contains(where: { lower.contains($0) }) {
            return "Tree Nuts"
        }

        // Cereals containing gluten (comprehensive)
        let glutenKeywords = ["wheat", "gluten", "barley", "rye", "oats", "spelt", "kamut", "einkorn",
                              "triticale", "durum", "farro", "freekeh", "seitan", "malt", "brewer's yeast",
                              "semolina", "bulgur", "couscous", "flour", "bread", "pasta", "beer", "lager", "ale", "stout"]
        if glutenKeywords.contains(where: { lower.contains($0) }) {
            return "Gluten"
        }

        // Soya (comprehensive)
        let soyKeywords = ["soy", "soya", "soybean", "tofu", "tempeh", "miso", "shoyu", "tamari",
                           "edamame", "soy sauce", "soy milk", "soy protein", "soy lecithin", "natto", "tvp"]
        if soyKeywords.contains(where: { lower.contains($0) }) {
            return "Soya"
        }

        // Fish (comprehensive - all common species)
        let fishKeywords = ["fish", "fish sauce", "worcestershire", "fish finger", "fish cake", "fish pie",
                            "salmon", "tuna", "cod", "bass", "trout", "anchovy", "sardine", "mackerel",
                            "haddock", "plaice", "pollock", "hake", "monkfish", "halibut", "tilapia",
                            "bream", "sole", "herring", "kipper", "whitebait", "pilchard", "sprat",
                            "swordfish", "snapper", "grouper", "perch", "catfish", "carp", "pike", "eel"]
        if fishKeywords.contains(where: { lower.contains($0) }) {
            return "Fish"
        }

        // Crustaceans (comprehensive)
        let crustaceanKeywords = ["shrimp", "prawn", "crab", "lobster", "crawfish", "crayfish", "langoustine",
                                  "king prawn", "tiger prawn", "crab stick", "crab cake", "shellfish"]
        if crustaceanKeywords.contains(where: { lower.contains($0) }) {
            return "Crustaceans"
        }

        // Molluscs (comprehensive)
        let molluscKeywords = ["mollusc", "clam", "mussel", "oyster", "scallop", "cockle", "winkle", "whelk",
                               "squid", "calamari", "octopus", "cuttlefish", "abalone", "snail", "escargot"]
        if molluscKeywords.contains(where: { lower.contains($0) }) {
            return "Molluscs"
        }

        // Sesame (comprehensive)
        let sesameKeywords = ["sesame", "tahini", "sesame oil", "sesame seed", "hummus", "houmous",
                              "halvah", "halva", "za'atar", "zaatar", "gomashio", "benne seed"]
        if sesameKeywords.contains(where: { lower.contains($0) }) {
            return "Sesame"
        }

        // Mustard
        let mustardKeywords = ["mustard", "mustard seed", "dijon", "wholegrain mustard"]
        if mustardKeywords.contains(where: { lower.contains($0) }) {
            return "Mustard"
        }

        // Celery
        let celeryKeywords = ["celery", "celeriac", "celery salt", "celery extract"]
        if celeryKeywords.contains(where: { lower.contains($0) }) {
            return "Celery"
        }

        // Lupin
        let lupinKeywords = ["lupin", "lupine", "lupin flour"]
        if lupinKeywords.contains(where: { lower.contains($0) }) {
            return "Lupin"
        }

        // Sulphites (comprehensive with E-numbers)
        let sulphiteKeywords = ["sulphite", "sulfite", "sulphur dioxide", "sulfur dioxide",
                                "e220", "e221", "e222", "e223", "e224", "e225", "e226", "e227", "e228",
                                "metabisulphite", "metabisulfite"]
        if sulphiteKeywords.contains(where: { lower.contains($0) }) {
            return "Sulphites"
        }

        return nil
    }

    /// Checks if an ingredient string is valid (not garbage data from OCR)
    private func isValidIngredient(_ ingredient: String) -> Bool {
        let trimmed = ingredient.trimmingCharacters(in: .whitespacesAndNewlines)

        // Too short or too long
        if trimmed.count < 2 || trimmed.count > 50 { return false }

        // Contains URLs
        if trimmed.contains("www.") || trimmed.contains("http") || trimmed.contains(".co.uk") || trimmed.contains(".com") { return false }

        // Contains phone numbers (sequences of 5+ digits)
        let digitCount = trimmed.filter { $0.isNumber }.count
        if digitCount >= 5 { return false }

        // Contains nutrition data patterns (percentages like "28G 11% 26G")
        let nutritionPattern = #"\d+[gG]\s+\d+%"#
        if trimmed.range(of: nutritionPattern, options: .regularExpression) != nil { return false }

        // Contains date patterns
        let datePattern = #"\d{2}/\d{2}/\d{2}"#
        if trimmed.range(of: datePattern, options: .regularExpression) != nil { return false }

        // Contains mostly uppercase letters with numbers (batch codes like "F 1 #1 Slo00")
        let uppercaseCount = trimmed.filter { $0.isUppercase }.count
        if uppercaseCount > trimmed.count / 2 && digitCount > 2 { return false }

        // Contains duplicate words (like "Wheat Flour Wheat Flour")
        let words = trimmed.lowercased().split(separator: " ").map { String($0) }
        if words.count >= 4 {
            let uniqueWords = Set(words)
            if Double(uniqueWords.count) / Double(words.count) < 0.6 { return false }
        }

        // Starts with connecting words (incomplete ingredient fragments)
        let invalidStarts = ["contains", "in addition to", "check out", "minimum", "age adult"]
        if invalidStarts.contains(where: { trimmed.lowercased().hasPrefix($0) }) { return false }

        return true
    }

    /// Checks if an ingredient is an additive (E-number or common additive name)
    private func isAdditive(_ ingredient: String) -> Bool {
        let lower = ingredient.lowercased()

        // E-number pattern (e.g., E100, E621, etc.)
        let eNumberPattern = #"^e\d{3,4}[a-z]?$"#
        if lower.range(of: eNumberPattern, options: .regularExpression) != nil {
            return true
        }

        // Common additive names
        let additiveKeywords = [
            "monosodium glutamate", "msg", "aspartame", "sodium benzoate",
            "potassium sorbate", "citric acid", "ascorbic acid", "sodium nitrite",
            "sodium nitrate", "carrageenan", "xanthan gum", "guar gum",
            "modified starch", "lecithin", "annatto", "caramel color",
            "artificial flavor", "artificial colour", "natural flavor"
        ]

        return additiveKeywords.contains(where: { lower.contains($0) })
    }

    private var allTriggers: [(ingredient: String, count: Int, percentage: Int, trend: PatternRow.Trend, isAllergen: Bool, isAdditive: Bool, baseAllergen: String?)] {
        // Require at least 3 reactions before showing patterns
        guard reactionManager.reactions.count >= 3 else { return [] }

        // Count ingredient frequencies (filtering out garbage)
        var ingredientCounts: [String: Int] = [:]
        for reaction in reactionManager.reactions {
            for ingredient in reaction.suspectedIngredients {
                let normalized = ingredient.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

                // Skip garbage data
                guard isValidIngredient(normalized) else { continue }

                ingredientCounts[normalized, default: 0] += 1
            }
        }

        // Calculate percentages and determine category
        let totalReactions = reactionManager.reactions.count
        let mapped = ingredientCounts.map { (ingredient, count) -> (ingredient: String, count: Int, percentage: Int, trend: PatternRow.Trend, isAllergen: Bool, isAdditive: Bool, baseAllergen: String?) in
            let percentage = Int((Double(count) / Double(totalReactions)) * 100)
            let trend = calculateTrend(for: ingredient)
            let baseAllergen = getBaseAllergen(for: ingredient)
            let allergen = baseAllergen != nil
            let additive = isAdditive(ingredient)
            return (ingredient.capitalized, count, percentage, trend, allergen, additive, baseAllergen)
        }

        // Sort by frequency (descending), then alphabetically for stable ordering
        return mapped.sorted {
            if $0.count != $1.count {
                return $0.count > $1.count
            }
            return $0.ingredient < $1.ingredient
        }
    }

    private var allergenTriggers: [(ingredient: String, count: Int, percentage: Int, trend: PatternRow.Trend, isAllergen: Bool, isAdditive: Bool, baseAllergen: String?)] {
        allTriggers.filter { $0.isAllergen }
    }

    private var additiveTriggers: [(ingredient: String, count: Int, percentage: Int, trend: PatternRow.Trend, isAllergen: Bool, isAdditive: Bool, baseAllergen: String?)] {
        allTriggers.filter { $0.isAdditive && !$0.isAllergen }
    }

    private var otherTriggers: [(ingredient: String, count: Int, percentage: Int, trend: PatternRow.Trend, isAllergen: Bool, isAdditive: Bool, baseAllergen: String?)] {
        allTriggers.filter { !$0.isAllergen && !$0.isAdditive }
    }

    // Group allergen triggers by their base allergen category with category percentage
    private var groupedAllergenTriggers: [(category: String, percentage: Int, ingredients: [(ingredient: String, count: Int, percentage: Int, trend: PatternRow.Trend)])] {
        var grouped: [String: [(ingredient: String, count: Int, percentage: Int, trend: PatternRow.Trend)]] = [:]

        for trigger in allergenTriggers {
            guard let category = trigger.baseAllergen else { continue }

            let ingredient = (
                ingredient: trigger.ingredient,
                count: trigger.count,
                percentage: trigger.percentage,
                trend: trigger.trend
            )

            if grouped[category] != nil {
                grouped[category]?.append(ingredient)
            } else {
                grouped[category] = [ingredient]
            }
        }

        // Sort ingredients within each category by frequency (stable sorting)
        for category in grouped.keys.sorted() {
            grouped[category]?.sort {
                if $0.count != $1.count {
                    return $0.count > $1.count
                }
                return $0.ingredient < $1.ingredient
            }
        }

        // Calculate category percentage (highest percentage ingredient in that category)
        // and convert to sorted array
        let groupedArray = grouped.map { (category, ingredients) -> (category: String, percentage: Int, ingredients: [(ingredient: String, count: Int, percentage: Int, trend: PatternRow.Trend)]) in
            let maxPercentage = ingredients.map { $0.percentage }.max() ?? 0
            return (category: category, percentage: maxPercentage, ingredients: ingredients)
        }

        // Sort by category percentage (descending), then alphabetically for stable ordering
        return groupedArray.sorted {
            if $0.percentage != $1.percentage {
                return $0.percentage > $1.percentage
            }
            return $0.category < $1.category
        }
    }

    private func calculateTrend(for ingredient: String) -> PatternRow.Trend {
        let calendar = Calendar.current
        let now = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let sixtyDaysAgo = calendar.date(byAdding: .day, value: -60, to: now) ?? now

        // Recent reactions (last 30 days)
        let recentCount = reactionManager.reactions.filter {
            let date = $0.timestamp.dateValue()
            return date >= thirtyDaysAgo && date <= now &&
                   $0.suspectedIngredients.contains { $0.lowercased() == ingredient.lowercased() }
        }.count

        // Previous period (30-60 days ago)
        let previousCount = reactionManager.reactions.filter {
            let date = $0.timestamp.dateValue()
            return date >= sixtyDaysAgo && date < thirtyDaysAgo &&
                   $0.suspectedIngredients.contains { $0.lowercased() == ingredient.lowercased() }
        }.count

        if recentCount > previousCount {
            return .increasing
        } else if recentCount < previousCount {
            return .decreasing
        } else {
            return .stable
        }
    }

    // MARK: - Tab Helper Views

    private func emptyTabMessage(_ message: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "tray")
                    .font(.system(size: 28))
                    .foregroundColor(.secondary.opacity(0.5))

                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 32)
            Spacer()
        }
    }

    private func patternRow(trigger: (ingredient: String, count: Int, percentage: Int, trend: PatternRow.Trend, isAllergen: Bool, isAdditive: Bool, baseAllergen: String?), showWatchButton: Bool) -> some View {
        let isWatched = watchedAdditives.contains(trigger.ingredient)

        return HStack(spacing: 10) {
            Text("—")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Text(trigger.ingredient)
                .font(.system(size: 15))
                .foregroundColor(.primary)

            Spacer()

            // Watch button for additives
            if showWatchButton {
                Button(action: {
                    toggleWatchedAdditive(trigger.ingredient)
                }) {
                    Image(systemName: isWatched ? "eye.fill" : "eye")
                        .font(.system(size: 14))
                        .foregroundColor(isWatched ? .orange : .secondary)
                }
                .buttonStyle(.plain)
            }

            // Percentage indicator
            Text("\(trigger.percentage)%")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(.leading, 4)
    }

    private func toggleWatchedAdditive(_ additive: String) {
        if watchedAdditives.contains(additive) {
            watchedAdditives.remove(additive)
        } else {
            watchedAdditives.insert(additive)
        }
        // Persist to UserDefaults
        UserDefaults.standard.set(Array(watchedAdditives), forKey: "watchedAdditives")
        // Post notification for other views to update
        NotificationCenter.default.post(name: NSNotification.Name("WatchedAdditivesChanged"), object: nil)
    }

    private func loadWatchedAdditives() {
        if let saved = UserDefaults.standard.array(forKey: "watchedAdditives") as? [String] {
            watchedAdditives = Set(saved)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with title and export button
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Patterns")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Common Ingredients from Your Reactions")
                        .font(.system(size: 13))
                        .italic()
                        .foregroundColor(.secondary)
                }

                Spacer()

                // PDF Export button - prominent and conditional on subscription
                if !allTriggers.isEmpty {
                    Button(action: {
                        if subscriptionManager.hasAccess {
                            showingPDFExportSheet = true
                        } else {
                            showingPaywall = true
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: subscriptionManager.hasAccess ? "doc.text.fill" : "lock.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("Export")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(subscriptionManager.hasAccess ? AppPalette.standard.accent : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(subscriptionManager.hasAccess ? AppPalette.standard.accent.opacity(0.12) : Color.gray.opacity(0.1))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Confidence indicator
            if !allTriggers.isEmpty {
                HStack(spacing: 8) {
                    Circle()
                        .fill(confidenceLevel.color)
                        .frame(width: 8, height: 8)

                    Text("Confidence: \(confidenceLevel.label)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(confidenceLevel.color)

                    Text("•")
                        .foregroundColor(.secondary.opacity(0.5))

                    Text(confidenceLevel.description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(confidenceLevel.color.opacity(0.08))
                )
            }

            if allTriggers.isEmpty {
                // Enhanced empty state with specific suggestions
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 52))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.6), AppPalette.standard.accent.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(spacing: 6) {
                        Text("Build Your Pattern Profile")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)

                        Text("Log at least 3 reactions to start seeing which ingredients may be causing issues")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Meal logging suggestions
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tips for better patterns:")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                            Text("Log reactions within 24 hours")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                            Text("Include all foods eaten before symptoms")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                            Text("Note specific symptoms for each reaction")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                // Tabbed Pattern View
                VStack(alignment: .leading, spacing: 16) {
                    // Tab Picker
                    HStack(spacing: 0) {
                        ForEach(PatternTab.allCases, id: \.self) { tab in
                            let count = tab == .allergens ? allergenTriggers.count :
                                       tab == .additives ? additiveTriggers.count :
                                       otherTriggers.count

                            Button(action: {
                                selectedPatternTab = tab
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }) {
                                VStack(spacing: 6) {
                                    Text(tab.rawValue)
                                        .font(.system(size: 13, weight: selectedPatternTab == tab ? .bold : .medium, design: .rounded))
                                        .foregroundColor(selectedPatternTab == tab ? .white : .secondary)

                                    Text("\(count)")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundColor(selectedPatternTab == tab ? .white.opacity(0.8) : .secondary.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    selectedPatternTab == tab ?
                                    LinearGradient(
                                        colors: [
                                            AppPalette.standard.accent,
                                            AppPalette.standard.accent.opacity(0.8)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    // Tab Content
                    VStack(alignment: .leading, spacing: 12) {
                        switch selectedPatternTab {
                        case .allergens:
                            if allergenTriggers.isEmpty {
                                emptyTabMessage("No allergens detected in your reactions")
                            } else {
                                // Grouped allergen display
                                ForEach(groupedAllergenTriggers, id: \.category) { group in
                                    SimplifiedAllergenGroup(
                                        allergenCategory: group.category,
                                        categoryPercentage: group.percentage,
                                        ingredients: group.ingredients,
                                        symptoms: symptomsForCategory(group.category)
                                    )
                                    .id(group.category)
                                }
                            }

                        case .additives:
                            if additiveTriggers.isEmpty {
                                emptyTabMessage("No additives detected in your reactions")
                            } else {
                                ForEach(additiveTriggers, id: \.ingredient) { trigger in
                                    patternRow(trigger: trigger, showWatchButton: true)
                                }
                            }

                        case .ingredients:
                            if otherTriggers.isEmpty {
                                emptyTabMessage("No other ingredients detected yet")
                            } else {
                                ForEach(otherTriggers, id: \.ingredient) { trigger in
                                    patternRow(trigger: trigger, showWatchButton: false)
                                }
                            }
                        }
                    }
                }
            }
        }
        .animation(nil, value: showOtherIngredients)  // Prevent all implicit animations on entire card
        .transaction { transaction in
            transaction.animation = nil  // Force disable all animations
        }
        .padding(AppSpacing.large)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(colorScheme == .dark ? Color(.systemGray4) : Color.white.opacity(0.6), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 10, x: 0, y: 4)
        .fullScreenCover(isPresented: $showingPDFExportSheet) {
            MultipleFoodReactionsPDFExportSheet(reactions: Array(reactionManager.reactions))
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(subscriptionManager)
        }
        .onAppear {
            loadWatchedAdditives()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WatchedAdditivesChanged"))) { _ in
            loadWatchedAdditives()
        }
    }
}

// MARK: - Simplified Allergen Group
struct SimplifiedAllergenGroup: View {
    let allergenCategory: String
    let categoryPercentage: Int
    let ingredients: [(ingredient: String, count: Int, percentage: Int, trend: PatternRow.Trend)]
    let symptoms: [(symptom: String, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Category header with premium percentage badge
            HStack(alignment: .center, spacing: 12) {
                Text(allergenCategory)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                // Premium gradient percentage badge
                Text("\(categoryPercentage)%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.red.opacity(0.12))

                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        }
                    )
                    .shadow(color: Color.red.opacity(0.15), radius: 3, x: 0, y: 2)
            }
            .padding(.bottom, 14)

            // Ingredient list - premium design with better spacing
            VStack(alignment: .leading, spacing: 10) {
                ForEach(ingredients, id: \.ingredient) { ingredient in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 4, height: 4)

                        Text(ingredient.ingredient)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)

                        Spacer()

                        // Percentage indicator with subtle background
                        Text("\(ingredient.percentage)%")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.secondary.opacity(0.1))
                            )
                    }
                    .padding(.leading, 2)
                }
            }

            // Symptom correlation section
            if !symptoms.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Common symptoms")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 12)

                    // Display symptoms as tags
                    HStack(spacing: 6) {
                        ForEach(symptoms, id: \.symptom) { symptomData in
                            HStack(spacing: 4) {
                                Image(systemName: symptomIcon(for: symptomData.symptom))
                                    .font(.system(size: 10))
                                Text(symptomData.symptom)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.12))
                            )
                        }
                    }
                }
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 2)
        .padding(.bottom, 8)
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(.systemGray5).opacity(0.5), Color(.systemGray5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // Map symptom names to appropriate icons
    private func symptomIcon(for symptom: String) -> String {
        let lower = symptom.lowercased()
        if lower.contains("stomach") || lower.contains("nausea") || lower.contains("cramp") || lower.contains("bloat") {
            return "bolt.heart.fill"
        } else if lower.contains("headache") || lower.contains("migraine") {
            return "brain.head.profile"
        } else if lower.contains("skin") || lower.contains("rash") || lower.contains("hive") || lower.contains("itch") {
            return "hand.raised.fill"
        } else if lower.contains("breath") || lower.contains("wheez") || lower.contains("throat") {
            return "lungs.fill"
        } else if lower.contains("fatigue") || lower.contains("tired") {
            return "battery.25"
        } else if lower.contains("diarr") || lower.contains("bowel") {
            return "arrow.down.circle.fill"
        } else if lower.contains("swell") {
            return "circle.fill"
        } else {
            return "cross.case.fill"
        }
    }
}

struct PatternRow: View {
    let trigger: String
    let frequency: String
    let trend: Trend
    let baseAllergen: String?

    enum Trend {
        case increasing, stable, decreasing

        var icon: String {
            switch self {
            case .increasing: return "arrow.up"
            case .stable: return "minus"
            case .decreasing: return "arrow.down"
            }
        }

        var color: Color {
            switch self {
            case .increasing: return .red
            case .stable: return .yellow
            case .decreasing: return .green
            }
        }
    }

    var body: some View {
        HStack {
            // Display ingredient with base allergen in brackets if available
            if let baseAllergen = baseAllergen {
                Text("\(trigger) (\(baseAllergen))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            } else {
                Text(trigger)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }

            Spacer()

            Text(frequency)
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Image(systemName: trend.icon)
                .font(.system(size: 12))
                .foregroundColor(trend.color)
        }
    }
}

// MARK: - Reaction Detail View
struct ReactionDetailView: View {
    let reaction: FoodReaction
    @Environment(\.dismiss) private var dismiss
    @State private var showingExportSheet = false

    var body: some View {
        navigationContainer {
            ScrollView {
                VStack(spacing: 16) {
                    // Food Info Card
                    VStack(alignment: .leading, spacing: 12) {
                        Label("FOOD", systemImage: "fork.knife")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(reaction.foodName)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        if let brand = reaction.foodBrand {
                            Text(brand)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

                    // Time & Severity Card
                    HStack(spacing: 12) {
                        // When Card
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppPalette.standard.accent.opacity(0.7))
                                Text("WHEN")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                            }

                            Text(formatFullDate(reaction.timestamp.dateValue()))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppPalette.standard.accent.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppPalette.standard.accent.opacity(0.15), lineWidth: 1)
                        )

                        // Severity Card
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(severityColor(for: reaction.severity).opacity(0.7))
                                Text("SEVERITY")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                            }

                            HStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(severityColor(for: reaction.severity).opacity(0.2))
                                        .frame(width: 12, height: 12)
                                    Circle()
                                        .fill(severityColor(for: reaction.severity))
                                        .frame(width: 8, height: 8)
                                }

                                Text(severityText(for: reaction.severity))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(severityColor(for: reaction.severity))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(severityColor(for: reaction.severity).opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(severityColor(for: reaction.severity).opacity(0.15), lineWidth: 1)
                        )
                    }

                    // Symptoms Card - only show if symptoms exist
                    if !reaction.symptoms.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("SYMPTOMS", systemImage: "heart.text.square.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            // Wrapping flow layout for symptoms
                            FlowLayout(spacing: 8) {
                                ForEach(reaction.symptoms, id: \.self) { symptom in
                                    Text(symptom)
                                        .font(.system(size: 14, weight: .medium))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(AppPalette.standard.accent.opacity(0.1))
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(AppPalette.standard.accent.opacity(0.2), lineWidth: 1)
                                        )
                                        .foregroundColor(AppPalette.standard.accent)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                    }

                    // Suspected Ingredients Card
                    if !reaction.suspectedIngredients.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("SUSPECTED INGREDIENTS", systemImage: "allergens")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            // Wrapping flow layout for ingredients
                            FlowLayout(spacing: 8) {
                                ForEach(reaction.suspectedIngredients, id: \.self) { ingredient in
                                    Text(ingredient)
                                        .font(.system(size: 13, weight: .semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(
                                            Capsule()
                                                .fill(Color.red.opacity(0.1))
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                                        )
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppColors.cardBackgroundElevated)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                    }

                    // Notes Card
                    if let notes = reaction.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("NOTES", systemImage: "note.text")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            Text(notes)
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                    }
                }
                .padding(20)
            }
            .background(AppAnimatedBackground())
            .navigationTitle("Reaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: { showingExportSheet = true }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                },
                trailing: Button("Done") {
                    dismiss()
                }
            )
            .fullScreenCover(isPresented: $showingExportSheet) {
                FoodReactionPDFExportSheet(reaction: reaction)
            }
        }
    }

    private func severityColor(for severity: ReactionSeverity) -> Color {
        switch severity {
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        }
    }

    private func severityText(for severity: ReactionSeverity) -> String {
        switch severity {
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        }
    }

    private func formatFullDate(_ date: Date) -> String {
        // PERFORMANCE: Use cached static formatter
        DateHelper.longDateShortTimeFormatter.string(from: date)
    }
}

// MARK: - Recipe Components
struct RecipeCollectionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recipe Collections")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                RecipeCollectionItem(name: "Quick & Easy", count: 24, color: AppPalette.standard.accent)
                RecipeCollectionItem(name: "Dairy Free", count: 18, color: .green)
                RecipeCollectionItem(name: "High Protein", count: 15, color: .red)
                RecipeCollectionItem(name: "Meal Prep", count: 12, color: .purple)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecipeCollectionItem: View {
    let name: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("\(count) recipes")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.adaptiveCard)
        .cornerRadius(8)
    }
}

struct FavouriteRecipesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Favourite Recipes")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                RecipeRow(name: "Quinoa Buddha Bowl", time: "25 min", difficulty: "Easy")
                RecipeRow(name: "Grilled Salmon", time: "20 min", difficulty: "Medium")
                RecipeRow(name: "Sweet Potato Curry", time: "35 min", difficulty: "Easy")
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SafeRecipeSuggestionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Safe Recipe Suggestions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Based on your safe foods and dietary preferences")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                RecipeRow(name: "Herb Roasted Chicken", time: "45 min", difficulty: "Easy")
                RecipeRow(name: "Mediterranean Rice Bowl", time: "30 min", difficulty: "Easy")
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecipeRow: View {
    let name: String
    let time: String
    let difficulty: String
    
    var body: some View {
        HStack {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 16))
                .foregroundColor(AppPalette.standard.accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("\(time) • \(difficulty)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Button Styles

/// Premium button style with satisfying press feedback
struct SpringyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(AppAnimation.bouncy, value: configuration.isPressed)
    }
}

/// Card button style with subtle press effect
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(AppAnimation.quick, value: configuration.isPressed)
    }
}

// MARK: - Reaction Management
@MainActor
class ReactionManager: ObservableObject {
    static let shared = ReactionManager()

    @Published var reactions: [FoodReaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    private var deletingIds: Set<UUID> = []
    private let firebaseManager = FirebaseManager.shared
    private var lastLoadedUserId: String?
    private var authObserver: NSObjectProtocol?

    var monthlyCount: Int {
        let currentDate = Date()
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: currentDate)?.start ?? currentDate

        return reactions.filter {
            $0.timestamp.dateValue() >= startOfMonth
        }.count
    }

    var weeklyCount: Int {
        let currentDate = Date()
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start ?? currentDate

        return reactions.filter {
            $0.timestamp.dateValue() >= startOfWeek
        }.count
    }

    var identificationRate: Int {
        guard !reactions.isEmpty else { return 0 }
        let identifiedCount = reactions.filter { !$0.suspectedIngredients.isEmpty }.count
        return Int((Double(identifiedCount) / Double(reactions.count)) * 100)
    }

    private init() {
        // Observe centralized auth state changes to keep reactions in sync
        if authObserver == nil {
            authObserver = NotificationCenter.default.addObserver(forName: .authStateChanged, object: nil, queue: .main) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    if self.firebaseManager.isAuthenticated,
                       let uid = self.firebaseManager.currentUser?.uid {
                        if self.lastLoadedUserId != uid || self.reactions.isEmpty {
                            self.reloadIfAuthenticated()
                        }
                    } else {
                        self.clearData()
                    }
                }
            }
        }
    }

    // Public method to reload reactions - should be called after successful authentication
    func reloadIfAuthenticated() {
        guard let uid = firebaseManager.currentUser?.uid else {
            clearData()
            return
        }
        // Avoid duplicate loads for the same user if data exists or a load is underway
        if lastLoadedUserId == uid && (isLoading || !reactions.isEmpty) {
            return
        }
        lastLoadedUserId = uid
        loadReactions()
    }

    func addReaction(_ reaction: FoodReaction) async {
        // Add to local array first for immediate UI update
        await MainActor.run {
            reactions.insert(reaction, at: 0)
        }

        // Save to Firebase
        do {
            try await firebaseManager.saveReaction(reaction)
        } catch {
                        await MainActor.run {
                errorMessage = "Failed to save reaction: \(error.localizedDescription)"
                showingError = true
                // Remove from local array since save failed
                reactions.removeAll { $0.id == reaction.id }
            }
        }
    }

    private func loadReactions() {
        Task {
            await MainActor.run {
                isLoading = true
            }

            do {
                let fetchedReactions = try await firebaseManager.getReactions()
                await MainActor.run {
                    self.reactions = fetchedReactions.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                    self.isLoading = false
                                    }
            } catch {
                                await MainActor.run {
                    self.reactions = []
                    self.isLoading = false
                }
            }
        }
    }

    func refreshReactions() async {
        await MainActor.run {
            isLoading = true
        }

        do {
            let fetchedReactions = try await firebaseManager.getReactions()
            await MainActor.run {
                self.reactions = fetchedReactions.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                self.isLoading = false
            }
        } catch {
                        await MainActor.run {
                self.isLoading = false
            }
        }
    }

    func preload(_ reactions: [FoodReaction], for userId: String) {
        let sorted = reactions.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
        reactionsDidPreload(sorted: sorted, userId: userId)
    }

    @MainActor
    private func reactionsDidPreload(sorted: [FoodReaction], userId: String) {
        self.reactions = sorted
        self.lastLoadedUserId = userId
        self.isLoading = false
    }

    func deleteReaction(_ reaction: FoodReaction) async {
        // Prevent double-delete race condition
        guard !deletingIds.contains(reaction.id) else { return }
        deletingIds.insert(reaction.id)

        // Remove from local array with animation for smooth SwiftUI list update
        withAnimation {
            reactions.removeAll { $0.id == reaction.id }
        }

        // Delete from Firebase
        do {
            try await firebaseManager.deleteReaction(reactionId: reaction.id)
        } catch {
                        // Re-add if deletion failed
            withAnimation {
                reactions.insert(reaction, at: 0)
                reactions.sort { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
            }
        }

        deletingIds.remove(reaction.id)
    }

    func clearData() {
        // Clear all reactions from memory when user logs out
        reactions.removeAll()
        isLoading = false
        errorMessage = nil
        showingError = false
        lastLoadedUserId = nil
            }
}

// MARK: - Log Reaction View
struct LogReactionView: View {
    @ObservedObject var reactionManager: ReactionManager
    @Binding var selectedTab: TabItem
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFood: FoodSearchResult?
    @State private var showingFoodSearch = false
    @State private var selectedSeverity: ReactionSeverity = .mild
    @State private var symptoms: [String] = []
    @State private var symptomInput = ""
    @State private var suspectedIngredients: [String] = []
    @State private var ingredientInput = ""
    @State private var notes = ""
    @State private var reactionTime = Date()
    @State private var isLoadingIngredients = false

    let availableSymptoms = [
        "Bloating", "Nausea", "Stomach pain", "Diarrhea", "Constipation",
        "Hives", "Itching", "Swelling", "Rash", "Headache", "Fatigue",
        "Breathing difficulty", "Runny nose", "Sneezing"
    ]

    var customSymptoms: [String] {
        symptoms.filter { !availableSymptoms.contains($0) }
    }

    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Food")
                        .font(.headline)

                    Button(action: {
                        showingFoodSearch = true
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                if let food = selectedFood {
                                    Text(food.name)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)

                                    if let brand = food.brand {
                                        Text(brand)
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Text("Select a food")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppPalette.standard.accent)
                                .font(.system(size: 16))
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onChange(of: selectedFood) { _, newFood in
                        if let food = newFood, let ingredients = food.ingredients, !ingredients.isEmpty {
                                                        autoLoadIngredientsFromFood(ingredients)
                        } else {
                                                    }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Reaction Time")
                        .font(.headline)
                    DatePicker("Time of reaction", selection: $reactionTime, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(CompactDatePickerStyle())
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Severity")
                        .font(.headline)
                    Picker("Severity", selection: $selectedSeverity) {
                        Text("Mild").tag(ReactionSeverity.mild)
                        Text("Moderate").tag(ReactionSeverity.moderate)
                        Text("Severe").tag(ReactionSeverity.severe)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Symptoms")
                        .font(.headline)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(availableSymptoms, id: \.self) { symptom in
                            Button(action: {
                                if symptoms.contains(symptom) {
                                    symptoms.removeAll { $0 == symptom }
                                } else {
                                    symptoms.append(symptom)
                                }
                            }) {
                                Text(symptom)
                                    .font(.system(size: 12))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(symptoms.contains(symptom) ? AppPalette.standard.accent : Color(.systemGray6))
                                    .foregroundColor(symptoms.contains(symptom) ? .white : .primary)
                                    .cornerRadius(20)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    // Display custom symptoms
                    if !customSymptoms.isEmpty {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(customSymptoms, id: \.self) { symptom in
                                HStack {
                                    Text(symptom)
                                        .font(.system(size: 12))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .foregroundColor(.white)
                                    Button(action: {
                                        symptoms.removeAll { $0 == symptom }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white.opacity(0.8))
                                            .font(.system(size: 14))
                                    }
                                }
                                .background(AppPalette.standard.accent)
                                .cornerRadius(20)
                            }
                        }
                        .padding(.top, 4)
                    }

                    HStack {
                        TextField("Add custom symptom", text: $symptomInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                addCustomSymptom()
                            }
                        Button(action: addCustomSymptom) {
                            Text("Add")
                                .foregroundColor(symptomInput.isEmpty ? .gray : AppPalette.standard.accent)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(symptomInput.isEmpty)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Suspected Ingredients")
                        .font(.headline)

                    if !suspectedIngredients.isEmpty {
                        ScrollView {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                ForEach(suspectedIngredients, id: \.self) { ingredient in
                                    HStack {
                                        Text(ingredient)
                                            .font(.system(size: 12))
                                        Button(action: {
                                            suspectedIngredients.removeAll { $0 == ingredient }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.system(size: 12))
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(20)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }

                    HStack {
                        TextField("Add suspected ingredient", text: $ingredientInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                addCustomIngredient()
                            }
                        Button(action: addCustomIngredient) {
                            Text("Add")
                                .foregroundColor(ingredientInput.isEmpty ? .gray : AppPalette.standard.accent)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(ingredientInput.isEmpty)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes (Optional)")
                        .font(.headline)
                    TextField("Additional notes about the reaction", text: $notes)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .padding()
        }
        .navigationTitle("Log Reaction")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button("Cancel") {
                dismiss()
            },
            trailing: Button("Save") {
                saveReaction()
            }
            .disabled(selectedFood == nil || symptoms.isEmpty)
        )
        .fullScreenCover(isPresented: $showingFoodSearch) {
            navigationContainer { FoodReactionSearchView(selectedFood: $selectedFood) }
        }
    }

    private func addCustomSymptom() {
        let trimmed = symptomInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty && !symptoms.contains(trimmed) else { return }
        symptoms.append(trimmed)
        symptomInput = ""
    }

    private func addCustomIngredient() {
        let trimmed = ingredientInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty && !suspectedIngredients.contains(trimmed) else { return }
        suspectedIngredients.append(trimmed)
        ingredientInput = ""
    }

    private func saveReaction() {
        guard let food = selectedFood else { return }

        let reaction = FoodReaction(
            foodName: food.name,
            foodId: food.id,
            foodBrand: food.brand,
            timestamp: Timestamp(date: reactionTime),
            severity: selectedSeverity,
            symptoms: symptoms,
            suspectedIngredients: suspectedIngredients,
            notes: notes.isEmpty ? nil : notes
        )

        Task {
            await reactionManager.addReaction(reaction)
            // Switch to Health tab to show reactions
            selectedTab = .food
            dismiss()
        }
    }

    private func autoLoadIngredientsFromFood(_ ingredients: [String]) {
        // Prevent concurrent calls
        guard !isLoadingIngredients else {
                        return
        }

        isLoadingIngredients = true

        // First, handle case where ingredients might be stored as one big string
        var expandedIngredients: [String] = []
        for ingredient in ingredients {
            // If an ingredient is very long (>200 chars), it's likely a comma-separated list
            if ingredient.count > 200 {
                                // Split by commas and clean up
                expandedIngredients.append(contentsOf: ingredient.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            } else {
                expandedIngredients.append(ingredient)
            }
        }

        
        // Apply client-side standardization ONLY (skip AI to prevent layout issues)
        let standardized = standardizeIngredients(expandedIngredients)

        // Update UI immediately with standardized results
        suspectedIngredients = standardized
        isLoadingIngredients = false

            }

    private func standardizeIngredients(_ ingredients: [String]) -> [String] {
        var processed: [String] = []
        var seen = Set<String>()

        for ingredient in ingredients {
            var cleaned = ingredient.trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip empty
            guard !cleaned.isEmpty else { continue }

            // Skip long text blocks (instructions/warnings)
            guard cleaned.count < 80 else { continue }

            // Skip if contains colons (labels)
            guard !cleaned.contains(":") else { continue }

            // Skip if has multiple sentences
            let periodCount = cleaned.filter { $0 == "." }.count
            guard periodCount <= 1 else { continue }

            // Filter out common non-ingredient text
            let excludeKeywords = [
                "ALLERGEN", "STORAGE", "HOW TO", "NUTRITION", "PREPARE",
                "REFRIGERATE", "BEST", "USE BY", "DEFROST", "COOKING",
                "INSTRUCTIONS", "WARNING", "CONTAINS", "MAY CONTAIN",
                "FOR ALLERGENS", "SEE INGREDIENTS", "MADE IN A",
                "INCLUDING CEREALS", "ENERGY", "FAT", "PROTEIN",
                "CARBOHYDRATE", "PER 100", "TYPICAL VALUES"
            ]

            let upperCleaned = cleaned.uppercased()
            var shouldSkip = false
            for keyword in excludeKeywords {
                if upperCleaned.contains(keyword) {
                    shouldSkip = true
                    break
                }
            }
            if shouldSkip { continue }

            // Remove vitamins and minerals
            let vitaminsMineral = [
                "CALCIUM CARBONATE", "IRON", "NIACIN", "THIAMIN", "RIBOFLAVIN",
                "VITAMIN", "FOLIC ACID", "ZINC", "MAGNESIUM", "POTASSIUM"
            ]
            for vm in vitaminsMineral {
                if upperCleaned.contains(vm) {
                    shouldSkip = true
                    break
                }
            }
            if shouldSkip { continue }

            // Clean up the ingredient name
            // Remove percentages
            cleaned = cleaned.replacingOccurrences(of: #"\s*\(\d+%?\)|\s*\d+%"#, with: "", options: .regularExpression)

            // Handle parenthetical sub-ingredients: "butter (milk)" → "butter, milk"
            if let openParen = cleaned.firstIndex(of: "("),
               let closeParen = cleaned.lastIndex(of: ")") {
                let main = String(cleaned[..<openParen]).trimmingCharacters(in: .whitespaces)
                let sub = String(cleaned[cleaned.index(after: openParen)..<closeParen]).trimmingCharacters(in: .whitespaces)

                // If sub-ingredient is not just clarification, keep both
                if !sub.isEmpty && !sub.lowercased().contains(main.lowercased()) {
                    if !seen.contains(main.lowercased()) {
                        processed.append(main)
                        seen.insert(main.lowercased())
                    }
                    if !seen.contains(sub.lowercased()) {
                        processed.append(sub)
                        seen.insert(sub.lowercased())
                    }
                    continue
                } else {
                    // Clarification, use main only
                    cleaned = main
                }
            }

            // Remove trailing/leading punctuation except periods at end
            cleaned = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: "()[]{}"))

            // Normalize spaces
            cleaned = cleaned.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

            // Final length check
            guard cleaned.count >= 2 else { continue }

            // Add if not duplicate
            let lowerCleaned = cleaned.lowercased()
            if !seen.contains(lowerCleaned) {
                processed.append(cleaned)
                seen.insert(lowerCleaned)
            }
        }

        return processed
    }

    private func standardizeIngredientsWithAI(_ ingredients: [String]) async throws -> [String] {
        guard let url = URL(string: "https://us-central1-nutrasafe-705c7.cloudfunctions.net/standardizeIngredients") else {
            throw NSError(domain: "StandardizeIngredients", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = ["data": ["ingredients": ingredients]]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(StandardizeResponse.self, from: data)

        guard response.result.success else {
            throw NSError(domain: "StandardizeIngredients", code: -1, userInfo: [NSLocalizedDescriptionKey: response.result.error ?? "Unknown error"])
        }

        return response.result.standardizedIngredients
    }

    struct StandardizeResponse: Codable {
        let result: StandardizeResult
    }

    struct StandardizeResult: Codable {
        let success: Bool
        let standardizedIngredients: [String]
        let error: String?
    }

    private func loadIngredientsFromFood() {
        guard let food = selectedFood,
              let ingredients = food.ingredients else { return }

        // Parse and add ingredients from the food's ingredient list with intelligent filtering
        let newIngredients = ingredients.compactMap { ingredient -> String? in
            let cleaned = ingredient.trimmingCharacters(in: .whitespacesAndNewlines)

            // Filter out empty strings
            guard !cleaned.isEmpty else { return nil }

            // Filter out long text blocks (likely instructions or warnings)
            guard cleaned.count < 50 else { return nil }

            // Filter out text containing colons (labels/headers)
            guard !cleaned.contains(":") else { return nil }

            // Filter out text with multiple sentences
            let periodCount = cleaned.filter { $0 == "." }.count
            guard periodCount <= 1 else { return nil }

            // Filter out common non-ingredient keywords
            let excludeKeywords = [
                "ALLERGEN", "STORAGE", "HOW TO", "NUTRITION", "PREPARE",
                "REFRIGERATE", "BEST", "USE BY", "DEFROST", "COOKING",
                "INSTRUCTIONS", "WARNING", "CONTAINS", "MAY CONTAIN"
            ]

            let upperCleaned = cleaned.uppercased()
            for keyword in excludeKeywords {
                if upperCleaned.contains(keyword) {
                    return nil
                }
            }

            return cleaned
        }

        for ingredient in newIngredients {
            if !suspectedIngredients.contains(ingredient) {
                suspectedIngredients.append(ingredient)
            }
        }
    }

    private func hasLoadedFoodIngredients(_ foodIngredients: [String]) -> Bool {
        // Check if the current suspected ingredients contain most of the food ingredients
        let cleanedFoodIngredients = foodIngredients.compactMap { ingredient in
            let cleaned = ingredient.trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned.isEmpty ? nil : cleaned
        }

        let matchCount = cleanedFoodIngredients.filter { suspectedIngredients.contains($0) }.count
        return Double(matchCount) >= Double(cleanedFoodIngredients.count) * 0.5 // At least 50% match
    }
}

// MARK: - Food Reaction Search View
struct FoodReactionSearchView: View {
    @Binding var selectedFood: FoodSearchResult?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [FoodSearchResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var isSearchFieldFocused: Bool
    @State private var showingManualEntry = false
    @State private var selectedTab = 0

    // PERFORMANCE: Debouncer to prevent search from running on every keystroke
    @StateObject private var searchDebouncer = Debouncer(milliseconds: 300)

    // Diary entries
    @State private var diaryEntries: [FoodEntry] = []
    @State private var isLoadingDiary = false

    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("", selection: $selectedTab) {
                Text("Search").tag(0)
                Text("From Diary").tag(1)
                Text("Add Manually").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Content based on selected tab
            if selectedTab == 0 {
                searchTabContent
            } else if selectedTab == 1 {
                diaryTabContent
            } else {
                manualEntryTab
            }
        }
        .navigationTitle("Select Food")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button("Cancel") {
                dismiss()
            }
        )
        .fullScreenCover(isPresented: $showingManualEntry) {
            navigationContainer {
                ManualReactionFoodEntryView(prefilledName: searchText) { manualFood in
                    selectedFood = manualFood
                    DispatchQueue.main.async { dismiss() }
                }
            }
        }
        .onAppear {
            if diaryEntries.isEmpty && !isLoadingDiary {
                loadRecentDiaryEntries()
            }
        }
        .onDisappear {
            searchTask?.cancel()
        }
    }

    // MARK: - Search Tab Content

    private var searchTabContent: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search foods...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .focused($isSearchFieldFocused)
                    .onChange(of: searchText) { _, newValue in
                        // PERFORMANCE: Debounce search to avoid running expensive operations on every keystroke
                        searchDebouncer.debounce {
                            performLiveSearch(query: newValue)
                        }
                    }
                    .onSubmit {
                        performSearch()
                    }

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Results
            if isSearching {
                VStack {
                    Spacer()
                    ProgressView("Searching...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                }
            } else if searchResults.isEmpty && !searchText.isEmpty {
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("No foods found")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Try different keywords")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .padding()
            } else if searchResults.isEmpty {
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("Search for foods")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Start typing to find foods from our database")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(searchResults, id: \.id) { food in
                            FoodSearchResultRowForReaction(
                                food: food,
                                onSelect: {
                                    selectedFood = food
                                    DispatchQueue.main.async {
                                        dismiss()
                                    }
                                }
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .onAppear {
            isSearchFieldFocused = true
        }
    }

    // MARK: - Diary Tab Content

    private var diaryTabContent: some View {
        VStack(spacing: 0) {
            if isLoadingDiary {
                VStack {
                    Spacer()
                    ProgressView("Loading diary entries...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                }
            } else if diaryEntries.isEmpty {
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("No recent diary entries")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Add foods to your diary to see them here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Group entries by date
                        ForEach(groupedDiaryEntries(), id: \.date) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                // Date header
                                Text(dateFormatter.string(from: group.date))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)
                                    .padding(.bottom, 4)

                                // Foods for this date
                                ForEach(group.entries) { entry in
                                    DiaryEntryRowForReaction(
                                        entry: entry,
                                        onSelect: {
                                            selectDiaryEntry(entry)
                                        }
                                    )
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    // MARK: - Manual Entry Tab

    private var manualEntryTab: some View {
        VStack {
            Spacer()
            VStack(spacing: 24) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text("Add Food Manually")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Enter custom food details for foods not in our database")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button(action: {
                    showingManualEntry = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Manual Entry")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.green)
                    .cornerRadius(12)
                }
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - Helper Methods

    private func loadRecentDiaryEntries() {
        isLoadingDiary = true

        Task {
            do {
                // Fetch last 14 days of diary entries
                let endDate = Date()
                let startDate = Calendar.current.date(byAdding: .day, value: -14, to: endDate) ?? endDate

                let entries = try await DiaryDataManager.shared.getMealsInTimeRange(from: startDate, to: endDate)

                await MainActor.run {
                    self.diaryEntries = entries.sorted { $0.date > $1.date }
                    self.isLoadingDiary = false
                }
            } catch {
                                await MainActor.run {
                    self.isLoadingDiary = false
                }
            }
        }
    }

    private func groupedDiaryEntries() -> [(date: Date, entries: [FoodEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: diaryEntries) { entry in
            calendar.startOfDay(for: entry.date)
        }

        return grouped.map { (date: $0.key, entries: $0.value) }
            .sorted { $0.date > $1.date }
    }

    private func selectDiaryEntry(_ entry: FoodEntry) {
        // Convert FoodEntry to FoodSearchResult
        let searchResult = FoodSearchResult(
            id: entry.id,
            name: entry.foodName,
            brand: entry.brandName,
            calories: entry.calories,
            protein: entry.protein,
            carbs: entry.carbohydrates,
            fat: entry.fat,
            fiber: entry.fiber ?? 0,
            sugar: entry.sugar ?? 0,
            sodium: entry.sodium ?? 0,
            servingDescription: (entry.isPerUnit == true) ? "1 \(entry.servingUnit)" : "\(entry.servingSize) \(entry.servingUnit)",
            servingSizeG: nil,
            isPerUnit: entry.isPerUnit,
            ingredients: entry.ingredients,
            confidence: 1.0,
            isVerified: true
        )

        selectedFood = searchResult
        DispatchQueue.main.async {
            dismiss()
        }
    }

    private var dateFormatter: DateFormatter {
        // PERFORMANCE: Use cached static formatter with relative dates
        DateHelper.relativeDateFormatter
    }

    private func performLiveSearch(query: String) {
        searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay

            if !Task.isCancelled {
                performSearch()
            }
        }
    }

    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        Task {
            do {
                let results = try await FirebaseManager.shared.searchFoods(query: query)

                // Enrich results with pending verification ingredients (same as diary search)
                let capturedResults = results
                Task.detached(priority: .background) {
                    do {
                        let pendingVerifications = try await FirebaseManager.shared.getPendingVerifications()

                        if Task.isCancelled { return }

                        var enrichedResults = capturedResults
                        var hasChanges = false

                        // Find matching foods and add pending ingredients
                        for i in 0..<enrichedResults.count {
                            let result = enrichedResults[i]

                            // Match strictly by name AND brand when both are present
                            let matchingVerifications = pendingVerifications.filter { pending in
                                let nameMatch = pending.foodName.lowercased() == result.name.lowercased()
                                guard let pendingBrand = pending.brandName?.trimmingCharacters(in: .whitespacesAndNewlines),
                                      !pendingBrand.isEmpty,
                                      let resultBrand = result.brand?.trimmingCharacters(in: .whitespacesAndNewlines),
                                      !resultBrand.isEmpty else {
                                    return false
                                }
                                let brandMatch = pendingBrand.lowercased() == resultBrand.lowercased()
                                return nameMatch && brandMatch
                            }

                            // If we found a matching verification with ingredients, use those
                            if let pendingMatch = matchingVerifications.first,
                               let ingredients = pendingMatch.ingredients,
                               !ingredients.isEmpty,
                               ingredients != "Processing ingredient image..." {

                                enrichedResults[i] = FoodSearchResult(
                                    id: result.id,
                                    name: result.name,
                                    brand: result.brand,
                                    calories: result.calories,
                                    protein: result.protein,
                                    carbs: result.carbs,
                                    fat: result.fat,
                                    fiber: result.fiber,
                                    sugar: result.sugar,
                                    sodium: result.sodium,
                                    servingDescription: result.servingDescription,
                                    ingredients: [ingredients + " (⏳ Awaiting Verification)"]
                                )
                                hasChanges = true
                            }
                        }

                        if hasChanges {
                            let finalResults = enrichedResults // Capture for Swift 6 concurrency
                            await MainActor.run {
                                self.searchResults = finalResults
                            }
                        }
                    } catch {
                        // Silently fail - show results without enrichment
                    }
                }

                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.searchResults = []
                    self.isSearching = false
                }
            }
        }
    }

    private func addManualFood() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let foodName = query.isEmpty ? "Custom Food" : query

        let manualFood = FoodSearchResult(
            id: UUID().uuidString,
            name: foodName,
            brand: nil,
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            fiber: 0,
            sugar: 0,
            sodium: 0,
            servingDescription: "Manual entry",
            ingredients: nil,
            confidence: 1.0,
            isVerified: false
        )

        selectedFood = manualFood
        dismiss()
    }

}

// MARK: - Diary Entry Row for Reactions
struct DiaryEntryRowForReaction: View {
    let entry: FoodEntry
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.foodName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    if let brand = entry.brandName {
                        Text(brand)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                            Text("\(Int(entry.calories)) cal")
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.orange)

                        Text(entry.isPerUnit == true ? "1 \(entry.servingUnit)" : "\(entry.servingSize.formatted()) \(entry.servingUnit)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        if let ingredients = entry.ingredients, !ingredients.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 10))
                                Text("\(ingredients.count)")
                            }
                            .font(.system(size: 12))
                            .foregroundColor(AppPalette.standard.accent)
                        }
                    }
                }

                Spacer()

                // Time display
                VStack(alignment: .trailing, spacing: 4) {
                    Text(timeFormatter.string(from: entry.date))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Text(entry.mealType.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppPalette.standard.accent.opacity(0.1))
                        .cornerRadius(6)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.adaptiveCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var timeFormatter: DateFormatter {
        // PERFORMANCE: Use cached static formatter
        DateHelper.shortTimeFormatter
    }
}

// MARK: - Food Search Result Row for Reactions
struct FoodSearchResultRowForReaction: View {
    let food: FoodSearchResult
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .onAppear {
                            }

                    if let brand = food.brand {
                        Text(brand)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    if let ingredients = food.ingredients, !ingredients.isEmpty {
                        let displayText = ingredients.prefix(3).joined(separator: ", ")
                        let suffix = ingredients.count > 3 ? "..." : ""
                        Text("Ingredients: \(displayText)\(suffix)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sample Data
let sampleReactions: [FoodReaction] = [
    FoodReaction(
        foodName: "Milk",
        foodId: "sample-milk-001",
        foodBrand: "Dairy Farm",
        timestamp: Timestamp(),
        severity: .moderate,
        symptoms: ["Bloating", "nausea"],
        suspectedIngredients: ["milk", "lactose"],
        notes: "Had with cereal"
    ),
    FoodReaction(
        foodName: "Peanuts",
        foodId: "sample-peanuts-002",
        foodBrand: "Nutty Co.",
        timestamp: Timestamp(),
        severity: .severe,
        symptoms: ["Hives", "itching"],
        suspectedIngredients: ["peanuts", "groundnuts"],
        notes: "Trail mix snack"
    ),
    FoodReaction(
        foodName: "Wheat bread",
        foodId: "sample-bread-003",
        foodBrand: "Bakery Fresh",
        timestamp: Timestamp(),
        severity: .mild,
        symptoms: ["Stomach pain"],
        suspectedIngredients: ["wheat", "gluten"],
        notes: "With breakfast"
    )
]

// Local definition to ensure build sees the manual entry view
struct ManualReactionFoodEntryView: View {
    let prefilledName: String
    let onSave: (FoodSearchResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var foodName: String
    @State private var ingredientsText: String = ""

    init(prefilledName: String, onSave: @escaping (FoodSearchResult) -> Void) {
        self.prefilledName = prefilledName
        self.onSave = onSave
        _foodName = State(initialValue: prefilledName.isEmpty ? "" : prefilledName)
    }

    var body: some View {
        Form {
            Section(header: Text("Food")) {
                TextField("Enter food name", text: $foodName)
            }

            Section(
                header: Text("Ingredients (optional)"),
                footer: Text("Separate ingredients with commas, e.g. milk, sugar, cocoa")
            ) {
                TextField("milk, sugar, cocoa", text: $ingredientsText)
            }
        }
        .navigationTitle("Add Manually")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button("Cancel") { dismiss() },
            trailing: Button("Save") {
                let trimmedName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty else { return }

                let ingredientsArray: [String]? = {
                    let raw = ingredientsText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if raw.isEmpty { return nil }
                    let parts = raw
                        .split(separator: ",")
                        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    return parts.isEmpty ? nil : parts
                }()

                let manualFood = FoodSearchResult(
                    id: UUID().uuidString,
                    name: trimmedName,
                    brand: nil,
                    calories: 0,
                    protein: 0,
                    carbs: 0,
                    fat: 0,
                    fiber: 0,
                    sugar: 0,
                    sodium: 0,
                    servingDescription: "Manual entry",
                    ingredients: ingredientsArray,
                    confidence: 1.0,
                    isVerified: false
                )

                onSave(manualFood)
                dismiss()
            }
            .disabled(foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        )
    }
}

// MARK: - Food Reaction PDF Export Sheet
struct FoodReactionPDFExportSheet: View {
    let reaction: FoodReaction
    @Environment(\.dismiss) private var dismiss
    @State private var pdfURL: URL?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showingShareSheet = false

    var body: some View {
        navigationContainer {
            VStack(spacing: 24) {
                if isGenerating {
                    ProgressView("Generating PDF...")
                        .padding()
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red)

                        Text("Export Failed")
                            .font(.headline)

                        Text(errorMessage)
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Try Again") {
                            generatePDF()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if pdfURL != nil {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)

                        Text("PDF Generated")
                            .font(.headline)

                        Text("Your reaction report is ready to share")
                            .font(.callout)
                            .foregroundColor(.secondary)

                        Button(action: { showingShareSheet = true }) {
                            Label("Share PDF", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal)
                    }
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Export Reaction Report")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Generate a detailed PDF report of this food reaction for your records or to share with your doctor or nutritionist.")
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Report Includes")
                                .font(.headline)
                                .foregroundColor(.primary)

                            VStack(alignment: .leading, spacing: 10) {
                                Label("Food name and brand", systemImage: "fork.knife")
                                Label("Reaction date and severity", systemImage: "calendar")
                                Label("Symptoms experienced", systemImage: "heart.text.square")
                                Label("Suspected ingredients", systemImage: "list.bullet")
                                Label("7-day meal history with ingredients", systemImage: "calendar.badge.clock")
                            }
                            .font(.callout)
                            .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: generatePDF) {
                            Label("Generate PDF", systemImage: "doc.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding()
                }
            }
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .fullScreenCover(isPresented: $showingShareSheet) {
                if let url = pdfURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func generatePDF() {
        isGenerating = true
        errorMessage = nil

        Task {
            do {
                // Calculate date range for meal history (7 days prior to reaction)
                let reactionDate = reaction.timestamp.dateValue()
                let startDate = reactionDate.addingTimeInterval(-7 * 24 * 3600)  // 7 days before

                // Fetch meals in the 7-day period
                let meals = try await DiaryDataManager.shared.getMealsInTimeRange(from: startDate, to: reactionDate)

                // Generate PDF on background thread
                let url = await Task.detached(priority: .userInitiated) {
                    return ReactionPDFExporter.exportFoodReactionReport(reaction: reaction, mealHistory: meals)
                }.value

                if let url = url {
                    await MainActor.run {
                        self.pdfURL = url
                        self.isGenerating = false
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "Failed to generate PDF. Please try again."
                        self.isGenerating = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to fetch meal history: \(error.localizedDescription)"
                    self.isGenerating = false
                }
            }
        }
    }
}

// MARK: - Food Reaction PDF Export Sheet (for multiple reactions)

struct MultipleFoodReactionsPDFExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let reactions: [FoodReaction]
    @State private var isGenerating = false
    @State private var pdfURL: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?
    @State private var userName: String = ""
    @State private var showingNameAlert = false

    // Get user's adaptive palette (fallback to safer theme if not set)
    private var userPalette: OnboardingPalette {
        if let intentRaw = UserDefaults.standard.string(forKey: "userIntent"),
           let intent = UserIntent(rawValue: intentRaw) {
            return OnboardingPalette.forIntent(intent)
        }
        return OnboardingPalette.safer
    }

    var body: some View {
        navigationContainer {
            ScrollView {
                VStack(spacing: 0) {
                    if isGenerating {
                        // Generating state - breathing animation
                        VStack(spacing: 32) {
                            Spacer()

                            ZStack {
                                Circle()
                                    .fill(userPalette.accent.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                    .scaleEffect(isGenerating ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isGenerating)

                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(userPalette.accent)
                            }

                            VStack(spacing: 12) {
                                Text("Creating Your Report")
                                    .font(AppTypography.sectionTitle(24))
                                    .foregroundColor(Color.textPrimary)

                                Text("Gathering your reaction patterns...")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(Color.textSecondary)
                                    .multilineTextAlignment(.center)
                            }

                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 24)

                    } else if let error = errorMessage {
                        // Error state - warm, supportive
                        VStack(spacing: 32) {
                            Spacer()

                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                                .padding(.top, 40)

                            VStack(spacing: 12) {
                                Text("Something Went Wrong")
                                    .font(AppTypography.sectionTitle(24))
                                    .foregroundColor(Color.textPrimary)

                                Text(error)
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(Color.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }

                            Spacer()

                            // Action buttons
                            VStack(spacing: 12) {
                                Button(action: {
                                    errorMessage = nil
                                    showingNameAlert = true
                                }) {
                                    Text("Try Again")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [userPalette.accent, userPalette.accent.opacity(0.8)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .cornerRadius(14)
                                }
                                .scaleEffect(isGenerating ? 0.98 : 1.0)

                                Button(action: {
                                    dismiss()
                                }) {
                                    Text("Close")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(userPalette.accent)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(userPalette.accent.opacity(0.3), lineWidth: 1.5)
                                        )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 32)
                        }

                    } else if pdfURL != nil {
                        // Success state - encouraging
                        VStack(spacing: 32) {
                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(userPalette.accent)
                                .padding(.top, 40)

                            VStack(spacing: 12) {
                                Text("Your Report Is Ready")
                                    .font(AppTypography.sectionTitle(28))
                                    .foregroundColor(Color.textPrimary)

                                Text("Share with your healthcare provider to help them understand your patterns.")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(Color.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }

                            Spacer()

                            // Action buttons
                            VStack(spacing: 12) {
                                Button(action: {
                                    showShareSheet = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Share Report")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [userPalette.accent, userPalette.accent.opacity(0.8)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(14)
                                }
                                .scaleEffect(isGenerating ? 0.98 : 1.0)

                                Button(action: {
                                    dismiss()
                                }) {
                                    Text("Done")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(userPalette.accent)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(userPalette.accent.opacity(0.3), lineWidth: 1.5)
                                        )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 32)
                        }

                    } else {
                        // Initial state - calm, informative
                        VStack(spacing: 32) {
                            // Header
                            VStack(spacing: 16) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 56))
                                    .foregroundColor(userPalette.accent)
                                    .padding(.top, 32)

                                VStack(spacing: 8) {
                                    Text("Share Your Patterns")
                                        .font(AppTypography.sectionTitle(32))
                                        .foregroundColor(Color.textPrimary)
                                        .multilineTextAlignment(.center)

                                    Text("A clear summary of your \(reactions.count) reaction\(reactions.count == 1 ? "" : "s") to help your healthcare provider understand.")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(Color.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 8)
                                }
                            }
                            .padding(.horizontal, 24)

                            // Report includes card
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Your Report Includes")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Color.textPrimary)

                                VStack(alignment: .leading, spacing: 16) {
                                    ReportIncludesRow(
                                        icon: "allergens",
                                        title: "Allergens Detected",
                                        description: "Recognized allergens across your reactions",
                                        color: userPalette.accent
                                    )

                                    ReportIncludesRow(
                                        icon: "eye.fill",
                                        title: "Additives Flagged",
                                        description: "E-numbers and additives you've reacted to",
                                        color: .orange
                                    )

                                    ReportIncludesRow(
                                        icon: "leaf.fill",
                                        title: "Common Ingredients",
                                        description: "Other ingredients appearing in patterns",
                                        color: .green
                                    )

                                    ReportIncludesRow(
                                        icon: "exclamationmark.triangle.fill",
                                        title: "Symptoms Logged",
                                        description: "What your body was telling you",
                                        color: .red
                                    )

                                    ReportIncludesRow(
                                        icon: "calendar",
                                        title: "Timeline & Context",
                                        description: "When reactions occurred and meal history",
                                        color: .blue
                                    )
                                }
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
                            )
                            .cardShadow()
                            .padding(.horizontal, 24)

                            // Disclaimer
                            VStack(spacing: 8) {
                                Text("For Healthcare Use")
                                    .font(.system(size: 13, weight: .semibold, design: .default))
                                    .foregroundColor(Color.textSecondary)

                                Text("This report is for informational purposes. Share it with a qualified healthcare provider for professional guidance.")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color.textTertiary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 32)

                            Spacer()

                            // Generate button
                            VStack(spacing: 12) {
                                Button(action: {
                                    showingNameAlert = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "doc.badge.plus")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Generate Report")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [userPalette.accent, userPalette.accent.opacity(0.8)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(14)
                                }
                                .scaleEffect(isGenerating ? 0.98 : 1.0)

                                Button(action: {
                                    dismiss()
                                }) {
                                    Text("Cancel")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(userPalette.accent)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(userPalette.accent.opacity(0.3), lineWidth: 1.5)
                                        )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 32)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height - 100)
            }
            .background(colorScheme == .dark ? Color.midnightBackground : Color(.systemBackground))
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showShareSheet) {
                if let url = pdfURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Personalise Your Report", isPresented: $showingNameAlert) {
                TextField("Your name (optional)", text: $userName)
                Button("Generate") {
                    generatePDF(userName: userName.isEmpty ? "User" : userName)
                }
                Button("Skip", role: .cancel) {
                    generatePDF(userName: "User")
                }
            } message: {
                Text("Add your name to help healthcare providers identify your report.")
            }
        }
        .onDisappear {
            // Clean up temporary file when sheet is dismissed
            if let url = pdfURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    private func generatePDF(userName: String) {
        isGenerating = true
        errorMessage = nil

        Task {
            do {
                guard !reactions.isEmpty else {
                    await MainActor.run {
                        self.errorMessage = "No reactions found to export."
                        self.isGenerating = false
                    }
                    return
                }

                // Get the most recent reaction
                guard let mostRecentReaction = reactions.first else {
                    await MainActor.run {
                        self.errorMessage = "No reactions found to export."
                        self.isGenerating = false
                    }
                                        return
                }
                let reactionDate = mostRecentReaction.timestamp.dateValue()

                // Fetch 7-day meal history prior to the most recent reaction
                let startDate = reactionDate.addingTimeInterval(-7 * 24 * 3600)  // 7 days before
                let meals = try await DiaryDataManager.shared.getMealsInTimeRange(from: startDate, to: reactionDate)

                // Filter out meals that are already in the reactions list (dedupe)
                let reactionFoodNames = Set(reactions.map { $0.foodName.lowercased() })
                let filteredMeals = meals.filter { meal in
                    !reactionFoodNames.contains(meal.foodName.lowercased())
                }

                // Generate PDF on background thread
                let url = await Task.detached(priority: .userInitiated) {
                    return ReactionPDFExporter.exportMultipleFoodReactions(
                        reactions: reactions,
                        mealHistory: filteredMeals,
                        userName: userName
                    )
                }.value

                if let url = url {
                    await MainActor.run {
                        self.pdfURL = url
                        self.isGenerating = false
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "Failed to generate PDF. Please try again."
                        self.isGenerating = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to generate PDF: \(error.localizedDescription)"
                    self.isGenerating = false
                }
            }
        }
    }
}

// MARK: - Report Includes Row Helper
struct ReportIncludesRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.textPrimary)

                Text(description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - FastingViewModel Wrapper
// ObservableObject wrapper to properly manage optional FastingViewModel with @StateObject
class FastingViewModelWrapper: ObservableObject {
    @Published var viewModel: FastingViewModel? {
        didSet {
            // When viewModel changes, forward its objectWillChange to our objectWillChange
            setupForwarding()
        }
    }

    private var cancellable: AnyCancellable?

    init() {
        setupForwarding()
    }

    deinit {
        cancellable?.cancel()
        cancellable = nil
    }

    private func setupForwarding() {
        cancellable?.cancel()
        cancellable = viewModel?.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
}
