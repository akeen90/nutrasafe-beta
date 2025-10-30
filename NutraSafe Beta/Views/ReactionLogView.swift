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

    var body: some View {
        Group {
            if manager.reactionLogs.isEmpty {
                emptyStateView
            } else {
                reactionListView
            }
        }
        .navigationTitle("Reaction Log")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingLogSheet = true }) {
                    Label("Log Reaction", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingLogSheet) {
            LogReactionSheet()
        }
        .sheet(item: $selectedEntry) { entry in
            ReactionLogDetailView(entry: entry)
        }
        .task {
            await manager.loadReactionLogs()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clipboard.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Reactions Logged")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start tracking reactions to identify possible food triggers")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: { showingLogSheet = true }) {
                Label("Log Your First Reaction", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.top)
        }
    }

    private var reactionListView: some View {
        List {
            // Add New Button at top
            Button(action: { showingLogSheet = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                    Text("Add New Reaction")
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.blue.opacity(0.05))

            ForEach(manager.reactionLogs) { entry in
                ReactionLogCard(entry: entry)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedEntry = entry
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            Task {
                                try? await manager.deleteReactionLog(entry)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
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
        .padding(.vertical, 4)
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

    @State private var selectedType: ReactionType = .headache
    @State private var customType: String = ""
    @State private var reactionDate: Date = Date()
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

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

                Section(header: Text("Notes (Optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }

                Section {
                    Text("The system will automatically analyze your food diary from the 72 hours before this reaction.")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                notes: notesText.isEmpty ? nil : notesText
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

            Text("72-Hour Window")
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
            let maxScore = ingredients.map { Int($0.totalScore) }.max() ?? 0
            return (category, maxScore, ingredients.sorted { $0.totalScore > $1.totalScore })
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
            // Frequency indicator
            Circle()
                .fill(frequencyColor)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

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

            Text("\(frequencyPercentage)%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(frequencyColor)
        }
        .padding(.vertical, 8)
    }

    // Calculate frequency percentage based on occurrences
    private var frequencyPercentage: Int {
        // Convert totalScore (0-100+) to a capped percentage
        return min(100, Int(score.totalScore))
    }

    private var frequencyColor: Color {
        if frequencyPercentage >= 80 {
            return .red
        } else if frequencyPercentage >= 40 {
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
            // Frequency indicator
            Circle()
                .fill(frequencyColor)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

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

            Text("\(frequencyPercentage)%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(frequencyColor)
        }
        .padding(.vertical, 8)
    }

    // Calculate frequency percentage based on occurrences
    private var frequencyPercentage: Int {
        // Convert totalScore (0-100+) to a capped percentage
        return min(100, Int(score.totalScore))
    }

    private var frequencyColor: Color {
        if frequencyPercentage >= 80 {
            return .red
        } else if frequencyPercentage >= 40 {
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

                    // Frequency badge
                    Text("\(min(100, categoryScore))%")
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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("History for \(food.foodName)")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Occurrence history and pattern analysis will be displayed here, showing all times this food was consumed before reactions.")
                        .foregroundColor(.secondary)

                    Text("Score: \(Int(food.totalScore))")
                    Text("Occurrences: \(food.occurrences)")
                    Text("Last seen: \(Int(food.lastSeenHoursBeforeReaction))h before reaction")
                }
                .padding()
            }
            .navigationTitle("Food History")
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
