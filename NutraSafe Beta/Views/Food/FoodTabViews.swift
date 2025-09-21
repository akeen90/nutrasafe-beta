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
        case pending = "Pending"
        case recipes = "Recipes"
        
        var icon: String {
            switch self {
            case .reactions: return "exclamationmark.triangle.fill"
            case .fasting: return "clock.fill"
            case .pending: return "hourglass.circle.fill"
            case .recipes: return "book.closed.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Text("Food Hub")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.primary)
                                .frame(width: 40, height: 40)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Sub-tab selector
                    FoodSubTabSelector(selectedTab: $selectedFoodSubTab)
                        .padding(.horizontal, 16)
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
                    case .pending:
                        PendingVerificationsView()
                    case .recipes:
                        RecipesView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Food Sub-Tab Selector
struct FoodSubTabSelector: View {
    @Binding var selectedTab: FoodTabView.FoodSubTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(FoodTabView.FoodSubTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? .white : .primary)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTab == tab ? Color.blue : Color.clear)
                    )
                }
                .buttonStyle(SpringyButtonStyle())
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Reaction Tracking")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(reactionManager.monthlyCount)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                    Text("This month")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 4) {
                    Text("\(reactionManager.weeklyCount)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                    Text("This week")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 4) {
                    Text("\(reactionManager.identificationRate)%")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.green)
                    Text("Identified")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Button(action: {
                showingLogReaction = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Log Reaction")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingLogReaction) {
            NavigationView {
                LogReactionView(reactionManager: reactionManager)
            }
        }
    }
}

struct FoodReactionListCard: View {
    let title: String
    let reactions: [FoodReaction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            if reactions.isEmpty {
                Text("No reactions logged")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(reactions, id: \.id) { reaction in
                        FoodReactionRow(reaction: reaction)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pattern Analysis")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                PatternRow(trigger: "Dairy Products", frequency: "67%", trend: .increasing)
                PatternRow(trigger: "Gluten", frequency: "34%", trend: .stable)
                PatternRow(trigger: "Nuts", frequency: "12%", trend: .decreasing)
            }
            
            Button("View Full Analysis") {
                print("View analysis tapped")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.blue)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
        guard !reactions.isEmpty else { return 85 }
        let identifiedCount = reactions.filter { !$0.suspectedIngredients.isEmpty }.count
        return Int((Double(identifiedCount) / Double(reactions.count)) * 100)
    }

    init() {
        loadReactions()
    }

    func addReaction(_ reaction: FoodReaction) {
        reactions.append(reaction)
        saveReactions()
    }

    private func loadReactions() {
        reactions = sampleReactions
    }

    private func saveReactions() {
        print("Saving \(reactions.count) reactions")
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

        reactionManager.addReaction(reaction)
        dismiss()
    }

    private func autoLoadIngredientsFromFood(_ ingredients: [String]) {
        // Automatically load ingredients when food is selected
        let newIngredients = ingredients.compactMap { ingredient in
            let cleaned = ingredient.trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned.isEmpty ? nil : cleaned
        }

        // Clear existing ingredients and load new ones
        suspectedIngredients.removeAll()
        suspectedIngredients.append(contentsOf: newIngredients)
    }

    private func loadIngredientsFromFood() {
        guard let food = selectedFood,
              let ingredients = food.ingredients else { return }

        // Parse and add ingredients from the food's ingredient list
        let newIngredients = ingredients.compactMap { ingredient in
            let cleaned = ingredient.trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned.isEmpty ? nil : cleaned
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