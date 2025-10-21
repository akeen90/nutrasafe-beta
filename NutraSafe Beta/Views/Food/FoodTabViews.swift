import SwiftUI
import Foundation
import FirebaseFirestore

// MARK: - Food Tab Navigation System
// Extracted from ContentView.swift (lines 4761-4936) + supporting components
// Complete food hub navigation with sub-tabs and comprehensive food tracking

struct FoodTabView: View {
    @Binding var showingSettings: Bool
    @State private var selectedFoodSubTab: FoodSubTab = .reactions
    
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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header - Simplified Clean Design
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        Text("Food")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .frame(height: 44, alignment: .center)
                            .foregroundColor(.black)

                        Spacer()

                        Button(action: { showingSettings = true }) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 44, height: 44)
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20, weight: .semibold))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Sub-tab selector - Native Segmented Control
                    SegmentedControlView(
                        tabs: FoodSubTab.allCases,
                        selectedTab: $selectedFoodSubTab
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                .background(Color(.systemBackground))
                
                // MARK: - Fasting Components have been extracted to Views/Fasting/FastingTimerView.swift
                // The following components were moved as part of Phase 13 ContentView.swift modularization effort:
                // - FastingTimerView: Main fasting timer interface
                // - FastingStageRow: Individual fasting stage display row
                // - FastingPresetButton: Quick-select fasting duration button
                
                // Content based on selected sub-tab
                Group {
                    switch selectedFoodSubTab {
                    case .reactions:
                        FoodReactionsView()
                    case .fasting:
                        FastingTimerView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
    }
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
                                    Color(red: 0.3, green: 0.5, blue: 1.0),
                                    Color(red: 0.5, green: 0.3, blue: 0.9)
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
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
                .fill(Color(.systemGray6))
        )
        .frame(height: 40)
    }
}

// MARK: - Food Sub Views
struct FoodReactionsView: View {
    @ObservedObject private var reactionManager = ReactionManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Reaction Summary
                FoodReactionSummaryCard()
                    .environmentObject(reactionManager)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // Recent Reactions
                FoodReactionListCard(
                    title: "Recent Reactions",
                    reactions: Array(reactionManager.reactions.prefix(10))
                )
                .environmentObject(reactionManager)
                .padding(.horizontal, 16)

                // Pattern Analysis
                FoodPatternAnalysisCard()
                    .environmentObject(reactionManager)
                    .padding(.horizontal, 16)

                // Info Notice for Patterns
                if reactionManager.reactions.count < 3 {
                    VStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)

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
                            .fill(Color.blue.opacity(0.1))
                    )
                    .padding(.horizontal, 16)
                }

                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
        .alert("Error", isPresented: $reactionManager.showingError) {
            Button("OK", role: .cancel) {
                reactionManager.errorMessage = nil
            }
        } message: {
            Text(reactionManager.errorMessage ?? "Unknown error occurred")
        }
    }
}

struct RecipesView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
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
    @State private var showingLogReaction = false
    @EnvironmentObject var reactionManager: ReactionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                StatMiniCard(
                    value: "\(reactionManager.monthlyCount)",
                    label: "Month",
                    color: .red
                )
                StatMiniCard(
                    value: "\(reactionManager.weeklyCount)",
                    label: "Week",
                    color: .orange
                )
                StatMiniCard(
                    value: "\(reactionManager.reactions.count)",
                    label: "Total",
                    color: .green
                )
            }

            Button(action: { showingLogReaction = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Log Reaction")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.3, green: 0.5, blue: 1.0),
                            Color(red: 0.5, green: 0.3, blue: 0.9)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .buttonStyle(SpringyButtonStyle())
        }
        .padding(AppSpacing.large)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(AppColors.cardBackgroundElevated)
        )
        .cardShadow()
        .sheet(isPresented: $showingLogReaction) {
            NavigationView {
                LogReactionView(reactionManager: reactionManager)
            }
        }
    }
}

struct StatMiniCard: View {
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
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.08))

                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.15), lineWidth: 1)
            }
        )
        .shadow(color: color.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct FoodReactionListCard: View {
    let title: String
    let reactions: [FoodReaction]
    @EnvironmentObject var reactionManager: ReactionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

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
                            .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
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
                .frame(height: CGFloat(reactions.count * 60))
            }
        }
        .padding(AppSpacing.large)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(AppColors.cardBackgroundElevated)
        )
        .cardShadow()
    }
}

struct FoodReactionRow: View {
    let reaction: FoodReaction
    @State private var showingDetail = false

    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack(spacing: 14) {
                // Premium severity indicator
                ZStack {
                    Circle()
                        .fill(severityColor(for: reaction.severity).opacity(0.15))
                        .frame(width: 10, height: 10)

                    Circle()
                        .fill(severityColor(for: reaction.severity))
                        .frame(width: 6, height: 6)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(reaction.foodName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(reaction.symptoms.joined(separator: ", "))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatDate(reaction.timestamp.dateValue()))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
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
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct FoodPatternAnalysisCard: View {
    @EnvironmentObject var reactionManager: ReactionManager
    @State private var showOtherIngredients = false

    // UK's 14 Major Allergens - Base Categories
    private func getBaseAllergen(for ingredient: String) -> String? {
        let lower = ingredient.lowercased()

        // Milk and dairy products
        if lower.contains("milk") || lower.contains("dairy") || lower.contains("lactose") ||
           lower.contains("cream") || lower.contains("butter") || lower.contains("cheese") ||
           lower.contains("yogurt") || lower.contains("yoghurt") || lower.contains("whey") ||
           lower.contains("casein") || lower.contains("ghee") {
            return "Milk"
        }

        // Eggs
        if lower.contains("egg") || lower.contains("albumin") || lower.contains("mayonnaise") {
            return "Eggs"
        }

        // Peanuts (separate from tree nuts)
        if lower.contains("peanut") || lower.contains("groundnut") {
            return "Peanuts"
        }

        // Tree nuts
        if lower.contains("almond") || lower.contains("hazelnut") || lower.contains("walnut") ||
           lower.contains("cashew") || lower.contains("pistachio") || lower.contains("pecan") ||
           lower.contains("brazil nut") || lower.contains("macadamia") || lower.contains("nut") {
            return "Tree Nuts"
        }

        // Cereals containing gluten
        if lower.contains("wheat") || lower.contains("gluten") || lower.contains("barley") ||
           lower.contains("rye") || lower.contains("oats") || lower.contains("spelt") ||
           lower.contains("kamut") {
            return "Gluten"
        }

        // Soya
        if lower.contains("soy") || lower.contains("soya") || lower.contains("soybean") ||
           lower.contains("tofu") || lower.contains("edamame") {
            return "Soya"
        }

        // Fish
        if lower.contains("fish") || lower.contains("salmon") || lower.contains("tuna") ||
           lower.contains("cod") || lower.contains("haddock") || lower.contains("trout") ||
           lower.contains("mackerel") {
            return "Fish"
        }

        // Crustaceans
        if lower.contains("shellfish") || lower.contains("shrimp") || lower.contains("crab") ||
           lower.contains("lobster") || lower.contains("prawn") || lower.contains("crayfish") ||
           lower.contains("langoustine") {
            return "Crustaceans"
        }

        // Molluscs
        if lower.contains("mollusc") || lower.contains("oyster") || lower.contains("clam") ||
           lower.contains("mussel") || lower.contains("squid") || lower.contains("octopus") ||
           lower.contains("snail") || lower.contains("whelk") {
            return "Molluscs"
        }

        // Sesame
        if lower.contains("sesame") || lower.contains("tahini") {
            return "Sesame"
        }

        // Mustard
        if lower.contains("mustard") {
            return "Mustard"
        }

        // Celery
        if lower.contains("celery") || lower.contains("celeriac") {
            return "Celery"
        }

        // Lupin
        if lower.contains("lupin") || lower.contains("lupine") {
            return "Lupin"
        }

        // Sulphites
        if lower.contains("sulphite") || lower.contains("sulfite") || lower.contains("sulphur dioxide") ||
           lower.contains("sulfur dioxide") || lower.contains("e220") || lower.contains("e221") ||
           lower.contains("e222") || lower.contains("e223") || lower.contains("e224") {
            return "Sulphites"
        }

        return nil
    }

    private var allTriggers: [(ingredient: String, count: Int, percentage: Int, trend: PatternRow.Trend, isAllergen: Bool, baseAllergen: String?)] {
        // Require at least 3 reactions before showing patterns
        guard reactionManager.reactions.count >= 3 else { return [] }

        // Count ingredient frequencies
        var ingredientCounts: [String: Int] = [:]
        for reaction in reactionManager.reactions {
            for ingredient in reaction.suspectedIngredients {
                let normalized = ingredient.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                ingredientCounts[normalized, default: 0] += 1
            }
        }

        // Calculate percentages and determine if allergen
        let totalReactions = reactionManager.reactions.count
        let mapped = ingredientCounts.map { (ingredient, count) -> (ingredient: String, count: Int, percentage: Int, trend: PatternRow.Trend, isAllergen: Bool, baseAllergen: String?) in
            let percentage = Int((Double(count) / Double(totalReactions)) * 100)
            let trend = calculateTrend(for: ingredient)
            let baseAllergen = getBaseAllergen(for: ingredient)
            let isAllergen = baseAllergen != nil
            return (ingredient.capitalized, count, percentage, trend, isAllergen, baseAllergen)
        }

        // Sort by frequency (descending), then alphabetically for stable ordering
        return mapped.sorted {
            if $0.count != $1.count {
                return $0.count > $1.count
            }
            return $0.ingredient < $1.ingredient
        }
    }

    private var allergenTriggers: [(ingredient: String, count: Int, percentage: Int, trend: PatternRow.Trend, isAllergen: Bool, baseAllergen: String?)] {
        allTriggers.filter { $0.isAllergen }
    }

    private var otherTriggers: [(ingredient: String, count: Int, percentage: Int, trend: PatternRow.Trend, isAllergen: Bool, baseAllergen: String?)] {
        allTriggers.filter { !$0.isAllergen }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Patterns")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)

                Text("Common Ingredients from Your Reactions")
                    .font(.system(size: 13))
                    .italic()
                    .foregroundColor(.secondary)
            }

            if allTriggers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("Not enough data")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("Log more reactions to see patterns")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    // Recognised Allergens Section (Simplified)
                    if !allergenTriggers.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Recognised Allergens")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(.bottom, 20)

                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(groupedAllergenTriggers, id: \.category) { group in
                                    SimplifiedAllergenGroup(
                                        allergenCategory: group.category,
                                        categoryPercentage: group.percentage,
                                        ingredients: group.ingredients
                                    )
                                    .id(group.category)  // Stable identity to prevent re-rendering
                                }
                            }
                        }
                        .id("recognised-allergens-section")  // Stable identity for entire section
                        .padding(.bottom, 28)
                    }

                    // Other Ingredients Section (Expandable)
                    if !otherTriggers.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            VStack(alignment: .leading, spacing: 4) {
                                Button(action: {
                                    showOtherIngredients.toggle()
                                }) {
                                    HStack(alignment: .center, spacing: 12) {
                                        Text("Other Ingredients")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.primary)

                                        Spacer()

                                        Image(systemName: showOtherIngredients ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.secondary.opacity(0.5))
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())

                                Text("Ingredients not identified as common allergens")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }

                            if showOtherIngredients {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(otherTriggers, id: \.ingredient) { trigger in
                                        HStack(spacing: 10) {
                                            Text("—")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.secondary)

                                            Text(trigger.ingredient)
                                                .font(.system(size: 15))
                                                .foregroundColor(.primary)

                                            Spacer()

                                            // Subtle percentage indicator
                                            Text("\(trigger.percentage)%")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.secondary.opacity(0.6))
                                        }
                                        .padding(.leading, 4)
                                    }
                                }
                                .padding(.top, 16)
                            }
                        }
                    }
                }
                .animation(nil, value: showOtherIngredients)  // Disable all animations when expanding/collapsing
            }
        }
        .animation(nil, value: showOtherIngredients)  // Prevent all implicit animations on entire card
        .transaction { transaction in
            transaction.animation = nil  // Force disable all animations
        }
        .padding(AppSpacing.large)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(AppColors.cardBackgroundElevated)
        )
        .cardShadow()
    }
}

// MARK: - Simplified Allergen Group
struct SimplifiedAllergenGroup: View {
    let allergenCategory: String
    let categoryPercentage: Int
    let ingredients: [(ingredient: String, count: Int, percentage: Int, trend: PatternRow.Trend)]

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

    var body: some View {
        NavigationView {
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
                            .fill(AppColors.cardBackgroundElevated)
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
                                    .foregroundColor(.blue.opacity(0.7))
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
                                .fill(Color.blue.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.1), lineWidth: 1)
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
                                .fill(severityColor(for: reaction.severity).opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(severityColor(for: reaction.severity).opacity(0.1), lineWidth: 1)
                        )
                    }

                    // Symptoms Card
                    VStack(alignment: .leading, spacing: 14) {
                        Label("SYMPTOMS", systemImage: "heart.text.square.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        // Simple wrapping layout for symptoms
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(reaction.symptoms, id: \.self) { symptom in
                                Text(symptom)
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color.blue.opacity(0.1))
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                    )
                                    .foregroundColor(.blue)
                                    .fixedSize()
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

                    // Suspected Ingredients Card
                    if !reaction.suspectedIngredients.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("SUSPECTED INGREDIENTS", systemImage: "allergens")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            // Simple wrapping layout for ingredients
                            VStack(alignment: .leading, spacing: 8) {
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
                                        .fixedSize()
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
                                .fill(Color(.systemGray6).opacity(0.5))
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
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Reaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
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
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
                RecipeCollectionItem(name: "Quick & Easy", count: 24, color: .blue)
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
        .background(Color(.systemBackground))
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
                .foregroundColor(.blue)
            
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
class ReactionManager: ObservableObject {
    static let shared = ReactionManager()

    @Published var reactions: [FoodReaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    private let firebaseManager = FirebaseManager.shared

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
        // Don't load reactions immediately on init - wait for auth to be ready
        // Reactions will be loaded when user is authenticated via reloadIfAuthenticated()
    }

    // Public method to reload reactions - should be called after successful authentication
    func reloadIfAuthenticated() {
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
            print("Failed to save reaction: \(error)")
            await MainActor.run {
                errorMessage = "Failed to save reaction: \(error.localizedDescription)"
                showingError = true
                // Remove from local array since save failed
                reactions.removeAll { $0.id == reaction.id }
            }
        }
    }

    private func loadReactions() {
        isLoading = true
        Task {
            do {
                let fetchedReactions = try await firebaseManager.getReactions()
                await MainActor.run {
                    self.reactions = fetchedReactions.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                    self.isLoading = false
                }
            } catch {
                print("Failed to load reactions: \(error)")
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
            print("Failed to refresh reactions: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    func deleteReaction(_ reaction: FoodReaction) async {
        // Remove from local array first for immediate UI update
        await MainActor.run {
            reactions.removeAll { $0.id == reaction.id }
        }

        // Delete from Firebase
        do {
            try await firebaseManager.deleteReaction(reactionId: reaction.id)
        } catch {
            print("Failed to delete reaction: \(error)")
            // Re-add if deletion failed
            await MainActor.run {
                reactions.insert(reaction, at: 0)
                reactions.sort { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
            }
        }
    }

    func clearData() {
        // Clear all reactions from memory when user logs out
        reactions.removeAll()
        isLoading = false
        errorMessage = nil
        showingError = false
        print("🧹 Cleared ReactionManager data")
    }
}

// MARK: - Log Reaction View
struct LogReactionView: View {
    @ObservedObject var reactionManager: ReactionManager
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

    let availableSymptoms = [
        "Bloating", "Nausea", "Stomach pain", "Diarrhea", "Constipation",
        "Hives", "Itching", "Swelling", "Rash", "Headache", "Fatigue",
        "Breathing difficulty", "Runny nose", "Sneezing"
    ]

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
                                .foregroundColor(.blue)
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
                    .onChange(of: selectedFood) { newFood in
                        if let food = newFood, let ingredients = food.ingredients {
                            autoLoadIngredientsFromFood(ingredients)
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
                                    .background(symptoms.contains(symptom) ? Color.blue : Color(.systemGray6))
                                    .foregroundColor(symptoms.contains(symptom) ? .white : .primary)
                                    .cornerRadius(20)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    HStack {
                        TextField("Add custom symptom", text: $symptomInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Add") {
                            if !symptomInput.isEmpty && !symptoms.contains(symptomInput) {
                                symptoms.append(symptomInput)
                                symptomInput = ""
                            }
                        }
                        .disabled(symptomInput.isEmpty)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Suspected Ingredients")
                            .font(.headline)

                        Spacer()

                        if let food = selectedFood,
                           let ingredients = food.ingredients,
                           !ingredients.isEmpty,
                           !hasLoadedFoodIngredients(ingredients) {
                            Button("Load from Food") {
                                loadIngredientsFromFood()
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        }
                    }

                    if !suspectedIngredients.isEmpty {
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

                    HStack {
                        TextField("Add suspected ingredient", text: $ingredientInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Add") {
                            if !ingredientInput.isEmpty && !suspectedIngredients.contains(ingredientInput) {
                                suspectedIngredients.append(ingredientInput)
                                ingredientInput = ""
                            }
                        }
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
        .sheet(isPresented: $showingFoodSearch) {
            NavigationView {
                FoodReactionSearchView(selectedFood: $selectedFood)
            }
        }
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
            dismiss()
        }
    }

    private func autoLoadIngredientsFromFood(_ ingredients: [String]) {
        // Apply instant client-side standardization
        let standardized = standardizeIngredients(ingredients)
        suspectedIngredients = standardized

        // Then try AI refinement in background
        Task {
            do {
                let aiRefined = try await standardizeIngredientsWithAI(standardized)
                await MainActor.run {
                    suspectedIngredients = aiRefined
                    print("✨ AI refined to: \(aiRefined.joined(separator: ", "))")
                }
            } catch {
                print("ℹ️ AI refinement unavailable, using client-side filter: \(error.localizedDescription)")
                // Keep the client-side results, which are already pretty good
            }
        }
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
    @StateObject private var fatSecretService = FatSecretService.shared
    @State private var searchText = ""
    @State private var searchResults: [FoodSearchResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search foods...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isSearchFieldFocused)
                        .onChange(of: searchText, perform: { newValue in
                            performLiveSearch(query: newValue)
                        })
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
                .padding(.top, 16)

                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        addManualFood()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Manually")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(20)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
            }

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

                        Text("Try different keywords or add manually")
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
                                    dismiss()
                                }
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle("Select Food")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button("Cancel") {
                dismiss()
            }
        )
        // Live scanner removed - feature deprecated
        .onAppear {
            // Automatically focus the search field when the view appears
            isSearchFieldFocused = true
        }
        .onDisappear {
            searchTask?.cancel()
        }
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
                let results = try await fatSecretService.searchFoods(query: query)

                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.searchResults = []
                    self.isSearching = false
                }
                print("Search error: \(error)")
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

                    if let brand = food.brand {
                        Text(brand)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    if let ingredients = food.ingredients, !ingredients.isEmpty {
                        Text("\(ingredients.count) ingredients")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
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