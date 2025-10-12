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
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.6, green: 0.3, blue: 0.8),
                                        Color(red: 0.4, green: 0.5, blue: 0.9)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

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
    @StateObject private var reactionManager = ReactionManager()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
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
                .padding(.horizontal, 16)

                // Pattern Analysis
                FoodPatternAnalysisCard()
                    .environmentObject(reactionManager)
                    .padding(.horizontal, 16)

                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
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
                    value: "\(reactionManager.identificationRate)%",
                    label: "ID Rate",
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
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
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
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct FoodReactionListCard: View {
    let title: String
    let reactions: [FoodReaction]

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
                VStack(spacing: 10) {
                    ForEach(reactions, id: \.id) { reaction in
                        FoodReactionRow(reaction: reaction)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }
}

struct FoodReactionRow: View {
    let reaction: FoodReaction
    
    var body: some View {
        HStack {
            Circle()
                .fill(severityColor(for: reaction.severity))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(reaction.foodName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(reaction.symptoms.joined(separator: ", "))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(formatDate(reaction.timestamp.dateValue()))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
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

    private var topTriggers: [(ingredient: String, count: Int, percentage: Int, trend: PatternRow.Trend)] {
        guard !reactionManager.reactions.isEmpty else { return [] }

        // Count ingredient frequencies
        var ingredientCounts: [String: Int] = [:]
        for reaction in reactionManager.reactions {
            for ingredient in reaction.suspectedIngredients {
                let normalized = ingredient.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                ingredientCounts[normalized, default: 0] += 1
            }
        }

        // Calculate percentages and get top 3
        let totalReactions = reactionManager.reactions.count
        let sorted = ingredientCounts.sorted { $0.value > $1.value }.prefix(3)

        return sorted.map { (ingredient, count) in
            let percentage = Int((Double(count) / Double(totalReactions)) * 100)
            let trend = calculateTrend(for: ingredient)
            return (ingredient.capitalized, count, percentage, trend)
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
            Text("Patterns")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            if topTriggers.isEmpty {
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
                VStack(spacing: 10) {
                    ForEach(topTriggers, id: \.ingredient) { trigger in
                        PatternRow(
                            trigger: trigger.ingredient,
                            frequency: "\(trigger.percentage)%",
                            trend: trigger.trend
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }
}

struct PatternRow: View {
    let trigger: String
    let frequency: String
    let trend: Trend
    
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
            Text(trigger)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
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
struct SpringyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: configuration.isPressed)
    }
}

// MARK: - Reaction Management
class ReactionManager: ObservableObject {
    @Published var reactions: [FoodReaction] = []
    @Published var isLoading = false
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

    init() {
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
        let standardized = standardizeIngredients(ingredients)
        suspectedIngredients = standardized
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
    @State private var showingLiveScanner = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search foods...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
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
                        showingLiveScanner = true
                    }) {
                        HStack {
                            Image(systemName: "camera.viewfinder")
                            Text("Scan Ingredients")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                    }

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
        .sheet(isPresented: $showingLiveScanner) {
            LiveIngredientScannerView { scannedText, _ in
                // Handle scanned ingredients
                handleScannedIngredients(scannedText)
            }
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

    private func handleScannedIngredients(_ scannedText: String) {
        // Create a custom food entry with scanned ingredients
        let foodName = searchText.isEmpty ? "Scanned Food" : searchText

        // Parse scanned text into ingredients
        let ingredients = parseIngredientsFromText(scannedText)

        let scannedFood = FoodSearchResult(
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
            servingDescription: "Scanned ingredients",
            ingredients: ingredients,
            confidence: 1.0,
            isVerified: false
        )

        selectedFood = scannedFood
        dismiss()
    }

    private func parseIngredientsFromText(_ text: String) -> [String] {
        // Basic ingredient parsing - split by common delimiters and clean up
        let separators = CharacterSet(charactersIn: ",;:")
        let ingredients = text.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { ingredient in
                // Remove common prefixes like "Ingredients:", "Contains:", etc.
                let cleaned = ingredient.replacingOccurrences(of: "^(Ingredients?|Contains?):?\\s*", with: "", options: .regularExpression)
                return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }

        return ingredients
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

                VStack(spacing: 4) {
                    Text("\(Int(food.calories))")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("kcal")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

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