//
//  ReactionLogView.swift
//  NutraSafe Beta
//
//  Reaction Log Mode - Track reactions and analyze possible food triggers
//

import SwiftUI

struct ReactionLogView: View {
    @StateObject private var manager = ReactionLogManager.shared
    @State private var showingLogSheet = false
    @State private var selectedEntry: ReactionLogEntry?
    @State private var selectedDayRange: DayRange = .threeDays

    enum DayRange: Int, CaseIterable {
        case threeDays = 3
        case fiveDays = 5
        case sevenDays = 7

        var displayText: String {
            "\(rawValue) days"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overview Section
                overviewSection

                // Log Reaction Button
                logReactionButton

                // Recent Reactions Section
                recentReactionsSection

                // Patterns Section
                patternsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color.adaptiveBackground)
        .sheet(isPresented: $showingLogSheet) {
            LogReactionSheet(selectedDayRange: selectedDayRange)
        }
        .sheet(item: $selectedEntry) { entry in
            ReactionLogDetailView(entry: entry, selectedDayRange: selectedDayRange)
        }
        .task {
            await manager.loadReactionLogs()
        }
    }

    // MARK: - Overview Section
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                StatCard(
                    count: reactionsThisMonth,
                    label: "MONTH",
                    color: .red
                )
                StatCard(
                    count: reactionsThisWeek,
                    label: "WEEK",
                    color: .orange
                )
                StatCard(
                    count: manager.reactionLogs.count,
                    label: "TOTAL",
                    color: .green
                )
            }
        }
    }

    // MARK: - Log Reaction Button
    private var logReactionButton: some View {
        Button(action: { showingLogSheet = true }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)

                Text("Log Reaction")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
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
            .cornerRadius(14)
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Recent Reactions Section
    private var recentReactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Meals")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            if manager.reactionLogs.isEmpty {
                emptyReactionsView
            } else {
                VStack(spacing: 12) {
                    ForEach(manager.reactionLogs.prefix(5)) { entry in
                        ReactionLogCard(entry: entry)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedEntry = entry
                            }
                    }
                }
            }
        }
    }

    // MARK: - Patterns Section
    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Patterns")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            if manager.reactionLogs.count < 2 {
                Text("Log at least 2 reactions to see patterns")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                commonIngredientsView
            }
        }
    }

    // MARK: - Empty State
    private var emptyReactionsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("No reactions logged")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Common Ingredients View
    private var commonIngredientsView: some View {
        let commonIngredients = calculateCommonIngredients()

        return VStack(spacing: 12) {
            if commonIngredients.isEmpty {
                Text("Not enough data to identify patterns")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                ForEach(commonIngredients.prefix(10), id: \.name) { ingredient in
                    CommonIngredientRow(
                        name: ingredient.name,
                        frequency: ingredient.frequency,
                        percentage: ingredient.percentage
                    )
                }
            }
        }
    }

    // MARK: - Computed Properties
    private var reactionsThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        return manager.reactionLogs.filter { $0.reactionDate >= startOfMonth }.count
    }

    private var reactionsThisWeek: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!

        return manager.reactionLogs.filter { $0.reactionDate >= startOfWeek }.count
    }

    // MARK: - Calculate Common Ingredients
    private func calculateCommonIngredients() -> [(name: String, frequency: Int, percentage: Double)] {
        var ingredientCounts: [String: (count: Int, displayName: String)] = [:]

        // Count ingredients across all reactions (case-insensitive)
        for entry in manager.reactionLogs {
            guard let analysis = entry.triggerAnalysis else { continue }

            for ingredient in analysis.topIngredients {
                let normalizedName = ingredient.ingredientName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

                if ingredientCounts[normalizedName] == nil {
                    ingredientCounts[normalizedName] = (count: 1, displayName: ingredient.ingredientName)
                } else {
                    ingredientCounts[normalizedName]?.count += 1
                }
            }
        }

        // Filter to ingredients appearing in 2+ reactions and calculate percentages
        let totalReactions = manager.reactionLogs.count
        return ingredientCounts
            .filter { $0.value.count >= 2 }
            .map { (name: $0.value.displayName, frequency: $0.value.count, percentage: (Double($0.value.count) / Double(totalReactions)) * 100.0) }
            .sorted { $0.frequency > $1.frequency }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Text("\(count)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Common Ingredient Row
struct CommonIngredientRow: View {
    let name: String
    let frequency: Int
    let percentage: Double

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(frequencyColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                Text("Appears in \(frequency) reaction\(frequency == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(percentage))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(frequencyColor)

                Text("frequency")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }

    private var frequencyColor: Color {
        if percentage >= 80 {
            return .red
        } else if percentage >= 50 {
            return .orange
        } else {
            return .yellow
        }
    }
}

// MARK: - Reaction Log Card

struct ReactionLogCard: View {
    let entry: ReactionLogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Reaction type icon
                Image(systemName: reactionIcon)
                    .font(.title3)
                    .foregroundColor(.orange)
                    .frame(width: 32, height: 32)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.reactionType)
                        .font(.headline)

                    Text(entry.reactionDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    +
                    Text(" at ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    +
                    Text(entry.reactionDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            if let notes = entry.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            if let analysis = entry.triggerAnalysis {
                HStack(spacing: 16) {
                    Label("\(analysis.mealCount) meals", systemImage: "fork.knife")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label("\(analysis.topFoods.count) triggers", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }

    private var reactionIcon: String {
        if let type = ReactionType(rawValue: entry.reactionType) {
            return type.icon
        }
        return "exclamationmark.circle"
    }
}

// MARK: - Log Reaction Sheet

struct LogReactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = ReactionLogManager.shared

    let selectedDayRange: ReactionLogView.DayRange

    @State private var selectedType: ReactionType = .headache
    @State private var customType: String = ""
    @State private var reactionDate: Date = Date()
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var dayRange: ReactionLogView.DayRange

    init(selectedDayRange: ReactionLogView.DayRange) {
        self.selectedDayRange = selectedDayRange
        self._dayRange = State(initialValue: selectedDayRange)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reaction Details")) {
                    // Reaction type picker
                    Picker("Reaction Type", selection: $selectedType) {
                        ForEach(ReactionType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }

                    if selectedType == .custom {
                        TextField("Describe reaction", text: $customType)
                    }

                    DatePicker("Date & Time", selection: $reactionDate, displayedComponents: [.date, .hourAndMinute])
                }

                Section(header: Text("Analysis Window")) {
                    Picker("Look back", selection: $dayRange) {
                        ForEach(ReactionLogView.DayRange.allCases, id: \.self) { range in
                            Text(range.displayText).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("The system will analyze your food diary from the last \(dayRange.rawValue) days before this reaction.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Notes (Optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Log Reaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveReaction()
                        }
                    }
                    .disabled(isSaving || !isValid)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)

                            Text("Analyzing food triggers...")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 20)
                    }
                }
            }
        }
    }

    private var isValid: Bool {
        if selectedType == .custom {
            return !customType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    private func saveReaction() async {
        isSaving = true
        defer { isSaving = false }

        do {
            let reactionType = selectedType == .custom ? customType : selectedType.rawValue
            let notesText = notes.trimmingCharacters(in: .whitespacesAndNewlines)

            _ = try await manager.saveReactionLog(
                reactionType: reactionType,
                reactionDate: reactionDate,
                notes: notesText.isEmpty ? nil : notesText,
                dayRange: dayRange.rawValue
            )

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Reaction Detail View

struct ReactionLogDetailView: View {
    let entry: ReactionLogEntry
    let selectedDayRange: ReactionLogView.DayRange

    @Environment(\.dismiss) private var dismiss
    @State private var showingExportSheet = false
    @State private var showOtherIngredients = false
    @State private var selectedFood: WeightedFoodScore?
    @State private var selectedIngredient: WeightedIngredientScore?
    @State private var selectedAllergenCategory: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    reactionHeader

                    if let analysis = entry.triggerAnalysis {
                        // Analysis Summary
                        analysisOverview(analysis: analysis)

                        // Top Trigger Foods
                        if !analysis.topFoods.isEmpty {
                            topFoodsSection(foods: analysis.topFoods)
                        }

                        // Top Trigger Ingredients
                        if !analysis.topIngredients.isEmpty {
                            topIngredientsSection(ingredients: analysis.topIngredients)
                        }
                    } else {
                        Text("No analysis available")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Reaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingExportSheet = true }) {
                        Label("Export PDF", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                PDFExportSheet(entry: entry)
            }
            .sheet(item: $selectedFood) { food in
                FoodHistoryDetailView(food: food, reactionDate: entry.reactionDate)
            }
            .sheet(item: $selectedIngredient) { ingredient in
                IngredientHistoryDetailView(ingredient: ingredient, reactionDate: entry.reactionDate)
            }
            .sheet(item: $selectedAllergenCategory) { category in
                AllergenCategoryDetailView(category: category, entry: entry)
            }
        }
    }

    private var reactionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: reactionIcon)
                    .font(.title)
                    .foregroundColor(.orange)

                Text(entry.reactionType)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            HStack(spacing: 16) {
                Label(entry.reactionDate.formatted(date: .long, time: .omitted), systemImage: "calendar")
                Label(entry.reactionDate.formatted(date: .omitted, time: .shortened), systemImage: "clock")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            if let notes = entry.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func analysisOverview(analysis: TriggerAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis Summary")
                .font(.headline)

            HStack(spacing: 20) {
                StatBox(value: "\(analysis.mealCount)", label: "Meals Analyzed", icon: "fork.knife")
                StatBox(value: "\(analysis.totalFoodsAnalyzed)", label: "Foods Reviewed", icon: "list.bullet")
            }

            Text("\(analysis.dayRange)-Day Window")
                .font(.caption)
                .foregroundColor(.secondary)
            +
            Text(" • ")
                .font(.caption)
                .foregroundColor(.secondary)
            +
            Text("\(analysis.timeRangeStart.formatted(date: .abbreviated, time: .shortened)) to \(analysis.timeRangeEnd.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private func topFoodsSection(foods: [WeightedFoodScore]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Possible Trigger Foods")
                .font(.headline)

            ForEach(foods.prefix(10)) { food in
                Button(action: {
                    selectedFood = food
                }) {
                    FoodScoreRow(score: food)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private func topIngredientsSection(ingredients: [WeightedIngredientScore]) -> some View {
        let ingredientData = categorizeIngredients(ingredients)

        return VStack(alignment: .leading, spacing: 20) {
            // Recognised Allergens Section
            if !ingredientData.allergenGroups.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Recognised Allergens")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.bottom, 20)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(ingredientData.allergenGroups, id: \.category) { group in
                            ReactionAllergenGroup(
                                allergenCategory: group.category,
                                categoryScore: group.maxScore,
                                ingredients: group.ingredients,
                                onIngredientTap: { ingredient in
                                    selectedIngredient = ingredient
                                },
                                onCategoryTap: {
                                    selectedAllergenCategory = group.category
                                }
                            )
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
            }

            // Other Ingredients Section (Expandable)
            if !ingredientData.otherIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showOtherIngredients.toggle()
                        }
                    }) {
                        HStack(alignment: .center, spacing: 12) {
                            Text("Other Ingredients")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: showOtherIngredients ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 20)
                    }
                    .buttonStyle(.plain)

                    if showOtherIngredients {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(ingredientData.otherIngredients) { ingredient in
                                Button(action: {
                                    selectedIngredient = ingredient
                                }) {
                                    IngredientScoreRow(score: ingredient)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
            }
        }
    }

    private func categorizeIngredients(_ ingredients: [WeightedIngredientScore]) -> (allergenGroups: [(category: String, maxScore: Int, ingredients: [WeightedIngredientScore])], otherIngredients: [WeightedIngredientScore]) {
        var allergenDict: [String: [WeightedIngredientScore]] = [:]
        var otherIngredients: [WeightedIngredientScore] = []

        for ingredient in ingredients.prefix(10) {
            if let allergenCategory = getBaseAllergen(for: ingredient.ingredientName) {
                allergenDict[allergenCategory, default: []].append(ingredient)
            } else {
                otherIngredients.append(ingredient)
            }
        }

        let allergenGroups = allergenDict.map { (category, ingredients) -> (category: String, maxScore: Int, ingredients: [WeightedIngredientScore]) in
            // Use maximum cross-reaction frequency for the category
            let maxScore = ingredients.map { Int($0.crossReactionFrequency) }.max() ?? 0
            return (category, maxScore, ingredients.sorted { $0.crossReactionFrequency > $1.crossReactionFrequency })
        }.sorted { $0.maxScore > $1.maxScore }

        return (allergenGroups, otherIngredients.sorted { $0.totalScore > $1.totalScore })
    }

    private func getBaseAllergen(for ingredient: String) -> String? {
        let lower = ingredient.lowercased()

        // Milk and dairy
        if lower.contains("milk") || lower.contains("dairy") || lower.contains("cream") ||
           lower.contains("cheese") || lower.contains("butter") || lower.contains("yogurt") ||
           lower.contains("whey") || lower.contains("casein") || lower.contains("lactose") {
            return "Milk"
        }

        // Eggs
        if lower.contains("egg") || lower.contains("albumin") || lower.contains("mayonnaise") {
            return "Eggs"
        }

        // Peanuts
        if lower.contains("peanut") || lower.contains("groundnut") {
            return "Peanuts"
        }

        // Tree nuts
        if lower.contains("almond") || lower.contains("hazelnut") || lower.contains("walnut") ||
           lower.contains("cashew") || lower.contains("pistachio") || lower.contains("pecan") ||
           lower.contains("brazil nut") || lower.contains("macadamia") || lower.contains("nut") {
            return "Tree Nuts"
        }

        // Gluten
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
           lower.contains("cod") || lower.contains("haddock") || lower.contains("trout") {
            return "Fish"
        }

        // Shellfish
        if lower.contains("shellfish") || lower.contains("shrimp") || lower.contains("prawn") ||
           lower.contains("crab") || lower.contains("lobster") || lower.contains("mussel") ||
           lower.contains("oyster") || lower.contains("clam") {
            return "Shellfish"
        }

        // Sesame
        if lower.contains("sesame") || lower.contains("tahini") {
            return "Sesame"
        }

        // Celery
        if lower.contains("celery") || lower.contains("celeriac") {
            return "Celery"
        }

        // Mustard
        if lower.contains("mustard") {
            return "Mustard"
        }

        // Sulphites
        if lower.contains("sulphite") || lower.contains("sulfite") {
            return "Sulphites"
        }

        return nil
    }

    private var reactionIcon: String {
        if let type = ReactionType(rawValue: entry.reactionType) {
            return type.icon
        }
        return "exclamationmark.circle"
    }
}

// MARK: - Helper Views

struct StatBox: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct FoodScoreRow: View {
    let score: WeightedFoodScore

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Frequency indicator (only show if we have cross-reaction data)
            if score.crossReactionFrequency > 0 {
                Circle()
                    .fill(frequencyColor)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(score.foodName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Label("\(score.occurrences)×", systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if score.occurrencesWithin24h > 0 {
                        Text("\(score.occurrencesWithin24h)× <24h")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Text("Last seen \(Int(score.lastSeenHoursBeforeReaction))h before reaction")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Only show cross-reaction percentage if there are 2+ reactions (crossReactionFrequency > 0)
            if score.crossReactionFrequency > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(score.crossReactionFrequency))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(frequencyColor)
                    Text("of reactions")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var frequencyColor: Color {
        let percentage = Int(score.crossReactionFrequency)
        if percentage >= 80 {
            return .red
        } else if percentage >= 40 {
            return .orange
        } else {
            return .yellow
        }
    }
}

struct IngredientScoreRow: View {
    let score: WeightedIngredientScore

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Frequency indicator (only show if we have cross-reaction data)
            if score.crossReactionFrequency > 0 {
                Circle()
                    .fill(frequencyColor)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(score.ingredientName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Label("\(score.occurrences)×", systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if score.symptomAssociationScore > 0 {
                        Label("Pattern detected", systemImage: "waveform.path.ecg")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Text("Found in: \(score.contributingFoodNames.prefix(3).joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Only show cross-reaction percentage if there are 2+ reactions (crossReactionFrequency > 0)
            if score.crossReactionFrequency > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(score.crossReactionFrequency))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(frequencyColor)
                    Text("of reactions")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var frequencyColor: Color {
        let percentage = Int(score.crossReactionFrequency)
        if percentage >= 80 {
            return .red
        } else if percentage >= 40 {
            return .orange
        } else {
            return .yellow
        }
    }
}

// MARK: - Reaction Allergen Group Component

struct ReactionAllergenGroup: View {
    let allergenCategory: String
    let categoryScore: Int
    let ingredients: [WeightedIngredientScore]
    let onIngredientTap: (WeightedIngredientScore) -> Void
    let onCategoryTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Category header with score badge - clickable
            Button(action: {
                onCategoryTap()
            }) {
                HStack(alignment: .center, spacing: 12) {
                    Text(allergenCategory)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    // Frequency badge (only show if there's cross-reaction data)
                    if categoryScore > 0 {
                        VStack(spacing: 2) {
                            Text("\(categoryScore)%")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.red, Color.red.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            Text("of reactions")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.red.opacity(0.7))
                        }
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
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, 14)

            // Ingredient list
            VStack(alignment: .leading, spacing: 10) {
                ForEach(ingredients) { ingredient in
                    Button(action: {
                        onIngredientTap(ingredient)
                    }) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 4, height: 4)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(ingredient.ingredientName)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)

                                HStack(spacing: 12) {
                                    Label("\(ingredient.occurrences)×", systemImage: "repeat")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    if ingredient.symptomAssociationScore > 0 {
                                        Label("Pattern detected", systemImage: "waveform.path.ecg")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }

                                Text("Found in: \(ingredient.contributingFoodNames.prefix(3).joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text("\(Int(ingredient.totalScore))")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(scoreColor(for: ingredient.totalScore))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.bottom, 28)
    }

    private func scoreColor(for score: Double) -> Color {
        if score >= 100 {
            return .red
        } else if score >= 50 {
            return .orange
        } else {
            return .yellow
        }
    }
}

// MARK: - PDF Export Sheet

struct PDFExportSheet: View {
    let entry: ReactionLogEntry
    @Environment(\.dismiss) private var dismiss
    @State private var isGenerating = false
    @State private var pdfURL: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if isGenerating {
                    ProgressView("Generating PDF...")
                        .font(.headline)
                        .padding()
                } else if let error = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)

                        Text("Export Failed")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Try Again") {
                            errorMessage = nil
                            generatePDF()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Close") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                } else if pdfURL != nil {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("PDF Ready")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Your reaction analysis report has been generated successfully.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: {
                            showShareSheet = true
                        }) {
                            Label("Share Report", systemImage: "square.and.arrow.up")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()

                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Export Reaction Report")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Generate a detailed PDF report of this reaction analysis to share with your healthcare provider or nutritionist.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Reaction details and timeline", systemImage: "info.circle")
                            Label("Trigger analysis results", systemImage: "chart.bar")
                            Label("Top foods and ingredients", systemImage: "list.bullet")
                            Label("Professional formatting", systemImage: "doc.richtext")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        Button(action: {
                            generatePDF()
                        }) {
                            Label("Generate PDF", systemImage: "doc.badge.plus")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()

                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showShareSheet) {
                if let url = pdfURL {
                    ShareSheet(items: [url])
                }
            }
        }
        .onDisappear {
            // Clean up temporary file when sheet is dismissed
            if let url = pdfURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    private func generatePDF() {
        isGenerating = true
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async {
            if let url = ReactionPDFExporter.exportReactionReport(entry: entry) {
                DispatchQueue.main.async {
                    self.pdfURL = url
                    self.isGenerating = false
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to generate PDF. Please try again."
                    self.isGenerating = false
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - History Detail Views (Placeholders)

struct FoodHistoryDetailView: View {
    let food: WeightedFoodScore
    let reactionDate: Date
    @Environment(\.dismiss) private var dismiss
    @State private var foodEntry: FoodEntry?
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(food.foodName)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 16) {
                            Label("\(food.occurrences)× consumed", systemImage: "repeat")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Label("Last: \(Int(food.lastSeenHoursBeforeReaction))h before", systemImage: "clock")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        // Cross-reaction frequency
                        if food.crossReactionFrequency > 0 {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(frequencyColor)
                                    .frame(width: 10, height: 10)

                                Text("Appears in \(Int(food.crossReactionFrequency))% of reactions")
                                    .font(.caption)
                                    .foregroundColor(frequencyColor)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Ingredients Section
                    if isLoading {
                        ProgressView("Loading ingredients...")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else if let ingredients = foodEntry?.ingredients, !ingredients.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Ingredients")
                                .font(.headline)

                            ingredientsBreakdownView(ingredients: ingredients)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 3)
                    } else {
                        Text("No ingredient information available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    }

                    // Time Window Breakdown
                    timeWindowBreakdown
                }
                .padding()
            }
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadFoodEntry()
            }
        }
    }

    private var frequencyColor: Color {
        let percentage = Int(food.crossReactionFrequency)
        if percentage >= 80 {
            return .red
        } else if percentage >= 40 {
            return .orange
        } else {
            return .yellow
        }
    }

    private var timeWindowBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Window Breakdown")
                .font(.headline)

            VStack(spacing: 8) {
                TimeWindowRow(label: "Within 24 hours", count: food.occurrencesWithin24h, color: .red)
                TimeWindowRow(label: "24-48 hours before", count: food.occurrencesBetween24_48h, color: .orange)
                TimeWindowRow(label: "48-72 hours before", count: food.occurrencesBetween48_72h, color: .yellow)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3)
    }

    private func ingredientsBreakdownView(ingredients: [String]) -> some View {
        let categorized = categorizeIngredients(ingredients)

        return VStack(alignment: .leading, spacing: 20) {
            // Recognised Allergens
            if !categorized.allergenGroups.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recognised Allergens")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)

                    ForEach(categorized.allergenGroups, id: \.category) { group in
                        AllergenCategoryCard(category: group.category, ingredients: group.ingredients)
                    }
                }
            }

            // Other Ingredients
            if !categorized.otherIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Other Ingredients")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    ForEach(categorized.otherIngredients, id: \.self) { ingredient in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 4, height: 4)

                            Text(ingredient)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
    }

    private func categorizeIngredients(_ ingredients: [String]) -> (allergenGroups: [(category: String, ingredients: [String])], otherIngredients: [String]) {
        var allergenDict: [String: [String]] = [:]
        var otherIngredients: [String] = []

        for ingredient in ingredients {
            if let allergenCategory = getBaseAllergen(for: ingredient) {
                allergenDict[allergenCategory, default: []].append(ingredient)
            } else {
                otherIngredients.append(ingredient)
            }
        }

        let allergenGroups = allergenDict.map { (category: $0.key, ingredients: $0.value) }
            .sorted { $0.category < $1.category }

        return (allergenGroups, otherIngredients)
    }

    private func getBaseAllergen(for ingredient: String) -> String? {
        let lower = ingredient.lowercased()

        if lower.contains("milk") || lower.contains("dairy") || lower.contains("cream") ||
           lower.contains("cheese") || lower.contains("butter") || lower.contains("yogurt") ||
           lower.contains("whey") || lower.contains("casein") || lower.contains("lactose") {
            return "Milk"
        }
        if lower.contains("egg") || lower.contains("albumin") || lower.contains("mayonnaise") {
            return "Eggs"
        }
        if lower.contains("peanut") || lower.contains("groundnut") {
            return "Peanuts"
        }
        if lower.contains("almond") || lower.contains("hazelnut") || lower.contains("walnut") ||
           lower.contains("cashew") || lower.contains("pistachio") || lower.contains("pecan") ||
           lower.contains("brazil nut") || lower.contains("macadamia") || lower.contains("nut") {
            return "Tree Nuts"
        }
        if lower.contains("wheat") || lower.contains("gluten") || lower.contains("barley") ||
           lower.contains("rye") || lower.contains("oats") || lower.contains("spelt") ||
           lower.contains("kamut") {
            return "Gluten"
        }
        if lower.contains("soy") || lower.contains("soya") || lower.contains("soybean") ||
           lower.contains("tofu") || lower.contains("edamame") {
            return "Soya"
        }
        if lower.contains("fish") || lower.contains("salmon") || lower.contains("tuna") ||
           lower.contains("cod") || lower.contains("haddock") || lower.contains("trout") {
            return "Fish"
        }
        if lower.contains("shellfish") || lower.contains("shrimp") || lower.contains("prawn") ||
           lower.contains("crab") || lower.contains("lobster") || lower.contains("mussel") ||
           lower.contains("oyster") || lower.contains("clam") {
            return "Shellfish"
        }
        if lower.contains("sesame") || lower.contains("tahini") {
            return "Sesame"
        }
        if lower.contains("celery") || lower.contains("celeriac") {
            return "Celery"
        }
        if lower.contains("mustard") {
            return "Mustard"
        }
        if lower.contains("sulphite") || lower.contains("sulfite") {
            return "Sulphites"
        }

        return nil
    }

    private func loadFoodEntry() async {
        isLoading = true
        defer { isLoading = false }

        // Try to fetch the food entry from the reaction date
        // We'll fetch all meals around the reaction time to find this specific food
        let startTime = reactionDate.addingTimeInterval(-7 * 24 * 3600) // 7 days before
        let endTime = reactionDate

        do {
            let meals = try await DiaryDataManager.shared.getMealsInTimeRange(from: startTime, to: endTime)

            // Find the food entry that matches our meal ID
            if let firstMealId = food.contributingMealIds.first {
                foodEntry = meals.first { $0.id == firstMealId }
            }
        } catch {
            print("Error loading food entry: \(error)")
        }
    }
}

// MARK: - Time Window Row
struct TimeWindowRow: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text("\(count)×")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Allergen Category Card
struct AllergenCategoryCard: View {
    let category: String
    let ingredients: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.red)

            ForEach(ingredients, id: \.self) { ingredient in
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 4, height: 4)

                    Text(ingredient)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(12)
        .background(Color.red.opacity(0.05))
        .cornerRadius(8)
    }
}

struct IngredientHistoryDetailView: View {
    let ingredient: WeightedIngredientScore
    let reactionDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("History for \(ingredient.ingredientName)")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Occurrence history and pattern analysis will be displayed here, showing all times this ingredient appeared before reactions.")
                        .foregroundColor(.secondary)

                    Text("Score: \(Int(ingredient.totalScore))")
                    Text("Occurrences: \(ingredient.occurrences)")
                    Text("Found in foods: \(ingredient.contributingFoodNames.joined(separator: ", "))")

                    if ingredient.symptomAssociationScore > 0 {
                        Text("Pattern detected: This ingredient has appeared before \(ingredient.appearedInSameSymptomCount) similar reactions")
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Ingredient History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AllergenCategoryDetailView: View {
    let category: String
    let entry: ReactionLogEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("\(category) History")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Complete history of all \(category.lowercased())-containing foods consumed before reactions will be displayed here.")
                        .foregroundColor(.secondary)

                    Text("This view will show:")
                        .font(.headline)
                        .padding(.top)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Timeline of \(category.lowercased()) consumption")
                        Text("• Specific ingredients within this category")
                        Text("• Cross-reaction patterns")
                        Text("• Severity trends over time")
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("\(category) Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - String Identifiable Extension

extension String: Identifiable {
    public var id: String { self }
}
